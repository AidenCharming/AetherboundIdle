class_name Skills
extends RefCounted
## Skill work: creatures in work slots complete actions on their own cooldown. step() is used both
## online (dt = one frame) and offline (dt = a slice of the away window), completing whole batches of
## actions at once, so offline progress is time / cooldown in bulk, never a replay of ticks.


## The action a skill is set to, falling back to the best one its level allows.
static func current_action(s: Dictionary, skill_id: String) -> Dictionary:
	var st: Dictionary = s.skills[skill_id]
	var acts: Dictionary = Data.actions[skill_id]
	var a: Dictionary = acts.get(st.action, {})
	if a.is_empty() or int(a.level) > int(st.level):
		a = {}
		for cand in Data.skills[skill_id].actions:
			if int(cand.level) <= int(st.level):
				a = cand
		st.action = a.id
	return a


static func action_unlocked(s: Dictionary, skill_id: String, action_id: String) -> bool:
	return int(Data.actions[skill_id][action_id].level) <= int(s.skills[skill_id].level)


# ---------------------------------------------------------------- auras

## Every aura given by a working creature: [{giver, group, key, scope, value}].
static func active_auras(s: Dictionary) -> Array:
	var out := []
	for skill in Data.skill_list:
		for c in GameState.workers(s, skill.id):
			for a in Traits.auras_of(c):
				a.giver = c.id
				a.skill = c.job.id
				out.append(a)
	return out


## Strongest aura value per group that reaches `c` while it works `skill_id`.
static func aura_bonus(c: Dictionary, skill_id: String, auras: Array) -> float:
	var best := {}
	for a in auras:
		var scope: Dictionary = a.scope
		var applies := false
		match scope.target:
			"other-active-in-skill":
				applies = a.giver != c.id and a.skill == skill_id and skill_id in scope.get("skills", [skill_id])
			"active-creatures":
				applies = false
				for t in scope.get("types", []):
					if t in Creatures.types_of(c):
						applies = true
		if applies:
			best[a.group] = maxf(best.get(a.group, 0.0), a.value)
	var total := 0.0
	for v in best.values():
		total += v
	return total


static func overclock_bonus(c: Dictionary) -> float:
	var sp: Dictionary = Data.species[c.species]
	var sig: Dictionary = Data.traits.get(sp.signatureTrait, {})
	for eff in sig.get("effects", []):
		if eff.has("dynamic"):
			var oc: Dictionary = Data.tuning.overclocked
			return mini(int(c.get("overclock", 0)), int(oc.maxStacks)) * float(oc.perStack)
	return 0.0


static func cooldown_reduction(c: Dictionary, skill_id: String, auras: Array) -> float:
	var red := Traits.self_mod(c, "cooldown_reduction", skill_id) + aura_bonus(c, skill_id, auras) + overclock_bonus(c)
	return minf(Traits.cap("cooldown_reduction"), red)


## `speed` is the running work-speed boost (see speed()).
static func worker_cooldown(c: Dictionary, skill_id: String, action: Dictionary, auras: Array, speed_mult := 1.0) -> float:
	return F.cooldown_ms(float(action.ms), Creatures.efficiency(c, skill_id), int(c.level), int(c.rarity), Creatures.form_of(c),
		cooldown_reduction(c, skill_id, auras)) / speed_mult


## Every worker's speed multiplier from a running Market boost (Tinker's Brew).
static func speed(s: Dictionary) -> float:
	return 1.0 + Market.bonus(s, "workSpeed")


# ---------------------------------------------------------------- stepping

static func step(s: Dictionary, dt_ms: float, rng: RandomNumberGenerator, offline := false) -> Array:
	var events := []
	if dt_ms <= 0.0:
		return events
	var auras := active_auras(s)
	var sp := speed(s)
	for skill in Data.skill_list:
		var ws := GameState.workers(s, skill.id)
		if ws.is_empty():
			continue
		var action := current_action(s, skill.id)
		for c in ws:
			var cd := worker_cooldown(c, skill.id, action, auras, sp)
			c.progress = float(c.progress) + dt_ms
			var n := int(floor(c.progress / cd + 1e-9))
			if n <= 0:
				c.erase("stalled")
				continue
			var done := complete(s, c, skill.id, action, n, rng, offline, events)
			if done < n:
				c.progress = cd
				c.stalled = true
			else:
				c.progress -= n * cd
				c.erase("stalled")
	return events


## Max whole actions the inventory can pay for, ignoring material saves.
static func affordable(s: Dictionary, action: Dictionary) -> int:
	var inputs: Dictionary = action.get("inputs", {})
	if inputs.is_empty():
		return 1 << 30
	var n := 1 << 30
	for id in inputs:
		n = mini(n, int(floor(GameState.count(s, id) / float(inputs[id]))))
	return n


## Completes up to `n` actions for one worker. Returns how many were done (fewer when inputs run out).
static func complete(s: Dictionary, c: Dictionary, skill_id: String, action: Dictionary, n: int, rng: RandomNumberGenerator,
		offline: bool, events: Array) -> int:
	var inputs: Dictionary = action.get("inputs", {})
	var tun: Dictionary = Data.tuning
	var gained := {}
	if not inputs.is_empty():
		var p_save := Traits.capped_self(c, "save_material_chance", skill_id)
		var can := affordable(s, action)
		if can <= 0:
			return 0
		# Saved materials stretch the stock: allow a few more actions than the raw count, then settle.
		var stretch := int(floor(can / maxf(0.05, 1.0 - p_save)))
		n = mini(n, stretch)
		var saved := Rng.binomial(rng, n, p_save)
		var charged := mini(n - saved, can)
		n = charged + saved
		GameState.pay(s, inputs, charged)
		if saved > 0:
			gained["_saved"] = saved
	if n <= 0:
		return 0
	# outputs
	var p_extra := Traits.self_mod(c, "extra_output_chance", skill_id)
	if offline:
		p_extra += Traits.self_mod(c, "offline_extra_output_chance", skill_id)
	p_extra = minf(Traits.cap("extra_output_chance"), p_extra)
	var extra := Rng.binomial(rng, n, p_extra)
	for id in action.outputs:
		var q: int = int(action.outputs[id]) * (n + extra)
		GameState.add_item(s, id, q)
		gained[id] = gained.get(id, 0) + q
	# rare drop and treasure
	var rare_scale: float = tun.skills.get("rareBonusScale", 10.0)
	if action.has("rare"):
		var p: float = action.rare.chance * (1.0 + rare_scale * Traits.capped_self(c, "rare_drop_chance", skill_id))
		var k := Rng.binomial(rng, n, p)
		if k > 0:
			GameState.add_item(s, action.rare.item, k)
			gained[action.rare.item] = gained.get(action.rare.item, 0) + k
			events.append({"type": "rare_drop", "skill": skill_id, "item": action.rare.item, "qty": k, "creature": c.id})
	if action.has("treasure"):
		var p: float = action.treasure.chance * (1.0 + rare_scale * Traits.capped_self(c, "treasure_drop_chance", skill_id))
		var k := Rng.binomial(rng, n, p)
		if k > 0:
			GameState.add_item(s, action.treasure.item, k)
			gained[action.treasure.item] = gained.get(action.treasure.item, 0) + k
			events.append({"type": "rare_drop", "skill": skill_id, "item": action.treasure.item, "qty": k, "creature": c.id})
	for pd in partner_drops_for(c, skill_id, action):
		var k := Rng.binomial(rng, n, pd.chance)
		if k > 0:
			GameState.add_item(s, pd.item, k)
			gained[pd.item] = gained.get(pd.item, 0) + k
	if action.has("gold"):
		var g := int(action.gold) * n
		GameState.add_item(s, "gold", g)
		gained["gold"] = gained.get("gold", 0) + g
	# XP
	var xp: float = float(action.xp) * n * (1.0 + Traits.capped_self(c, "bonus_xp", skill_id))
	events.append_array(add_skill_xp(s, skill_id, xp))
	var cev := Creatures.add_xp(c, xp * float(tun.creature.workXpShare))
	for e in cev:
		if e.type == "evolved":
			Collection.on_evolved(s, c)
	events.append_array(cev)
	c.overclock = int(c.get("overclock", 0)) + n
	s.counters.actions = int(s.counters.actions) + n
	events.append({"type": "produced", "skill": skill_id, "creature": c.id, "n": n, "items": gained, "xp": xp})
	return n


## A worker's trait bonuses on this action, as the numbers complete() actually uses (capped), for the UI:
## [{key, value}] plus {key: "partner_element_drop_chance", value, type} per partner drop. Speed is left
## out (it shows as the cooldown), and so is anything that does nothing on this action.
static func work_perks(c: Dictionary, skill_id: String, action: Dictionary) -> Array:
	var out := []
	var extra := Traits.capped_self(c, "extra_output_chance", skill_id)
	if extra > 0.0:
		out.append({"key": "extra_output_chance", "value": extra})
	var away := minf(Traits.cap("extra_output_chance"), Traits.self_mod(c, "extra_output_chance", skill_id)
		+ Traits.self_mod(c, "offline_extra_output_chance", skill_id)) - extra
	if away > 0.0:
		out.append({"key": "offline_extra_output_chance", "value": away})
	if not action.get("inputs", {}).is_empty():
		var save := Traits.capped_self(c, "save_material_chance", skill_id)
		if save > 0.0:
			out.append({"key": "save_material_chance", "value": save})
	var rare_scale: float = Data.tuning.skills.get("rareBonusScale", 10.0)
	for pair in [["rare", "rare_drop_chance"], ["treasure", "treasure_drop_chance"]]:
		if action.has(pair[0]):
			var v := Traits.capped_self(c, pair[1], skill_id)
			if v > 0.0:
				out.append({"key": pair[1], "value": rare_scale * v, "item": action[pair[0]].item})
	var xp := Traits.capped_self(c, "bonus_xp", skill_id)
	if xp > 0.0:
		out.append({"key": "bonus_xp", "value": xp})
	for pd in partner_drops_for(c, skill_id, action):
		out.append({"key": "partner_element_drop_chance", "value": pd.chance, "item": pd.item})
	return out


## Partner-element drops this worker would roll on this action: [{item, chance}].
static func partner_drops_for(c: Dictionary, skill_id: String, action: Dictionary) -> Array:
	var out := []
	for pd in Traits.partner_drops(c, skill_id):
		var id := element_item(pd.type, int(Data.items[action.outputs.keys()[0]].tier))
		if id != "":
			out.append({"item": id, "chance": pd.chance})
	return out


## The item of an element type at a tier (partner-element drops), or the nearest lower tier.
static func element_item(type_id: String, tier: int) -> String:
	var best := ""
	var best_tier := 0
	for it in Data.item_list:
		if it.get("element", "") == type_id and int(it.tier) <= tier and int(it.tier) > best_tier and it.category != "rare":
			best = it.id
			best_tier = int(it.tier)
	return best


static func add_skill_xp(s: Dictionary, skill_id: String, xp: float) -> Array:
	var events := []
	var st: Dictionary = s.skills[skill_id]
	var max_lv: int = Data.tuning.skills.maxLevel
	var before := int(st.level)
	var slots_before := GameState.slot_count(s, skill_id)
	st.xp = minf(float(st.xp) + xp, F.xp_for_level(F.skill_curve(), max_lv, max_lv))
	st.level = F.level_for_xp(F.skill_curve(), st.xp, max_lv)
	if int(st.level) > before:
		for lv in range(before + 1, int(st.level) + 1):
			st.levelTimes[str(lv)] = int(Time.get_unix_time_from_system())
		events.append({"type": "skill_level", "skill": skill_id, "level": st.level, "from": before})
		if GameState.slot_count(s, skill_id) > slots_before:
			events.append({"type": "slot_unlocked", "skill": skill_id, "slots": GameState.slot_count(s, skill_id)})
		for a in Data.skills[skill_id].actions:
			if int(a.level) > before and int(a.level) <= int(st.level):
				events.append({"type": "action_unlocked", "skill": skill_id, "action": a.id})
	return events


# ---------------------------------------------------------------- assignment

## Puts a creature to work in a skill's first free slot. Returns "" on success or a reason.
static func assign(s: Dictionary, c: Dictionary, skill_id: String) -> String:
	if not Creatures.can_work(c, skill_id):
		var t: Dictionary = Data.types[Data.skills[skill_id].type]
		return "%s needs a %s Aetherling." % [Data.skills[skill_id].name, t.name]
	var ws := GameState.workers(s, skill_id)
	var slots := GameState.slot_count(s, skill_id)
	if c.job.get("kind", "") == "skill" and c.job.id == skill_id:
		return ""
	if ws.size() >= slots:
		return "Every %s slot is full." % Data.skills[skill_id].name
	var used := ws.map(func(w): return int(w.job.get("slot", 0)))
	var slot := 0
	while slot in used:
		slot += 1
	unassign(s, c)
	c.job = {"kind": "skill", "id": skill_id, "slot": slot}
	GameState.roster_changed()
	c.progress = 0.0
	c.overclock = 0
	return ""


## Resting Aetherlings who could fill this skill's empty slots, best first (most product per hour on the
## current task), no more than there are empty slots. Workers elsewhere and the party are left alone.
static func fill_candidates(s: Dictionary, skill_id: String) -> Array:
	var free := GameState.slot_count(s, skill_id) - GameState.workers(s, skill_id).size()
	if free <= 0:
		return []
	var action := current_action(s, skill_id)
	var auras := active_auras(s)
	var keyed := []
	for c in s.creatures.values():
		if Creatures.is_benched(c) and Creatures.can_work(c, skill_id):
			keyed.append([float(work_rates(c, skill_id, action, auras).output), int(c.level), c])
	keyed.sort_custom(func(a, b): return [a[0], a[1]] > [b[0], b[1]])
	return keyed.slice(0, free).map(func(k): return k[2])


## Whether "Fill empty slots" has anyone to place: fill_candidates without ranking the whole roster.
static func can_fill(s: Dictionary, skill_id: String) -> bool:
	if GameState.slot_count(s, skill_id) <= GameState.workers(s, skill_id).size():
		return false
	for c in s.creatures.values():
		if Creatures.is_benched(c) and Creatures.can_work(c, skill_id):
			return true
	return false


## Puts the best resting Aetherlings into every empty slot of a skill. Returns how many went to work.
static func fill_slots(s: Dictionary, skill_id: String) -> int:
	var n := 0
	for c in fill_candidates(s, skill_id):
		if assign(s, c, skill_id) == "":
			n += 1
	return n


static func unassign(s: Dictionary, c: Dictionary) -> void:
	if c.job.get("kind", "") == "party":
		s.expedition.party.erase(c.id)
	c.job = {}
	GameState.roster_changed()
	c.progress = 0.0
	c.overclock = 0
	c.erase("stalled")


## What a worker would make per hour on an action, reckoned as complete() rolls it: its cooldown, the product
## (with extra-output rolls, online) and secondary finds (rare drop, treasure and partner-element drops).
## The worker picker sorts by these.
static func work_rates(c: Dictionary, skill_id: String, action: Dictionary, auras: Array, sp := 1.0) -> Dictionary:
	var cd := worker_cooldown(c, skill_id, action, auras, sp)
	var per := 3600000.0 / cd
	var qty := 0.0
	for id in action.outputs:
		qty += float(action.outputs[id])
	var rare_scale: float = Data.tuning.skills.get("rareBonusScale", 10.0)
	var finds := 0.0
	for pair in [["rare", "rare_drop_chance"], ["treasure", "treasure_drop_chance"]]:
		if action.has(pair[0]):
			finds += float(action[pair[0]].chance) * (1.0 + rare_scale * Traits.capped_self(c, pair[1], skill_id))
	for pd in partner_drops_for(c, skill_id, action):
		finds += float(pd.chance)
	return {"cooldown": cd, "output": per * qty * (1.0 + Traits.capped_self(c, "extra_output_chance", skill_id)), "secondary": per * finds}


## Expected output per hour for one worker (for the UI).
static func per_hour(s: Dictionary, c: Dictionary, skill_id: String) -> Dictionary:
	var action := current_action(s, skill_id)
	var cd := worker_cooldown(c, skill_id, action, active_auras(s), speed(s))
	var per := 3600000.0 / cd
	return {"actions": per, "cooldown": cd, "xp": per * float(action.xp) * (1.0 + Traits.capped_self(c, "bonus_xp", skill_id))}
