extends Node
## How long each page's refresh() takes with a big roster (the work Game.changed triggers on the open page).
##   godot --headless --path . res://tools/refresh_bench.tscn [-- --n=600]
## Uses an in-memory game (no save slot), so nothing on disk is touched.

const SECTIONS := {"skill": ["_fill_slots", "_fill_actions", "_fill_rate"],
	"expeditions": ["_apply_folds", "_fill_zones", "_fill_preview", "_fill_controls", "_fill_right"]}


func _ready() -> void:
	print("bench start")
	var n := 600
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--n="):
			n = int(a.substr(4))
	Game.slot = 0
	Game.state = GameState.new_game()
	var s := Game.state
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in n:
		var sp: Dictionary = Data.species_list[i % Data.species_list.size()]
		var c := Creatures.make(s, sp.id, 1 + i % 9, 1 + i % 60, i % 97 == 0, [], "bench")
		s.creatures[c.id] = c
		Collection.on_owned(s, c)
	GameState.roster_changed()
	var party: Array = s.creatures.values().slice(0, 3)
	for i in 3:
		Expedition.set_party_member(s, i, party[i])
	Expedition.start(s, Data.zone_list[0].id, rng)
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
		if not main.SCREENS.has(p[0]):
			continue
		main.show_screen(p[0], p[1])
		await get_tree().process_frame
		var times := []
		for i in 5:
			var t0 := Time.get_ticks_usec()
			main._screen.refresh()
			times.append((Time.get_ticks_usec() - t0) / 1000.0)
			await get_tree().process_frame
		times.sort()
		var parts: Array = SECTIONS.get(p[0], [])
		if not parts.is_empty():
			sections(main._screen, parts)
		print("%-14s median %6.1f ms  (min %.1f, max %.1f)" % [p[0], times[2], times[0], times[4]])
	get_tree().quit(0)


## Times each named section of the open page (for finding what a refresh spends its time on).
static func sections(screen: Node, names: Array) -> void:
	for m in names:
		var t0 := Time.get_ticks_usec()
		screen.call(m)
		print("    %-18s %6.1f ms" % [m, (Time.get_ticks_usec() - t0) / 1000.0])
