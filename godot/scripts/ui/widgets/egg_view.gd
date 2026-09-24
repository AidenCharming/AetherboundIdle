class_name EggView
extends ColorRect
## An egg drawn by shader. The shell speckles use the offspring's type colours; the glow hints at its
## rarity (the "shell" rarity, which is right most of the time and one tier off otherwise).

const SHADER := preload("res://assets/shaders/egg.gdshader")

var mat: ShaderMaterial


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


func set_crack(v: float) -> void:
	mat.set_shader_parameter("crack", v)


func set_flash(v: float) -> void:
	mat.set_shader_parameter("flash", v)
