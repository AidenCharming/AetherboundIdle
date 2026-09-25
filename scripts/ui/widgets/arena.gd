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
var _announced := ""   # the wave whose shinies and rare Aetherlings have been announced

## Where feet touch the ground, as a fraction of the arena's height: front row, and how much higher the back
## row stands (a slight stagger, so each side reads as one line). Painted backdrops (assets/zones/<id>.png) are drawn with their ground across this band.
const GROUND_Y := 0.84
const BACK_ROW_RISE := 0.03
const HORIZON_Y := 0.62


func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# the painted backdrop is placed by _layout_backdrop: it covers the arena, but its bottom edge stays on the
	# arena's bottom, so the painted ground is always where the fighters stand, however wide the arena gets
	_backdrop = TextureRect.new()
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_SCALE
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
	_banner.add_theme_constant_override("outline_size", 12)
	_banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	_banner.offset_top = 17
	_banner.z_index = 6
	add_child(_banner)
	_status = UI.label("", "Dim")
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	_status.offset_top = -41
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
	_ground.draw_line(Vector2(0, ground_top), Vector2(s.x, ground_top), Color(c.lightened(0.1), 0.45), 2.4)
	# scattered stones and tufts, fixed per island
	for i in 26:
		var fx := fposmod(sin((i + 1) * 12.9898 + _zone_seed) * 43758.5453, 1.0)
		var fy := fposmod(sin((i + 1) * 78.233 + _zone_seed) * 12345.678, 1.0)
		var y := ground_top + 10.0 + fy * (s.y - ground_top - 12.0)
		var r := 2.4 + 6.0 * fy
		_ground.draw_set_transform(Vector2(fx * s.x, y), 0.0, Vector2(1.0, 0.45))
		_ground.draw_circle(Vector2.ZERO, r, Color(c.darkened(0.4), 0.55), true, -1.0, true)
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
	var forms := ""
	for f in b.allies:
		forms += str(int(f.form))
	var key := "%s|%d|%d|%d|%s" % [b.zone, int(b.wave), b.allies.size(), b.enemies.size(), forms]
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


## Fighters face the other side: the party (left) looks right, wild Aetherlings (right) look left. The
## sprites are painted facing left (`combat.spriteFacing`); a form whose sprite faces another way says so
## with a `facing` of "left", "right" or "front" in species.json.
static func _needs_flip(species_id: String, form: int, side: int) -> bool:
	var forms: Array = Data.species[species_id].forms
	var fd: Dictionary = forms[clampi(form, 1, forms.size()) - 1]
	var native: String = fd.get("facing", Data.tuning.combat.get("spriteFacing", "left"))
	if native == "front":
		return false
	return native != ("right" if side == 0 else "left")


## A fighter's nameplate: a small glass panel edged in its rarity colour, with the owned badge (wild
## Aetherlings whose species you have), the name, a level chip, and the health and shield bars.
func _nameplate(f: Dictionary, side: int, boss: bool, width: float) -> Dictionary:
	var rc := Data.rarity_color(int(f.rarity))
	var edge := Palette.GOLD if boss else rc
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := ThemeFactory.box(Color(0.05, 0.055, 0.13, 0.84), 11, 1, Color(edge, 0.85), 0)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 5
	sb.content_margin_bottom = 6
	sb.border_width_top = 2
	sb.shadow_color = Color(0, 0, 0.04, 0.45)
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 2)
	panel.add_theme_stylebox_override("panel", sb)
	var v := UI.vbox(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(v)
	var row := UI.hbox(5)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if side == 1 and not boss and Collection.is_owned(Game.state, f.species):
		var mark := UI.owned_mark(17)
		mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(mark)
	if bool(f.get("shiny", false)):
		var sm := UI.icon(Data.ui_icon("shiny"), 17)
		sm.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(sm)
	var nm := UI.label(f.name, "Small", Color("ffe9a8") if bool(f.get("shiny", false)) else Palette.TEXT)
	nm.add_theme_font_size_override("font_size", 17 if boss else 14)
	nm.clip_text = true
	nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	nm.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nm.custom_minimum_size.x = 36
	row.add_child(nm)
	var lv := PanelContainer.new()
	lv.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lsb := ThemeFactory.box(Color(rc, 0.22), 119, 1, Color(rc, 0.7), 0)
	lsb.content_margin_left = 6
	lsb.content_margin_right = 6
	lv.add_theme_stylebox_override("panel", lsb)
	var ll := UI.label("Lv %d" % int(f.level), "Small", rc.lightened(0.35))
	ll.add_theme_font_size_override("font_size", 12)
	lv.add_child(ll)
	lv.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_child(row)
	# the level chip sits beside the bars, so the name gets the plate's full width
	var bars_row := UI.hbox(6)
	bars_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars_row.add_child(lv)
	var bars := UI.vbox(2)
	bars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bars.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var hp := UI.bar(Palette.GOOD if side == 0 else Palette.DANGER, 8)
	bars.add_child(hp)
	var sh := UI.bar(Color(0.6, 0.9, 1.0, 0.9), 4)
	sh.modulate.a = 0.0
	bars.add_child(sh)
	# party members show their progress to the next level, so XP from every kill is seen
	var xpb: ProgressBar = null
	if side == 0:
		xpb = UI.bar(Palette.AETHER, 4)
		bars.add_child(xpb)
	bars_row.add_child(bars)
	v.add_child(bars_row)
	panel.custom_minimum_size.x = width
	# rarity pips sit on the plate's top edge, one per tier
	var pips := Control.new()
	pips.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tier := int(f.rarity)
	pips.draw.connect(func(): UI.draw_pips(pips, Vector2.ZERO, tier, 4.0, Data.rarity_color_live(tier)))
	return {"panel": panel, "hp": hp, "shield": sh, "pips": pips, "sb": sb, "tier": tier, "boss": boss, "xp": xpb, "lv": ll}


## A shiny or a rare wild Aetherling entering the fight gets a sound, a burst of light and a word over its
## head, once per wave. "Rare" means a rarity this island rolls at most `combat.rareAnnounceChance` of the time.
func _announce(b: Dictionary) -> void:
	var key := "%s|%d|%d" % [b.zone, int(b.wave), int(Game.state.expedition.zones.get(b.zone, {}).get("runs", 0))]
	if key == _announced:
		return
	_announced = key
	var z: Dictionary = Data.zones[b.zone]
	var weights: Array = z.rarityWeights
	var total := 0.0
	for w in weights:
		total += float(w)
	var sound := ""
	for i in _enemies.size():
		var f: Dictionary = b.enemies[i]
		if f.get("boss", false):
			continue
		var r := int(f.rarity)
		var share := float(weights[r - 1]) / total if r - 1 < weights.size() else 0.0
		var rare := r > 1 and share <= float(Data.tuning.combat.get("rareAnnounceChance", 0.1))
		if not (f.shiny or rare):
			continue
		var v: Dictionary = _enemies[i]
		var col: Color = Color(CreaturePortrait.shiny_palette(f.species).light) if f.shiny else Data.rarity_color(r)
		var centre: Vector2 = v.root.position + v.root.size * 0.5
		_burst(centre, col, 1.4 if f.shiny else 1.0)
		FloatText.spawn(_fx, v.root.position + Vector2(v.root.size.x * 0.5, float(v.tag_top) - 12.0),
			"Shiny!" if f.shiny else Data.rarity(r).name + "!", col, Data.ui_icon("shiny") if f.shiny else null, 20, 41.0, true)
		sound = "shiny_appear" if f.shiny else (sound if sound != "" else "rare_appear")
	if sound != "":
		Sfx.play(sound)


## An expanding ring of light with short rays, fading out.
func _burst(at: Vector2, col: Color, strength: float) -> void:
	var fx := Control.new()
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fx.position = at
	fx.z_index = 8
	_fx.add_child(fx)
	var state := {"k": 0.0}
	fx.draw.connect(func():
		var k: float = state.k
		var a := 1.0 - k
		var r := 24.0 + 84.0 * k * strength
		fx.draw_arc(Vector2.ZERO, r, 0, TAU, 48, Color(col, 0.8 * a), 3.6 + 3.6 * a, true)
		fx.draw_circle(Vector2.ZERO, r * 0.6, Color(col, 0.18 * a), true, -1.0, true)
		for i in 10:
			var ang := TAU * i / 10.0 + k * 0.6
			var d := Vector2(cos(ang), sin(ang))
			fx.draw_line(d * r * 0.75, d * (r * 1.15 + 12.0), Color(col.lightened(0.3), 0.7 * a), 2.4, true))
	var tw := fx.create_tween()
	tw.tween_method(func(k: float):
		state.k = k
		fx.queue_redraw(), 0.0, 1.0, 0.9 if Options.get_value("reduce_motion") == false else 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_callback(fx.queue_free)


## Scales the backdrop to cover the arena, centred left to right and resting on the arena's bottom edge (a wide
## arena crops sky, never ground).
func _layout_backdrop() -> void:
	var tex := _backdrop.texture
	if tex == null:
		_backdrop.position = Vector2.ZERO
		_backdrop.size = size
		return
	var ts := Vector2(tex.get_size())
	var k := maxf(size.x / ts.x, size.y / ts.y)
	var drawn := ts * k
	_backdrop.size = drawn
	_backdrop.position = Vector2((size.x - drawn.x) / 2.0, size.y - drawn.y)


## Where the fighters' feet go: {y, h} in arena pixels, h being the height the ground band scales with. A painted
## backdrop has its ground at GROUND_Y of the image, wherever the image is drawn.
func _ground_line() -> Dictionary:
	if _backdrop.texture != null:
		return {"y": _backdrop.position.y + GROUND_Y * _backdrop.size.y, "h": _backdrop.size.y}
	return {"y": size.y * GROUND_Y, "h": size.y}


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
	_layout_backdrop()
	_ground.queue_redraw()
	var s := size
	var ground := _ground_line()
	for side in [0, 1]:
		var list: Array = b.allies if side == 0 else b.enemies
		var n := list.size()
		# a slightly staggered line that fits the side's half of the arena. Every fighter is sized for a full
		# side, so a lone enemy is drawn at the same size as one of three.
		var side_w := s.x * 0.44
		var full := maxi(maxi(int(Data.tuning.combat.partySize), 3), maxi(b.allies.size(), b.enemies.size()))
		var base_px := clampf(minf(side_w / (full * 0.78 + 0.35), s.y * 0.34), 77.0, 180.0)
		for i in n:
			var f: Dictionary = list[i]
			var boss: bool = f.get("boss", false)
			var px := minf(base_px * (1.45 if boss else 1.0), s.y * 0.5)
			var slot_x := side_w * (i + 0.5) / n
			var x := (s.x * 0.04 + slot_x if side == 0 else s.x * 0.96 - slot_x) - px / 2.0
			var back := (i % 2 == 1) if n > 1 else false
			# keep the fighter, its name and its bars inside the backdrop, with a small margin
			var edge := s.x * 0.02 + 24.0
			x = clampf(x, edge, maxf(edge, s.x - edge - px))
			var root := Control.new()
			root.mouse_filter = Control.MOUSE_FILTER_IGNORE
			root.size = Vector2(px, px)
			var por := CreaturePortrait.make(f.species, int(f.form), int(f.rarity), bool(f.shiny), px)
			por.plate = false
			por.flip = _needs_flip(f.species, int(f.form), side)
			por.size = Vector2(px, px)
			por.refresh()
			# stand the visible art on the ground line: its lowest opaque pixel touches the feet line
			var art := por.art_bounds()
			var feet_y: float = ground.y - (ground.h * BACK_ROW_RISE if back else 0.0)
			root.position = Vector2(x, feet_y - art.end.y)
			var shadow := Control.new()
			shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			shadow.size = root.size
			var sh_w := art.size.x * 0.42
			var sh_at := Vector2(art.get_center().x, art.end.y)
			shadow.draw.connect(func():
				shadow.draw_set_transform(sh_at, 0.0, Vector2(1.0, 0.22))
				for k in 3:
					shadow.draw_circle(Vector2.ZERO, sh_w * (1.0 - k * 0.22), Color(0, 0, 0, 0.16), true, -1.0, true)
				shadow.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE))
			root.add_child(shadow)
			root.add_child(por)
			root.z_index = 0 if back else 1
			add_child(root)
			# the nameplate floats above the head; back-row plates sit a step higher so neighbours never overlap
			var plate_w := clampf(1.55 * side_w / maxf(1.0, float(full)) - 7.0, 110.0, 180.0)
			if boss:
				plate_w = 176.0
			var np := _nameplate(f, side, boss, plate_w)
			root.add_child(np.panel)
			var ph: float = np.panel.get_combined_minimum_size().y
			var head := art.position.y
			var top := head - 6.0 - ph - ((ph + 4.0) if back else 0.0)
			np.panel.size = Vector2(plate_w, ph)
			# centred over the art, but never past the arena's edges
			var plate_x := clampf(root.position.x + art.get_center().x - plate_w / 2.0, 5.0, s.x - 5.0 - plate_w)
			np.panel.position = Vector2(plate_x - root.position.x, top)
			root.add_child(np.pips)
			np.pips.position = np.panel.position + Vector2(plate_w / 2.0, 0)
			var rec := {"root": root, "portrait": por, "hp": np.hp, "shield": np.shield, "home": root.position, "down": false,
				"tag_top": top - 6.0, "pips": np.pips, "sb": np.sb, "tier": np.tier, "boss": np.boss, "xp": np.xp, "lv": np.lv,
				"cid": f.get("cid", "")}
			(_allies if side == 0 else _enemies).append(rec)
	_announce(b)
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
			if Data.rarity_animated(int(v.get("tier", 1))):
				v.pips.queue_redraw()
				if not v.boss:
					v.sb.border_color = Color(Data.rarity_color_live(int(v.tier)), 0.9)
			v.shield.value = clampf(float(f.shield) / maxf(1.0, float(f.maxHp)), 0.0, 1.0)
			v.shield.modulate.a = 1.0 if float(f.shield) > 0.5 else 0.0   # keeps its space, so the plate never jumps
			if side == 0:
				_update_xp(v)
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


## A party member's level chip and XP bar, read from the creature itself.
func _update_xp(v: Dictionary) -> void:
	var c: Dictionary = Game.state.creatures.get(v.get("cid", ""), {})
	if c.is_empty():
		return
	v.lv.text = "Lv %d" % int(c.level)
	if v.xp == null:
		return
	var max_lv: int = Data.tuning.creature.maxLevel
	var lv := int(c.level)
	if lv >= max_lv:
		v.xp.value = 1.0
		return
	var lo := F.xp_for_level(F.creature_curve(), lv, max_lv)
	var hi := F.xp_for_level(F.creature_curve(), lv + 1, max_lv)
	v.xp.value = clampf((float(c.xp) - lo) / maxf(1.0, hi - lo), 0.0, 1.0)


## Where the next number over a fighter starts. Numbers that land close together take the next lane
## (centre, left, right, then a row higher), so a flurry of hits reads as separate numbers.
const NUMBER_LANES := [Vector2(0, 0), Vector2(-0.3, -0.08), Vector2(0.3, -0.08), Vector2(-0.15, -0.3), Vector2(0.15, -0.3), Vector2(0, -0.45)]

func _number_at(v: Dictionary) -> Vector2:
	var now := Time.get_ticks_msec()
	var recent: Array = v.get("nums", []).filter(func(t): return now - int(t) < 650)
	var lane: Vector2 = NUMBER_LANES[recent.size() % NUMBER_LANES.size()]
	recent.append(now)
	v.nums = recent
	var px: float = v.root.size.x
	return v.root.position + Vector2(px * (0.5 + lane.x), px * (0.22 + lane.y))


## Damage and healing as whole numbers ("9", not "8.8"); big ones keep the short form (1.2K).
static func _num(v: float) -> String:
	return str(maxi(1, roundi(v))) if v < 1000.0 else F.format_num(v)


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
				tw.tween_property(att.root, "position", att.home + Vector2(31 * dir, -7), 0.08).set_trans(Tween.TRANS_QUAD)
				tw.tween_property(att.root, "position", att.home, 0.14).set_trans(Tween.TRANS_QUAD)
			var por: CreaturePortrait = def.portrait
			var ft := por.create_tween()
			ft.tween_method(func(v): por.set_flash(v), 0.8, 0.0, 0.18)
			if motion:
				var st: Tween = def.root.create_tween()
				st.tween_property(def.root, "position", def.home + Vector2(randf_range(-6, 6), randf_range(-4, 4)), 0.04)
				st.tween_property(def.root, "position", def.home, 0.06)
			var eff: float = e.eff
			if Options.get_value("damage_numbers"):
				var col := Palette.GOLD if eff > 1.01 else (Palette.TEXT_FAINT if eff < 0.99 else Palette.TEXT)
				FloatText.spawn(_fx, _number_at(def), _num(e.dmg) + ("!" if eff > 1.01 else ""), col, null, 22 if e.ability != "" else 18, 48.0, true)
			# each type has its own hit sound; the pitch varies a little so a flurry doesn't drone
			var dtype: String = e.get("dtype", "")
			Sfx.play("hit_" + dtype if dtype != "" else "hit", randf_range(0.9, 1.12))
			if eff > 1.01:
				Sfx.play("strong", randf_range(0.97, 1.05))
		"ability":
			var v := _view(e.side, e.index)
			if v.is_empty():
				return
			var ab: Dictionary = Data.abilities[e.ability]
			# starts above the name tag so it never crosses the fighter's own name
			var at: Vector2 = v.root.position + Vector2(v.root.size.x * 0.5, float(v.get("tag_top", -10.0)) - 7.0)
			FloatText.spawn(_fx, at, ab.name, Data.type_color(ab.damageType) if Data.types.has(ab.damageType) else Palette.AETHER, null, 18, 31.0, true)
			if Data.types.has(ab.damageType):
				Sfx.play("cast_" + ab.damageType)
			if motion:
				var por: Control = v.portrait
				por.pivot_offset = por.size / 2.0
				var tw := por.create_tween()
				tw.tween_property(por, "scale", Vector2(1.12, 1.12), 0.1)
				tw.tween_property(por, "scale", Vector2.ONE, 0.16)
		"heal":
			var v := _view(e.side, e.index)
			if not v.is_empty() and Options.get_value("damage_numbers"):
				FloatText.spawn(_fx, _number_at(v), "+" + _num(e.amount), Palette.GOOD, null, 17, 41.0, true)
		"thorns":
			var v := _view(e.side, e.to)
			if not v.is_empty() and Options.get_value("damage_numbers"):
				FloatText.spawn(_fx, _number_at(v), _num(e.dmg), Data.type_color("verdant"), null, 16, 36.0, true)
		"party_xp":
			# every kill's XP, over each party member it went to
			for v in _allies:
				if e.xp.has(v.cid) and not v.down:
					var at: Vector2 = v.root.position + Vector2(v.root.size.x * 0.5, float(v.get("tag_top", -10.0)) - 26.0)
					FloatText.spawn(_fx, at, "+%s XP" % _num(float(e.xp[v.cid])), Palette.AETHER, null, 16, 36.0, true)
		"creature_level":
			for v in _allies:
				if v.cid == e.creature:
					var at: Vector2 = v.root.position + Vector2(v.root.size.x * 0.5, float(v.get("tag_top", -10.0)) - 48.0)
					FloatText.spawn(_fx, at, "Level %d!" % int(e.level), Palette.GOLD, null, 20, 53.0, true)
		"captured":
			var at := Vector2(size.x * 0.73, size.y * 0.35)
			FloatText.spawn(_fx, at, "Bound!", Data.rarity_color(int(e.rarity)), Data.ui_icon("vessel"), 26, 72.0)
		"escaped":
			FloatText.spawn(_fx, Vector2(size.x * 0.73, size.y * 0.35), "Broke free", Palette.TEXT_FAINT, null, 19, 48.0)
		"creature_level":
			for v in _allies:
				if v.get("cid", "") == e.creature:
					FloatText.spawn(_fx, v.root.position + Vector2(v.root.size.x * 0.5, float(v.tag_top) - 12.0),
						"Level %d!" % int(e.level), Palette.AETHER, Data.ui_icon("xp"), 19, 36.0, true)
		"boss_defeated":
			_show_banner("Victory!", Palette.GOLD)
		"wiped":
			_show_banner("The party retreats…", Palette.DANGER)
