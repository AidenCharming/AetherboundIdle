class_name ToggleSwitch
extends CheckButton
## The game's on/off switch: a CheckButton (so text, signals, keyboard and set_pressed_no_signal all work as
## usual) that paints its own track and knob instead of the theme's icon. Drawn with anti-aliased shapes at the
## real screen scale, so it stays smooth at any window size, and the knob slides instead of jumping.

const W := 55.0
const H := 31.0
const SLIDE := 0.14   ## seconds for the knob to cross

var _t := 0.0          # 0 = off, 1 = on, in between while sliding
var _tween: Tween
var _hover := false


func _ready() -> void:
	_t = 1.0 if button_pressed else 0.0
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# the switch must never cover the text: room for both, whatever the theme's icon allowance is
	if text != "":
		var fs := get_theme_font_size("font_size")
		custom_minimum_size.x = maxf(custom_minimum_size.x, get_theme_font("font").get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + W + 12.0)
	toggled.connect(_slide)
	mouse_entered.connect(func():
		_hover = true
		queue_redraw())
	mouse_exited.connect(func():
		_hover = false
		queue_redraw())


func _slide(on: bool) -> void:
	if _tween:
		_tween.kill()
	if Options.get_value("reduce_motion") or not is_inside_tree():
		_t = 1.0 if on else 0.0
		queue_redraw()
		return
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_method(func(v: float):
		_t = v
		queue_redraw(), _t, 1.0 if on else 0.0, SLIDE)


func _draw() -> void:
	if not (_tween and _tween.is_running()):
		_t = 1.0 if button_pressed else 0.0   # set_pressed_no_signal() skips `toggled`: catch up
	# the theme gives CheckButton a blank icon of W×H, so the text leaves room for the switch on the right
	var r := Rect2(Vector2(size.x - W, (size.y - H) * 0.5), Vector2(W, H))
	var off_col := Color(0.16, 0.18, 0.36)
	var on_col := Palette.AETHER_DEEP
	var track := StyleBoxFlat.new()
	track.set_corner_radius_all(int(H * 0.5))
	track.anti_aliasing = true
	track.bg_color = off_col.lerp(on_col, _t)
	if _hover and not disabled:
		track.bg_color = track.bg_color.lightened(0.12)
	track.set_border_width_all(1)
	track.border_color = Palette.LINE_STRONG.lerp(Color(Palette.AETHER, 0.7), _t)
	if _t > 0.0:
		track.shadow_color = Color(Palette.AETHER_DEEP, 0.45 * _t)
		track.shadow_size = 10
	if has_focus():
		track.border_color = Palette.AETHER
		track.set_border_width_all(2)
	draw_style_box(track, r)
	var pad := 3.6
	var rad := H * 0.5 - pad
	var cx := lerpf(r.position.x + pad + rad, r.end.x - pad - rad, _t)
	var c := Vector2(cx, r.position.y + H * 0.5)
	draw_circle(c + Vector2(0, 1.8), rad, Color(0, 0, 0.05, 0.35), true, -1.0, true)   # soft drop shadow
	draw_circle(c, rad, Palette.TEXT_DIM.lerp(Color.WHITE, _t), true, -1.0, true)
	# a small aether dot in the knob when on, so on and off differ by more than colour
	if _t > 0.5:
		draw_circle(c, rad * 0.32 * (_t - 0.5) * 2.0, Palette.AETHER_DEEP, true, -1.0, true)
