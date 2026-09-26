extends RefCounted
## Achievements: the data, unlocking and rewards, secrets (pokes and play patterns), the quiet backfill for old
## saves and the title-screen secrets that wait for a slot.

var t


func _fresh() -> Dictionary:
	return GameState.new_game(1)


func test_data_is_well_formed() -> void:
	var ids := {}
	for a in Data.achievement_list:
		t.ok(not ids.has(a.id), "unique id %s" % a.id)
		ids[a.id] = true
		t.ok(a.category in Achievements.CATEGORIES, "%s: category %s" % [a.id, a.category])
		t.ok(a.check.kind in Achievements.KINDS or a.check.kind in Goals.KINDS, "%s: known check %s" % [a.id, a.check.kind])
		t.ok(a.name != "" and a.text != "", "%s: has a name and text" % a.id)
		t.ok(int(a.tier) >= 0 and int(a.tier) <= 3, "%s: tier" % a.id)
		t.eq(a.category == "secret", a.get("secret", false), "%s: secret flag matches the category" % a.id)
		if a.get("secret", false):
			t.ok(str(a.get("hint", "")) != "", "%s: a secret has a hint" % a.id)
		t.ok(Data.achievement_icon(a) != null, "%s: art %s (painting or placeholder)" % [a.id, a.art])
		match a.check.kind:
			"skill_level":
				t.ok(Data.skills.has(a.check.skill), "%s: skill" % a.id)
			"zone":
				t.ok(Data.zones.has(a.check.zone), "%s: zone" % a.id)
	t.ok(Data.achievement_list.size() >= 100, "about 110 achievements")


func test_every_counter_a_check_reads_exists_in_a_new_game() -> void:
	var s := _fresh()
	for a in Data.achievement_list:
		if a.check.kind == "counter":
			t.ok(s.counters.has(a.check.counter), "%s: counter %s" % [a.id, a.check.counter])


func test_unlock_pays_once_and_gives_the_title() -> void:
	var s := _fresh()
	s.skills.woodcutting.level = 10
	var gold := float(s.gold)
	var events := Achievements.check(s)
	t.ok(events.any(func(e): return e.id == "woodcutting-10"), "Woodcutting 10 unlocks")
	t.ok(float(s.gold) > gold, "its reward is paid")
	gold = float(s.gold)
	t.eq(Achievements.check(s).size(), 0, "nothing unlocks twice")
	t.eq(float(s.gold), gold, "and nothing is paid twice")
	for sk in Data.skill_list:
		s.skills[sk.id].level = 99
	Achievements.check(s)
	t.ok("Grand Master" in s.collection.titles, "every skill at 99 gives the Grand Master title")


func test_a_new_game_unlocks_nothing() -> void:
	var s := _fresh()
	t.eq(Achievements.check(s).size(), 0, "a brand new game has no achievements yet")


func test_secret_pokes_count_to_the_goal() -> void:
	var s := _fresh()
	Achievements.poke(s, "pet", 24)
	t.eq(Achievements.check(s).size(), 0, "24 pets are not enough")
	Achievements.poke(s, "pet")
	var events := Achievements.check(s)
	t.ok(events.any(func(e): return e.id == "headpats"), "the 25th pet unlocks Headpats")


func test_riches_to_rags() -> void:
	var s := _fresh()
	GameState.add_item(s, "gold", 1000000)
	t.ok(int(s.counters.goldPeak) >= 1000000, "gold peak follows the gold")
	var ids := Achievements.check(s).map(func(e): return e.id)
	t.ok("gold-1m" in ids, "Millionaire")
	t.ok(not ("riches-to-rags" in ids), "not rags while rich")
	GameState.add_item(s, "gold", -float(s.gold) + 500)
	ids = Achievements.check(s).map(func(e): return e.id)
	t.ok("riches-to-rags" in ids, "under 1,000 gold after a million: Riches to Rags")


func test_play_pattern_counters() -> void:
	var s := _fresh()
	var it: Dictionary = Data.item_list.filter(func(i): return int(i.get("sell", 0)) == 1)[0] if Data.item_list.any(func(i): return int(i.get("sell", 0)) == 1) else {}
	if not it.is_empty():
		GameState.add_item(s, it.id, 1)
		Economy.sell(s, it.id, 1)
		t.eq(int(s.counters.oneGoldSale), 1, "a 1-gold sale is noticed")
	var c := Creatures.make(s, "sproutlet", 1, 1, true, [], "wild")
	s.creatures[c.id] = c
	GameState.roster_changed()
	Economy.release(s, c)
	t.eq(int(s.counters.shinyReleased), 1, "releasing a shiny is counted")
	t.ok(Achievements.check(s).any(func(e): return e.id == "catch-release"), "Catch and Release")


func test_old_save_backfills_quietly() -> void:
	var s := _fresh()
	s.erase("achievements")
	s.skills.mining.level = 50
	GameState.migrate(s)
	t.ok(Achievements.is_unlocked(s, "mining-10") and Achievements.is_unlocked(s, "mining-50"), "earned ones unlock on load")
	t.eq(int(s.achievements.quiet), 2, "counted for one summary toast")
	t.eq(Achievements.unseen(s), 0, "and not flagged as new")


func test_title_screen_secret_waits_for_a_slot() -> void:
	var keep := {"running": Game.running, "state": Game.state, "pending": Options.get_value("secrets_pending")}
	Game.running = false
	Options.values.secrets_pending = {}
	Game.note_secret("konami")
	t.eq(int(Options.get_value("secrets_pending").get("konami", 0)), 1, "kept in Options while no save is loaded")
	Game.state = _fresh()
	Game.running = true
	Game._claim_pending_secrets()
	t.ok(Achievements.is_unlocked(Game.state, "konami"), "granted when a slot starts")
	t.ok(Options.get_value("secrets_pending").is_empty(), "and cleared")
	Game.running = keep.running
	Game.state = keep.state
	Options.values.secrets_pending = keep.pending


func test_breeding_counts_mutations_and_best_rarity() -> void:
	var s := _fresh()
	s.pods = [{"species": "sproutlet", "rarity": 3, "shiny": false, "traits": [], "tier": 1, "laidAt": 0.0, "readyAt": 0.0,
		"parents": ["sproutlet", "sproutlet"], "shell": 3, "parentRarity": 1}]
	Breeding.hatch(s, 0, 10.0)
	t.eq(int(s.counters.mutations), 1, "rarer than both parents is a mutation")
	t.eq(int(s.counters.bestBred), 3, "best bred rarity")
