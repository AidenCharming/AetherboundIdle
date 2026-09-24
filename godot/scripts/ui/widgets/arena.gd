class_name Arena
extends Control
## The live battle view. Reads state.expedition.battle every frame for health bars and rebuilds the
## fighters when a new wave spawns; Game events drive the animations (lunges, hit flashes, damage
## numbers, ability callouts, knock-outs). The battle's outcome never depends on this view.

var _allies: Array = []    # [{root, portrait, hp, shield, name}]
var _enemies: Array = []
var _key := ""
var _fx: Control
var _banner: Label
var _status: Label
var _ground: Control
var _zone_type := "verdant"


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ground = Control.new()
	_ground.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ground.draw.connect(_draw_ground)
	add_child(_ground)
	_fx = Control.new()
	_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fx.z_index = 5
	add_child(_fx)
	_banner = UI.label("", "H1")
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_color_override("font_outline_color", Palette.INK)
	_banner.add_theme_constant_override("outline_size", 10)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_banner.offset_top = 14
	_banner.z_index = 6
	add_child(_banner)
	_status = UI.label("", "Dim")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_status.offset_top = -34
	_status.z_index = 6
	add_child(_status)
	Game.event.connect(_on_event)
	resized.connect(func(): _key = "")


func _draw_ground() -> void:
	var s := size
	var c := Data.type_color(_zone_type)
	# a floating island platform under each side
	for side in [0, 1]:
		var cx := s.x * (0.27 if side == 0 else 0.73)
		var cy := s.y * 0.72
		var w := s.x * 0.36
		var pts := PackedVector2Array()
		for i in 25:
			var a := PI * i / 24.0
			pts.append(Vector2(cx + cos(a) * w / 2.0, cy + sin(a) * s.y * 0.2 * (1.0 if i % 3 else 0.8)))
		_ground.draw_colored_polygon(pts, Color(0.1, 0.1, 0.2, 0.9))
		_ground.draw_set_transform(Vector2(cx, cy), 0.0, Vector2(1.0, 0.18))
		_ground.draw_circle(Vector2.ZERO, w / 2.0, Color(c.darkened(0.45), 0.95))
		_ground.draw_arc(Vector2.ZERO, w / 2.0, 0, TAU, 64, Color(c, 0.7), 6.0, true)
		_ground.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _process(_d: float) -> void:
	var s := Game.state
	if s.is_empty():
		return
	var b: Dictionary = s.expedition.battle
	if not Expedition.is_running(s) or b.is_empty():
		if _key != "idle":
			_key = "idle"
			_clear()
			_banner.text = ""
			_status.text = ""
		return
	var key := "%s|%d|%d|%d" % [b.zone, int(b.wave), b.allies.size(), b.enemies.size()]
	if key != _key:
		_key = key
		_build(b)
	_update(b)


func _clear() -> void:
	for list in [_allies, _enemies]:
		for f in list:
			f.root.queue_free()
		list.clear()


func _build(b: Dictionary) -> void:
	_clear()
	_zone_type = Data.zones[b.zone].type
	_ground.queue_redraw()
	var s := size
	for side in [0, 1]:
		var list: Array = b.allies if side == 0 else b.enemies
		var n := list.size()
		# a staggered formation that fits the side's half of the arena
		var side_w := s.x * 0.44
		var base_px := clampf(minf(side_w / (n * 0.78 + 0.35), s.y * 0.34), 64.0, 150.0)
		for i in n:
			var f: Dictionary = list[i]
			var boss: bool = f.get("boss", false)
			var px := minf(base_px * (1.45 if boss else 1.0), s.y * 0.5)
			var slot_x := side_w * (i + 0.5) / n
			var x := (s.x * 0.04 + slot_x if side == 0 else s.x * 0.96 - slot_x) - px / 2.0
			var back := (i % 2 == 1) if n > 1 else false
			var y := s.y * 0.7 - px - (px * 0.22 if back else 0.0)
			var root := Control.new()
			root.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.size = Vector2(px, px + 44)
			root.position = Vector2(x, y)
			var por := CreaturePortrait.make(f.species, int(f.form), int(f.rarity), bool(f.shiny), px)
			por.plate = false
			por.flip = side == 1
			por.refresh()
			root.add_child(por)
			var nm := UI.label("%s %d" % [f.name, int(f.level)], "Small", Data.rarity_color(int(f.rarity)).lightened(0.3) if side == 1 else Palette.TEXT)
			nm.add_theme_color_override("font_outline_color", Palette.INK)
			nm.add_theme_constant_override("outline_size", 5)
			nm.position = Vector2(0, px + 2)
			nm.size = Vector2(px, 18)
			nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nm.clip_text = true
			root.add_child(nm)
			var hp := UI.bar(Palette.GOOD if side == 0 else Palette.DANGER, 8)
			hp.position = Vector2(px * 0.1, px + 22)
			hp.size = Vector2(px * 0.8, 8)
			root.add_child(hp)
			var sh := UI.bar(Color(0.6, 0.9, 1.0, 0.85), 4)
			sh.position = Vector2(px * 0.1, px + 32)
			sh.size = Vector2(px * 0.8, 4)
			root.add_child(sh)
			nm.add_theme_font_size_override("font_size", 15 if boss else 12)
			root.z_index = 0 if back else 1
			add_child(root)
			var rec := {"root": root, "portrait": por, "hp": hp, "shield": sh, "home": root.position, "down": false}
			(_allies if side == 0 else _enemies).append(rec)
	var z: Dictionary = Data.zones[b.zone]
	if int(b.wave) >= int(b.waves):
		_show_banner("BOSS: " + z.boss.name, Palette.GOLD)
	elif int(b.wave) > 0:
		_show_banner("Wave %d of %d" % [int(b.wave), int(b.waves) - 1], Palette.TEXT)


func _show_banner(text: String, color: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(_banner, "modulate:a", 1.0, 0.25)
	tw.tween_interval(1.4)
	tw.tween_property(_banner, "modulate:a", 0.35, 0.6)


func _update(b: Dictionary) -> void:
	for side in [0, 1]:
		var list: Array = b.allies if side == 0 else b.enemies
		var views: Array = _allies if side == 0 else _enemies
		for i in mini(list.size(), views.size()):
			var f: Dictionary = list[i]
			var v: Dictionary = views[i]
			v.hp.value = float(f.hp) / maxf(1.0, float(f.maxHp))
			v.shield.value = clampf(float(f.shield) / maxf(1.0, float(f.maxHp)), 0.0, 1.0)
			v.shield.visible = float(f.shield) > 0.5
			if not f.alive and not v.down:
				v.down = true
				var tw := create_tween()
				tw.tween_property(v.root, "modulate", Color(0.4, 0.4, 0.5, 0.35), 0.4)
	match b.phase:
		"rest":
			if not Combat.any_alive(b.allies):
				_status.text = "The party is resting · back in %s" % F.format_seconds(float(b.timer) / 1000.0)
			else:
				_status.text = "Run complete · next run in %s" % F.format_seconds(float(b.timer) / 1000.0)
		"gap":
			_status.text = "Moving on…" if int(b.wave) > 0 else "Setting out…"
		_:
			_status.text = "Meals left this run: %d" % int(b.meals)


func _view(side: int, index: int) -> Dictionary:
	var list: Array = _allies if side == 0 else _enemies
	return list[index] if index >= 0 and index < list.size() else {}


func _on_event(e: Dictionary) -> void:
	if not is_visible_in_tree() or _key == "idle" or _key == "":
		return
	var motion: bool = not Options.get_value("reduce_motion")
	match e.type:
		"hit":
			var att := _view(e.side, e.from)
			var def := _view(1 - e.side, e.to)
			if att.is_empty() or def.is_empty():
				return
			if motion and e.ability == "":
				var dir := 1.0 if e.side == 0 else -1.0
				var tw := create_tween()
				tw.tween_property(att.root, "position", att.home + Vector2(26 * dir, -6), 0.08).set_trans(Tween.TRANS_QUAD)
				tw.tween_property(att.root, "position", att.home, 0.14).set_trans(Tween.TRANS_QUAD)
			var por: CreaturePortrait = def.portrait
			var ft := create_tween()
			ft.tween_method(func(v): por.set_flash(v), 0.8, 0.0, 0.18)
			if motion:
				var st := create_tween()
				st.tween_property(def.root, "position", def.home + Vector2(randf_range(-5, 5), randf_range(-3, 3)), 0.04)
				st.tween_property(def.root, "position", def.home, 0.06)
			if Options.get_value("damage_numbers"):
				var eff: float = e.eff
				var col := Palette.GOLD if eff > 1.01 else (Palette.TEXT_FAINT if eff < 0.99 else Palette.TEXT)
				var txt := F.format_num(e.dmg) + ("!" if eff > 1.01 else "")
				var at: Vector2 = def.root.position + Vector2(def.root.size.x * randf_range(0.3, 0.6), def.root.size.x * 0.2)
				FloatText.spawn(_fx, at, txt, col, null, 18 if e.ability != "" else 15, 40.0)
			Sfx.play("hit", randf_range(0.85, 1.2))
		"ability":
			var v := _view(e.side, e.index)
			if v.is_empty():
				return
			var ab: Dictionary = Data.abilities[e.ability]
			var at: Vector2 = v.root.position + Vector2(v.root.size.x * 0.1, -8)
			FloatText.spawn(_fx, at, ab.name, Data.type_color(ab.damageType) if Data.types.has(ab.damageType) else Palette.AETHER, null, 15, 30.0)
			if motion:
				var por: Control = v.portrait
				por.pivot_offset = por.size / 2.0
				var tw := create_tween()
				tw.tween_property(por, "scale", Vector2(1.12, 1.12), 0.1)
				tw.tween_property(por, "scale", Vector2.ONE, 0.16)
		"heal":
			var v := _view(e.side, e.index)
			if not v.is_empty() and Options.get_value("damage_numbers"):
				FloatText.spawn(_fx, v.root.position + Vector2(v.root.size.x * 0.5, v.root.size.x * 0.1), "+" + F.format_num(e.amount), Palette.GOOD, null, 14, 34.0)
		"thorns":
			var v := _view(e.side, e.to)
			if not v.is_empty() and Options.get_value("damage_numbers"):
				FloatText.spawn(_fx, v.root.position + Vector2(v.root.size.x * 0.5, 0), F.format_num(e.dmg), Data.type_color("verdant"), null, 13, 30.0)
		"captured":
			var at := Vector2(size.x * 0.73, size.y * 0.35)
			FloatText.spawn(_fx, at, "Bound!", Data.rarity_color(int(e.rarity)), Data.ui_icon("vessel"), 22, 60.0)
		"escaped":
			FloatText.spawn(_fx, Vector2(size.x * 0.73, size.y * 0.35), "Broke free", Palette.TEXT_FAINT, null, 16, 40.0)
		"boss_defeated":
			_show_banner("Victory!", Palette.GOLD)
		"wiped":
			_show_banner("The party retreats…", Palette.DANGER)
