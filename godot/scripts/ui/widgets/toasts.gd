class_name Toasts
extends VBoxContainer
## Stacked toast notifications in the top-right corner. They slide in, wait, and fade out.

const MAX := 4
const LIFE := 4.5


func _ready() -> void:
	add_theme_constant_override("separation", 8)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Game.toast.connect(show_toast)


func show_toast(text: String, tex: Texture2D, color: Color) -> void:
	if not Options.get_value("toasts"):
		return
	while get_child_count() >= MAX:
		var old := get_child(0)
		remove_child(old)
		old.queue_free()
	var p := PanelContainer.new()
	var sb := ThemeFactory.box(Color(0.08, 0.09, 0.2, 0.94), 14, 1, Color(color, 0.55), 12, 12)
	sb.border_width_left = 4
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := UI.hbox(10)
	if tex:
		h.add_child(UI.icon(tex, 26))
	var l := UI.label(text, "", Palette.TEXT)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 280
	h.add_child(l)
	p.add_child(h)
	p.custom_minimum_size.x = 340
	add_child(p)
	p.modulate.a = 0.0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.18)
	tw.tween_interval(LIFE)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)
