class_name Achievements
extends RefCounted
## Achievements (data/achievements.json): one-time badges with a small Aether/gold reward and, for a few, a
## player title. Checks reuse Goals.progress for the kinds goals already know; the rest are below. Secret ones
## come from pokes the UI reports (Game.poke) and from play-pattern counters.

const CATEGORIES := ["skills", "nexus", "adventure", "breeding", "secret"]
## Check kinds only achievements use (the rest are Goals.KINDS).
const KINDS := ["secret", "log", "kind_owned", "all_types", "perches_full", "gold_peak", "riches_to_rags"]

static var _check_in := 0.0


static func fresh_state() -> Dictionary:
	return {"unlocked": {}, "seen": {}, "secrets": {}, "quiet": 0}


static func is_unlocked(s: Dictionary, id: String) -> bool:
	return s.achievements.unlocked.has(id)


## [have, need] for an achievement.
static func progress(s: Dictionary, a: Dictionary) -> Array:
	var c: Dictionary = a.check
	match c.kind:
		"secret":
			return [mini(int(s.achievements.secrets.get(c.id, 0)), int(c.n)), int(c.n)]
		"log":
			var need := Collection.total(c.track) if str(c.n) == "all" else int(c.n)
			return [mini(Collection.progress(s, c.track), need), need]
		"kind_owned":
			var have := 0
			for id in s.collection.species:
				if Data.species.has(id) and Data.species[id].kind == c.species_kind:
					have += 1
			return [mini(have, int(c.n)), int(c.n)]
		"all_types":
			var have := 0
			for t in Data.type_list:
				have += 1 if Collection.owned_type(s, t.id) else 0
			return [have, Data.type_list.size()]
		"perches_full":
			var u: Dictionary = Data.upgrades["perches"]
			var built: bool = GameState.upgrade_level(s, "perches") >= u.levels.size()
			var need := int(GameState.upgrade_value(s, "perches"))
			return [1 if built and GameState.perched(s).size() >= need else 0, 1]
		"gold_peak":
			return [mini(int(s.counters.get("goldPeak", 0)), int(c.n)), int(c.n)]
		"riches_to_rags":
			var fell := int(s.counters.get("goldPeak", 0)) >= int(c.peak) and float(s.gold) < float(c.below)
			return [1 if fell else 0, 1]
	return Goals.progress(s, a)


## Unlocks everything newly earned, pays the rewards and returns an "achievement" event for each.
static func check(s: Dictionary) -> Array:
	var events := []
	for a in Data.achievement_list:
		if is_unlocked(s, a.id):
			continue
		var p := progress(s, a)
		if p[0] >= p[1]:
			events.append(unlock(s, a))
	return events


static func unlock(s: Dictionary, a: Dictionary) -> Dictionary:
	s.achievements.unlocked[a.id] = int(Time.get_unix_time_from_system())
	var r: Dictionary = a.reward
	for k in ["aether", "gold"]:
		if r.has(k):
			GameState.add_item(s, k, float(r[k]))
	if r.has("title") and not (r.title in s.collection.titles):
		s.collection.titles.append(r.title)
	return {"type": "achievement", "id": a.id}


## Checks on a throttle (tuning achievements.checkEvery), from Sim.step.
static func tick(s: Dictionary, dt_sec: float) -> Array:
	_check_in -= dt_sec
	if _check_in > 0.0:
		return []
	_check_in = float(Data.tuning.achievements.checkEvery)
	return check(s)


## A secret interaction the UI noticed (a poke, a pet, a code). Counts only until its achievement is earned.
static func poke(s: Dictionary, secret_id: String, n := 1) -> void:
	var sec: Dictionary = s.achievements.secrets
	sec[secret_id] = int(sec.get(secret_id, 0)) + n


## Keeps the gold-peak counter (Riches to Rags, Millionaire). Called whenever gold is added.
static func note_gold(s: Dictionary) -> void:
	if s.has("counters") and float(s.gold) > float(s.counters.get("goldPeak", 0)):
		s.counters.goldPeak = int(s.gold)


## A save from before achievements: unlock what it has already earned, quietly (the rewards are paid; the game
## shows one summary toast instead of dozens, see Game.start_slot).
static func backfill(s: Dictionary) -> void:
	s.counters.goldPeak = maxi(int(s.counters.get("goldPeak", 0)), int(s.gold))
	s.achievements.quiet = check(s).size()
	for id in s.achievements.unlocked:
		s.achievements.seen[id] = true


## Unlocked achievements not yet looked at on the Achievements page.
static func unseen(s: Dictionary) -> int:
	var n := 0
	for id in s.achievements.unlocked:
		n += 0 if s.achievements.seen.has(id) else 1
	return n


static func count_unlocked(s: Dictionary, category := "") -> int:
	var n := 0
	for a in Data.achievement_list:
		if (category == "" or a.category == category) and is_unlocked(s, a.id):
			n += 1
	return n


static func count_total(category := "") -> int:
	return Data.achievement_list.filter(func(a): return category == "" or a.category == category).size()
