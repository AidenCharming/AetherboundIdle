class_name GameState
extends RefCounted
## The shape of a save, new-game setup, inventory helpers and save migration.
## The whole game is one Dictionary so it serialises straight to JSON.

const SAVE_VERSION := 3  # 2: creature XP curve changed; 3: skill and creature curves retuned (levels kept, see migrate)


static func new_game(seed_value: int = 0) -> Dictionary:
	var now := int(Time.get_unix_time_from_system())
	var t: Dictionary = Data.tuning
	var s := {
		"version": SAVE_VERSION,
		"created": now,
		"lastSeen": now,
		"playSeconds": 0.0,
		"awaySeconds": 0.0,
		"rng": {"seed": seed_value, "state": 0},
		"aether": float(t.aether.startingAether),
		"gold": float(t.aether.startingGold),
		"items": {},
		"nextCreatureId": 0,
		"creatures": {},
		"skills": {},
		"expedition": {
			"zone": "",
			"party": [],
			"running": false,
			"autoRepeat": true,
			"meal": "",
			"autobind": {"vessel": "best", "minRarity": 2, "newSpecies": true, "enabled": true, "maxCopies": 5},
			"battle": {},
			"exhaustedUntil": 0,
			"zones": {},
			"pending": [],
			"log": [],
		},
		"pods": [],
		"collection": {"species": {}, "recipes": [], "revealed": [], "claimed": {}, "titles": [], "seen": {}},
		"counters": {"encountersSinceShiny": 0, "hatchesSinceShiny": 0, "hatches": 0, "captures": 0, "kills": 0,
			"actions": 0, "bossKills": 0, "released": 0, "bred": 0},
		"upgrades": {},
		"settings": {"sfx": 0.7, "dev": false, "reduceMotion": false, "title": ""},
		"goals": {"index": 0, "claimed": []},
		"notices": [],
		"market": Market.fresh_state(),
	}
	for skill in Data.skill_list:
		s.skills[skill.id] = {"xp": 0.0, "level": 1, "action": skill.actions[0].id, "levelTimes": {}}
	var start: Dictionary = t.start
	var c := Creatures.make(s, start.creature.species, int(start.creature.rarity), int(start.creature.level), false, [], "start")
	s.creatures[c.id] = c
	Collection.on_owned(s, c)
	for id in start.items:
		add_item(s, id, int(start.items[id]))
	sync_pods(s)
	return s


# ---------------------------------------------------------------- inventory

static func count(s: Dictionary, id: String) -> float:
	if id == "aether":
		return float(s.aether)
	if id == "gold":
		return float(s.gold)
	return float(s.items.get(id, 0))


static func add_item(s: Dictionary, id: String, qty: float) -> void:
	if qty == 0:
		return
	if id == "aether":
		s.aether = maxf(0.0, float(s.aether) + qty)
	elif id == "gold":
		s.gold = maxf(0.0, float(s.gold) + qty)
	else:
		var v := int(s.items.get(id, 0)) + int(qty)
		if v <= 0:
			s.items.erase(id)
		else:
			s.items[id] = v


static func can_afford(s: Dictionary, cost: Dictionary, times := 1) -> bool:
	for id in cost:
		if count(s, id) + 1e-6 < float(cost[id]) * times:
			return false
	return true


static func pay(s: Dictionary, cost: Dictionary, times := 1) -> bool:
	if not can_afford(s, cost, times):
		return false
	for id in cost:
		add_item(s, id, -float(cost[id]) * times)
	return true


# ---------------------------------------------------------------- upgrades

static func upgrade_level(s: Dictionary, id: String) -> int:
	return int(s.upgrades.get(id, 0))


## A Pearl upgrade's level (0 without a state, e.g. a preview with no game loaded).
static func pearl(s: Dictionary, id: String) -> int:
	return 0 if s.is_empty() or not s.has("upgrades") else upgrade_level(s, id)


## Adds Aether Pearls and returns the event that announces them (empty when n is 0).
static func give_pearls(s: Dictionary, n: int, why: String) -> Array:
	if n <= 0:
		return []
	add_item(s, "aether-pearl", n)
	return [{"type": "pearl", "amount": n, "why": why}]


static func upgrade_value(s: Dictionary, id: String) -> float:
	var u: Dictionary = Data.upgrades[id]
	var lv := upgrade_level(s, id)
	return float(u.base) if lv <= 0 else float(u.levels[lv - 1].value)


## How many hours away count as offline progress: the Dream Anchor's hours plus the Pearl Hourglass's.
static func offline_cap_hours(s: Dictionary) -> float:
	return upgrade_value(s, "offline-cap") + float(Data.tuning.pearls.offlineHoursPerLevel) * pearl(s, "pearl-hourglass")


static func pod_count(s: Dictionary) -> int:
	return int(upgrade_value(s, "genesis-pods"))


static func sync_pods(s: Dictionary) -> void:
	while s.pods.size() < pod_count(s):
		s.pods.append({})


# ---------------------------------------------------------------- lookups

static func creature(s: Dictionary, id: String) -> Dictionary:
	return s.creatures.get(id, {})


static func workers(s: Dictionary, skill_id: String) -> Array:
	var out := []
	for c in s.creatures.values():
		if c.job.get("kind", "") == "skill" and c.job.id == skill_id:
			out.append(c)
	out.sort_custom(func(a, b): return int(a.job.get("slot", 0)) < int(b.job.get("slot", 0)))
	return out


static func party(s: Dictionary) -> Array:
	var out := []
	for id in s.expedition.party:
		if s.creatures.has(id):
			out.append(s.creatures[id])
	return out


static func slot_count(s: Dictionary, skill_id: String) -> int:
	var lv := int(s.skills[skill_id].level)
	var n := 0
	for need in Data.tuning.skills.slotLevels:
		if lv >= int(need):
			n += 1
	return n + Market.extra_slots(s, skill_id)


# ---------------------------------------------------------------- save migration

## Brings an older save up to SAVE_VERSION and fills in any key a newer build added.
static func migrate(s: Dictionary) -> Dictionary:
	var fresh := new_game()
	_fill_missing(s, fresh, ["creatures", "items", "skills", "pods", "upgrades", "species", "zones", "claimed", "seen"])
	var skill_max: int = Data.tuning.skills.maxLevel
	for skill in Data.skill_list:
		if not s.skills.has(skill.id):
			s.skills[skill.id] = fresh.skills[skill.id]
			continue
		var st: Dictionary = s.skills[skill.id]
		if not Data.actions[skill.id].has(st.action):
			st.action = skill.actions[0].id
		# as with creatures below: the saved level is kept across a change to the skill XP curve
		st.level = clampi(int(st.get("level", 1)), 1, skill_max)
		if F.level_for_xp(F.skill_curve(), float(st.get("xp", 0.0)), skill_max) != int(st.level):
			st.xp = F.xp_for_level(F.skill_curve(), int(st.level), skill_max)
	for id in s.creatures.keys():
		var c: Dictionary = s.creatures[id]
		if not Data.species.has(c.get("species", "")):
			s.creatures.erase(id)
			continue
		for k in ["job", "progress", "overclock", "nick", "locked", "traits", "shiny"]:
			if not c.has(k):
				c[k] = {"job": {}, "progress": 0.0, "overclock": 0, "nick": "", "locked": false, "traits": [], "shiny": false}[k]
		c.traits = c.traits.filter(func(t): return Data.traits.has(t.id))
		# the saved level is the truth: if the XP curve changed since the save, put the XP back at the start of
		# that level instead of letting the next XP gain recompute (and lower) the level
		var max_lv: int = Data.tuning.creature.maxLevel
		c.level = clampi(int(c.level), 1, max_lv)
		if F.level_for_xp(F.creature_curve(), float(c.xp), max_lv) != int(c.level):
			c.xp = F.xp_for_level(F.creature_curve(), int(c.level), max_lv)
	for id in s.items.keys():
		if not Data.items.has(id):
			s.items.erase(id)
	Goals.migrate(s)
	s.version = SAVE_VERSION
	sync_pods(s)
	return s


static func _fill_missing(target: Dictionary, template: Dictionary, skip: Array) -> void:
	for k in template:
		if not target.has(k):
			target[k] = template[k]
		elif k in skip:
			continue
		elif template[k] is Dictionary and target[k] is Dictionary and k != "creatures":
			_fill_missing(target[k], template[k], skip)
