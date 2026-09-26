extends Control
## Title screen: Continue, New Game, Load Game (three save slots), Options, Credits, Quit; patch notes on the right.

const GAME_SCENE := "res://scenes/main.tscn"

var _overlay: Control
var _drifters: Array = []
var _bg: TextureRect
var _t := 0.0
var _fade: ColorRect
var _logo: Label
## Secrets: an old code typed on the title screen turns the logo into a rainbow.
const KONAMI := [KEY_UP, KEY_UP, KEY_DOWN, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_LEFT, KEY_RIGHT, KEY_B, KEY_A]
var _konami_at := 0
var _rainbow := false


func _ready() -> void:
	theme = ThemeFactory.get_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var sky := SkyBackdrop.new()
	add_child(sky)
	_bg = TextureRect.new()
	_bg.texture = load("res://assets/backgrounds/sanctum.jpg")
	_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg.modulate = Color(1, 1, 1, 0.9)
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg)
	_spawn_drifters()
	var shade := ColorRect.new()
	shade.color = Color(0.02, 0.02, 0.07, 0.35)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	_build_menu()
	_overlay = Control.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.z_index = 110
	add_child(_overlay)
	Modal.layer = _overlay
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 1)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.z_index = 130
	add_child(_fade)
	create_tween().tween_property(_fade, "color:a", 0.0, 0.8)
	Music.play("title")


func _build_menu() -> void:
	var root := UI.margin(UI.vbox(0), 115, 84, 72, 60)
	root.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	root.custom_minimum_size.x = 744
	add_child(root)
	var col: VBoxContainer = root.get_child(0)
	col.add_theme_constant_override("separation", 12)
	col.size_flags_vertical = Control.SIZE_EXPAND_FILL
	col.add_child(UI.spacer(true))
	var logo := UI.label("Aetherbound", "Title")
	_logo = logo
	logo.add_theme_font_size_override("font_size", 110)
	logo.add_theme_color_override("font_color", Color("f3f1ff"))
	logo.add_theme_color_override("font_shadow_color", Color(0.45, 0.85, 1.0, 0.55))
	logo.add_theme_constant_override("shadow_outline_size", 26)
	logo.add_theme_constant_override("shadow_offset_x", 0)
	logo.add_theme_constant_override("shadow_offset_y", 0)
	logo.add_theme_color_override("font_outline_color", Palette.INK)
	logo.add_theme_constant_override("outline_size", 12)
	col.add_child(logo)
	var sub := UI.label("I   D   L   E", "H2", Palette.AETHER)
	sub.add_theme_font_size_override("font_size", 29)
	col.add_child(UI.margin(sub, 10, -17, 0, 0))
	col.add_child(UI.label("Collect Aetherlings. Put them to work. Breed the impossible.", "Dim"))
	col.add_child(UI.spacer(false, 31))
	var last := _last_slot()
	if last > 0:
		var info := Game.slot_info(last)
		var cont := _menu_button("Continue", "Primary", func(): _start(last, false))
		col.add_child(cont)
		col.add_child(UI.margin(UI.label("%s · %s played · last seen %s" % [_slot_title(last, info), F.format_seconds(info.playSeconds), _ago(info.lastSeen)], "Faint"), 7, -5, 0, 7))
	col.add_child(_menu_button("New Game", "" if last > 0 else "Primary", func(): _slots_modal("new")))
	col.add_child(_menu_button("Load Game", "", func(): _slots_modal("load")))
	col.add_child(_menu_button("Options", "", func(): OptionsPanel.open_modal()))
	col.add_child(_menu_button("Credits", "", _credits))
	if OS.get_name() != "Web":
		col.add_child(_menu_button("Quit", "Ghost", func(): get_tree().quit()))
	col.add_child(UI.spacer(true))
	col.add_child(UI.label("Progress saves automatically", "Faint"))   # the version is on the patch notes
	var notes := PatchNotes.new()
	notes.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	notes.offset_left = -660
	notes.offset_right = -72
	notes.offset_top = 84
	notes.offset_bottom = -60
	add_child(notes)


func _menu_button(text: String, variation: String, cb: Callable) -> Button:
	var b := UI.button(text, variation, cb)
	b.custom_minimum_size = Vector2(384, 62)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.add_theme_font_override("font", ThemeFactory.head_font())
	b.add_theme_font_size_override("font_size", 25)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.mouse_entered.connect(func(): Sfx.play("click", 1.4))
	return b


func _last_slot() -> int:
	var best := 0
	var best_time := -1.0
	for n in range(1, Game.SLOTS + 1):
		var info := Game.slot_info(n)
		if not info.is_empty() and info.lastSeen > best_time:
			best_time = info.lastSeen
			best = n
	return best


func _ago(unix: float) -> String:
	var d := Time.get_unix_time_from_system() - unix
	if d < 90:
		return "just now"
	return F.format_seconds(d) + " ago"


# ---------------------------------------------------------------- save slots

func _slots_modal(mode: String) -> void:
	var row := UI.hbox(19)
	var m: Modal = Modal.open(row, "Choose a save slot" if mode == "new" else "Load a game", 1272)
	_fill_slots(row, mode, m)


func _fill_slots(row: HBoxContainer, mode: String, m: Modal) -> void:
	UI.clear(row)
	for n in range(1, Game.SLOTS + 1):
		var info := Game.slot_info(n)
		var card := UI.panel("Card")
		card.custom_minimum_size = Vector2(384, 396)
		var v := UI.vbox(10)
		card.add_child(v)
		v.add_child(UI.label(_slot_title(n, info), "H2"))
		if info.is_empty():
			v.add_child(UI.label("Empty", "Dim"))
			v.add_child(UI.spacer(true))
			v.add_child(UI.wrap_label("A fresh Sanctum, one Sproutlet and five Tinker's Vessels.", "Faint"))
			v.add_child(UI.button("Start a new game here", "Primary", func(): _start(n, true)))
		else:
			if info.title != "":
				v.add_child(UI.label(info.title, "", Palette.GOLD))
			v.add_child(UI.label("Last played %s" % _ago(info.lastSeen), "Dim"))
			v.add_child(UI.sep())
			v.add_child(UI.stat_line("time", "%s played" % F.format_seconds(info.playSeconds)))
			v.add_child(UI.stat_line("nexus", "%d Aetherlings · %d species" % [info.creatures, info.species]))
			if info.bestSkill != "":
				v.add_child(UI.stat_line(info.bestSkill, "%s level %d" % [Data.skills[info.bestSkill].name, info.bestLevel]))
			v.add_child(UI.stat_line("expeditions", "%d of %d islands cleared" % [info.zones, Data.zone_list.size()]))
			v.add_child(UI.stat_line("aether", "%s Aether" % F.format_num(info.aether)))
			v.add_child(UI.spacer(true))
			if mode == "load":
				v.add_child(UI.button("Load", "Primary", func(): _start(n, false)))
			else:
				v.add_child(UI.button("Overwrite with a new game", "Danger", func():
					Modal.confirm("Overwrite slot %d?" % n, "This deletes the game in slot %d for good and starts over." % n, "Overwrite", func(): _start(n, true), true)))
			v.add_child(UI.button("Rename", "Ghost", func(): _rename_slot(n, info, row, mode, m)))
			v.add_child(UI.button("Delete", "Ghost", func():
				Modal.confirm("Delete slot %d?" % n, "The save in slot %d will be gone for good." % n, "Delete", func():
					Game.delete_slot(n)
					_fill_slots(row, mode, m), true)))
		row.add_child(card)


## "Dev Save (slot 2)" when the player named the slot, otherwise "Slot 2".
func _slot_title(n: int, info: Dictionary) -> String:
	var nm: String = info.get("name", "")
	return "%s (slot %d)" % [nm, n] if nm != "" else "Slot %d" % n


func _rename_slot(n: int, info: Dictionary, row: HBoxContainer, mode: String, slots_modal: Modal) -> void:
	var v := UI.vbox(14)
	var le := LineEdit.new()
	le.text = info.get("name", "")
	le.placeholder_text = "Slot %d" % n
	le.max_length = 24
	v.add_child(le)
	var box := {}  # holds the modal: lambdas capture locals by value, a Dictionary by reference
	var apply := func(t: String):
		box.m.close()
		Game.rename_slot(n, t)
		_fill_slots(row, mode, slots_modal)
	var r := UI.hbox(10)
	r.add_child(UI.button("Clear name", "Ghost", func(): apply.call("")))
	r.add_child(UI.spacer())
	r.add_child(UI.button("Save", "Primary", func(): apply.call(le.text)))
	v.add_child(r)
	le.text_submitted.connect(func(t): apply.call(t))
	box.m = Modal.open(v, "Name this save", 504)
	le.grab_focus.call_deferred()


func _start(n: int, fresh: bool) -> void:
	Sfx.play("start")
	mouse_filter = Control.MOUSE_FILTER_STOP
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", 1.0, 0.45)
	tw.tween_callback(func():
		Game.start_slot(n, fresh)
		get_tree().change_scene_to_file(GAME_SCENE))


func _credits() -> void:
	var v := UI.vbox(12)
	v.add_child(UI.rich("[b]Aetherbound Idle[/b], rebuilt in Godot %s.\n\n" % Engine.get_version_info().string
		+ "[b]Creature art[/b]: the designer's approved Aetherling sprites.\n"
		+ "[b]Background[/b]: the designer's approved Sanctum background.\n"
		+ "[b]Icons, shaders, music and sound effects[/b]: generated in code for this project.\n"
		+ "[b]Fonts[/b]: Fredoka (The Fredoka Project Authors) and Nunito (The Nunito Project Authors), SIL Open Font License 1.1.\n"
		+ "[b]Engine[/b]: Godot Engine, MIT licence, godotengine.org."))
	Modal.open(v, "Credits", 744)


# ---------------------------------------------------------------- drifting creatures

func _spawn_drifters() -> void:
	var base := Data.species_list.filter(func(s): return s.kind == "base")
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 7:
		var sp: Dictionary = base[rng.randi_range(0, base.size() - 1)]
		var depth := rng.randf_range(0.45, 1.0)
		var p := CreaturePortrait.make(sp.id, rng.randi_range(1, 3), 1, rng.randf() < 0.15, 180.0 * depth)
		p.plate = false
		p.modulate = Color(0.75 + 0.25 * depth, 0.75 + 0.25 * depth, 0.9 + 0.1 * depth, 0.35 + 0.55 * depth)
		p.set_meta("speed", rng.randf_range(12.0, 31.0) * depth)
		p.set_meta("y", rng.randf_range(0.15, 0.85))
		p.set_meta("phase", rng.randf() * TAU)
		p.position.x = rng.randf_range(0.0, 1.0)
		# a click makes a drifter hop (secrets: five hops, and catching a shiny one)
		p.pokeable = true
		p.poke_mode = "hop"
		p.poked.connect(func(_n: int): _on_drifter_poked(p))
		add_child(p)
		_drifters.append(p)


func _on_drifter_poked(p: CreaturePortrait) -> void:
	Game.note_secret("hop_scotch")
	if p.shiny:
		Sfx.play("shiny_appear")
		FloatText.spawn(p, Vector2(p.size.x / 2.0, p.size.y * 0.2), "✦ a wish! ✦", Palette.GOLD, null, 20, 50.0, true)
		Game.note_secret("wish")


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var code: int = event.keycode
	if code == KONAMI[_konami_at]:
		_konami_at += 1
		if _konami_at == KONAMI.size():
			_konami_at = 0
			_rainbow = true
			Sfx.play("shiny_appear")
			Game.note_secret("konami")
	else:
		_konami_at = 1 if code == KONAMI[0] else 0


func _process(delta: float) -> void:
	_t += delta
	var vs := size
	for p in _drifters:
		var sp: float = p.get_meta("speed")
		var x: float = p.position.x + sp * delta
		if x > vs.x + 48:
			x = -p.custom_minimum_size.x - 24
		if p.position.x <= 1.0 and p.position.x >= 0.0 and not p.has_meta("placed"):
			x = p.position.x * vs.x
			p.set_meta("placed", true)
		p.position = Vector2(x, vs.y * p.get_meta("y") + sin(_t * 0.6 + p.get_meta("phase")) * 19.0)
	if _rainbow and _logo:
		_logo.add_theme_color_override("font_color", Color.from_hsv(fmod(_t * 0.25, 1.0), 0.35, 1.0))
	if not Options.get_value("reduce_motion"):
		_bg.scale = Vector2.ONE * (1.04 + 0.02 * sin(_t * 0.05))
		_bg.pivot_offset = _bg.size / 2.0
