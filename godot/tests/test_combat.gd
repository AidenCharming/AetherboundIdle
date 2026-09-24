extends RefCounted
## Combat, expeditions and capture.

var t


func _rng(seed_value := 5) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func _party_game(specs: Array) -> Dictionary:
	var s := GameState.new_game()
	s.creatures.clear()
	var i := 0
	for spec in specs:
		var c := Creatures.make(s, spec[0], spec[1], spec[2], false, [], "test")
		s.creatures[c.id] = c
		Expedition.set_party_member(s, i, c)
		i += 1
	return s


func test_type_wheel() -> void:
	t.near(Combat.type_mult("verdant", ["telluric"]), 1.5, 0.001, "verdant beats telluric")
	t.near(Combat.type_mult("telluric", ["verdant"]), 0.75, 0.001, "telluric resisted by verdant")
	t.near(Combat.type_mult("pyric", ["pyric"]), 1.0, 0.001)
	t.near(Combat.type_mult("void", ["pyric"]), 1.25, 0.001, "void deals 1.25")
	t.near(Combat.type_mult("pyric", ["void"]), 0.75, 0.001, "void takes 0.75")
	t.near(Combat.type_mult("pyric", ["void", "verdant"]), 1.5 * 0.875, 0.001, "void hybrid keeps its wheel place, half the resistance")


func test_strong_party_beats_a_weak_wild() -> void:
	var s := _party_game([["emberfang", 5, 40]])
	var ally := Combat.ally(s.creatures.values()[0])
	var enemy := Combat.wild("sproutlet", 3, 1, false, {})
	var rng := _rng()
	for i in 200:
		Combat.step([ally], [enemy], 250.0, rng)
		if not enemy.alive:
			break
	t.ok(not enemy.alive, "enemy down")
	t.ok(ally.alive, "ally standing")


func test_start_needs_a_party_and_an_unlocked_zone() -> void:
	var s := GameState.new_game()
	var rng := _rng()
	t.ok(Expedition.start(s, "whisperleaf-hollow", rng) != "", "empty party refused")
	Expedition.set_party_member(s, 0, s.creatures.values()[0])
	t.ok(Expedition.start(s, "fractured-quarry", rng) != "", "locked zone refused")
	t.eq(Expedition.start(s, "whisperleaf-hollow", rng), "")
	t.ok(Expedition.is_running(s))
	t.eq(Creatures.job_kind(s.creatures.values()[0]), "party")


func test_clearing_a_boss_unlocks_the_next_island() -> void:
	var s := _party_game([["emberfang", 6, 40], ["tuskcub", 6, 40], ["dewdrop", 6, 40]])
	var rng := _rng()
	Expedition.start(s, "whisperleaf-hollow", rng)
	var unlocked := false
	for i in 4000:
		for e in Expedition.step(s, 250.0, rng):
			if e.type == "zone_unlocked" and e.zone == "fractured-quarry":
				unlocked = true
		if unlocked:
			break
	t.ok(unlocked, "zone unlocked event")
	t.ok(Expedition.zone_unlocked(s, "fractured-quarry"))


func test_first_of_a_type_binds_free() -> void:
	var s := GameState.new_game()
	s.items.clear()
	var ev := []
	var w := {"species": "tuskcub", "level": 8, "rarity": 1, "shiny": false}
	Expedition.try_capture(s, w, [], _rng(), ev, {"freeBinds": 0})
	t.ok(ev.any(func(e): return e.type == "captured" and e.how == "guaranteed"), "guaranteed capture")
	t.ok(Collection.owned_type(s, "telluric"))


func test_capture_consumes_a_vessel() -> void:
	var s := GameState.new_game()
	var before := GameState.count(s, "tinkerers-vessel")
	var ev := []
	Expedition.try_capture(s, {"species": "brambletrundle", "level": 3, "rarity": 1, "shiny": false}, [], _rng(), ev, {"freeBinds": 0})
	t.eq(GameState.count(s, "tinkerers-vessel"), before - 1.0)
	t.ok(ev.any(func(e): return e.type in ["captured", "escaped"]))


func test_autobind_respects_min_rarity_for_owned_species() -> void:
	var s := GameState.new_game()
	s.expedition.autobind.minRarity = 3
	t.ok(not Expedition.wants_bind(s, {"species": "sproutlet", "rarity": 1, "shiny": false}), "owned Dim skipped")
	t.ok(Expedition.wants_bind(s, {"species": "buzzbud", "rarity": 1, "shiny": false}), "new species tried")
	t.ok(Expedition.wants_bind(s, {"species": "sproutlet", "rarity": 3, "shiny": false}), "Steady tried")
	t.ok(Expedition.wants_bind(s, {"species": "sproutlet", "rarity": 1, "shiny": true}), "shiny always tried")


func test_a_shiny_with_no_vessel_waits() -> void:
	var s := GameState.new_game()
	s.items.clear()
	var ev := []
	Expedition.try_capture(s, {"species": "brambletrundle", "level": 3, "rarity": 1, "shiny": true}, [], _rng(), ev, {"freeBinds": 0})
	t.eq(s.expedition.pending.size(), 1)
	GameState.add_item(s, "luminescent-vessel", 5)
	var rng := _rng(9)
	var tries := 0
	while not s.expedition.pending.is_empty() and tries < 5:
		Expedition.retry_pending(s, 0, "luminescent-vessel", rng)
		tries += 1
	t.ok(s.expedition.pending.is_empty(), "bound on retry")


func test_bind_chance_falls_with_rarity_and_rises_with_vessel() -> void:
	var s := GameState.new_game()
	t.ok(Expedition.bind_chance(s, "tinkerers-vessel", 1, []) > Expedition.bind_chance(s, "tinkerers-vessel", 5, []))
	t.ok(Expedition.bind_chance(s, "luminescent-vessel", 5, []) > Expedition.bind_chance(s, "tinkerers-vessel", 5, []))


func test_offline_expedition_is_bounded_and_productive() -> void:
	var s := _party_game([["emberfang", 4, 30], ["tuskcub", 4, 30], ["dewdrop", 4, 30]])
	var rng := _rng()
	Expedition.start(s, "whisperleaf-hollow", rng)
	var t0 := Time.get_ticks_msec()
	Expedition.offline(s, 12.0 * 3600000.0, rng)
	var ms := Time.get_ticks_msec() - t0
	t.ok(int(s.counters.kills) > 500, "kills %d" % int(s.counters.kills))
	t.ok(ms < 8000, "12 hours resolved in %d ms" % ms)
	t.ok(Expedition.zone_state(s, "whisperleaf-hollow").cleared)


func test_wipe_rests_then_retries() -> void:
	var s := _party_game([["sproutlet", 1, 1]])
	var rng := _rng()
	Expedition.start(s, "null-horizon", rng) # unlocked by nothing: force it
	s.expedition.zones["thunderhum-steppe"] = {"cleared": true, "runs": 0, "bestWave": 0, "kills": 0}
	Expedition.start(s, "null-horizon", rng)
	var wiped := false
	var restarted := false
	for i in 2000:
		for e in Expedition.step(s, 250.0, rng):
			if e.type == "wiped":
				wiped = true
			if e.type == "run_start" and wiped:
				restarted = true
		if restarted:
			break
	t.ok(wiped, "a level-1 solo wipes at the last island")
	t.ok(restarted, "and tries again after resting")


func test_bulk_release_keeps_the_best_of_each_species() -> void:
	var s := GameState.new_game()
	var keep := Creatures.make(s, "brambletrundle", 2, 10, false, [], "test")
	s.creatures[keep.id] = keep
	for i in 5:
		var c := Creatures.make(s, "brambletrundle", 1, 3, false, [], "test")
		s.creatures[c.id] = c
	var shiny := Creatures.make(s, "brambletrundle", 1, 3, true, [], "test")
	s.creatures[shiny.id] = shiny
	var res := Economy.bulk_release(s, 2)
	t.eq(res.count, 5)
	t.ok(s.creatures.has(keep.id), "best kept")
	t.ok(s.creatures.has(shiny.id), "shiny kept")
	t.eq(s.creatures.size(), 3, "starter, best and shiny remain")


func test_autobind_stops_at_max_copies_unless_rarer() -> void:
	var s := GameState.new_game()
	s.expedition.autobind.minRarity = 1
	s.expedition.autobind.maxCopies = 2
	for i in 2:
		var c := Creatures.make(s, "buzzbud", 2, 3, false, [], "test")
		s.creatures[c.id] = c
		Collection.on_owned(s, c)
	t.ok(not Expedition.wants_bind(s, {"species": "buzzbud", "rarity": 2, "shiny": false}), "two already")
	t.ok(Expedition.wants_bind(s, {"species": "buzzbud", "rarity": 3, "shiny": false}), "rarer than the best")


func test_the_party_is_locked_while_a_run_is_going() -> void:
	var s := _party_game([["emberfang", 6, 20]])
	var extra := Creatures.make(s, "sproutlet", 1, 3, false, [], "test")
	s.creatures[extra.id] = extra
	var rng := _rng()
	t.eq(Expedition.start(s, "whisperleaf-hollow", rng), "")
	for i in 40:
		Expedition.step(s, 250.0, rng)
	var wave := int(s.expedition.battle.wave)
	t.eq(Expedition.set_party_member(s, 1, extra), Expedition.PARTY_LOCKED, "adding is refused")
	t.eq(Expedition.set_party_member(s, 0, extra), Expedition.PARTY_LOCKED, "swapping is refused")
	t.eq(GameState.party(s).size(), 1)
	t.ok(Creatures.is_benched(extra), "the newcomer stayed where it was")
	t.eq(int(s.expedition.battle.wave), wave, "the run carried on")
	Expedition.stop(s)
	t.eq(Expedition.set_party_member(s, 1, extra), "", "free again once stopped")
	t.eq(GameState.party(s).size(), 2)
