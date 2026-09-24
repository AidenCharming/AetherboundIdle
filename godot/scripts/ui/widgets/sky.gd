class_name SkyBackdrop
extends ColorRect
## Full-screen animated night sky (shader), optionally tinted for a zone or screen.

const SHADER := preload("res://assets/shaders/sky.gdshader")

var _mat: ShaderMaterial


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	material = _mat


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and size.y > 0:
		_mat.set_shader_parameter("aspect", Vector2(size.x / size.y, 1.0))


func tint(a: Color, b: Color, strength := 0.35) -> void:
	_mat.set_shader_parameter("nebula_a", a)
	_mat.set_shader_parameter("nebula_b", b)
	_mat.set_shader_parameter("nebula_strength", strength)


func set_colors(top: Color, bottom: Color) -> void:
	_mat.set_shader_parameter("top_color", top)
	_mat.set_shader_parameter("bottom_color", bottom)
