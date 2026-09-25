class_name CreaturePortrait
extends Control
## A creature on a round art plate: type-coloured rim, rarity glow, the approved sprite (or the aether-blob
## placeholder for species without art), shiny hue shift and sparkle, optional idle motion (breathing, a
## slight sway, now and then a hop).
## Use setup() or set the fields and call refresh().

const CREATURE_SHADER := preload("res://assets/shaders/creature.gdshader")
const BLOB_SHADER := preload("res://assets/shaders/blob.gdshader")
const FORM_SCALE := [0.74, 0.87, 1.0]

var species := ""
var form := 1
var rarity := 1
var shiny := false
var silhouette := false
var plate := true
var bob := true
var flip := false
var glow_scale := 1.0

var _art: Control
var _mat: ShaderMaterial
var _t := 0.0
var _phase := 0.0
var _twinkle_t := 0.0
var _hop_in := -1.0    # seconds to the next little hop (set on the first frame)
var _hop_t := -1.0     # time into the current hop, or -1
var _glints: Control


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false


static func make(sp: String, f: int, r: int, sh: bool, size_px: float) -> CreaturePortrait:
	var p := CreaturePortrait.new()
	p.custom_minimum_size = Vector2(size_px, size_px)
	p.setup(sp, f, r, sh)
	return p


static func of(c: Dictionary, size_px: float) -> CreaturePortrait:
	return make(c.species, Creatures.form_of(c), int(c.rarity), bool(c.shiny), size_px)


func setup(sp: String, f: int, r: int, sh: bool) -> void:
	species = sp
	form = f
	rarity = r
	shiny = sh
	_phase = float(hash(sp) % 1000) / 100.0
	refresh()


func refresh() -> void:
	if _art:
		_art.queue_free()
		_art = null
	if species == "":
		return
	var tex := Data.creature_texture(species, form)
	_mat = ShaderMaterial.new()
	if tex:
		var rect := TextureRect.new()
		rect.texture = tex
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.flip_h = flip
		_mat.shader = CREATURE_SHADER
		_art = rect
	else:
		var cr := ColorRect.new()
		_mat.shader = BLOB_SHADER
		var types: Array = Data.species[species].types
		if shiny:
			# a shiny placeholder takes its first type's shiny palette
			var pal: Dictionary = Data.types[types[0]].shiny
			_mat.set_shader_parameter("color_a", Color(pal.mid))
			_mat.set_shader_parameter("color_b", Color(pal.light))
		else:
			_mat.set_shader_parameter("color_a", Data.type_color(types[0]))
			_mat.set_shader_parameter("color_b", Data.type_color(types[types.size() - 1]).lightened(0.1))
		_mat.set_shader_parameter("form", float(form))
		_mat.set_shader_parameter("seed", float(hash(species) % 97))
		_art = cr
	_art.material = _mat
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_art)
	if _glints:
		_glints.queue_free()
	_glints = Control.new()
	_glints.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_glints.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_glints.draw.connect(_draw_twinkles.bind(_glints))
	add_child(_glints)
	_apply_shader()
	_layout()
	queue_redraw()


func set_silhouette(on: bool) -> void:
	silhouette = on
	_apply_shader()
	queue_redraw()


func set_flash(v: float) -> void:
	if _mat:
		_mat.set_shader_parameter("flash", v)


func _apply_shader() -> void:
	if not _mat:
		return
	_mat.set_shader_parameter("silhouette", 1.0 if silhouette else 0.0)
	if _mat.shader == CREATURE_SHADER:
		var on := shiny and Data.species.has(species)
		_mat.set_shader_parameter("shiny", 1.0 if on else 0.0)
		if on:
			var pal: Dictionary = shiny_palette(species)
			_mat.set_shader_parameter("pal_dark", Color(pal.dark))
			_mat.set_shader_parameter("pal_mid", Color(pal.mid))
			_mat.set_shader_parameter("pal_light", Color(pal.light))
		_mat.set_shader_parameter("shimmer", 1.0 if on and not silhouette else 0.0)
		_mat.set_shader_parameter("fx", float(Data.rarity(rarity).get("fx", 0)))
		_mat.set_shader_parameter("fx_color", Data.rarity_color(rarity))


## The shiny palette for a species: its first type's (data/types.json "shiny").
static func shiny_palette(sp_id: String) -> Dictionary:
	return Data.types[Data.species[sp_id].types[0]].shiny


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout()


## Where the visible art sits inside this portrait at rest (no bob), in local pixels.
func art_bounds() -> Rect2:
	var s := size.x if size.x > 0 else custom_minimum_size.x
	var k: float = FORM_SCALE[clampi(form, 1, 3) - 1] * (0.9 if plate else 1.0)
	var art := s * k
	var origin := Vector2((s - art) / 2.0, (s - art) / 2.0 + s * 0.02)
	var tex := Data.creature_texture(species, form)
	# the aether-blob placeholder fills about this much of its square
	var r := Data.opaque_rect(tex) if tex else Rect2(0.14, 0.12, 0.72, 0.78)
	if flip:
		r.position.x = 1.0 - r.position.x - r.size.x
	return Rect2(origin + r.position * art, r.size * art)


func _layout() -> void:
	if not _art:
		return
	var s := size.x if size.x > 0 else custom_minimum_size.x
	var k: float = FORM_SCALE[clampi(form, 1, 3) - 1] * (0.9 if plate else 1.0)
	var art_size := Vector2(s, s) * k
	_art.size = art_size
	_art.pivot_offset = Vector2(art_size.x / 2.0, art_size.y)   # breathing and sway pivot on the feet
	_art.position = (Vector2(s, s) - art_size) / 2.0 + Vector2(0, s * 0.02)


func _process(delta: float) -> void:
	# a portrait scrolled out of view is still "visible in tree": a late Creaturedex has dozens of animated ones
	var on_screen := is_visible_in_tree() and get_global_rect().intersects(get_viewport_rect())
	if plate and not silhouette and Data.rarity_animated(rarity) and on_screen:
		queue_redraw()
	if shiny and not silhouette and on_screen and _glints:
		_twinkle_t += delta
		_glints.queue_redraw()
	if not bob or not _art or not on_screen:
		return
	if Options.get_value("reduce_motion"):
		return
	_t += delta
	var s := size.x
	var m := idle_motion(_t, _phase, plate)
	# now and then a little hop: a crouch, a jump, a landing squash
	if _hop_in < 0.0:
		_hop_in = 4.0 + fposmod(_phase * 3.7, 7.0)
	var hop := Vector3.ZERO   # (lift, squash, unused)
	if _hop_t >= 0.0:
		_hop_t += delta
		hop = hop_motion(_hop_t)
		if _hop_t >= HOP_TIME:
			_hop_t = -1.0
			_hop_in = randf_range(6.0, 14.0)
	else:
		_hop_in -= delta
		if _hop_in <= 0.0:
			_hop_t = 0.0
	var k: float = FORM_SCALE[clampi(form, 1, 3) - 1] * (0.9 if plate else 1.0)
	var art_size := Vector2(s, s) * k
	_art.position = (Vector2(s, s) - art_size) / 2.0 + Vector2(0, s * 0.02 + (m.x - hop.x) * s)
	var sq: float = m.y * (1.0 + hop.y)
	_art.scale = Vector2(1.0 / sqrt(sq), sq)
	_art.rotation = m.z


const HOP_TIME := 0.55


## The idle loop at time `t`: (lift as a share of the size, vertical stretch, sway in radians). Breathing is a
## slow stretch from the feet with a slight lean; on a plate it also floats a little. On the ground (the
## arena, plate off) the feet stay planted.
static func idle_motion(t: float, phase: float, on_plate: bool) -> Vector3:
	var breathe := 1.0 + sin(t * 2.4 + phase) * 0.022
	var sway := sin(t * 1.1 + phase * 1.7) * 0.022
	var lift := sin(t * 2.1 + phase) * 0.014 if on_plate else 0.0
	return Vector3(lift, breathe, sway)


## A hop at time `t` into it: (height as a share of the size, extra vertical stretch). A crouch first, a
## stretched jump, then a squash on landing.
static func hop_motion(t: float) -> Vector3:
	var u := clampf(t / HOP_TIME, 0.0, 1.0)
	if u < 0.18:   # crouch
		return Vector3(0.0, -0.08 * sin(u / 0.18 * PI), 0.0)
	if u < 0.8:    # in the air
		var a := (u - 0.18) / 0.62
		return Vector3(0.06 * sin(a * PI), 0.06 * cos(a * PI), 0.0)
	return Vector3(0.0, -0.07 * sin((u - 0.8) / 0.2 * PI), 0.0)   # landing


func _draw() -> void:
	if plate:
		_draw_plate()


## Four-point glints that fade in and out around a shiny, in its palette's light colour.
func _draw_twinkles(on: Control) -> void:
	if not shiny or silhouette or not Data.species.has(species):
		return
	var s := size.x
	var pal: Dictionary = shiny_palette(species)
	var col := Color(pal.light)
	for i in 4:
		var ph := fmod(_twinkle_t * 0.55 + i * 0.25 + _phase, 1.0)
		var a := sin(ph * PI)
		if a <= 0.05:
			continue
		var sd: float = float(i) * 2.3 + _phase + floor(_twinkle_t * 0.55 + i * 0.25 + _phase) * 1.7
		var pos := Vector2(0.18 + 0.64 * fposmod(sin(sd * 12.9) * 43.7, 1.0), 0.12 + 0.6 * fposmod(sin(sd * 78.2) * 17.3, 1.0)) * s
		var r := s * 0.05 * a
		var c := Color(col, a)
		UI.fill_polygon(on, PackedVector2Array([pos + Vector2(0, -r), pos + Vector2(r * 0.22, -r * 0.22), pos + Vector2(r, 0), pos + Vector2(r * 0.22, r * 0.22),
			pos + Vector2(0, r), pos + Vector2(-r * 0.22, r * 0.22), pos + Vector2(-r, 0), pos + Vector2(-r * 0.22, -r * 0.22)]), c)


func _draw_plate() -> void:
	var s := size.x
	var c := Vector2(s, s) / 2.0
	var r := s * 0.47
	var type_c := Palette.TEXT_FAINT
	if Data.species.has(species) and not silhouette:
		type_c = Data.type_color(Data.species[species].types[0])
	# rarity glow: soft rings outside the plate
	var glow: float = Data.rarity(rarity).glow * glow_scale if not silhouette else 0.0
	if glow > 0.0:
		var rc := Data.rarity_color_live(rarity)
		for i in 6:
			var rr := r + s * 0.012 * (i + 1)
			draw_circle(c, rr, Color(rc, 0.07 * glow * (1.0 - i / 6.0)), true, -1.0, true)
	draw_circle(c, r, Color(0.06, 0.065, 0.16, 0.95), true, -1.0, true)
	# inner gradient: a lighter disc toward the top
	for i in 5:
		draw_circle(c - Vector2(0, r * 0.12 * i / 5.0), r * (0.95 - i * 0.12), Color(type_c, 0.035), true, -1.0, true)
	draw_arc(c, r, 0, TAU, 64, Color(type_c, 0.85), maxf(2.0, s * 0.022), true)
	if not silhouette and rarity > 1:
		draw_arc(c, r + s * 0.02, -PI * 0.85, -PI * 0.15, 32, Color(Data.rarity_color_live(rarity), 0.9), maxf(1.5, s * 0.014), true)
	# frame effects for the top tiers: a rainbow tier's rim is a moving rainbow (Aetheric adds a second ring
	# turning the other way), and lights orbit the rim (`orbiters` in rarities.json)
	if not silhouette and Data.rarity_animated(rarity):
		var t := Time.get_ticks_msec() / 1000.0
		var rd: Dictionary = Data.rarity(rarity)
		if rd.get("live", "") == "rainbow":
			for i in 24:
				var a0 := TAU * i / 24.0
				draw_arc(c, r, a0, a0 + TAU / 24.0 + 0.02, 4, Color.from_hsv(fmod(t * 0.18 + i / 24.0, 1.0), 0.45, 1.0, 0.95), maxf(2.4, s * 0.026), true)
			if int(rd.fx) >= 6:
				for i in 24:
					var a0 := TAU * i / 24.0
					draw_arc(c, r + s * 0.045, a0, a0 + TAU / 24.0 + 0.02, 4, Color.from_hsv(fmod(-t * 0.3 + i / 24.0, 1.0), 0.6, 1.0, 0.6), maxf(1.4, s * 0.012), true)
		var orbiters := int(rd.get("orbiters", 0))
		for i in orbiters:
			var a := t * 0.9 + TAU * i / float(orbiters)
			var p := c + Vector2(cos(a), sin(a)) * (r + s * 0.02)
			var oc := Data.rarity_color_live(rarity)
			draw_circle(p, maxf(2.0, s * 0.02), Color(oc, 0.35), true, -1.0, true)
			draw_circle(p, maxf(1.2, s * 0.011), Color(oc.lightened(0.5), 0.95), true, -1.0, true)
	# rarity pips (one per tier) along the bottom of the rim, so the tier can be counted, not just colour-read
	if not silhouette and s >= 53.0:
		var pr := clampf(s * 0.024, 2.6, 6.0)
		var n := rarity
		var step_a := (pr * 2.3) / r
		for i in n:
			var a := PI / 2.0 + (float(i) - float(n - 1) / 2.0) * step_a
			UI.draw_pips(self, c + Vector2(cos(a), sin(a)) * r, 1, pr, Data.rarity_color_live(rarity))
