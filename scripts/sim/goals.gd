class_name Goals
extends RefCounted
## Overseer Vance's guidance: a chain of goals (data/goals.json) that walks a new player through every system
## and then paces the month to mastery. One goal is active at a time; finishing it pays a reward.

## The chain before it grew to ~100 goals: an old save's goals.index points into this list (see migrate).
const OLD_CHAIN := ["work", "logs", "explore", "bind", "team", "vessel", "wc10", "breed", "hatch", "boss1", "telluric",
	"slot2", "works", "form2", "species10", "boss2", "hybrid", "boss3", "boss4", "boss5", "boss6", "boss7", "boss8",
	"boss9", "boss10", "special"]
## Every check kind progress() understands (tests check data/goals.json against it).
const KINDS := ["working", "item", "expedition", "captures", "creatures", "species", "upgrades", "slots", "form",
	"hybrids", "specials", "counter", "skill_level", "zone", "own_type", "rarity", "creature_level", "total_level",
	"skills_at"]


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
		"captures", "creatures", "species", "upgrades", "slots", "form", "hybrids", "specials", "counter", \
				"rarity", "creature_level", "total_level", "skills_at":
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
				"rarity":
					for cr in s.creatures.values():
						have = maxi(have, int(cr.rarity))
				"creature_level":
					for cr in s.creatures.values():
						have = maxi(have, int(cr.level))
				"total_level":
					for id in s.skills:
						have += int(s.skills[id].level)
				"skills_at":
					for id in s.skills:
						have += 1 if int(s.skills[id].level) >= int(c.level) else 0
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
	s.goals.id = current(s).get("id", "")
	return g


## Keeps a save on the same goal when the chain changes: goals.id names the active goal. A save from before
## goals.id existed used the short OLD_CHAIN, so its index is read against that list.
static func migrate(s: Dictionary) -> void:
	var id: String = s.goals.get("id", "")
	if not s.goals.has("id"):
		var i := int(s.goals.index)
		# past the end of the old chain: carry on after its last goal
		id = OLD_CHAIN[i] if i < OLD_CHAIN.size() else ""
		if id == "":
			s.goals.index = index_of(OLD_CHAIN[-1]) + 1
	if id != "" and index_of(id) >= 0:
		s.goals.index = index_of(id)
	s.goals.index = clampi(int(s.goals.index), 0, Data.goals.size())
	s.goals.id = current(s).get("id", "")


static func index_of(id: String) -> int:
	for i in Data.goals.size():
		if Data.goals[i].id == id:
			return i
	return -1
