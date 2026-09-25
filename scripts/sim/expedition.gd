class_name Expedition
extends RefCounted
## Expedition runs: a zone is a run of waves ending in a boss. Defeated wild Aetherlings may be bound
## with Aether Vessels according to the auto-bind settings. Runs repeat on their own; a wiped party
## rests for a while, then tries again.
## state.expedition.battle = {zone, wave, waves, phase: fight|gap|rest, timer, allies, enemies, meals,
##                            freeBinds, runMs, kills}


static func zone_unlocked(s: Dictionary, zone_id: String) -> bool:
	var z: Dictionary = Data.zones[zone_id]
	if z.unlockAfter == null:
		return true
	return zone_state(s, z.unlockAfter).get("cleared", false)


static func zone_state(s: Dictionary, zone_id: String) -> Dictionary:
	if not s.expedition.zones.has(zone_id):
		s.expedition.zones[zone_id] = {"cleared": false, "runs": 0, "bestWave": 0, "kills": 0}
	return s.expedition.zones[zone_id]


static func is_running(s: Dictionary) -> bool:
	return bool(s.expedition.running)


# ---------------------------------------------------------------- party

const PARTY_LOCKED := "The party is out on an expedition. Stop it to change the party."


## The party is fixed for a whole expedition: members join, leave or swap only while it is stopped.
static func party_locked(s: Dictionary) -> bool:
	return is_running(s)


static func set_party_member(s: Dictionary, slot: int, c: Dictionary) -> String:
	if party_locked(s):
		return PARTY_LOCKED
	var party: Array = s.expedition.party
	var size: int = Data.tuning.combat.partySize
	if slot < 0 or slot >= size:
		return "No such party slot."
	if not c.is_empty():
		if c.job.get("kind", "") == "party":
			party.erase(c.id)
		Skills.unassign(s, c)
		c.job = {"kind": "party"}
	while party.size() <= slot:
		party.append("")
	var old: String = party[slot]
	if old != "" and s.creatures.has(old) and (c.is_empty() or old != c.id):
		s.creatures[old].job = {}
	party[slot] = c.id if not c.is_empty() else ""
	_compact_party(s)
	if GameState.party(s).is_empty():
		stop(s)
	return ""


static func remove_from_party(s: Dictionary, c: Dictionary) -> void:
	s.expedition.party.erase(c.id)
	c.job = {}
	_compact_party(s)
	if GameState.party(s).is_empty():
		stop(s)


static func _compact_party(s: Dictionary) -> void:
	s.expedition.party = s.expedition.party.filter(func(id): return id != "" and s.creatures.has(id))


# ---------------------------------------------------------------- run control

static func start(s: Dictionary, zone_id: String, rng: RandomNumberGenerator) -> String:
	if not zone_unlocked(s, zone_id):
		return "Clear the previous island's boss first."
	if GameState.party(s).is_empty():
		return "Choose at least one Aetherling for the party."
	s.expedition.zone = zone_id
	s.expedition.running = true
	_new_run(s, rng)
	return ""


static func stop(s: Dictionary) -> void:
	s.expedition.running = false
	s.expedition.battle = {}


static func _new_run(s: Dictionary, _rng: RandomNumberGenerator) -> void:
	var z: Dictionary = Data.zones[s.expedition.zone]
	var party := GameState.party(s)
	var allies := party.map(func(c): return Combat.ally(c))
	s.expedition.battle = {
		"zone": z.id, "wave": 0, "waves": int(z.waves) + 1, "phase": "gap", "timer": float(Data.tuning.combat.waveGapMs),
		"allies": allies, "enemies": [], "meals": int(GameState.upgrade_value(s, "supply-crates")),
		"freeBinds": int(minf(Traits.cap("free_bind_attempts"), Traits.party_mod(party, "free_bind_attempts"))),
		"runMs": 0.0, "kills": 0,
	}


static func _spawn_wave(s: Dictionary, rng: RandomNumberGenerator, events: Array) -> void:
	var b: Dictionary = s.expedition.battle
	var z: Dictionary = Data.zones[b.zone]
	b.wave = int(b.wave) + 1
	b.enemies = []
	if int(b.wave) >= int(b.waves):
		var boss: Dictionary = z.boss
		b.enemies.append(Combat.wild(boss.model, int(boss.level), int(boss.get("rarity", 1)), false, boss.mult, boss.name, boss.ability, int(boss.form)))
		events.append({"type": "boss_wave", "zone": z.id})
	else:
		var count: int = Rng.pick(rng, z.enemiesPerWave)
		for i in count:
			var w := roll_wild(s, z, rng)
			var mult := {"health": z.enemyMult, "power": z.enemyMult, "guard": z.enemyMult}
			var f := Combat.wild(w.species, w.level, w.rarity, w.shiny, mult)
			b.enemies.append(f)
			if w.shiny:
				events.append({"type": "shiny_spotted", "species": w.species})
	events.append({"type": "wave", "wave": b.wave, "waves": b.waves})


## A random wild encounter for a zone: {species, level, rarity, shiny}. Counts toward shiny pity and marks
## the species as seen in the Aether-Log.
static func roll_wild(s: Dictionary, z: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var sp_id: String = Rng.weighted_key(rng, z.species)
	# a Glimmer Lure makes every rarity above Dim more common
	var weights: Array = z.rarityWeights.duplicate()
	var lure := Market.bonus(s, "wildRarity")
	for i in range(1, weights.size()):
		weights[i] = float(weights[i]) * (1.0 + lure)
	var rarity := Rng.weighted_index(rng, weights) + 1
	var level := rng.randi_range(int(z.levels[0]), int(z.levels[1]))
	var sh: Dictionary = Data.tuning.shiny
	var since := int(s.counters.encountersSinceShiny)
	var p: float = sh.encounterRate
	if since > int(sh.encounterPityStart):
		p = lerpf(sh.encounterRate, 1.0, clampf(float(since - int(sh.encounterPityStart)) / float(int(sh.encounterPityFull) - int(sh.encounterPityStart)), 0.0, 1.0))
	p += float(Data.tuning.pearls.lensWildPerLevel) * GameState.pearl(s, "pearl-lens")
	var shiny := Rng.chance(rng, p)
	s.counters.encountersSinceShiny = 0 if shiny else since + 1
	s.collection.seen[sp_id] = true
	return {"species": sp_id, "level": level, "rarity": rarity, "shiny": shiny}


# ---------------------------------------------------------------- stepping

static func step(s: Dictionary, dt_ms: float, rng: RandomNumberGenerator) -> Array:
	var events := []
	if not is_running(s) or s.expedition.battle.is_empty():
		return events
	var b: Dictionary = s.expedition.battle
	var left := dt_ms
	var guard := 0
	while left > 0.0 and is_running(s) and guard < 10000:
		guard += 1
		b = s.expedition.battle
		match b.phase:
			"gap", "rest":
				var d := minf(left, float(b.timer))
				b.timer = float(b.timer) - d
				b.runMs = float(b.runMs) + d
				left -= d
				if float(b.timer) <= 0.0:
					if b.phase == "rest":
						if s.expedition.autoRepeat:
							_new_run(s, rng)
							events.append({"type": "run_start"})
						else:
							stop(s)
					else:
						_spawn_wave(s, rng, events)
						b.phase = "fight"
			"fight":
				var d := minf(left, 250.0)
				left -= d
				b.runMs = float(b.runMs) + d
				var cev := Combat.step(b.allies, b.enemies, d, rng)
				events.append_array(cev)
				for e in cev:
					if e.type == "down" and e.side == 1:
						_on_enemy_down(s, b.enemies[e.index], rng, events)
				if not Combat.any_alive(b.allies):
					_on_wipe(s, events)
				elif not Combat.any_alive(b.enemies):
					_on_wave_cleared(s, rng, events)
			_:
				stop(s)
	return events


static func _alive_party(s: Dictionary) -> Array:
	var b: Dictionary = s.expedition.battle
	var out := []
	for f in b.allies:
		if f.alive and s.creatures.has(f.cid):
			out.append(s.creatures[f.cid])
	return out


static func kill_xp(level: int, rarity: int, boss := false) -> float:
	var k: Dictionary = Data.tuning.combat.xpPerKill
	var xp := float(k.base) * pow(level, float(k.exp)) * (1.0 + (rarity - 1) * float(Data.tuning.combat.rarityXpPerTier))
	if boss:
		xp *= float(Data.tuning.combat.bossXpMult)
	return xp


static func _on_enemy_down(s: Dictionary, f: Dictionary, rng: RandomNumberGenerator, events: Array) -> void:
	var b: Dictionary = s.expedition.battle
	b.kills = int(b.kills) + 1
	if f.get("boss", false):
		return  # boss rewards land when the wave clears
	defeated_wild(s, Data.zones[b.zone], {"species": f.species, "level": int(f.level), "rarity": int(f.rarity), "shiny": bool(f.shiny)},
		_alive_party(s), rng, events, b)


## Everything that follows a wild Aetherling's defeat: XP, loot, a capture attempt. Shared by live
## battles and the offline extrapolation.
static func defeated_wild(s: Dictionary, z: Dictionary, w: Dictionary, party: Array, rng: RandomNumberGenerator, events: Array, b: Dictionary) -> void:
	s.counters.kills = int(s.counters.kills) + 1
	var zs := zone_state(s, z.id)
	zs.kills = int(zs.kills) + 1
	_party_xp(s, party, kill_xp(int(w.level), int(w.rarity)), events, b)
	var gold := rng.randi_range(int(z.gold[0]), int(z.gold[1]))
	GameState.add_item(s, "gold", gold)
	var loot := {"gold": gold}
	for l in z.loot:
		if Rng.chance(rng, float(l.chance)):
			var q := rng.randi_range(int(l.qty[0]), int(l.qty[1]))
			GameState.add_item(s, l.item, q)
			loot[l.item] = loot.get(l.item, 0) + q
	events.append({"type": "loot", "items": loot})
	try_capture(s, w, party, rng, events, b)


## Combat XP for each party member. One who levels or evolves mid-run fights at the new level at once: its
## fighter in the live battle `b` is refreshed, so XP from every kill shows, not only after the boss.
static func _party_xp(s: Dictionary, party: Array, xp: float, events: Array, b: Dictionary) -> void:
	for c in party:
		var cev := Creatures.add_xp(c, xp * (1.0 + Traits.capped_self(c, "bonus_combat_xp") + Market.bonus(s, "partyXp")))
		if cev.is_empty():
			continue
		for e in cev:
			if e.type == "evolved":
				Collection.on_evolved(s, c)
		events.append_array(cev)
		for f in b.get("allies", []):
			if f.get("cid", "") == c.id:
				Combat.refresh_ally(f, c)


## Picks the vessel the auto-bind settings allow for this encounter, or "" to let it go.
static func choose_vessel(s: Dictionary, w: Dictionary) -> String:
	var ab: Dictionary = s.expedition.autobind
	var vessels := Data.item_list.filter(func(it): return it.category == "vessel" and GameState.count(s, it.id) >= 1)
	if vessels.is_empty():
		return ""
	var want: String = ab.get("vessel", "best")
	if want == "cheapest":
		return vessels[0].id
	if want == "best" or w.get("shiny", false):
		return vessels.back().id
	return want if GameState.count(s, want) >= 1 else ""


static func bind_chance(s: Dictionary, vessel_id: String, rarity: int, party: Array) -> float:
	var v: Dictionary = Data.items[vessel_id].vessel
	var bonus := minf(Traits.cap("bind_rate"), Traits.party_mod(party, "bind_rate"))
	bonus += float(Data.tuning.pearls.bindPerLevel) * GameState.pearl(s, "pearl-vessel")
	return clampf(float(v.base) * pow(float(v.falloff), rarity - 1) * (1.0 + bonus), 0.0, 0.98)


## How many of a species the player owns and the best rarity among them: [count, best rarity].
static func owned_copies(s: Dictionary, species_id: String, cache: Dictionary = {}) -> Array:
	if cache.has(species_id):
		return cache[species_id]
	var n := 0
	var best := 0
	for c in s.creatures.values():
		if c.species == species_id:
			n += 1
			best = maxi(best, int(c.rarity))
	cache[species_id] = [n, best]
	return cache[species_id]


## The auto-bind rules: shinies always; new species if that box is ticked; otherwise the minimum rarity,
## and no more than `maxCopies` of a species unless the new one is rarer than the best one owned.
static func wants_bind(s: Dictionary, w: Dictionary, cache: Dictionary = {}) -> bool:
	var ab: Dictionary = s.expedition.autobind
	if w.get("shiny", false):
		return true
	if not ab.get("enabled", true):
		return false
	if ab.get("newSpecies", true) and not Collection.is_owned(s, w.species):
		return true
	if int(w.rarity) < int(ab.get("minRarity", 1)):
		return false
	var owned := owned_copies(s, w.species, cache)
	return owned[0] < int(ab.get("maxCopies", 5)) or int(w.rarity) > int(owned[1])


static func try_capture(s: Dictionary, w: Dictionary, party: Array, rng: RandomNumberGenerator, events: Array, b: Dictionary) -> void:
	var first_of_type := not Collection.owned_type(s, Data.species[w.species].types[0])
	if first_of_type:
		_bind(s, w, rng, events, "guaranteed")
		return
	if not wants_bind(s, w):
		return
	if int(b.get("freeBinds", 0)) > 0:
		b.freeBinds = int(b.freeBinds) - 1
		if Rng.chance(rng, bind_chance(s, "resonant-vessel", int(w.rarity), party)):
			_bind(s, w, rng, events, "free")
		else:
			events.append({"type": "escaped", "species": w.species, "rarity": w.rarity})
		return
	var vessel := choose_vessel(s, w)
	if vessel == "":
		if w.get("shiny", false):
			s.expedition.pending.append(w)
			events.append({"type": "pending", "species": w.species})
		return
	GameState.add_item(s, vessel, -1)
	if Rng.chance(rng, bind_chance(s, vessel, int(w.rarity), party)):
		_bind(s, w, rng, events, vessel)
	elif w.get("shiny", false):
		# a shiny never flees: it waits in the pending queue for another try
		s.expedition.pending.append(w)
		events.append({"type": "pending", "species": w.species})
	else:
		events.append({"type": "escaped", "species": w.species, "rarity": w.rarity, "vessel": vessel})


static func _bind(s: Dictionary, w: Dictionary, rng: RandomNumberGenerator, events: Array, how: String) -> Dictionary:
	var traits := Traits.roll_fresh(rng, Data.species[w.species].types)
	var c := Creatures.make(s, w.species, int(w.rarity), int(w.level), bool(w.shiny), traits, "wild")
	s.creatures[c.id] = c
	s.counters.captures = int(s.counters.captures) + 1
	events.append({"type": "captured", "creature": c.id, "species": c.species, "rarity": c.rarity, "shiny": c.shiny, "how": how})
	if c.shiny:
		events.append_array(GameState.give_pearls(s, int(Data.tuning.pearls.shinyFound), "a shiny was bound"))
	events.append_array(Collection.on_owned(s, c))
	return c


## Try again on a pending (shiny) bind with a chosen vessel.
static func retry_pending(s: Dictionary, index: int, vessel_id: String, rng: RandomNumberGenerator) -> Array:
	var events := []
	if index < 0 or index >= s.expedition.pending.size() or GameState.count(s, vessel_id) < 1:
		return events
	var w: Dictionary = s.expedition.pending[index]
	GameState.add_item(s, vessel_id, -1)
	if Rng.chance(rng, bind_chance(s, vessel_id, int(w.rarity), GameState.party(s))):
		s.expedition.pending.remove_at(index)
		_bind(s, w, rng, events, vessel_id)
	else:
		events.append({"type": "escaped", "species": w.species, "rarity": w.rarity, "vessel": vessel_id, "pending": true})
	return events


static func _on_wave_cleared(s: Dictionary, rng: RandomNumberGenerator, events: Array) -> void:
	var b: Dictionary = s.expedition.battle
	var z: Dictionary = Data.zones[b.zone]
	var zs := zone_state(s, z.id)
	zs.bestWave = maxi(int(zs.bestWave), int(b.wave))
	if int(b.wave) >= int(b.waves):
		_on_boss_defeated(s, z, rng, events)
		zs.runs = int(zs.runs) + 1
		b.phase = "rest"
		b.timer = float(Data.tuning.combat.waveGapMs) * 2.0
		events.append({"type": "run_complete", "zone": z.id})
		return
	_eat_if_needed(s, events)
	b.phase = "gap"
	b.timer = float(Data.tuning.combat.waveGapMs)


static func _on_boss_defeated(s: Dictionary, z: Dictionary, rng: RandomNumberGenerator, events: Array) -> void:
	var zs := zone_state(s, z.id)
	var first: bool = not zs.cleared
	zs.cleared = true
	s.counters.bossKills = int(s.counters.bossKills) + 1
	var boss: Dictionary = z.boss
	_party_xp(s, _alive_party(s), kill_xp(int(boss.level), 3, true), events, s.expedition.battle)
	var bl: Dictionary = z.bossLoot
	GameState.add_item(s, "gold", float(bl.gold))
	for id in bl.items:
		GameState.add_item(s, id, float(bl.items[id]))
	# the last islands' bosses sometimes leave an Aether Pearl
	if Rng.chance(rng, float(bl.get("pearlChance", 0.0))):
		events.append_array(GameState.give_pearls(s, 1, z.boss.name + " left a pearl"))
	events.append({"type": "boss_defeated", "zone": z.id, "first": first, "loot": bl})
	if first:
		for other in Data.zone_list:
			if other.unlockAfter == z.id:
				events.append({"type": "zone_unlocked", "zone": other.id})
		if z.has("firstClearCreature"):
			var fc: Dictionary = z.firstClearCreature
			var pool := Data.species_list.filter(func(x): return x.kind == "base" and x.types[0] in fc.types)
			var sp: Dictionary = Rng.pick(rng, pool)
			_bind(s, {"species": sp.id, "level": int(boss.level) - 10, "rarity": int(fc.rarity), "shiny": false}, rng, events, "boss")


static func _eat_if_needed(s: Dictionary, events: Array) -> void:
	var b: Dictionary = s.expedition.battle
	if int(b.meals) <= 0:
		return
	var low := false
	for f in b.allies:
		if f.alive and f.hp < f.maxHp * float(Data.tuning.combat.eatBelow):
			low = true
	if not low:
		return
	var meal := pick_meal(s)
	if meal == "":
		return
	GameState.add_item(s, meal, -1)
	b.meals = int(b.meals) - 1
	var heal: float = Data.items[meal].heal
	for f in b.allies:
		if f.alive:
			f.hp = minf(f.maxHp, f.hp + f.maxHp * heal)
	events.append({"type": "ate", "item": meal})


## The meal the party eats: the chosen one if any are left, otherwise the best meal in the pack.
static func pick_meal(s: Dictionary) -> String:
	var want: String = s.expedition.get("meal", "")
	if want != "" and GameState.count(s, want) >= 1:
		return want
	var best := ""
	for it in Data.item_list:
		if it.category == "meal" and GameState.count(s, it.id) >= 1:
			best = it.id
	return best


static func _on_wipe(s: Dictionary, events: Array) -> void:
	var b: Dictionary = s.expedition.battle
	zone_state(s, b.zone).bestWave = maxi(int(zone_state(s, b.zone).bestWave), int(b.wave) - 1)
	b.phase = "rest"
	b.timer = float(Data.tuning.combat.exhaustMs)
	events.append({"type": "wiped", "zone": b.zone, "wave": b.wave})


# ---------------------------------------------------------------- offline

## Runs the real battle for up to `offlineFullRuns` runs, then extrapolates the rest of the window from
## the rates those runs produced (kills, boss clears and meals per ms), rolling each extra encounter.
static func offline(s: Dictionary, ms: float, rng: RandomNumberGenerator) -> Array:
	var events := []
	if not is_running(s) or s.expedition.battle.is_empty():
		return events
	var cb: Dictionary = Data.tuning.combat
	var step_ms: float = cb.offlineStepMs
	var max_runs: int = cb.offlineFullRuns
	var kills0 := int(s.counters.kills)
	var bosses0 := int(s.counters.bossKills)
	var runs := 0
	var simulated := 0.0
	while simulated < ms and runs < max_runs and is_running(s):
		var d := minf(step_ms, ms - simulated)
		var ev := step(s, d, rng)
		simulated += d
		for e in ev:
			if e.type in ["run_complete", "wiped"]:
				runs += 1
			if e.type in ["captured", "evolved", "boss_defeated", "zone_unlocked", "discovered", "pending", "wiped", "escaped", "loot"]:
				events.append(e)
	var remaining := ms - simulated
	if remaining <= 0.0 or not is_running(s) or simulated <= 0.0:
		return events
	var kill_rate := float(int(s.counters.kills) - kills0) / simulated
	var boss_rate := float(int(s.counters.bossKills) - bosses0) / simulated
	var z: Dictionary = Data.zones[s.expedition.zone]
	var party := GameState.party(s)
	var extra_kills := Rng.poisson(rng, kill_rate * remaining) if kill_rate * remaining < 12.0 else roundi(kill_rate * remaining)
	extrapolate_kills(s, z, party, extra_kills, rng, events)
	var extra_bosses := int(floor(boss_rate * remaining))
	for i in extra_bosses:
		_on_boss_defeated(s, z, rng, events)
		zone_state(s, z.id).runs = int(zone_state(s, z.id).runs) + 1
	# keep only the events a summary needs
	return events.filter(func(e): return e.type != "loot")


## `n` wild defeats resolved in bulk: every encounter is still rolled (species, rarity, shiny pity, the
## capture decision), but XP is added once per party member and loot is rolled as totals.
static func extrapolate_kills(s: Dictionary, z: Dictionary, party: Array, n: int, rng: RandomNumberGenerator, events: Array) -> void:
	if n <= 0:
		return
	var xp := 0.0
	var fake_battle := {"freeBinds": 0}
	var cache := {}
	for i in n:
		var w := roll_wild(s, z, rng)
		xp += kill_xp(int(w.level), int(w.rarity))
		if w.shiny or wants_bind(s, w, cache) or not Collection.owned_type(s, Data.species[w.species].types[0]):
			var before: int = s.creatures.size()
			try_capture(s, w, party, rng, events, fake_battle)
			if s.creatures.size() != before:
				cache.erase(w.species)
	s.counters.kills = int(s.counters.kills) + n
	var zs := zone_state(s, z.id)
	zs.kills = int(zs.kills) + n
	for c in party:
		var cev := Creatures.add_xp(c, xp * (1.0 + Traits.capped_self(c, "bonus_combat_xp") + Market.bonus(s, "partyXp")))
		for e in cev:
			if e.type == "evolved":
				Collection.on_evolved(s, c)
		events.append_array(cev)
	GameState.add_item(s, "gold", roundi(n * (float(z.gold[0]) + float(z.gold[1])) / 2.0))
	for l in z.loot:
		var k := Rng.binomial(rng, n, float(l.chance))
		if k > 0:
			GameState.add_item(s, l.item, roundi(k * (float(l.qty[0]) + float(l.qty[1])) / 2.0))
