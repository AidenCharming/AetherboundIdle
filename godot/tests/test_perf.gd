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
