extends Node
## Visual tour for development: builds a varied game in save slot 3, visits every screen and writes a
## screenshot of each. Needs a real display (or xvfb):
##   godot --path . res://tests/tour.tscn -- --out=/some/folder [--only=name,name] [--size=1280x720]
## It overwrites save slot 3.

var out := "user://tour"
var only: Array = []
var size := Vector2i(1920, 1080)   ## --size=1280x720 to see a smaller window


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a.begins_with("--only="):
			only = a.substr(7).split(",")
		elif a.begins_with("--size="):
			var wh := a.substr(7).split("x")
			size = Vector2i(int(wh[0]), int(wh[1]))
	DirAccess.make_dir_recursive_absolute(out)
	get_window().size = size
	# stay alive across scene changes: this node stops being "the current scene"
	await get_tree().process_frame
	get_tree().current_scene = null
	await _run()
	get_tree().quit()


func _want(shot_name: String) -> bool:
	return only.is_empty() or shot_name in only


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png(out.path_join(shot_name + ".png"))
	print("shot ", shot_name)


func _tip_label(text: String) -> Label:
	var l := Label.new()
	l.theme_type_variation = "TooltipLabel"
	l.text = text
	return l


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _run() -> void:
	Options.values.reduce_motion = false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--ui-scale="):
			Options.values.ui_scale = int(a.substr(11))   # this run only: not saved to options.cfg
			Options.apply()
	if _want("title"):
		get_tree().change_scene_to_file("res://scenes/title.tscn")
		await _wait(1.6)
		await _shot("title")
		var title: Node = get_tree().current_scene
		title._slots_modal("load")
		await _wait(0.5)
		await _shot("title_load")
		_close_modals()
		title._slots_modal("new")
		await _wait(0.3)
		_close_modals()
		title._credits()
		await _wait(0.3)
		_close_modals()
	if _want("fresh"):
		Game.start_slot(3, true)
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		await _wait(1.2)
		await _shot("fresh_welcome")
		for m in Modal.layer.get_children():
			m.queue_free()
		Main.go("skill", "woodcutting")
		await _wait(0.3)
		Game.assign(Game.state.creatures.keys()[0], "woodcutting")
		await _wait(7.0)
		await _shot("fresh_woodcutting")
		Main.go("sanctum")
		await _wait(4.0)
		await _shot("fresh_sanctum")
		Main.go("expeditions")
		await _wait(0.6)
		await _shot("fresh_expeditions")
		Game.leave()
	Game.start_slot(3, true)
	_populate()
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await _wait(1.0)
	for m in Modal.layer.get_children():
		m.queue_free()
	await _wait(0.4)
	GameState.add_item(Game.state, "sunken-trinket", 2)
	GameState.add_item(Game.state, "seedcache", 1)
	load("res://scripts/ui/screens/inventory_screen.gd").selected = "oak-log"
	for screen in [["sanctum", ""], ["skill", "woodcutting"], ["skill", "smithing"], ["skill", "fishing"], ["nexus", ""], ["pods", ""], ["aetherlog", ""], ["inventory", ""], ["works", ""], ["achievements", ""]]:
		var shot_name: String = screen[0] + ("_" + screen[1] if screen[1] != "" else "")
		if not _want(shot_name):
			continue
		Main.go(screen[0], screen[1])
		await _wait(1.2)
		await _shot(shot_name)
	if _want("picker"):
		# the worker picker lists each creature's trait bonuses for the job
		Main.go("skill", "woodcutting")
		await _wait(0.4)
		Main.instance._screen._pick("")
		await _wait(0.4)
		await _shot("picker")
		_close_modals()
	if _want("expeditions"):
		Game.start_expedition("fractured-quarry")
		Main.go("expeditions")
		await _wait(5.0)
		await _shot("expeditions")
		# a dialog over a live battle: the fighters must stay underneath it
		Main.instance._open_notifications()
		await _wait(0.4)
		await _shot("expeditions_dialog")
		_close_modals()
	if _want("autobind"):
		Main.go("expeditions")
		await _wait(0.4)
		for tab in ["autobind", "party", "supplies"]:
			Main.instance._screen._bottom_tab = tab
			Main.instance._screen._fill_bottom()
			await _wait(0.4)
			await _shot("bottom_" + tab)
	if _want("folded"):
		Main.go("expeditions")
		await _wait(0.3)
		Main.instance._screen._set_open("exp_log_open", false)
		Main.instance._screen._set_open("exp_zones_open", false)
		await _wait(0.6)
		await _shot("folded")
		Main.instance._screen._set_open("exp_log_open", true)
		Main.instance._screen._set_open("exp_zones_open", true)
	if _want("tooltip"):
		# tooltips can't be hovered here: draw the two kinds in their themed panel instead
		var row := UI.hbox(24)
		row.position = Vector2(420, 200)
		for content in [UI.item_tooltip("oak-log"), UI.item_tooltip("timber-frame"), _tip_label("A Faint Brambletrundle broke free of a Tinker's Vessel · 41% chance")]:
			var p := PanelContainer.new()
			p.theme_type_variation = "TooltipPanel"
			p.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			p.add_child(content)
			row.add_child(p)
		Main.instance.add_child(row)
		await _wait(0.4)
		await _shot("tooltip")
		row.queue_free()
	if _want("milestones"):
		Main.go("aetherlog")
		await _wait(0.3)
		Main.instance._screen.tab = "milestones"
		Main.instance._screen.refresh()
		await _wait(0.6)
		await _shot("milestones")
	if _want("dexpage"):
		# the species page for a species owned at its highest form
		var best: Dictionary = Game.state.creatures.values().reduce(func(a, b): return a if Creatures.form_of(a) >= Creatures.form_of(b) else b)
		AetherlogScreen._detail(Data.species[best.species])
		await _wait(0.5)
		await _shot("dexpage")
		_close_modals()
	if _want("attune"):
		Main.go("nexus")
		await _wait(0.4)
		var c: Dictionary = Game.state.creatures.values().filter(func(x): return x.traits.size() >= 2)[0]
		Main.instance._screen._attune(c)
		await _wait(0.5)
		await _shot("attune")
		_close_modals()
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
	if _want("smoke"):
		await _smoke()
	if _want("options"):
		OptionsPanel.open_modal()
		await _wait(0.5)
		await _shot("options")
	if _want("market"):
		await _market()


## The Market's tabs (with a limited offer forced into today's stock), the Egg Market, running boosts in
## the top bar, bulk selling and a bought work slot.
func _market() -> void:
	var s := Game.state
	s.gold = 4.0e6
	for i in 7:
		Expedition.zone_state(s, Data.zone_list[i].id).cleared = true
	var now := Game.now_sec()
	var w := 0
	while w < 400 and not Market.roll_stock(s, w).offers.any(func(o): return o.get("limited", false) and o.kind == "egg"):
		w += 1
	var st := Market.roll_stock(s, w)
	st.window = Market.window(now)
	s.market.stock = st
	Market.add_boost(s, "aether-incense")
	Market.add_boost(s, "glimmer-lure")
	Game.changed.emit()
	for tab in ["stock", "vessels", "materials", "boosts", "slots"]:
		MarketScreen.tab = tab
		Main.go("market")
		Main.instance._screen.refresh()
		await _wait(0.8)
		await _shot("market_" + tab)
		Main.go("sanctum")
	Main.go("eggmarket")
	await _wait(1.0)
	await _shot("eggmarket")
	Main.go("inventory")
	await _wait(0.4)
	Main.instance._screen._bulk_sell()
	await _wait(0.4)
	await _shot("inventory_bulk")
	_close_modals()
	Game.dev_skill_level("woodcutting", 70)
	Market.buy_slot(s, "woodcutting")
	Main.go("skill", "woodcutting")
	await _wait(0.8)
	await _shot("skill_extra_slot")


## Opens every dialog and tab once so script errors show up in the log.
func _smoke() -> void:
	var s := Game.state
	var main: Node = Main.instance
	var any_c: Dictionary = s.creatures.values()[1]
	Main.go("nexus", any_c.id)
	await _wait(0.4)
	var nx: Node = main._screen
	nx._attune(any_c)
	await _wait(0.3)
	await _shot("smoke_attune")
	_close_modals()
	nx._rename(any_c)
	await _wait(0.2)
	_close_modals()
	nx._release(any_c)
	await _wait(0.2)
	_close_modals()
	nx._join_party(any_c)
	for tab in ["recipes", "milestones", "dex"]:
		Main.go("sanctum")
		await _wait(0.1)
		AetherlogScreen.tab = tab
		Main.go("aetherlog")
		await _wait(0.5)
		await _shot("smoke_log_" + tab)
	var aether_log: Node = main._screen
	aether_log._detail(Data.species["sproutlet"])
	await _wait(0.3)
	await _shot("smoke_dex_detail")
	_close_modals()
	aether_log._detail(Data.species["sorrelcliff"])
	await _wait(0.2)
	_close_modals()
	Main.go("skill", "mining")
	await _wait(0.3)
	main._screen._pick("")
	await _wait(0.4)
	await _shot("smoke_picker")
	_close_modals()
	Main.go("pods")
	await _wait(0.3)
	var cs: Array = s.creatures.values()
	PodsScreen.parent_a = cs[1].id
	PodsScreen.parent_b = cs[5].id
	main._screen.refresh()
	await _wait(0.4)
	await _shot("smoke_pods_pair")
	main._screen._pick(0)
	await _wait(0.2)
	_close_modals()
	Main.go("expeditions")
	await _wait(0.3)
	main._screen._pick_party(0)
	await _wait(0.2)
	_close_modals()
	main.open_pause_menu()
	await _wait(0.3)
	await _shot("smoke_pause")
	_close_modals()
	main._backup_modal()
	await _wait(0.2)
	_close_modals()
	main._open_notifications()
	await _wait(0.2)
	_close_modals()
	main._show_summary(Offline.apply(s, 7200.0, Game.rng))
	await _wait(0.4)
	await _shot("smoke_summary")
	_close_modals()
	Main.go("inventory")
	await _wait(0.2)
	InventoryScreen.selected = "oak-log"
	main._screen.refresh()
	await _wait(0.3)
	await _shot("smoke_inventory_item")
	Game.sell("oak-log", 5)
	Game.market_buy("tinkerers-vessel", 1)
	Game.buy_upgrade("perches")
	for i in 3:
		Game.claim_goal()
	for c in Collection.claimable(s):
		Game.claim_milestone(c.track, c.index)
	await _wait(0.3)


func _close_modals() -> void:
	for m in Modal.layer.get_children():
		if m is Modal:
			m.queue_free()


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
