class_name EggView
extends ColorRect
## An egg drawn by shader. The shell speckles use the offspring's type colours; the glow hints at its
## rarity (the "shell" rarity, which is right most of the time and one tier off otherwise).

const SHADER := preload("res://assets/shaders/egg.gdshader")

var mat: ShaderMaterial
## Knocking (a secret): a knockable egg wobbles when clicked, and the third knock in a row makes it squeak.
var knockable := false
var _knocks: Array = []


static func make(egg: Dictionary, px: float) -> EggView:
	var e := EggView.new()
	e.custom_minimum_size = Vector2(px, px)
	e.setup(egg)
	return e


func setup(egg: Dictionary) -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	color = Color.WHITE
	mat = ShaderMaterial.new()
	mat.shader = SHADER
	material = mat
	var types: Array = Data.species[egg.species].types
	var shell_tier := int(egg.get("shell", egg.rarity))
	var rc := Data.rarity_color(shell_tier)
	mat.set_shader_parameter("shell", Color("f4efff").lerp(Data.type_color(types[0]), 0.12))
	mat.set_shader_parameter("spots", Data.type_color(types[types.size() - 1]))
	mat.set_shader_parameter("glow", rc)
	mat.set_shader_parameter("glow_strength", 0.25 + 0.6 * float(Data.rarity(shell_tier).glow))
	mat.set_shader_parameter("seed", float(hash(str(egg.get("laidAt", 0))) % 50) + 1.0)


func _gui_input(event: InputEvent) -> void:
	if knockable and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		accept_event()
		knock()


func knock() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	_knocks = _knocks.filter(func(x): return now - float(x) < 3.0)
	_knocks.append(now)
	pivot_offset = Vector2(size.x / 2.0, size.y * 0.9)
	var tw := create_tween()
	for a in [0.12, -0.1, 0.06, 0.0]:
		tw.tween_property(self, "rotation", a, 0.07)
	if _knocks.size() >= 3:
		_knocks.clear()
		Sfx.play("squeak")
		FloatText.spawn(self, Vector2(size.x / 2.0, size.y * 0.1), "Patience!", Palette.GOLD, null, 16, 45.0, true)
		Game.note_secret("patience")
	else:
		Sfx.play("crack", 1.4)


func set_crack(v: float) -> void:
	mat.set_shader_parameter("crack", v)


func set_flash(v: float) -> void:
	mat.set_shader_parameter("flash", v)
