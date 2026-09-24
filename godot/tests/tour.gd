extends Node
## Visual tour for development: builds a varied game in save slot 3, visits every screen and writes a
## screenshot of each. Needs a real display (or xvfb):
##   godot --path godot res://tests/tour.tscn -- --out=/some/folder [--only=name,name]
## It overwrites save slot 3.

var out := "user://tour"
var only: Array = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--only="):
			only = a.substr(7).split(",")
	DirAccess.make_dir_recursive_absolute(out)
	get_window().size = Vector2i(1600, 900)
	# stay alive across scene changes: this node stops being "the current scene"
	await get_tree().process_frame
	get_tree().current_scene = null
	await _run()
	get_tree().quit()


func _want(name: String) -> bool:
	return only.is_empty() or name in only


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out.path_join(name + ".png"))
	print("shot ", name)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _run() -> void:
	Options.values.reduce_motion = false
	if _want("title"):
		get_tree().change_scene_to_file("res://scenes/title.tscn")
		await _wait(1.6)
		await _shot("title")
	Game.start_slot(3, true)
	_populate()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await _wait(1.0)
	for m in Modal.layer.get_children():
		m.queue_free()
	await _wait(0.4)
	for screen in [["sanctum", ""], ["skill", "woodcutting"], ["skill", "smithing"], ["nexus", ""], ["pods", ""], ["aetherlog", ""], ["inventory", ""], ["works", ""]]:
		var name: String = screen[0] + ("_" + screen[1] if screen[1] != "" else "")
		if not _want(name):
			continue
		Main.go(screen[0], screen[1])
		await _wait(1.2)
		await _shot(name)
	if _want("expeditions"):
		Game.start_expedition("fractured-quarry")
		Main.go("expeditions")
		await _wait(5.0)
		await _shot("expeditions")
	if _want("shinies"):
		Main.go("nexus")
		var scr: Node = Main.instance._screen
		scr._filter_status = "shiny"
		scr.refresh()
		await _wait(1.0)
		await _shot("shinies")
	if _want("hatch"):
		Main.go("pods")
		await _wait(0.5)
		var egg: Dictionary = Game.state.pods[0]
		egg.readyAt = Game.now_sec() - 1
		Game.hatch(0)
		await _wait(2.4)
		await _shot("hatch_buildup")
		await _wait(2.2)
		await _shot("hatch_reveal")
	if _want("options"):
		OptionsPanel.open_modal()
		await _wait(0.5)
		await _shot("options")


## A mid-game Sanctum: several species, a shiny of every type, resources, an egg in a pod.
func _populate() -> void:
	var s := Game.state
	Game.dev_skill_level("woodcutting", 32)
	Game.dev_skill_level("mining", 18)
	Game.dev_skill_level("smithing", 12)
	var picks := [["brambletrundle", 2, 24, false], ["buzzbud", 3, 12, false], ["tuskcub", 4, 30, false], ["geodecore", 2, 15, false],
		["emberfang", 5, 44, false], ["roastbelly", 1, 8, false], ["dewdrop", 3, 21, false], ["voltfluff", 2, 5, false],
		["ashwood", 4, 22, false], ["riftsneak", 6, 50, false], ["sorrelcliff", 5, 26, false]]
	for p in picks:
		Game.dev_grant(p[0], p[1], p[2], p[3])
	for sp in ["sproutlet", "quakemaw", "cinderpup", "splashfin", "coilchirp", "eclipsa", "mudskulker"]:
		Game.dev_grant(sp, 3, 25, true)
	for id in ["oak-log", "willow-log", "copper-ore", "iron-ore", "minnow", "scrap", "copper-bar", "grilled-minnow", "timber-frame", "maple-log"]:
		Game.dev_add(id, 60)
	Game.dev_add("aether", 5000)
	Game.dev_add("gold", 3000)
	var cs: Array = s.creatures.values()
	var sprout: Dictionary = cs[0]
	Skills.assign(s, sprout, "woodcutting")
	for c in cs:
		match c.species:
			"brambletrundle":
				Skills.assign(s, c, "woodcutting")
			"buzzbud":
				Skills.assign(s, c, "herbalism")
			"tuskcub", "geodecore":
				Skills.assign(s, c, "mining")
			"emberfang":
				Skills.assign(s, c, "smithing")
			"dewdrop":
				Skills.assign(s, c, "fishing")
			"voltfluff":
				Skills.assign(s, c, "scavenging")
	var party := cs.filter(func(c): return c.species in ["riftsneak", "sorrelcliff", "quakemaw"])
	for i in party.size():
		Expedition.set_party_member(s, i, party[i])
	s.expedition.zones["whisperleaf-hollow"] = {"cleared": true, "runs": 4, "bestWave": 6, "kills": 40}
	var a: Dictionary = cs.filter(func(c): return c.species == "tuskcub")[0]
	var b: Dictionary = cs.filter(func(c): return c.species == "emberfang")[0]
	Game.dev_add("aether", 2000)
	Game.dev_add("copper-ore", 10)
	Game.dev_add("copper-bar", 10)
	Game.dev_add("iron-ore", 10)
	Game.dev_add("iron-bar", 10)
	Game.breed(a.id, b.id, 2)
	Game.changed.emit()
