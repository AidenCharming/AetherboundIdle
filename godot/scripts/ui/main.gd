class_name Main
extends Control
## The game shell: navigation rail, top bar, the current screen, and overlays (modals, toasts, reveals).

const SCREENS := {
	"sanctum": preload("res://scripts/ui/screens/sanctum_screen.gd"),
	"skill": preload("res://scripts/ui/screens/skill_screen.gd"),
	"nexus": preload("res://scripts/ui/screens/nexus_screen.gd"),
	"pods": preload("res://scripts/ui/screens/pods_screen.gd"),
	"expeditions": preload("res://scripts/ui/screens/expedition_screen.gd"),
	"aetherlog": preload("res://scripts/ui/screens/aetherlog_screen.gd"),
	"inventory": preload("res://scripts/ui/screens/inventory_screen.gd"),
	"works": preload("res://scripts/ui/screens/works_screen.gd"),
}

static var instance: Control

var current := ""
var current_arg := ""
var _content: Control
var _screen: Control
var _rail_list: VBoxContainer
var _nav_buttons: Dictionary = {}
var _top: Dictionary = {}
var _overlay: Control
var _reveal_layer: Control
var _reveal: Reveal
var _fade: ColorRect
var _sky: SkyBackdrop
var _rail_refresh := 0.0


func _ready() -> void:
	instance = self
	theme = ThemeFactory.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if Game.state.is_empty():
		Game.start_slot(1)
	_sky = SkyBackdrop.new()
	add_child(_sky)
	var root := UI.hbox(0)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.add_child(_build_rail())
	var right := UI.vbox(0)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(right)
	right.add_child(_build_top_bar())
	_content = Control.new()
	_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_content.clip_contents = true
	right.add_child(_content)
	_reveal_layer = Control.new()
	_reveal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_reveal_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_reveal_layer)
	# Controls draw by z_index before tree order, and the arena lifts its fighters and effects a few z levels,
	# so the overlays sit well above anything a screen can raise (reveal < dialogs < toasts < fade).
	_reveal_layer.z_index = 100
	_overlay = Control.new()
	_overlay.z_index = 110
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	Modal.layer = _overlay
	# toasts stack up from the bottom-right corner, clear of the top bar and the side panels' headers
	var toasts := Toasts.new()
	toasts.anchor_left = 1.0
	toasts.anchor_right = 1.0
	toasts.anchor_top = 1.0
	toasts.anchor_bottom = 1.0
	toasts.offset_left = -380
	toasts.offset_right = -22
	toasts.offset_top = -400
	toasts.offset_bottom = -22
	toasts.alignment = BoxContainer.ALIGNMENT_END
	toasts.z_index = 120
	add_child(toasts)
	_reveal = Reveal.new()
	_reveal_layer.add_child(_reveal)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.z_index = 130
	add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 0.6)

	Game.changed.connect(_on_changed)
	Game.offline_summary.connect(_show_summary)
	Game.reveal_requested.connect(func(kind, data): _reveal.enqueue(kind, data))
	Game.notifications_changed.connect(_update_bell)
	show_screen("sanctum")
	Music.play("sanctum")
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title("Aetherbound Idle · Slot %d" % Game.slot)
	if not Game.last_offline_summary.is_empty():
		var s := Game.last_offline_summary
		Game.last_offline_summary = {}
		_show_summary.call_deferred(s)
		# play at most a handful of evolution reveals after a long absence; the summary lists the rest
		var evolutions: Array = s.events.filter(func(e): return e.type == "evolved")
		for e in evolutions.slice(0, 5):
			_reveal.enqueue("evolve", e)
	if int(Game.state.counters.actions) == 0 and Game.state.creatures.size() == 1:
		_welcome.call_deferred()


# ---------------------------------------------------------------- navigation

static func go(screen: String, arg := "") -> void:
	if instance:
		instance.show_screen(screen, arg)


func show_screen(screen: String, arg := "") -> void:
	if screen == current and arg == current_arg and _screen:
		return
	current = screen
	current_arg = arg
	if _screen:
		_screen.queue_free()
	var s: Control = SCREENS[screen].new()
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if s.has_method("setup"):
		s.setup(arg)
	_screen = s
	_content.add_child(s)
	s.modulate.a = 0.0
	create_tween().tween_property(s, "modulate:a", 1.0, 0.15)
	_update_nav()
	Music.play("expedition" if screen == "expeditions" else "sanctum")
	var tint := {"expeditions": [Color(0.5, 0.25, 0.3), Color(0.2, 0.4, 0.7)], "pods": [Color(0.55, 0.3, 0.7), Color(0.2, 0.6, 0.6)],
		"aetherlog": [Color(0.35, 0.3, 0.75), Color(0.6, 0.45, 0.2)]}
	var tt: Array = tint.get(screen, [Color(0.25, 0.2, 0.7), Color(0.1, 0.55, 0.7)])
	_sky.tint(tt[0], tt[1], 0.3)


func _on_changed() -> void:
	if _screen and _screen.has_method("refresh"):
		_screen.refresh()
	_refresh_rail()


func _build_rail() -> Control:
	var rail := UI.panel("Rail")
	rail.custom_minimum_size.x = 236
	var v := UI.vbox(6)
	rail.add_child(v)
	var logo := UI.hbox(8)
	logo.add_child(UI.icon(Data.ui_icon("aether"), 30))
	var title_lbl := UI.label("Aetherbound", "H2")
	title_lbl.add_theme_color_override("font_shadow_color", Color(0.45, 0.85, 1.0, 0.4))
	title_lbl.add_theme_constant_override("shadow_outline_size", 10)
	logo.add_child(title_lbl)
	v.add_child(UI.margin(logo, 6, 8, 0, 10))
	_rail_list = UI.vbox(2)
	v.add_child(UI.scroll(_rail_list))
	var menu := UI.button("Menu", "Ghost", open_pause_menu, Data.ui_icon("settings"))
	menu.alignment = HORIZONTAL_ALIGNMENT_LEFT
	v.add_child(menu)
	_fill_rail()
	return rail


func _fill_rail() -> void:
	UI.clear(_rail_list)
	_nav_buttons.clear()
	_nav_item("sanctum", "", "Sanctum", "sanctum")
	_section("Skills")
	for skill in Data.skill_list:
		_nav_item("skill", skill.id, skill.name, skill.id)
	_section("Creatures")
	_nav_item("nexus", "", "Nexus", "nexus")
	_nav_item("pods", "", "Genesis Pods", "pods")
	_section("Adventure")
	_nav_item("expeditions", "", "Expeditions", "expeditions")
	_section("Collection")
	_nav_item("aetherlog", "", "Aether-Log", "aetherlog")
	_section("Sanctum")
	_nav_item("inventory", "", "Inventory & Market", "inventory")
	_nav_item("works", "", "Sanctum Works", "works")
	_refresh_rail()


func _section(text: String) -> void:
	var l := UI.label(text.to_upper(), "Faint")
	l.add_theme_font_size_override("font_size", 12)
	_rail_list.add_child(UI.margin(l, 12, 12, 0, 2))


func _nav_item(screen: String, arg: String, text: String, icon_name: String) -> void:
	var b := UI.button("", "Nav")
	b.custom_minimum_size.y = 38
	var h := UI.hbox(10)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	h.offset_left = 10
	h.offset_right = -10
	h.add_child(UI.icon(Data.ui_icon(icon_name), 24))
	var l := UI.label(text)
	l.add_theme_font_override("font", ThemeFactory.bold_font())
	l.add_theme_font_size_override("font_size", 15)
	h.add_child(l)
	h.add_child(UI.spacer())
	var extra := UI.label("", "Small")
	h.add_child(extra)
	b.add_child(h)
	b.pressed.connect(func(): show_screen(screen, arg))
	_rail_list.add_child(b)
	_nav_buttons[screen + ":" + arg] = {"button": b, "extra": extra, "label": l, "icon": h.get_child(0)}


func _update_nav() -> void:
	for key in _nav_buttons:
		var b: Button = _nav_buttons[key].button
		b.theme_type_variation = "NavActive" if key == current + ":" + current_arg else "Nav"


func _refresh_rail() -> void:
	if Game.state.is_empty():
		return
	var s := Game.state
	for skill in Data.skill_list:
		var nb: Dictionary = _nav_buttons.get("skill:" + skill.id, {})
		if nb.is_empty():
			continue
		var workers := GameState.workers(s, skill.id).size()
		var usable := skill.type == null or Collection.owned_type(s, skill.type)
		nb.extra.text = "%d" % int(s.skills[skill.id].level)
		nb.extra.add_theme_color_override("font_color", Palette.AETHER if workers > 0 else Palette.TEXT_FAINT)
		nb.label.modulate.a = 1.0 if usable else 0.45
		nb.icon.modulate.a = 1.0 if usable else 0.4
		nb.button.tooltip_text = "" if usable else "Needs a %s Aetherling" % Data.types[skill.type].name
	var pods: Dictionary = _nav_buttons["pods:"]
	var ready_count := Game.ready_eggs().size()
	pods.extra.text = "%d ready_count" % ready_count if ready_count > 0 else ""
	pods.extra.add_theme_color_override("font_color", Palette.GOLD)
	var ex: Dictionary = _nav_buttons["expeditions:"]
	if Expedition.is_running(s) and not s.expedition.battle.is_empty():
		ex.extra.text = "wave %d" % int(s.expedition.battle.wave) if s.expedition.battle.phase != "rest" else "resting"
	else:
		ex.extra.text = "%d waiting" % s.expedition.pending.size() if not s.expedition.pending.is_empty() else ""
	ex.extra.add_theme_color_override("font_color", Palette.AETHER)
	var log_nav: Dictionary = _nav_buttons["aetherlog:"]
	var claim := Collection.claimable(s).size()
	log_nav.extra.text = "%d reward%s" % [claim, "" if claim == 1 else "s"] if claim > 0 else ""
	log_nav.extra.add_theme_color_override("font_color", Palette.GOLD)


# ---------------------------------------------------------------- top bar

func _build_top_bar() -> Control:
	var bar := UI.hbox(10)
	var m := UI.margin(bar, 18, 12, 18, 6)
	_top.aether = _chip("aether", "Aether: your main currency. Perched Aetherlings and the Resonance Extractor make it.")
	_top.gold = _chip("gold", "Gold: from selling items, scavenging and expeditions.")
	_top.vessels = _chip("vessel", "Aether Vessels: bind wild Aetherlings on expeditions.")
	_top.meals = _chip("meal", "Meals: your expedition party eats them to heal between waves.")
	for k in ["aether", "gold", "vessels", "meals"]:
		bar.add_child(_top[k].panel)
	_top.vessels.panel.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: show_screen("inventory"))
	bar.add_child(UI.spacer())
	_top.status = UI.label("", "Dim")
	bar.add_child(_top.status)
	var bell := UI.button("", "Ghost", _open_notifications, Data.ui_icon("bell"))
	bell.tooltip_text = "Notifications"
	_top.bell = bell
	bar.add_child(bell)
	var menu := UI.button("", "Ghost", open_pause_menu, Data.ui_icon("settings"))
	menu.tooltip_text = "Menu (Esc)"
	bar.add_child(menu)
	return m


func _chip(icon_name: String, tip: String) -> Dictionary:
	var p := UI.panel("Pill")
	p.tooltip_text = tip
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	var h := UI.hbox(8)
	h.add_child(UI.icon(Data.ui_icon(icon_name), 24))
	var v := UI.label("0", "Num")
	v.add_theme_font_size_override("font_size", 18)
	h.add_child(v)
	var sub := UI.label("", "Faint")
	h.add_child(sub)
	p.add_child(h)
	return {"panel": p, "value": v, "sub": sub}


func _update_bell() -> void:
	_top.bell.text = str(Game.unread) if Game.unread > 0 else ""


func _process(delta: float) -> void:
	if Game.state.is_empty():
		return
	var s := Game.state
	_top.aether.value.text = F.format_num(float(s.aether))
	_top.aether.sub.text = "+%s/min" % F.format_num(Economy.aether_per_min(s))
	_top.gold.value.text = F.format_num(float(s.gold))
	var vessels := 0.0
	var meals := 0.0
	for it in Data.item_list:
		if it.category == "vessel":
			vessels += GameState.count(s, it.id)
		elif it.category == "meal":
			meals += GameState.count(s, it.id)
	_top.vessels.value.text = F.format_num(vessels)
	_top.meals.value.text = F.format_num(meals)
	_rail_refresh -= delta
	if _rail_refresh <= 0.0:
		_rail_refresh = 1.0
		_refresh_rail()
		var working := 0
		for c in s.creatures.values():
			if Creatures.job_kind(c) == "skill":
				working += 1
		_top.status.text = "%d working · %d perched" % [working, Economy.perched(s).size()]


const SHORTCUTS := {KEY_1: "sanctum", KEY_2: "nexus", KEY_3: "pods", KEY_4: "expeditions", KEY_5: "aetherlog", KEY_6: "inventory", KEY_7: "works"}


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not Modal.any_open() and not _reveal.active:
		get_viewport().set_input_as_handled()
		open_pause_menu()
	elif event is InputEventKey and event.pressed and not event.echo and not Modal.any_open() and not _reveal.active:
		var screen: String = SHORTCUTS.get(event.keycode, "")
		if screen != "" and not (get_viewport().gui_get_focus_owner() is LineEdit):
			get_viewport().set_input_as_handled()
			show_screen(screen)


# ---------------------------------------------------------------- menus and summaries

func open_pause_menu() -> void:
	var v := UI.vbox(10)
	v.add_child(UI.wrap_label("Your Aetherlings keep working while this menu is open, and while the game is closed (up to %d hours)." % int(GameState.upgrade_value(Game.state, "offline-cap")), "Faint", 380))
	var box := {}  # holds the modal: lambdas capture locals by value, a Dictionary by reference
	var add := func(text: String, variation: String, cb: Callable):
		var b := UI.button(text, variation, cb)
		b.custom_minimum_size.y = 44
		v.add_child(b)
	add.call("Resume", "Primary", func(): box.m.close())
	add.call("Options", "", func(): OptionsPanel.open_modal())
	add.call("Save now", "", func():
		Game.save_game()
		Game.info("Saved to slot %d" % Game.slot, Data.ui_icon("xp")))
	add.call("Back up or restore this save", "", _backup_modal)
	if Options.get_value("dev_tools"):
		add.call("Developer tools", "", _dev_modal)
	add.call("Save and return to title", "", func(): _leave(false))
	if OS.get_name() != "Web":
		add.call("Save and quit to desktop", "Ghost", func(): _leave(true))
	box.m = Modal.open(v, "Slot %d" % Game.slot, 440)


func _leave(quit: bool) -> void:
	Game.leave()
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_title("Aetherbound Idle")
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.4)
	tw.tween_callback(func():
		if quit:
			get_tree().quit()
		else:
			get_tree().change_scene_to_file("res://scenes/title.tscn"))


func _backup_modal() -> void:
	var v := UI.vbox(12)
	v.add_child(UI.wrap_label("Copy your save as text to keep it somewhere safe, or paste a saved text to restore it into this slot. Saves also live in the game's user folder:", "Dim", 560))
	v.add_child(UI.label(ProjectSettings.globalize_path("user://"), "Faint"))
	var te := TextEdit.new()
	te.custom_minimum_size = Vector2(600, 150)
	te.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	te.placeholder_text = "Paste a save here to restore it"
	v.add_child(te)
	var row := UI.hbox(10)
	row.add_child(UI.button("Copy save to clipboard", "Primary", func():
		DisplayServer.clipboard_set(Game.export_text())
		Game.info("Save copied to the clipboard")))
	row.add_child(UI.spacer())
	row.add_child(UI.button("Restore pasted save", "Danger", func():
		if te.text.strip_edges() == "":
			Game.warn("Paste a save first.")
			return
		Modal.confirm("Restore this save?", "It replaces the game in slot %d." % Game.slot, "Restore", func():
			var err := Game.import_text(te.text)
			if err != "":
				Game.warn(err)
			else:
				Game.info("Save restored")
				show_screen("sanctum")
				_fill_rail(), true)))
	v.add_child(row)
	Modal.open(v, "Back up or restore", 660)


func _dev_modal() -> void:
	var v := UI.vbox(12)
	v.add_child(UI.wrap_label("Testing shortcuts. Anything done here counts like normal play in this save slot.", "Faint", 560))
	# grant a creature: one row (the dialog is wide enough for it)
	var row := UI.hbox(8)
	var sp := OptionButton.new()
	for i in Data.species_list.size():
		sp.add_item(Data.species_list[i].name, i)
	var rar := OptionButton.new()
	for i in Data.rarities.size():
		rar.add_item(Data.rarities[i].name, i)
	var lvl := SpinBox.new()
	lvl.min_value = 1
	lvl.max_value = Data.tuning.creature.maxLevel
	lvl.value = 1
	var shiny := CheckButton.new()
	shiny.text = "Shiny"
	# form comes from level: picking a form sets the level to where that form starts, and typing a level
	# shows the form it gives
	var form_levels: Array = Data.tuning.creature.formLevels
	var form := OptionButton.new()
	for i in form_levels.size():
		form.add_item("Form %d" % (i + 1), i)
	form.item_selected.connect(func(i): lvl.value = int(form_levels[i]))
	lvl.value_changed.connect(func(new_level): form.selected = F.form_for_level(int(new_level)) - 1)
	row.add_child(sp)
	row.add_child(rar)
	row.add_child(form)
	row.add_child(UI.label("Lv", "Faint"))
	row.add_child(lvl)
	row.add_child(shiny)
	row.add_child(UI.button("Grant", "Primary", func():
		Game.dev_grant(Data.species_list[sp.selected].id, rar.selected + 1, int(lvl.value), shiny.button_pressed)
		Game.info("Granted %s" % Data.species_list[sp.selected].name)))
	v.add_child(UI.label("Grant an Aetherling", "H3"))
	v.add_child(row)
	v.add_child(UI.label("Resources", "H3"))
	var res := UI.flow(8, 8)
	for pair in [["aether", 1000], ["aether", 100000], ["gold", 1000], ["gold", 100000]]:
		res.add_child(UI.button("+%s %s" % [F.format_num(pair[1]), Data.item_name(pair[0])], "", func(): Game.dev_add(pair[0], pair[1])))
	res.add_child(UI.button("+50 of every item", "", func():
		for it in Data.item_list:
			Game.dev_add(it.id, 50)))
	v.add_child(res)
	v.add_child(UI.label("Time", "H3"))
	var ff := UI.flow(8, 8)
	for h in [1, 4, 12]:
		ff.add_child(UI.button("Fast-forward %dh" % h, "", func(): Game.dev_fast_forward(h)))
	ff.add_child(UI.button("Finish all eggs", "", func():
		for egg in Game.state.pods:
			if not egg.is_empty():
				egg.readyAt = Game.now_sec()
		Game.changed.emit()))
	v.add_child(ff)
	v.add_child(UI.label("Skill level", "H3"))
	var sr := UI.hbox(8)
	var sk := OptionButton.new()
	for i in Data.skill_list.size():
		sk.add_item(Data.skill_list[i].name, i)
	var sl := SpinBox.new()
	sl.min_value = 1
	sl.max_value = Data.tuning.skills.maxLevel
	sl.value = 10
	sr.add_child(sk)
	sr.add_child(sl)
	sr.add_child(UI.button("Set", "", func(): Game.dev_skill_level(Data.skill_list[sk.selected].id, int(sl.value))))
	v.add_child(sr)
	Modal.open(v, "Developer tools", 920)


func _open_notifications() -> void:
	Game.unread = 0
	_update_bell()
	var v := UI.vbox(6)
	if Game.notifications.is_empty():
		v.add_child(UI.label("Nothing yet. Level-ups, captures and rare finds show up here.", "Dim"))
	for n in Game.notifications:
		var h := UI.hbox(10)
		if n.icon:
			h.add_child(UI.icon(n.icon, 22))
		h.add_child(UI.wrap_label(n.text, ""))
		h.add_child(UI.label(F.format_seconds(Game.now_sec() - n.time) + " ago", "Faint"))
		v.add_child(h)
	var sc := UI.scroll(v)
	sc.custom_minimum_size = Vector2(560, 420)
	Modal.open(sc, "Notifications", 620)


func _show_summary(s: Dictionary) -> void:
	Game.last_offline_summary = {}
	if float(s.get("usedSeconds", 0.0)) < 60.0:
		return
	var root := UI.vbox(16)
	# headline: how long, and whether the Sanctum worked the whole time
	var head := UI.vbox(2)
	head.add_child(UI.label("You were away for %s" % F.format_seconds(s.elapsed), "H1"))
	head.add_child(UI.wrap_label("Your Sanctum kept working the whole time." if not s.capped else
		"Your Sanctum worked for the first %s. Build the Dream Anchor in Sanctum Works to cover longer." % F.format_seconds(s.usedSeconds), "Dim", 820))
	root.add_child(head)
	# big tiles: Aether, gold, tasks
	var tiles := UI.hbox(12)
	if s.aether > 0.5:
		tiles.add_child(_summary_tile(Data.ui_icon("aether"), F.format_num(s.aether), "Aether", Palette.AETHER))
	if s.gold > 0.5:
		tiles.add_child(_summary_tile(Data.ui_icon("gold"), F.format_num(s.gold), "Gold", Palette.GOLD))
	if s.actions > 0:
		tiles.add_child(_summary_tile(Data.ui_icon("works"), F.format_num(s.actions), "Tasks finished", Palette.TEXT))
	var eggs := Game.ready_eggs().size()
	if eggs > 0:
		tiles.add_child(_summary_tile(Data.ui_icon("pods"), str(eggs), "Eggs ready", Palette.GOOD))
	root.add_child(tiles)
	var cols := UI.hbox(18)
	root.add_child(cols)
	# left: what was made and used
	var left := UI.vbox(10)
	left.custom_minimum_size.x = 440
	cols.add_child(left)
	if not s.gained.is_empty():
		left.add_child(UI.label("Gathered and crafted", "H3"))
		var g := GridContainer.new()
		g.columns = 3
		g.add_theme_constant_override("h_separation", 8)
		g.add_theme_constant_override("v_separation", 8)
		var ids: Array = s.gained.keys()
		ids.sort_custom(func(a, b): return s.gained[a] > s.gained[b])
		for id in ids:
			g.add_child(_summary_item(id, s.gained[id], Palette.TEXT))
		left.add_child(g)
	if not s.used.is_empty():
		left.add_child(UI.label("Used up", "H3"))
		var g2 := GridContainer.new()
		g2.columns = 3
		g2.add_theme_constant_override("h_separation", 8)
		g2.add_theme_constant_override("v_separation", 8)
		for id in s.used:
			g2.add_child(_summary_item(id, s.used[id], Palette.TEXT_DIM, "-"))
		left.add_child(g2)
	# right: level-ups and highlights
	var right := UI.vbox(10)
	right.custom_minimum_size.x = 380
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	if not s.levels.is_empty():
		right.add_child(UI.label("Level ups", "H3"))
		for id in s.levels:
			var lv: Array = s.levels[id]
			var row := UI.hbox(10)
			row.add_child(UI.icon(Data.ui_icon(id), 28))
			row.add_child(UI.label(Data.skills[id].name, ""))
			row.add_child(UI.spacer())
			row.add_child(UI.label(str(int(lv[0])), "Faint"))
			row.add_child(UI.label("→", "Faint"))
			row.add_child(UI.label(str(int(lv[1])), "Num", Palette.GOOD))
			row.add_child(UI.chip("+%d" % (int(lv[1]) - int(lv[0])), Palette.GOOD))
			right.add_child(UI.panel("Inset", row))
	# captures grouped (4× Faint Buzzbud), then the other moments, each with an icon
	var caught := {}
	var order := []
	var moments := []
	for e in s.events:
		match e.type:
			"captured":
				var key := "%s|%d|%s" % [e.species, int(e.rarity), str(e.shiny)]
				if not caught.has(key):
					caught[key] = {"species": e.species, "rarity": int(e.rarity), "shiny": bool(e.shiny), "n": 0}
					order.append(key)
				caught[key].n += 1
			"evolved":
				moments.append([Data.ui_icon("upgrade"), "%s evolved into %s" % [Data.form_name(e.species, e.from), Data.form_name(e.species, e.form)], Palette.AETHER])
			"boss_defeated":
				if e.first:
					moments.append([Data.ui_icon("expeditions"), "Defeated %s for the first time" % Data.zones[e.zone].boss.name, Palette.GOLD])
			"zone_unlocked":
				moments.append([Data.ui_icon("expeditions"), "Unlocked %s" % Data.zones[e.zone].name, Palette.GOLD])
			"slot_unlocked":
				moments.append([Data.ui_icon(e.skill), "A new %s slot opened" % Data.skills[e.skill].name, Palette.TEXT])
			"pearl":
				moments.append([Data.item_icon("aether-pearl"), "+%d Aether Pearl (%s)" % [int(e.amount), e.why], Color("f1e6ff")])
	if not moments.is_empty():
		right.add_child(UI.label("Highlights", "H3"))
		for m in moments.slice(0, 8):
			right.add_child(UI.hbox(8, [UI.icon(m[0], 22), UI.wrap_label(m[1], "", 300)]))
			right.get_child(right.get_child_count() - 1).get_child(1).add_theme_color_override("font_color", m[2])
		if moments.size() > 8:
			right.add_child(UI.label("…and %d more" % (moments.size() - 8), "Faint"))
	if not order.is_empty():
		order.sort_custom(func(a, b): return [caught[a].shiny, caught[a].rarity, caught[a].n] > [caught[b].shiny, caught[b].rarity, caught[b].n])
		var total := 0
		for k in order:
			total += int(caught[k].n)
		right.add_child(UI.hbox(8, [UI.label("Bound", "H3"), UI.chip("%d Aetherlings" % total, Palette.AETHER)]))
		var bf := UI.flow(8, 8)
		for k in order.slice(0, 12):
			var c: Dictionary = caught[k]
			var cell := UI.hbox(6)
			var por := CreaturePortrait.make(c.species, 1, c.rarity, c.shiny, 44)
			por.bob = false
			cell.add_child(por)
			var cv := UI.vbox(0)
			cv.add_child(UI.label("%d×  %s" % [int(c.n), Data.species[c.species].name], "Small", Palette.TEXT))
			cv.add_child(UI.label(("Shiny " if c.shiny else "") + Data.rarity(c.rarity).name, "Small", Palette.GOLD if c.shiny else Data.rarity_color(c.rarity)))
			cell.add_child(cv)
			bf.add_child(UI.panel("Inset", cell))
		right.add_child(bf)
		if order.size() > 12:
			right.add_child(UI.label("…and %d more kinds" % (order.size() - 12), "Faint"))
	# actions
	var box := {}   # the modal, for the buttons (lambdas capture locals by value)
	var act := UI.hbox(10)
	act.add_child(UI.spacer())
	if eggs > 0:
		act.add_child(UI.button("%d egg%s ready to hatch" % [eggs, "" if eggs == 1 else "s"], "Gold", func():
			box.m.close()
			show_screen("pods")))
	act.add_child(UI.button("Continue", "Primary", func(): box.m.close()))
	root.add_child(act)
	var sc := UI.scroll(root)
	# tall enough for the longer column, up to what fits on screen (then it scrolls)
	var left_h: int = ceili(s.gained.size() / 3.0) * 66 + (40 + ceili(s.used.size() / 3.0) * 66 if not s.used.is_empty() else 0)
	var right_h: int = s.levels.size() * 54 + (40 + mini(moments.size(), 8) * 34 if not moments.is_empty() else 0) + (44 + ceili(mini(order.size(), 12) / 3.0) * 62 if not order.is_empty() else 0)
	sc.custom_minimum_size = Vector2(880, clampi(260 + maxi(left_h, right_h), 320, 660))
	box.m = Modal.open(sc, "Welcome back", 940)


## A big number tile for the welcome-back summary.
func _summary_tile(tex: Texture2D, value: String, caption: String, col: Color) -> PanelContainer:
	var h := UI.hbox(12)
	h.add_child(UI.icon(tex, 38))
	var v := UI.vbox(0)
	var big := UI.label(value, "H1", col)
	v.add_child(big)
	v.add_child(UI.label(caption, "Faint"))
	h.add_child(v)
	var p := UI.panel("Inset", h)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return p


## One item in the summary: icon, amount and name.
func _summary_item(id: String, qty: float, col: Color, sign := "+") -> PanelContainer:
	var h := UI.hbox(8)
	h.add_child(UI.icon(Data.item_icon(id) if Data.items.has(id) else Data.ui_icon(id), 30))
	var v := UI.vbox(0)
	v.add_child(UI.label(sign + F.format_num(qty), "Num", col))
	var nm := UI.label(Data.item_name(id), "Faint")
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.custom_minimum_size.x = 80
	v.add_child(nm)
	h.add_child(v)
	var p := UI.panel("Inset", h)
	p.custom_minimum_size.x = 140
	return p


func _welcome() -> void:
	var v := UI.vbox(14)
	var h := UI.hbox(16)
	var p := CreaturePortrait.make("sproutlet", 1, 1, false, 120)
	h.add_child(p)
	h.add_child(UI.wrap_label("Welcome to your Sanctum, Architect. I'm Overseer Vance.\n\nThis little Sproutlet is your first Aetherling. "
		+ "Put it to work chopping wood, send it exploring to bind new Aetherlings, and when you have a few, "
		+ "breed them in the Genesis Pods for rarer ones.\n\nEverything keeps going while you're away.", "", 420))
	v.add_child(h)
	var box := {}
	v.add_child(UI.button("Let's start: open Woodcutting", "Primary", func():
		box.m.close()
		show_screen("skill", "woodcutting")))
	box.m = Modal.open(v, "A new Sanctum", 620, false)
