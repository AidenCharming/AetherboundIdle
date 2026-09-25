class_name Economy
extends RefCounted
## Aether emission from perched (benched) creatures and the Resonance Extractor, selling, Sanctum Works
## upgrades and releasing creatures. Buying lives in Market.


## Benched creatures that sit on a perch, rarest (highest emission) first.
## The resting Aetherlings on the perches (kept by GameState's roster index).
static func perched(s: Dictionary) -> Array:
	return GameState.perched(s)


## Works out the perch holders: the best emitters, highest rate first (ties by id).
static func find_perched(s: Dictionary) -> Array:
	# one pass keeping the best n (n is the perch count, small): a full sort of thousands resting was most
	# of a frame, and so was working out each one's rate once per comparison
	var n := int(GameState.upgrade_value(s, "perches"))
	var best := []   # [rate, id, creature], best first
	for c in s.creatures.values():
		if not Creatures.is_benched(c):
			continue
		var r := Creatures.bench_rate_per_min(c)
		if best.size() >= n and not _ahead(r, c.id, best[-1]):
			continue
		var i := best.size()
		while i > 0 and _ahead(r, c.id, best[i - 1]):
			i -= 1
		best.insert(i, [r, c.id, c])
		if best.size() > n:
			best.pop_back()
	return best.map(func(e): return e[2])


static func _ahead(rate: float, id: String, e: Array) -> bool:
	return rate > float(e[0]) or (rate == float(e[0]) and id < String(e[1]))


static func bench_aether_per_min(s: Dictionary) -> float:
	var total := 0.0
	for c in perched(s):
		total += Creatures.bench_rate_per_min(c)
	return total


static func aether_per_min(s: Dictionary) -> float:
	return (bench_aether_per_min(s) + GameState.upgrade_value(s, "extractor")) * (1.0 + Market.bonus(s, "aether"))


## Emission accrues continuously from dt, so online and offline can never drift apart.
static func step(s: Dictionary, dt_sec: float) -> float:
	var gain := aether_per_min(s) * dt_sec / 60.0
	s.aether = float(s.aether) + gain
	return gain


static func sell(s: Dictionary, id: String, qty: int) -> int:
	qty = mini(qty, int(GameState.count(s, id)))
	if qty <= 0 or not Data.items.has(id):
		return 0
	var gold := int(Data.items[id].sell) * qty
	GameState.add_item(s, id, -qty)
	GameState.add_item(s, "gold", gold)
	return gold


## Aether Crystals turn into Aether.
static func shatter(s: Dictionary, id: String, qty: int) -> float:
	var it: Dictionary = Data.items.get(id, {})
	qty = mini(qty, int(GameState.count(s, id)))
	if qty <= 0 or not it.has("aether"):
		return 0.0
	GameState.add_item(s, id, -qty)
	var gain := float(it.aether) * qty
	GameState.add_item(s, "aether", gain)
	return gain


## Everything an item is good for besides selling: [{kind, name, ...}] with kind "recipe" (a skill task that uses
## it, with skill and level), "upgrade" (a Sanctum Works build), "breeding" (a Genesis Pods material), "vessel",
## "meal" or "shatter". Empty means it is only worth its gold.
static func uses(id: String) -> Array:
	var out := []
	var it: Dictionary = Data.items.get(id, {})
	if it.is_empty():
		return out
	match str(it.category):
		"vessel":
			out.append({"kind": "vessel", "name": "Binding wild Aetherlings on expeditions"})
		"meal":
			out.append({"kind": "meal", "name": "Healing the party between waves"})
	if it.has("aether"):
		out.append({"kind": "shatter", "name": "Shatter into %s Aether" % F.format_num(float(it.aether))})
	for sk in Data.skill_list:
		for a in sk.actions:
			if a.has("inputs") and a.inputs.has(id):
				out.append({"kind": "recipe", "name": a.name, "skill": sk.id, "level": int(a.level), "qty": int(a.inputs[id])})
	for u in Data.upgrade_list:
		for lv in u.levels:
			if lv.cost.has(id):
				out.append({"kind": "upgrade", "name": u.name, "id": u.id})
				break
	if it.has("element") and it.category != "rare" and Breeding.material(str(it.element), int(it.tier)) == id:
		out.append({"kind": "breeding", "name": "Tier %d eggs in Genesis Pods (%s parents)" % [int(it.tier), Data.types[it.element].name]})
	return out


## Where the item comes from, at base odds (traits and boosts raise the chances): a skill action that makes it,
## an action's rare drop or treasure (chance per action), an island's loot (chance per wild Aetherling beaten,
## with the amount), a boss's reward (every win) and the Market. Each is a Dictionary with a "kind".
static func sources(id: String) -> Array:
	var out := []
	for sk in Data.skill_list:
		for a in sk.actions:
			if a.outputs.has(id):
				out.append({"kind": "make", "name": a.name, "skill": sk.id, "level": int(a.level), "qty": int(a.outputs[id])})
			for k in ["rare", "treasure"]:
				if a.has(k) and a[k].item == id:
					out.append({"kind": k, "name": a.name, "skill": sk.id, "level": int(a.level), "chance": float(a[k].chance)})
	for z in Data.zone_list:
		for l in z.loot:
			if l.item == id:
				out.append({"kind": "loot", "zone": z.id, "name": z.name, "chance": float(l.chance), "qty": [int(l.qty[0]), int(l.qty[1])]})
		var bl: Dictionary = z.bossLoot
		if bl.items.has(id):
			out.append({"kind": "boss", "zone": z.id, "name": z.boss.name, "island": z.name, "qty": int(bl.items[id])})
		if id == "aether-pearl" and float(bl.get("pearlChance", 0.0)) > 0.0:
			out.append({"kind": "boss", "zone": z.id, "name": z.boss.name, "island": z.name, "qty": 1, "chance": float(bl.pearlChance)})
	if Market.sells(id):
		out.append({"kind": "market", "name": "Market", "price": Market.buy_price(id)})
	return out


static func next_upgrade(s: Dictionary, id: String) -> Dictionary:
	var u: Dictionary = Data.upgrades[id]
	var lv := GameState.upgrade_level(s, id)
	return u.levels[lv] if lv < u.levels.size() else {}


static func buy_upgrade(s: Dictionary, id: String) -> String:
	var nxt := next_upgrade(s, id)
	if nxt.is_empty():
		return "Already at the highest level."
	if not GameState.pay(s, nxt.cost):
		return "Not enough materials."
	s.upgrades[id] = GameState.upgrade_level(s, id) + 1
	GameState.roster_changed()   # more perches
	GameState.sync_pods(s)
	return ""


static func release(s: Dictionary, c: Dictionary) -> int:
	if c.get("locked", false):
		return -1
	if s.creatures.size() <= 1:
		return -1
	var value := Creatures.release_value(c)
	Skills.unassign(s, c)
	s.creatures.erase(c.id)
	GameState.roster_changed()
	GameState.add_item(s, "aether", value)
	# the rarest (and shinies) leave Aether Pearls behind
	var pearls := int(Data.rarity(int(c.rarity)).get("releasePearls", 0)) + (int(Data.tuning.pearls.shinyRelease) if c.get("shiny", false) else 0)
	if pearls > 0:
		GameState.add_item(s, "aether-pearl", pearls)
	s.counters.released = int(s.counters.released) + 1
	return value


## Bulk release options, all optional: minRarity/maxRarity (tiers, inclusive), type and species ("" for any),
## maxLevel (0 for any), keepPerSpecies (the best N of each species by rarity, then level, then shiny always stay,
## counting every one you own), shinies and working (let those go too). Locked Aetherlings and the expedition
## party always stay, and so does your last Aetherling.
const BULK_DEFAULTS := {"minRarity": 1, "maxRarity": 1, "type": "", "species": "", "maxLevel": 0, "keepPerSpecies": 1,
	"shinies": false, "working": false}


## Who a bulk release would let go, and why each other Aetherling stays: {list, kept: {reason: count}}.
static func bulk_release_plan(s: Dictionary, opts: Dictionary) -> Dictionary:
	var o := BULK_DEFAULTS.duplicate()
	o.merge(opts, true)
	var keep_n := maxi(0, int(o.keepPerSpecies))
	var by_species := {}
	for c in s.creatures.values():
		if not by_species.has(c.species):
			by_species[c.species] = []
		by_species[c.species].append(c)
	var best := {}
	for sp in by_species:
		var ranked: Array = by_species[sp].map(func(c): return [[int(c.rarity), int(c.level), int(bool(c.shiny))], c.id])
		ranked.sort_custom(func(a, b): return a[0] > b[0])
		for i in mini(keep_n, ranked.size()):
			best[ranked[i][1]] = true
	var kept := {}
	var out := []
	for c in s.creatures.values():
		var why := ""
		var kind := Creatures.job_kind(c)
		if c.get("locked", false):
			why = "locked"
		elif kind == "party":
			why = "in the party"
		elif kind == "skill" and not o.working:
			why = "working"
		elif c.shiny and not o.shinies:
			why = "shiny"
		elif int(c.rarity) < int(o.minRarity) or int(c.rarity) > int(o.maxRarity):
			why = "other rarity"
		elif o.type != "" and not (o.type in Creatures.types_of(c)):
			why = "other type"
		elif o.species != "" and c.species != o.species:
			why = "other species"
		elif int(o.maxLevel) > 0 and int(c.level) > int(o.maxLevel):
			why = "above the level"
		elif best.has(c.id):
			why = "best of its species"
		if why == "":
			out.append(c)
		else:
			kept[why] = int(kept.get(why, 0)) + 1
	if not out.is_empty() and out.size() >= s.creatures.size():
		out.pop_back()
		kept["your last one"] = 1
	return {"list": out, "kept": kept}


## `opts` is the options Dictionary, or (the older form) the highest rarity with `under_level` (0: any) the
## level they must be under.
static func bulk_release_candidates(s: Dictionary, opts: Variant, under_level := 0) -> Array:
	if not opts is Dictionary:
		opts = {"maxRarity": int(opts), "maxLevel": under_level - 1 if under_level > 0 else 0}
	return bulk_release_plan(s, opts).list


static func bulk_release(s: Dictionary, opts: Variant, under_level := 0) -> Dictionary:
	var list := bulk_release_candidates(s, opts, under_level)
	var total := 0
	var count := 0
	var pearls_before := GameState.count(s, "aether-pearl")
	for c in list:
		var v := release(s, c)
		if v > 0:
			total += v
			count += 1
	return {"count": count, "aether": total, "pearls": int(GameState.count(s, "aether-pearl") - pearls_before)}
