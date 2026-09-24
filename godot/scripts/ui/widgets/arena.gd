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
var _backdrop: TextureRect
var _zone_type := "verdant"
var _zone_seed := 0.0
var _boss_music := false   # the boss track is playing because of this arena

## Where feet touch the ground, as a fraction of the arena's height: front row, and how much higher the back
## row stands (a slight stagger, so each side reads as one line). Painted backdrops (assets/zones/<id>.png) are drawn with their ground across this band.
const GROUND_Y := 0.84
const BACK_ROW_RISE := 0.03
const HORIZON_Y := 0.62


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop = TextureRect.new()
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_backdrop)
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
	var ground_top := s.y * (GROUND_Y - 0.12)
	if _backdrop.texture:
		# painted backdrop: only darken the bottom a little so names and bars stay readable
		_grad_rect(Rect2(0, s.y * 0.55, s.x, s.y * 0.45), Color(0, 0, 0, 0.0), Color(0.02, 0.02, 0.06, 0.45))
		return
	# a drawn landscape in the zone's colour: haze on the horizon, two ranges of hills, then open ground
	_grad_rect(Rect2(0, 0, s.x, s.y * HORIZON_Y), Color(c, 0.0), Color(c.darkened(0.3), 0.28))
	_hills(s.y * HORIZON_Y, s.y * 0.16, Color(c.darkened(0.55), 0.85), 3.0, _zone_seed)
	_hills(s.y * (HORIZON_Y + 0.06), s.y * 0.1, Color(c.darkened(0.7), 0.95), 5.0, _zone_seed + 4.0)
	_grad_rect(Rect2(0, ground_top, s.x, s.y - ground_top), Color(c.darkened(0.62), 1.0), Color(c.darkened(0.82), 1.0))
	_ground.draw_line(Vector2(0, ground_top), Vector2(s.x, ground_top), Color(c.lightened(0.1), 0.45), 2.0)
	# scattered stones and tufts, fixed per island
	for i in 26:
		var fx := fposmod(sin((i + 1) * 12.9898 + _zone_seed) * 43758.5453, 1.0)
		var fy := fposmod(sin((i + 1) * 78.233 + _zone_seed) * 12345.678, 1.0)
		var y := ground_top + 8.0 + fy * (s.y - ground_top - 10.0)
		var r := 2.0 + 5.0 * fy
		_ground.draw_set_transform(Vector2(fx * s.x, y), 0.0, Vector2(1.0, 0.45))
		_ground.draw_circle(Vector2.ZERO, r, Color(c.darkened(0.4), 0.55))
		_ground.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _grad_rect(r: Rect2, top: Color, bottom: Color) -> void:
	_ground.draw_polygon(PackedVector2Array([r.position, r.position + Vector2(r.size.x, 0), r.end, r.position + Vector2(0, r.size.y)]),
		PackedColorArray([top, top, bottom, bottom]))


func _hills(base_y: float, height: float, col: Color, freq: float, seed_value: float) -> void:
	var s := size
	var pts := PackedVector2Array([Vector2(0, s.y)])
	var steps := 48
	for i in steps + 1:
		var x := s.x * i / float(steps)
		var u := float(i) / steps
		var h := 0.55 + 0.3 * sin(u * freq * TAU * 0.5 + seed_value) + 0.15 * sin(u * freq * TAU * 1.3 + seed_value * 2.1)
		pts.append(Vector2(x, base_y - height * h))
	pts.append(Vector2(s.x, s.y))
	_ground.draw_colored_polygon(pts, col)


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
		_set_boss_music(false)
		return
	var key := "%s|%d|%d|%d" % [b.zone, int(b.wave), b.allies.size(), b.enemies.size()]
	if key != _key:
		_key = key
		_build(b)
	_update(b)
	# the sim moves to "rest" in the same step it reports boss_defeated or wiped, so this also ends the boss
	# music on those outcomes
	_set_boss_music(is_visible_in_tree() and int(b.wave) >= int(b.waves) and b.phase == "fight")


## A boss fight on screen gets the boss track; once it resolves (or the run stops, or another zone is shown)
## the calm expedition track comes back. Music.play crossfades.
func _set_boss_music(on: bool) -> void:
	if on == _boss_music or _leaving():
		return
	_boss_music = on
	Music.play("boss" if on else "expedition")


## True while this arena's screen is being replaced, when the new screen has already chosen its music.
func _leaving() -> bool:
	var n: Node = self
	while n:
		if n.is_queued_for_deletion():
			return true
		n = n.get_parent()
	return false


func _clear() -> void:
	for list in [_allies, _enemies]:
		for f in list:
			f.root.queue_free()
		list.clear()


func _build(b: Dictionary) -> void:
	_clear()
	_zone_type = Data.zones[b.zone].type
	_zone_seed = float(hash(String(b.zone)) % 1000) / 37.0
	_backdrop.texture = Data.zone_backdrop(b.zone)
	_ground.queue_redraw()
	var s := size
	for side in [0, 1]:
		var list: Array = b.allies if side == 0 else b.enemies
		var n := list.size()
		# a slightly staggered line that fits the side's half of the arena. Every fighter is sized for a full
		# side, so a lone enemy is drawn at the same size as one of three.
		var side_w := s.x * 0.44
		var full := maxi(maxi(int(Data.tuning.combat.partySize), 3), maxi(b.allies.size(), b.enemies.size()))
		var base_px := clampf(minf(side_w / (full * 0.78 + 0.35), s.y * 0.34), 64.0, 150.0)
		for i in n:
			var f: Dictionary = list[i]
			var boss: bool = f.get("boss", false)
			var px := minf(base_px * (1.45 if boss else 1.0), s.y * 0.5)
			var slot_x := side_w * (i + 0.5) / n
			var x := (s.x * 0.04 + slot_x if side == 0 else s.x * 0.96 - slot_x) - px / 2.0
			var back := (i % 2 == 1) if n > 1 else false
			# keep the fighter, its name and its bars inside the backdrop, with a small margin
			var edge := s.x * 0.02 + 20.0
			x = clampf(x, edge, maxf(edge, s.x - edge - px))
			var root := Control.new()
			root.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.size = Vector2(px, px)
			var por := CreaturePortrait.make(f.species, int(f.form), int(f.rarity), bool(f.shiny), px)
			por.plate = false
			por.flip = side == 1
			por.size = Vector2(px, px)
			por.refresh()
			# stand the visible art on the ground line: its lowest opaque pixel touches the feet line
			var art := por.art_bounds()
			var feet_y := s.y * (GROUND_Y - (BACK_ROW_RISE if back else 0.0))
			root.position = Vector2(x, feet_y - art.end.y)
			var shadow := Control.new()
			shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			shadow.size = root.size
			var sh_w := art.size.x * 0.42
			var sh_at := Vector2(art.get_center().x, art.end.y)
			shadow.draw.connect(func():
				shadow.draw_set_transform(sh_at, 0.0, Vector2(1.0, 0.22))
				for k in 3:
					shadow.draw_circle(Vector2.ZERO, sh_w * (1.0 - k * 0.22), Color(0, 0, 0, 0.16))
				shadow.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
			root.add_child(shadow)
			root.add_child(por)
			# name and bars float just above the head
			var head := art.position.y
			var nm := UI.label("%s %d" % [f.name, int(f.level)], "Small", Data.rarity_color(int(f.rarity)).lightened(0.3) if side == 1 else Palette.TEXT)
			nm.add_theme_color_override("font_outline_color", Palette.INK)
			nm.add_theme_constant_override("outline_size", 5)
			# the fighters stand almost in a line, so back-row name tags sit a step higher to stay readable
			var tag_rise := 17.0 if back else 0.0
			nm.position = Vector2(-20, head - 36 - tag_rise)
			nm.size = Vector2(px + 40, 18)
			nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			root.add_child(nm)
			var hp := UI.bar(Palette.GOOD if side == 0 else Palette.DANGER, 8)
			hp.position = Vector2(art.get_center().x - px * 0.35, head - 16)
			hp.size = Vector2(px * 0.7, 8)
			root.add_child(hp)
			var sh := UI.bar(Color(0.6, 0.9, 1.0, 0.85), 4)
			sh.position = Vector2(art.get_center().x - px * 0.35, head - 7)
			sh.size = Vector2(px * 0.7, 4)
			root.add_child(sh)
			nm.add_theme_font_size_override("font_size", 15 if boss else 12)
			root.z_index = 0 if back else 1
			add_child(root)
			# a wild Aetherling whose species you already own gets the owned badge just left of its name
			if side == 1 and not boss and Collection.is_owned(Game.state, f.species):
				var fs := nm.get_theme_font_size("font_size")
				var w := nm.get_theme_font("font").get_string_size(nm.text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				var mark := UI.owned_mark(16)
				mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
				mark.position = Vector2(nm.position.x + (nm.size.x - minf(w, nm.size.x)) / 2.0 - 19.0, nm.position.y + 1.0)
				root.add_child(mark)
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
				var tw: Tween = att.root.create_tween()   # bound to the fighter, so it dies with it when the wave is rebuilt
				tw.tween_property(att.root, "position", att.home + Vector2(26 * dir, -6), 0.08).set_trans(Tween.TRANS_QUAD)
				tw.tween_property(att.root, "position", att.home, 0.14).set_trans(Tween.TRANS_QUAD)
			var por: CreaturePortrait = def.portrait
			var ft := por.create_tween()
			ft.tween_method(func(v): por.set_flash(v), 0.8, 0.0, 0.18)
			if motion:
				var st: Tween = def.root.create_tween()
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
				var tw := por.create_tween()
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
