class_name CreaturePortrait
extends Control
## A creature on a round art plate: type-coloured rim, rarity glow, the approved sprite (or the aether-blob
## placeholder for species without art), shiny hue shift and sparkle, optional idle bob.
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
	_art.pivot_offset = art_size / 2.0
	_art.position = (Vector2(s, s) - art_size) / 2.0 + Vector2(0, s * 0.02)


func _process(delta: float) -> void:
	if shiny and not silhouette and is_visible_in_tree() and _glints:
		_twinkle_t += delta
		_glints.queue_redraw()
	if not bob or not _art or not is_visible_in_tree():
		return
	if Options.get_value("reduce_motion"):
		return
	_t += delta
	var s := size.x
	var y := sin(_t * 2.1 + _phase) * s * 0.018
	var sq := 1.0 + sin(_t * 4.2 + _phase) * 0.012
	var k: float = FORM_SCALE[clampi(form, 1, 3) - 1] * (0.9 if plate else 1.0)
	var art_size := Vector2(s, s) * k
	_art.position = (Vector2(s, s) - art_size) / 2.0 + Vector2(0, s * 0.02 + y)
	_art.scale = Vector2(1.0 / sq, sq)


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
		on.draw_polygon(PackedVector2Array([pos + Vector2(0, -r), pos + Vector2(r * 0.22, -r * 0.22), pos + Vector2(r, 0), pos + Vector2(r * 0.22, r * 0.22),
			pos + Vector2(0, r), pos + Vector2(-r * 0.22, r * 0.22), pos + Vector2(-r, 0), pos + Vector2(-r * 0.22, -r * 0.22)]), PackedColorArray([c]))


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
		var rc := Data.rarity_color(rarity)
		for i in 6:
			var rr := r + s * 0.012 * (i + 1)
			draw_circle(c, rr, Color(rc, 0.07 * glow * (1.0 - i / 6.0)))
	draw_circle(c, r, Color(0.06, 0.065, 0.16, 0.95))
	# inner gradient: a lighter disc toward the top
	for i in 5:
		draw_circle(c - Vector2(0, r * 0.12 * i / 5.0), r * (0.95 - i * 0.12), Color(type_c, 0.035))
	draw_arc(c, r, 0, TAU, 64, Color(type_c, 0.85), maxf(2.0, s * 0.022), true)
	if not silhouette and rarity > 1:
		draw_arc(c, r + s * 0.02, -PI * 0.85, -PI * 0.15, 32, Color(Data.rarity_color(rarity), 0.9), maxf(1.5, s * 0.014), true)
