extends Node
## Development probe (not a test): timing metrics for a big late-game save, through the real code.
##   godot --headless --path . res://tests/perf_probe.tscn [-- --n=600] [--seconds=60] [--only=sim,offline,save,pages]
## Builds a save with N Aetherlings (every skill's slots full, a party on an island, every island open), then
##   sim     runs Sim.step for --seconds of game time at 60 steps a second (the game's own tick);
##   offline resolves a 12-hour absence;
##   save    writes and reads the save as JSON (in memory, no slot touched);
##   pages   opens every page and times refresh() with nothing changed and after a capture.
## Prints the Perf table (Developer tools > Timings shows the same while playing). Uses no save slot.

var n := 600
var seconds := 60.0
var only := ["sim", "offline", "save", "pages"]


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="):
			n = int(a.substr(4))
		elif a.begins_with("--seconds="):
			seconds = float(a.substr(10))
		elif a.begins_with("--only="):
			only = a.substr(7).split(",")
	var t0 := Time.get_ticks_msec()
	print("perf probe: %d Aetherlings" % n)
	if "sim" in only:
		_sim()
	if "offline" in only:
		_offline()
	if "save" in only:
		_save()
	if "pages" in only:
		await _pages()
	print("\n" + Perf.table())
	print("\n(probe took %.1f s)" % ((Time.get_ticks_msec() - t0) / 1000.0))
	get_tree().quit(0)


## A late-game save: N Aetherlings of every species, every skill at 99 with its slots filled, every island
## cleared, a party of three on the last island.
static func big_save(count: int) -> Dictionary:
	var s := GameState.new_game(7)
	for i in count:
		var sp: Dictionary = Data.species_list[i % Data.species_list.size()]
		var c := Creatures.make(s, sp.id, 1 + i % 9, 1 + (i * 7) % 99, i % 97 == 0, [], "probe")
		s.creatures[c.id] = c
		Collection.on_owned(s, c)
	for skill in Data.skill_list:
		s.skills[skill.id].level = 99
	for z in Data.zone_list:
		s.expedition.zones[z.id] = {"cleared": true, "runs": 1, "bestWave": int(z.waves), "kills": 0}
	GameState.roster_changed(s)
	for skill in Data.skill_list:
		Skills.fill_slots(s, skill.id)
	var free: Array = s.creatures.values().filter(func(c): return Creatures.is_benched(c))
	for i in 3:
		Expedition.set_party_member(s, i, free[free.size() - 1 - i])
	for id in ["tinkerers-vessel", "flimsy-vessel"]:
		if Data.items.has(id):
			GameState.add_item(s, id, 500)
	return s


func _rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	return rng


func _sim() -> void:
	var s := big_save(n)
	var rng := _rng()
	var err := Expedition.start(s, Data.zone_list[-1].id, rng)
	if err != "":
		printerr("expedition: " + err)
	var steps := int(seconds * 60.0)
	var kills0 := int(s.counters.kills)
	for i in steps:
		Sim.step(s, 1.0 / 60.0, rng)
	print("sim: %d steps (%.0f s of play), %d kills, %d workers" % [steps, seconds, int(s.counters.kills) - kills0,
		s.creatures.values().filter(func(c): return Creatures.job_kind(c) == "skill").size()])


func _offline() -> void:
	var s := big_save(n)
	var rng := _rng()
	Expedition.start(s, Data.zone_list[-1].id, rng)
	var t0 := Perf.begin()
	var sum := Offline.apply(s, 12 * 3600.0, rng)
	Perf.end("probe.offline_12h", t0)
	print("offline: %d actions, %d Aetherlings after" % [int(sum.actions), s.creatures.size()])


func _save() -> void:
	var s := big_save(n)
	for i in 5:
		var t0 := Perf.begin()
		var text := JSON.stringify(s)
		Perf.end("save.stringify", t0)
		var t1 := Perf.begin()
		var parsed: Variant = JSON.parse_string(text)
		Perf.end("probe.save_parse", t1)
		if i == 0:
			print("save: %.0f KB, %d top-level keys" % [text.length() / 1024.0, (parsed as Dictionary).size()])


func _pages() -> void:
	Game.slot = 0
	Game.state = big_save(n)
	var layer := Control.new()
	add_child(layer)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	Modal.layer = layer
	for c in layer.get_children():
		c.free()
	var pages := [["nexus", ""], ["aetherlog", ""], ["expeditions", ""], ["skill", "woodcutting"], ["market", ""],
		["inventory", ""], ["pods", ""], ["sanctum", ""], ["achievements", ""], ["works", ""], ["eggmarket", ""]]
	for p in pages:
		main.show_screen(p[0], p[1])
		await get_tree().process_frame
	# each page once more: the first open also loads its sprites and icons, the second is the page alone
	for p in pages:
		main.show_screen("works" if p[0] != "works" else "market")
		await get_tree().process_frame
		main.show_screen(p[0], p[1])
		await get_tree().process_frame
		for i in 5:
			var t0 := Perf.begin()
			main._screen.refresh()
			Perf.end("page.refresh_same." + p[0], t0)
			await get_tree().process_frame
		# a capture: one more Aetherling of a species already logged, the most common Game.changed
		var c := Creatures.make(Game.state, "sproutlet", 1, 1, false, [], "probe")
		Game.state.creatures[c.id] = c
		Collection.on_owned(Game.state, c)
		GameState.roster_changed(Game.state)
		var t1 := Perf.begin()
		main._screen.refresh()
		Perf.end("page.refresh_capture." + p[0], t1)
	main.queue_free()
