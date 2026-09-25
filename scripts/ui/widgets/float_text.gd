class_name FloatText
extends RefCounted
## Small rising "+1 [icon]" pickups and damage numbers.


static func spawn(parent: Control, at: Vector2, text: String, color := Palette.TEXT, tex: Texture2D = null, size := 19, rise := 55.0, centered := false) -> void:
	if not is_instance_valid(parent):
		return
	var h := UI.hbox(5)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if tex:
		h.add_child(UI.icon(tex, size + 5))
	var l := UI.label(text, "Num", color)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.1, 0.9))
	l.add_theme_constant_override("outline_size", 6)
	h.add_child(l)
	parent.add_child(h)
	h.position = at - Vector2(h.get_combined_minimum_size().x * 0.5 if centered else 19.0, 12)
	h.z_index = 10
	var tw := h.create_tween().set_parallel(true)
	tw.tween_property(h, "position:y", h.position.y - rise, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(h, "modulate:a", 0.0, 1.0).set_delay(0.45)
	tw.chain().tween_callback(h.queue_free)
