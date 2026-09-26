extends RefCounted
## A busy mid-game save (13 workers across every skill and an expedition) through a full 12-hour offline
## window: it must resolve quickly and must not flood the Nexus.

var t


func test_twelve_hours_offline_is_fast_and_bounded() -> void:
	var s := GameState.new_game()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var specs := [["sproutlet","woodcutting"],["brambletrundle","woodcutting"],["buzzbud","herbalism"],["tuskcub","mining"],["geodecore","mining"],
		["emberfang","smithing"],["roastbelly","cooking"],["dewdrop","fishing"],["voltfluff","circuitry"],["eclipsa","aether-weaving"],["riftsneak","vessel-crafting"],["mossgear","scavenging"],["joulebug","fabrication"]]
	for sp in specs:
		var c := Creatures.make(s, sp[0], 3, 30, false, [], "t")
		s.creatures[c.id] = c
		Skills.assign(s, c, sp[1])
	for i in 3:
		var c := Creatures.make(s, "quakemaw", 3, 30, false, [], "t")
		s.creatures[c.id] = c
		Expedition.set_party_member(s, i, c)
	for z in Data.zone_list:
		s.expedition.zones[z.id] = {"cleared": true, "runs": 0, "bestWave": 0, "kills": 0}
	Expedition.start(s, "smoldering-caldera", rng)
	var t0 := Time.get_ticks_msec()
	var sum := Offline.apply(s, 12 * 3600.0, rng)
	var ms := Time.get_ticks_msec() - t0
	t.ok(ms < 4000, "12 hours resolved in %d ms" % ms)
	t.ok(sum.actions > 10000, "work happened")
	t.ok(s.creatures.size() < 300, "auto-bind kept the Nexus to %d" % s.creatures.size())


## Perf keeps a count, total, max, median and p95 per metric, and reset clears them.
func test_perf_records_timings() -> void:
	Perf.reset()
	for ms in [1.0, 2.0, 3.0, 4.0, 10.0]:
		Perf.sample("t.sample", ms)
	var t0 := Perf.begin()
	Perf.end("t.timed", t0)
	var rows := Perf.report("t.")
	t.eq(rows.size(), 2, "two metrics under the prefix")
	var r: Dictionary = rows.filter(func(x): return x.name == "t.sample")[0]
	t.eq(r.n, 5, "five samples")
	t.ok(is_equal_approx(r.total, 20.0) and is_equal_approx(r.max, 10.0) and is_equal_approx(r.median, 3.0), "total, max and median")
	t.ok(is_equal_approx(r.p95, 10.0), "the slowest 5%")
	t.ok("t.sample" in Perf.table("t."), "the text table names it")
	Perf.reset()
	t.ok(not Perf.has("t.sample"), "reset clears it")


## The game's own tick records the sim's parts.
func test_sim_step_is_timed() -> void:
	Perf.reset()
	var s := GameState.new_game()
	Sim.step(s, 1.0, RandomNumberGenerator.new())
	for metric in ["sim.step", "sim.skills", "sim.economy", "sim.expedition", "sim.market", "sim.achievements"]:
		t.ok(Perf.has(metric), metric + " recorded")


## Skills.step keeps each worker's cooldown between steps; a level-up, a task change, a new worker or a trait
## reroll must still reach it.
func test_cached_cooldowns_follow_changes() -> void:
	var s := GameState.new_game()
	var rng := RandomNumberGenerator.new()
	var c := Creatures.make(s, "sproutlet", 1, 1, false, [], "t")
	s.creatures[c.id] = c
	Skills.assign(s, c, "woodcutting")
	var cd := func() -> float:
		return Skills._step_cooldown(c, "woodcutting", Skills.current_action(s, "woodcutting"), Skills.cached_auras(s), Skills.speed(s), GameState.roster_revision(s))
	var direct := func() -> float:
		return Skills.worker_cooldown(c, "woodcutting", Skills.current_action(s, "woodcutting"), Skills.active_auras(s), Skills.speed(s))
	Skills.step(s, 10.0, rng)
	t.ok(is_equal_approx(cd.call(), direct.call()), "starts equal")
	c.level = 60
	c.form = 3
	t.ok(is_equal_approx(cd.call(), direct.call()), "follows a level-up and evolution")
	s.skills.woodcutting.level = 99
	for a in Data.skills.woodcutting.actions:
		s.skills.woodcutting.action = a.id
	t.ok(is_equal_approx(cd.call(), direct.call()), "follows a task change")
	var quick: Array = Data.pool_traits.filter(func(pt): return pt.effects.any(func(e): return e.key == "cooldown_reduction" and not e.has("aura")))
	c.traits = [{"id": quick[0].id, "s": "major"}]
	GameState.roster_changed(s)
	t.ok(is_equal_approx(cd.call(), direct.call()), "follows a trait reroll")
