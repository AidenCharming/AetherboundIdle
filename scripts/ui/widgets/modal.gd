class_name Modal
extends Control
## A dimmed full-screen overlay with a centred glass panel. Modal.open() puts it on the overlay layer
## registered by the current scene. Esc or a click on the dim area closes it (unless locked).

signal closed

static var layer: Control   ## set by the title and game scenes

var panel: PanelContainer
var body: VBoxContainer
var locked := false
var closing := false   ## fading out: it no longer counts as open and lets every click through
var _dim: ColorRect


static func open(content: Control, title := "", width := 672.0, close_button := true) -> Modal:
	var m := Modal.new()
	m._build(content, title, width, close_button)
	var host: Control = layer if layer and is_instance_valid(layer) else null
	if host:
		host.add_child(m)
	return m


## The round close button: a drawn cross that brightens on hover. Its tooltip is "Close", which is how tests
## and the bridge's `click "Close"` find it.
static func close_x(on_press: Callable) -> Button:
	var b := Button.new()
	b.tooltip_text = "Close"
	b.custom_minimum_size = Vector2(40, 40)
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.add_theme_stylebox_override("normal", ThemeFactory.box(Color(1, 1, 1, 0.04), 20, 1, Color(1, 1, 1, 0.1), 0))
	b.add_theme_stylebox_override("hover", ThemeFactory.box(Color(1, 1, 1, 0.12), 20, 1, Color(1, 1, 1, 0.25), 0))
	b.add_theme_stylebox_override("pressed", ThemeFactory.box(Color(1, 1, 1, 0.2), 20, 1, Color(1, 1, 1, 0.3), 0))
	b.pressed.connect(on_press)
	b.mouse_entered.connect(b.queue_redraw)
	b.mouse_exited.connect(b.queue_redraw)
	b.draw.connect(func():
		var c := b.size * 0.5
		var r := 7.0
		var col := Palette.TEXT if b.is_hovered() else Palette.TEXT_DIM
		b.draw_line(c + Vector2(-r, -r), c + Vector2(r, r), col, 2.5, true)
		b.draw_line(c + Vector2(r, -r), c + Vector2(-r, r), col, 2.5, true))
	return b


func _build(content: Control, title: String, width: float, close_button: bool) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim = ColorRect.new()
	_dim.color = Color(0.01, 0.01, 0.04, 0.72)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.gui_input.connect(func(ev):
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT and not locked:
			close())
	add_child(_dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	panel = UI.panel("Modal")
	panel.custom_minimum_size.x = width
	center.add_child(panel)
	body = UI.vbox(17)
	panel.add_child(body)
	if title != "":
		var head := UI.hbox(12)
		head.add_child(UI.label(title, "H2"))
		head.add_child(UI.spacer())
		if close_button:
			head.add_child(close_x(close))
		body.add_child(head)
	elif close_button:
		# no title: the close button sits in the corner over the content, not on a header row of its own
		var over := Control.new()
		over.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var x := close_x(close)
		x.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
		x.offset_left = -40
		x.offset_bottom = 40
		over.add_child(x)
		panel.add_child(over)
	body.add_child(content)
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	modulate.a = 0.0
	panel.scale = Vector2(0.96, 0.96)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.14)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	panel.resized.connect(func(): panel.pivot_offset = panel.size / 2.0)


func _ready() -> void:
	get_viewport().size_changed.connect(func(): _remeasure.call_deferred())


## A wrapping label measured while the window is changing mode can keep a stale height of thousands of
## pixels, which stretches the panel off both ends of the screen. Measure them again once the size settles.
func _remeasure() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	var stack: Array[Node] = [panel]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is Label and n.autowrap_mode != TextServer.AUTOWRAP_OFF:
			n.update_minimum_size()
		stack.append_array(n.get_children())
	panel.update_minimum_size()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not locked and not closing:
		get_viewport().set_input_as_handled()
		close()


func close() -> void:
	if closing or is_queued_for_deletion():
		return
	closing = true
	# while it fades, clicks go to whatever is under it: a click on the rail or a button a moment after
	# closing a dialog was being swallowed by the fading dim
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_behavior_recursive = Control.MOUSE_BEHAVIOR_DISABLED
	focus_behavior_recursive = Control.FOCUS_BEHAVIOR_DISABLED
	closed.emit()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.1)
	tw.tween_callback(queue_free)


## Yes/no dialog.
static func confirm(title: String, text: String, yes_text: String, on_yes: Callable, danger := false) -> Modal:
	var v := UI.vbox(22)
	v.add_child(UI.wrap_label(text, "Dim", 504))
	var row := UI.hbox(12)
	row.add_child(UI.spacer())
	# Lambdas capture local variables by value when they are created, so the modal (opened after its buttons
	# exist) is kept in a Dictionary, which the lambdas share by reference.
	var box := {}
	row.add_child(UI.button("Cancel", "", func(): box.m.close()))
	row.add_child(UI.button(yes_text, "Danger" if danger else "Primary", func():
		box.m.close()
		on_yes.call()))
	v.add_child(row)
	box.m = open(v, title, 576)
	return box.m


## Open and taking input: not closing or freed.
func is_open() -> bool:
	return not closing and not is_queued_for_deletion()


static func close_all() -> void:
	if not layer or not is_instance_valid(layer):
		return
	for c in layer.get_children():
		if c is Modal and c.is_open():
			c.close()


static func any_open() -> bool:
	if not layer or not is_instance_valid(layer):
		return false
	for c in layer.get_children():
		if c is Modal and c.is_open():
			return true
	return false
