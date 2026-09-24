class_name Goals
extends RefCounted
## Overseer Vance's guidance: a short chain of goals (data/goals.json) that walks a new player through
## every system. One goal is active at a time; finishing it pays a small reward.


static func current(s: Dictionary) -> Dictionary:
	var i := int(s.goals.index)
	return Data.goals[i] if i < Data.goals.size() else {}


## [have, need] for a goal.
static func progress(s: Dictionary, g: Dictionary) -> Array:
	var c: Dictionary = g.check
	match c.kind:
		"working":
			return [mini(1, GameState.workers(s, c.skill).size()), 1]
		"item":
			return [mini(int(GameState.count(s, c.item)), int(c.n)), int(c.n)]
		"expedition":
			return [1 if Expedition.is_running(s) or int(s.counters.kills) > 0 else 0, 1]
		"captures", "creatures", "species", "upgrades", "slots", "form", "hybrids", "specials", "counter":
			var have := 0
			match c.kind:
				"captures":
					have = int(s.counters.captures)
				"creatures":
					have = s.creatures.size()
				"species":
					have = s.collection.species.size()
				"upgrades":
					for id in s.upgrades:
						have += int(s.upgrades[id])
				"slots":
					for skill in Data.skill_list:
						have = maxi(have, GameState.slot_count(s, skill.id))
				"form":
					for cr in s.creatures.values():
						have = maxi(have, Creatures.form_of(cr))
				"hybrids":
					have = s.collection.recipes.size()
				"specials":
					have = s.collection.recipes.filter(func(id): return Data.species[id].kind == "special").size()
				"counter":
					have = int(s.counters.get(c.counter, 0))
			return [mini(have, int(c.n)), int(c.n)]
		"skill_level":
			return [mini(int(s.skills[c.skill].level), int(c.n)), int(c.n)]
		"zone":
			return [1 if Expedition.zone_state(s, c.zone).cleared else 0, 1]
		"own_type":
			return [1 if Collection.owned_type(s, c.type) else 0, 1]
	return [0, 1]


static func is_done(s: Dictionary, g: Dictionary) -> bool:
	var p := progress(s, g)
	return p[0] >= p[1]


## Pays the active goal's reward and moves on. Returns the goal or {}.
static func claim(s: Dictionary) -> Dictionary:
	var g := current(s)
	if g.is_empty() or not is_done(s, g):
		return {}
	var r: Dictionary = g.reward
	for k in ["aether", "gold"]:
		if r.has(k):
			GameState.add_item(s, k, float(r[k]))
	for id in r.get("items", {}):
		GameState.add_item(s, id, float(r.items[id]))
	s.goals.index = int(s.goals.index) + 1
	return g
