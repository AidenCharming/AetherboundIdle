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
	]
	for cs in cases:
		var res := probe(cs[0], cs[1], 5)
		print("%-20s %-50s wins %d/5  avg wave %.1f  avg run %.0fs  kills/min %.1f" % [cs[0], str(cs[1]), res.wins, res.wave, res.secs, res.kpm])
	get_tree().quit()


func probe(zone: String, party_spec: Array, runs: int) -> Dictionary:
	var wins := 0
	var waves := 0.0
	var secs := 0.0
	var kills := 0
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
	return {"wins": wins, "wave": waves / runs, "secs": secs / runs, "kpm": kills / (secs / 60.0)}
