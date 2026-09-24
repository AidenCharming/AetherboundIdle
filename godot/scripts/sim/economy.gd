class_name Economy
extends RefCounted
## Aether emission from perched (benched) creatures and the Resonance Extractor, selling, Sanctum Works
## upgrades and releasing creatures. Buying lives in Market.


## Benched creatures that sit on a perch, rarest (highest emission) first.
static func perched(s: Dictionary) -> Array:
	var benched: Array = s.creatures.values().filter(func(c): return Creatures.is_benched(c))
	benched.sort_custom(func(a, b):
		var ra := Creatures.bench_rate_per_min(a)
		var rb := Creatures.bench_rate_per_min(b)
		return ra > rb if ra != rb else a.id < b.id)
	var n := int(GameState.upgrade_value(s, "perches"))
	return benched.slice(0, n)


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
	GameState.add_item(s, "aether", value)
	# the rarest (and shinies) leave Aether Pearls behind
	var pearls := int(Data.rarity(int(c.rarity)).get("releasePearls", 0)) + (int(Data.tuning.pearls.shinyRelease) if c.get("shiny", false) else 0)
	if pearls > 0:
		GameState.add_item(s, "aether-pearl", pearls)
	s.counters.released = int(s.counters.released) + 1
	return value


## Who a bulk release would let go: resting, unlocked, not shiny, at or below `max_rarity`, and never the
## best (highest rarity, then level) of each species, so a species is never lost from the Nexus.
static func bulk_release_candidates(s: Dictionary, max_rarity: int) -> Array:
	var best := {}
	for c in s.creatures.values():
		var b: Dictionary = best.get(c.species, {})
		if b.is_empty() or [int(c.rarity), int(c.level)] > [int(b.rarity), int(b.level)]:
			best[c.species] = c
	var out := []
	for c in s.creatures.values():
		if not Creatures.is_benched(c) or c.get("locked", false) or c.shiny or int(c.rarity) > max_rarity:
			continue
		if best[c.species].id == c.id:
			continue
		out.append(c)
	return out


static func bulk_release(s: Dictionary, max_rarity: int) -> Dictionary:
	var list := bulk_release_candidates(s, max_rarity)
	var total := 0
	for c in list:
		var v := release(s, c)
		if v > 0:
			total += v
	return {"count": list.size(), "aether": total}
