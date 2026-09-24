extends Node
## Development probe (not a test): runs the combat sim for a few parties and prints how far they get.
## godot --headless --path godot res://tests/balance_probe.tscn

func _ready() -> void:
	var cases := [
		["whisperleaf-hollow", [["sproutlet", 1, 1]]],
		["whisperleaf-hollow", [["sproutlet", 1, 4]]],
		["whisperleaf-hollow", [["sproutlet", 1, 6], ["brambletrundle", 1, 4]]],
		["whisperleaf-hollow", [["sproutlet", 1, 8], ["brambletrundle", 2, 6], ["buzzbud", 1, 6]]],
		["fractured-quarry", [["sproutlet", 1, 10], ["brambletrundle", 2, 8], ["buzzbud", 1, 8]]],
		["fractured-quarry", [["sproutlet", 2, 16], ["tuskcub", 2, 14], ["buzzbud", 2, 14]]],
		["smoldering-caldera", [["tuskcub", 2, 22], ["quakemaw", 2, 22], ["sproutlet", 2, 24]]],
		["smoldering-caldera", [["tuskcub", 3, 28], ["quakemaw", 3, 28], ["sproutlet", 3, 28]]],
		["whispering-tides", [["emberfang", 3, 36], ["cinderpup", 3, 36], ["tuskcub", 3, 36]]],
		["thunderhum-steppe", [["dewdrop", 3, 46], ["splashfin", 3, 46], ["tuskcub", 4, 46]]],
		["null-horizon", [["coilchirp", 4, 56], ["voltfluff", 4, 56], ["tuskcub", 4, 56]]],
		["verdigris-canopy", [["emberfang", 4, 64], ["charwhisk", 4, 64], ["tuskcub", 4, 64]]],
		["verdigris-canopy", [["emberfang", 5, 68], ["charwhisk", 5, 68], ["tuskcub", 5, 68]]],
		["magmaglass-rift", [["splashfin", 5, 74], ["dewdrop", 5, 74], ["puddlescoop", 5, 74]]],
		["magmaglass-rift", [["splashfin", 5, 78], ["dewdrop", 5, 78], ["puddlescoop", 5, 78]]],
		["stormsea-expanse", [["quakemaw", 5, 82], ["tuskcub", 5, 82], ["geodecore", 5, 82]]],
		["stormsea-expanse", [["quakemaw", 6, 86], ["tuskcub", 6, 86], ["geodecore", 6, 86]]],
		["magmaglass-rift", [["splashfin", 4, 72], ["dewdrop", 4, 72], ["puddlescoop", 4, 72]]],
		["stormsea-expanse", [["quakemaw", 4, 82], ["tuskcub", 4, 82], ["geodecore", 4, 82]]],
		["zenith-spire", [["riftsneak", 4, 90], ["eclipsa", 4, 90], ["netherpod", 4, 90]]],
		["zenith-spire", [["riftsneak", 5, 92], ["eclipsa", 5, 92], ["netherpod", 5, 92]]],
		["zenith-spire", [["riftsneak", 6, 92], ["eclipsa", 6, 92], ["netherpod", 6, 92]]],
		["zenith-spire", [["riftsneak", 6, 97], ["eclipsa", 6, 97], ["netherpod", 6, 97]]],
	]
	for cs in cases:
		var res := probe(cs[0], cs[1], 5)
		print("%-20s %-50s wins %d/5  avg wave %.1f  avg run %.0fs  kills/min %.1f  xp/run %.0f  levels/run %.2f  min/level %.1f" % [cs[0], str(cs[1]), res.wins, res.wave, res.secs, res.kpm, res.xp, res.levels,
			F.xp_to_next(F.creature_curve(), cs[1][0][2]) / maxf(1.0, res.xp / res.secs * 60.0)])
	get_tree().quit()


func probe(zone: String, party_spec: Array, runs: int) -> Dictionary:
	var wins := 0
	var waves := 0.0
	var secs := 0.0
	var kills := 0
	var xp := 0.0
	var levels := 0.0
	for r in runs:
		var s := GameState.new_game()
		s.creatures.clear()
		var rng := RandomNumberGenerator.new()
		rng.seed = r * 31 + 7
		var i := 0
		for spec in party_spec:
			var c := Creatures.make(s, spec[0], spec[1], spec[2], false, [], "probe")
			s.creatures[c.id] = c
			Expedition.set_party_member(s, i, c)
			i += 1
		# everyone "owns" all types so no free captures skew anything, and no vessels
		s.items.clear()
		s.expedition.autoRepeat = false
		for z in Data.zone_list:
			s.expedition.zones[z.id] = {"cleared": true, "runs": 0, "bestWave": 0, "kills": 0}
		var lead: Dictionary = s.creatures[s.expedition.party[0]]
		var xp0 := float(lead.xp)
		var lv0 := int(lead.level)
		Expedition.start(s, zone, rng)
		var t := 0.0
		var won := false
		var wave := 0
		while Expedition.is_running(s) and t < 1800000.0:
			var ev := Expedition.step(s, 250.0, rng)
			t += 250.0
			if not s.expedition.battle.is_empty():
				wave = maxi(wave, int(s.expedition.battle.wave))
			for e in ev:
				if e.type == "run_complete":
					won = true
				if e.type in ["run_complete", "wiped"]:
					Expedition.stop(s)
		wins += 1 if won else 0
		waves += wave
		secs += t / 1000.0
		kills += int(s.counters.kills)
		xp += float(lead.xp) - xp0
		levels += int(lead.level) - lv0
	return {"wins": wins, "wave": waves / runs, "secs": secs / runs, "kpm": kills / (secs / 60.0), "xp": xp / runs, "levels": levels / runs}
