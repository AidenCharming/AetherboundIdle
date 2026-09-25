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
	"market": preload("res://scripts/ui/screens/market_screen.gd"),
	"eggmarket": preload("res://scripts/ui/screens/egg_market_screen.gd"),
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
var _pending_flash := false   # shinies are waiting for a vessel: the Expeditions badge pulses
var _limited_flash := false   # a rare limited offer is in the Market: its badge pulses
var _boosts_box: HBoxContainer
var _mouse_held := false        # the left button is down: rebuilding now could free the button being clicked
var _refresh_waiting := false   # a Game.changed came while it was down; the screen rebuilds on release


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
	# A capture or level-up mid-click used to rebuild the screen between mouse down and up, freeing the button
	# and losing the click. While the button is held, the rebuild waits for the release.
	if _mouse_held:
		_refresh_waiting = true
	else:
		_refresh_screen()
	_refresh_rail()


func _refresh_screen() -> void:
	_refresh_waiting = false
	if _screen and _screen.has_method("refresh"):
		_screen.refresh()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse_held = event.pressed
		if not event.pressed and _refresh_waiting:
			_refresh_screen.call_deferred()   # after the release has reached (and clicked) the button


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
	_nav_item("inventory", "", "Inventory", "inventory")
	_nav_item("market", "", "Market", "market")
	_nav_item("eggmarket", "", "Egg Market", "egg-market")
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
	h.offset_right = -6
	h.add_child(UI.icon(Data.ui_icon(icon_name), 24))
	var l := UI.label(text)
	l.add_theme_font_override("font", ThemeFactory.bold_font())
	l.add_theme_font_size_override("font_size", 15)
	h.add_child(l)
	h.add_child(UI.spacer())
	var extra := UI.chip("", Palette.AETHER, 11)
	extra.custom_minimum_size.x = 26
	(extra.get_child(0) as Label).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	extra.visible = false
	h.add_child(extra)
	b.add_child(h)
	b.pressed.connect(func(): show_screen(screen, arg))
	_rail_list.add_child(b)
	_nav_buttons[screen + ":" + arg] = {"button": b, "extra": extra, "label": l, "icon": h.get_child(0)}


## A nav entry's badge: a chip, hidden when there's nothing to say.
func _set_extra(nb: Dictionary, text: String, color: Color) -> void:
	nb.extra.visible = text != ""
	if text != "":
		UI.set_chip(nb.extra, text, color)


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
		# the level as a chip: aether while someone works there, a quiet indigo otherwise
		_set_extra(nb, "%d" % int(s.skills[skill.id].level), Palette.AETHER if workers > 0 else Palette.TEXT_DIM.darkened(0.2))
		nb.label.modulate.a = 1.0 if usable else 0.45
		nb.icon.modulate.a = 1.0 if usable else 0.4
		nb.extra.modulate.a = 1.0 if usable else 0.45
		nb.button.tooltip_text = "" if usable else "Needs a %s Aetherling" % Data.types[skill.type].name
	var ready_count := Game.ready_eggs().size()
	_set_extra(_nav_buttons["pods:"], "%d ready" % ready_count if ready_count > 0 else "", Palette.GOLD)
	var ex: Dictionary = _nav_buttons["expeditions:"]
	# shinies waiting for a vessel matter more than the wave count: gold, and they pulse (see _process)
	_pending_flash = not s.expedition.pending.is_empty()
	if _pending_flash:
		_set_extra(ex, "%d to bind!" % s.expedition.pending.size(), Palette.GOLD)
	else:
		ex.extra.modulate.a = 1.0
		var wave := ""
		if Expedition.is_running(s) and not s.expedition.battle.is_empty():
			wave = "wave %d" % int(s.expedition.battle.wave) if s.expedition.battle.phase != "rest" else "resting"
		_set_extra(ex, wave, Palette.AETHER)
	var claim := Collection.claimable(s).size()
	_set_extra(_nav_buttons["aetherlog:"], "%d" % claim if claim > 0 else "", Palette.GOLD)
	_nav_buttons["aetherlog:"].button.tooltip_text = "%d milestone reward%s to claim" % [claim, "" if claim == 1 else "s"] if claim > 0 else ""
	# the Market: a rare limited offer pulses in gold; fresh stock you haven't looked at says "new"
	var mk: Dictionary = _nav_buttons["market:"]
	var now := Game.now_sec()
	_limited_flash = Market.has_limited(s, now)
	if _limited_flash:
		_set_extra(mk, "limited!", Palette.GOLD)
	else:
		mk.extra.modulate.a = 1.0
		_set_extra(mk, "new" if int(Market.state(s).seenWindow) != Market.window(now) else "", Palette.AETHER)
	_fill_boosts()


## Running Market boosts in the top bar: each icon with its time left.
func _fill_boosts() -> void:
	if _boosts_box == null:
		return
	UI.clear(_boosts_box)
	for b in Market.cfg().boosts.list:
		var left := Market.boost_left(Game.state, b.id)
		if left <= 0.0:
			continue
		var p := UI.panel("Pill")
		p.tooltip_text = "%s: %s\n%s left" % [b.name, b.desc, F.format_seconds(left)]
		p.mouse_filter = Control.MOUSE_FILTER_STOP
		p.gui_input.connect(func(e): if e is InputEventMouseButton and e.pressed: show_screen("market"))
		p.add_child(UI.hbox(4, [UI.icon(Data.ui_icon(b.icon), 20), UI.label(F.format_seconds(left), "Small", Palette.AETHER)]))
		_boosts_box.add_child(p)


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
	_boosts_box = UI.hbox(6)
	bar.add_child(_boosts_box)
	_top.working = UI.chip("", Palette.GOOD, 14)
	_top.working.tooltip_text = "Aetherlings working in skills"
	_top.working.mouse_filter = Control.MOUSE_FILTER_PASS
	bar.add_child(_top.working)
	_top.perched = UI.chip("", Palette.AETHER, 14)
	_top.perched.tooltip_text = "Aetherlings resting on the perches, making Aether"
	_top.perched.mouse_filter = Control.MOUSE_FILTER_PASS
	bar.add_child(_top.perched)
	var bell := UI.button("", "Ghost", _open_notifications, Data.ui_icon("bell"))
	bell.tooltip_text = "Notifications"
	_top.bell = bell
	bar.add_child(bell)
	var menu := UI.button("", "Ghost", open_pause_menu, Data.ui_icon("settings"))
	menu.tooltip_text = "Menu (Esc)"
	bar.add_child(menu)
	# a darker band with a hairline under it separates the top bar from the page
	var band := PanelContainer.new()
	var sb := ThemeFactory.box(Color(0.02, 0.025, 0.07, 0.55), 0, 0, Palette.LINE, 0)
	sb.border_width_bottom = 1
	sb.border_color = Palette.LINE_STRONG
	sb.shadow_color = Color(0, 0, 0.04, 0.35)
	sb.shadow_size = 6
	band.add_theme_stylebox_override("panel", sb)
	band.add_child(m)
	return band


func _chip(icon_name: String, tip: String) -> Dictionary:
	var p := UI.panel("Pill")
	p.tooltip_text = tip
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	var h := UI.hbox(8)
	h.add_child(UI.icon(Data.ui_icon(icon_name), 24))
	var v := UI.label("0", "Num")
	v.add_theme_font_size_override("font_size", 18)
	h.add_child(v)
	var sub := UI.label("", "Small", Palette.AETHER.darkened(0.1))
	h.add_child(sub)
	p.add_child(h)
	return {"panel": p, "value": v, "sub": sub}


func _update_bell() -> void:
	_top.bell.text = str(Game.unread) if Game.unread > 0 else ""


func _process(delta: float) -> void:
	if Game.state.is_empty():
		return
	if _mouse_held and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_mouse_held = false   # released where this window never saw it (focus lost mid-click)
		if _refresh_waiting:
			_refresh_screen()
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
	if _pending_flash and _nav_buttons.has("expeditions:"):
		_nav_buttons["expeditions:"].extra.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 180.0)
	if _limited_flash and _nav_buttons.has("market:"):
		_nav_buttons["market:"].extra.modulate.a = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 180.0)
	_rail_refresh -= delta
	if _rail_refresh <= 0.0:
		_rail_refresh = 1.0
		_refresh_rail()
		var working := 0
		for c in s.creatures.values():
			if Creatures.job_kind(c) == "skill":
				working += 1
		UI.set_chip(_top.working, "%d working" % working, Palette.GOOD)
		UI.set_chip(_top.perched, "%d perched" % Economy.perched(s).size(), Palette.AETHER)


const SHORTCUTS := {KEY_1: "sanctum", KEY_2: "nexus", KEY_3: "pods", KEY_4: "expeditions", KEY_5: "aetherlog", KEY_6: "inventory", KEY_7: "works",
	KEY_8: "market", KEY_9: "eggmarket"}


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
	v.add_child(UI.wrap_label("Your Aetherlings keep working while this menu is open, and while the game is closed (up to %d hours)." % int(GameState.offline_cap_hours(Game.state)), "Faint", 380))
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
	var shiny := ToggleSwitch.new()
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
			row.add_child(UI.label(str(int(lv[0])), "Num", Palette.AETHER.darkened(0.15)))
			row.add_child(UI.label("→", "", Palette.GOLD))
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
func _summary_item(id: String, qty: float, col: Color, prefix := "+") -> PanelContainer:
	var h := UI.hbox(8)
	h.add_child(UI.icon(Data.item_icon(id) if Data.items.has(id) else Data.ui_icon(id), 30))
	var v := UI.vbox(0)
	v.add_child(UI.label(prefix + F.format_num(qty), "Num", col))
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
