class_name Offline
extends RefCounted
## Progress while the game was closed. Time away is capped (Dream Anchor upgrade), then split into a few
## slices so crafting chains can feed each other (logs chopped in slice 1 are smelted in slice 2).
## Every slice completes its actions in bulk: elapsed / cooldown, never a replay of ticks.


static func apply(s: Dictionary, elapsed_sec: float, rng: RandomNumberGenerator) -> Dictionary:
	var cap := GameState.upgrade_value(s, "offline-cap") * 3600.0
	var used := clampf(elapsed_sec, 0.0, cap)
	var before := snapshot(s)
	var events := []
	if used > 0.0:
		var segments := maxi(1, int(Data.tuning.offline.segments))
		var slice := used / segments
		for i in segments:
			events.append_array(Skills.step(s, slice * 1000.0, rng, true))
		Economy.step(s, used)
		events.append_array(Expedition.offline(s, used * 1000.0, rng))
	s.awaySeconds = float(s.get("awaySeconds", 0.0)) + used
	var summary := diff(s, before, events)
	summary.elapsed = elapsed_sec
	summary.usedSeconds = used
	summary.capped = elapsed_sec > cap
	return summary


static func snapshot(s: Dictionary) -> Dictionary:
	var levels := {}
	for id in s.skills:
		levels[id] = int(s.skills[id].level)
	return {"items": s.items.duplicate(), "aether": float(s.aether), "gold": float(s.gold), "levels": levels,
		"creatures": s.creatures.size()}


## What changed: items gained and used, currencies, skill levels, notable events.
static func diff(s: Dictionary, before: Dictionary, events: Array) -> Dictionary:
	var gained := {}
	var used := {}
	var ids := {}
	for id in before.items:
		ids[id] = true
	for id in s.items:
		ids[id] = true
	for id in ids:
		var d := int(s.items.get(id, 0)) - int(before.items.get(id, 0))
		if d > 0:
			gained[id] = d
		elif d < 0:
			used[id] = -d
	var levels := {}
	for id in s.skills:
		if int(s.skills[id].level) > int(before.levels.get(id, 1)):
			levels[id] = [int(before.levels.get(id, 1)), int(s.skills[id].level)]
	var notable := events.filter(func(e): return e.type in ["evolved", "captured", "boss_defeated", "zone_unlocked", "slot_unlocked", "discovered", "shiny"])
	var actions := 0
	for e in events:
		if e.type == "produced":
			actions += int(e.n)
	return {"gained": gained, "used": used, "aether": float(s.aether) - before.aether, "gold": float(s.gold) - before.gold,
		"levels": levels, "events": notable, "actions": actions, "newCreatures": s.creatures.size() - int(before.creatures)}
