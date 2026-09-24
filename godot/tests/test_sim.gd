extends RefCounted
## The economy sim: formulas, skills, aether, offline progress, saves.

var t


func _rng(seed_value := 1) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func _starter(s: Dictionary) -> Dictionary:
	return s.creatures.values()[0]


func test_xp_curve_round_trip() -> void:
	var curve := F.skill_curve()
	var max_lv: int = Data.tuning.skills.maxLevel
	for lv in [1, 2, 10, 50, 99]:
		t.eq(F.level_for_xp(curve, F.xp_for_level(curve, lv, max_lv), max_lv), lv, "level %d" % lv)
	t.eq(F.level_for_xp(curve, F.xp_for_level(curve, 10, max_lv) - 0.5, max_lv), 9)


func test_new_game_has_starter_and_vessels() -> void:
	var s := GameState.new_game()
	t.eq(s.creatures.size(), 1)
	t.eq(_starter(s).species, "sproutlet")
	t.eq(GameState.count(s, "tinkerers-vessel"), 5.0)
	t.ok(Collection.is_owned(s, "sproutlet"))
	t.eq(s.pods.size(), 2)


func test_cooldown_floor_and_efficiency() -> void:
	var base := F.cooldown_ms(3000, 1.0, 1, 1, 1, 0.0)
	t.near(base, 3000.0, 0.01)
	# max everything still stops at the floor
	var floor_ms := F.cooldown_ms(3000, 1.0, 60, 9, 3, 0.5)
	t.near(floor_ms, 3000.0 * Data.tuning.cooldown.floorFraction, 0.01)
	# an off-primary hybrid's floor is higher than a specialist's
	var off := F.cooldown_ms(3000, 0.6, 60, 9, 3, 0.5)
	t.ok(off > floor_ms, "off-primary floor")


func test_assign_rules() -> void:
	var s := GameState.new_game()
	var c := _starter(s)
	t.eq(Skills.assign(s, c, "woodcutting"), "")
	t.eq(GameState.workers(s, "woodcutting").size(), 1)
	t.ok(Skills.assign(s, c, "mining") != "", "Verdant cannot mine")
	t.eq(Skills.assign(s, c, "scavenging"), "", "open skills take anyone")
	t.eq(GameState.workers(s, "woodcutting").size(), 0, "moved, not duplicated")


func test_woodcutting_produces_logs_and_xp() -> void:
	var s := GameState.new_game()
	var c := _starter(s)
	Skills.assign(s, c, "woodcutting")
	var rng := _rng()
	var cd := Skills.worker_cooldown(c, "woodcutting", Skills.current_action(s, "woodcutting"), [])
	var ev := Skills.step(s, cd * 10.0 + 1.0, rng)
	t.ok(GameState.count(s, "oak-log") >= 10.0, "at least 10 logs")
	t.ok(float(s.skills.woodcutting.xp) >= 50.0, "xp")
	t.ok(ev.any(func(e): return e.type == "produced"))


func test_crafting_consumes_and_stalls() -> void:
	var s := GameState.new_game()
	var c := Creatures.make(s, "emberfang", 1, 1, false, [], "test")
	s.creatures[c.id] = c
	t.eq(Skills.assign(s, c, "smithing"), "")
	GameState.add_item(s, "copper-ore", 4)
	Skills.step(s, 60000.0, _rng())
	t.eq(GameState.count(s, "copper-bar"), 2.0, "2 bars from 4 ore")
	t.eq(GameState.count(s, "copper-ore"), 0.0)
	t.ok(c.get("stalled", false), "stalled without ore")


func test_bench_emission_is_linear_in_time() -> void:
	var s := GameState.new_game()
	var rate := Economy.aether_per_min(s)
	t.near(rate, 2.0, 0.001, "one Dim starter on a perch")
	var before := float(s.aether)
	Economy.step(s, 90.0)
	t.near(float(s.aether) - before, 3.0, 0.0001)


func test_perches_limit_emitters() -> void:
	var s := GameState.new_game()
	for i in 10:
		var c := Creatures.make(s, "sproutlet", 1, 1, false, [], "test")
		s.creatures[c.id] = c
	t.eq(Economy.perched(s).size(), 4)


func test_offline_matches_elapsed_over_cooldown() -> void:
	var s := GameState.new_game()
	# a max-level worker cannot speed up mid-window, so the count is exactly elapsed / cooldown
	var c := Creatures.make(s, "sproutlet", 2, 60, false, [], "test")
	s.creatures[c.id] = c
	Skills.assign(s, c, "woodcutting")
	var cd := Skills.worker_cooldown(c, "woodcutting", Skills.current_action(s, "woodcutting"), [])
	var summary := Offline.apply(s, 3600.0, _rng())
	var expected := int(floor(3600000.0 / cd))
	t.ok(absi(summary.actions - expected) <= 1, "actions %d vs %d" % [summary.actions, expected])
	t.ok(summary.gained.has("oak-log"))


func test_offline_is_capped() -> void:
	var s := GameState.new_game()
	var summary := Offline.apply(s, 3600.0 * 100.0, _rng())
	t.near(float(summary.usedSeconds), 12.0 * 3600.0, 0.01)
	t.ok(summary.capped)


func test_offline_crafting_chain_feeds_through_slices() -> void:
	var s := GameState.new_game()
	var miner := Creatures.make(s, "tuskcub", 3, 20, false, [], "test")
	var smith := Creatures.make(s, "emberfang", 3, 20, false, [], "test")
	s.creatures[miner.id] = miner
	s.creatures[smith.id] = smith
	Skills.assign(s, miner, "mining")
	Skills.assign(s, smith, "smithing")
	Offline.apply(s, 2 * 3600.0, _rng())
	t.ok(GameState.count(s, "copper-bar") > 100.0, "bars made from ore mined while away")


func test_save_round_trip() -> void:
	var s := GameState.new_game()
	Skills.assign(s, _starter(s), "woodcutting")
	Skills.step(s, 20000.0, _rng())
	var text := JSON.stringify(s)
	var back: Dictionary = GameState.migrate(Game._fix_numbers(JSON.parse_string(text)))
	t.eq(back.creatures.size(), s.creatures.size())
	t.eq(GameState.count(back, "oak-log"), GameState.count(s, "oak-log"))
	t.eq(GameState.workers(back, "woodcutting").size(), 1)


func test_migration_fills_missing_keys() -> void:
	var s := GameState.new_game()
	s.erase("counters")
	s.expedition.erase("autobind")
	s.skills.erase("fishing")
	var m := GameState.migrate(s)
	t.ok(m.has("counters"))
	t.ok(m.expedition.has("autobind"))
	t.ok(m.skills.has("fishing"))


func test_rare_drop_bonus_raises_rate() -> void:
	var s := GameState.new_game()
	var plain := Creatures.make(s, "sproutlet", 1, 1, false, [], "test")
	var lucky := Creatures.make(s, "sproutlet", 1, 1, false, [{"id": "lucky", "s": "major"}], "test")
	t.ok(Traits.capped_self(lucky, "rare_drop_chance", "woodcutting") > Traits.capped_self(plain, "rare_drop_chance", "woodcutting"))


func test_aura_strongest_only() -> void:
	var s := GameState.new_game()
	var g1 := Creatures.make(s, "geodecore", 1, 1, false, [], "test")
	var g2 := Creatures.make(s, "geodecore", 1, 1, false, [], "test")
	var miner := Creatures.make(s, "tuskcub", 1, 1, false, [], "test")
	for c in [g1, g2, miner]:
		s.creatures[c.id] = c
	s.skills.mining.level = 60
	for c in [g1, g2, miner]:
		t.eq(Skills.assign(s, c, "mining"), "")
	var bonus := Skills.aura_bonus(miner, "mining", Skills.active_auras(s))
	t.near(bonus, Data.tuning.traitStrength.minor, 0.0001, "two auras, one applies")


func test_binomial_is_sane() -> void:
	var rng := _rng(3)
	var total := 0
	for i in 200:
		total += Rng.binomial(rng, 1000, 0.1)
	t.near(total / 200.0, 100.0, 5.0)


func test_a_new_rarity_is_a_log_entry_of_its_own() -> void:
	var s := GameState.new_game()
	s.creatures.clear()
	s.collection.species.clear()
	var dim := Creatures.make(s, "buzzbud", 1, 1, false, [], "test")
	var ev1 := Collection.on_owned(s, dim)
	t.ok(ev1.any(func(e): return e.type == "discovered"), "the first one is the discovery")
	t.ok(not ev1.any(func(e): return e.type == "rarity_logged"), "not also a rarity entry")
	var aether0 := float(s.aether)
	var faint := Creatures.make(s, "buzzbud", 2, 1, false, [], "test")
	var ev2 := Collection.on_owned(s, faint)
	var logged := ev2.filter(func(e): return e.type == "rarity_logged")
	t.eq(logged.size(), 1, "a Faint after a Dim is a new entry")
	t.near(float(s.aether) - aether0, Collection.rarity_reward(2), 0.01, "with its Aether")
	t.eq(Collection.progress(s, "rarities"), 2)
	t.eq(Collection.on_owned(s, Creatures.make(s, "buzzbud", 2, 1, false, [], "test")).filter(func(e): return e.type == "rarity_logged").size(), 0, "a second Faint is not")
	t.ok(Collection.rarity_reward(5) > Collection.rarity_reward(2), "rarer entries pay more")
