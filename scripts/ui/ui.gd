class_name UI
extends RefCounted
## Small constructors so screens read as layout, not boilerplate.


static func label(text: String, variation := "", color := Color(0, 0, 0, 0)) -> Label:
	var l := Label.new()
	l.text = text
	if variation != "":
		l.theme_type_variation = variation
	if color.a > 0:
		l.add_theme_color_override("font_color", color)
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return l


static func wrap_label(text: String, variation := "Dim", min_width := 0) -> Label:
	var l := label(text, variation)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if min_width > 0:
		l.custom_minimum_size.x = min_width
	return l


static func rich(bbcode: String, fit := true) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = fit
	r.scroll_active = false
	r.text = bbcode
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.add_theme_color_override("default_color", Palette.TEXT_DIM)
	r.add_theme_font_override("bold_font", ThemeFactory.bold_font())
	return r


static func icon(tex: Texture2D, size := 24) -> TextureRect:
	var r := TextureRect.new()
	r.texture = tex
	r.custom_minimum_size = Vector2(size, size)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


## The "you own this species" badge. With `corner` (the size of the picture it sits on) it is placed on
## that picture's bottom-right corner.
static func owned_mark(size := 20, corner := Vector2.ZERO) -> TextureRect:
	var r := icon(Data.ui_icon("owned"), size)
	r.size = Vector2(size, size)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	r.tooltip_text = "You own this species"
	if corner != Vector2.ZERO:
		r.position = corner - Vector2(size, size) * 0.9
	return r


## Draws rarity pips: `n` small diamonds with a dark outline, centred on `at`, laid along `dir`.
static func draw_pips(ci: CanvasItem, at: Vector2, n: int, r: float, col: Color, dir := Vector2.RIGHT) -> void:
	var step := r * 2.3
	for i in n:
		var p := at + dir * (float(i) - float(n - 1) / 2.0) * step
		var o := r + maxf(1.0, r * 0.35)
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -o), p + Vector2(o, 0), p + Vector2(0, o), p + Vector2(-o, 0)]), Palette.INK)
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r, 0), p + Vector2(0, r), p + Vector2(-r, 0)]), col)
		ci.draw_colored_polygon(PackedVector2Array([p + Vector2(0, -r), p + Vector2(r * 0.45, -r * 0.1), p + Vector2(0, -r * 0.2)]), Color(1, 1, 1, 0.55))


## A small number chip in the nameplates' style: a rounded pill tinted with `color` (level, dex number).
static func chip(text: String, color: Color, font_size := 11) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := ThemeFactory.box(Color(color, 0.18), 99, 1, Color(color, 0.65), 0)
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	sb.content_margin_top = 1
	sb.content_margin_bottom = 1
	p.add_theme_stylebox_override("panel", sb)
	var l := label(text, "Small", color.lightened(0.3))
	l.add_theme_font_size_override("font_size", font_size)
	p.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


## Recolours and retexts a chip made by chip() (for numbers that change in place).
static func set_chip(p: PanelContainer, text: String, color: Color) -> void:
	var sb := p.get_theme_stylebox("panel") as StyleBoxFlat
	sb.bg_color = Color(color, 0.18)
	sb.border_color = Color(color, 0.65)
	var l := p.get_child(0) as Label
	l.text = text
	l.add_theme_color_override("font_color", color.lightened(0.3))


## A count against a target as a chip: gold when done, aether while going.
static func count_chip(have: float, need: float, font_size := 12) -> PanelContainer:
	var done := have >= need
	return chip("%s / %s" % [F.format_num(have), F.format_num(need)], Palette.GOOD if done else Palette.AETHER, font_size)


static func hbox(gap := 10, children: Array = []) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", gap)
	for c in children:
		b.add_child(c)
	return b


static func vbox(gap := 10, children: Array = []) -> VBoxContainer:
	var b := VBoxContainer.new()
	b.add_theme_constant_override("separation", gap)
	for c in children:
		b.add_child(c)
	return b


static func grid(columns: int, hsep := 12, vsep := 12) -> GridContainer:
	var g := GridContainer.new()
	g.columns = columns
	g.add_theme_constant_override("h_separation", hsep)
	g.add_theme_constant_override("v_separation", vsep)
	return g


## A flow of cards that wraps to the width available.
static func flow(hsep := 12, vsep := 12) -> HFlowContainer:
	var f := HFlowContainer.new()
	f.add_theme_constant_override("h_separation", hsep)
	f.add_theme_constant_override("v_separation", vsep)
	f.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return f


static func panel(variation := "Glass", child: Control = null) -> PanelContainer:
	var p := PanelContainer.new()
	p.theme_type_variation = variation
	if child:
		p.add_child(child)
	return p


static func margin(child: Control, l := 0, t := 0, r := 0, b := 0) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	m.add_child(child)
	return m


static func spacer(expand := true, min_size := 0) -> Control:
	var c := Control.new()
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.custom_minimum_size = Vector2(min_size, min_size)
	return c


static func button(text: String, variation := "", callback: Callable = Callable(), tex: Texture2D = null) -> Button:
	var b := Button.new()
	b.text = text
	if variation != "":
		b.theme_type_variation = variation
	if tex:
		b.icon = tex
		b.expand_icon = false
	if callback.is_valid():
		b.pressed.connect(callback)
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return b


static func bar(color: Color, height := 10, show_pct := false) -> ProgressBar:
	var p := ProgressBar.new()
	p.min_value = 0.0
	p.max_value = 1.0
	p.step = 0.0
	p.show_percentage = show_pct
	p.custom_minimum_size.y = height
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("fill", ThemeFactory.box(color, 99, 0, Palette.LINE, 0))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func scroll(child: Control, horizontal := false) -> ScrollContainer:
	var s := ScrollContainer.new()
	s.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if horizontal else ScrollContainer.SCROLL_MODE_DISABLED
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	child.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# a gutter between the content and the scrollbar, only while the scrollbar shows
	var gutter := MarginContainer.new()
	gutter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gutter.size_flags_vertical = child.size_flags_vertical
	gutter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	gutter.add_child(child)
	s.add_child(gutter)
	var vbar := s.get_v_scroll_bar()
	var fit := func(): gutter.add_theme_constant_override("margin_right", 12 if vbar.visible else 0)
	vbar.visibility_changed.connect(fit)
	fit.call()
	return s


static func sep() -> HSeparator:
	return HSeparator.new()


static func clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


## Icon + amount, e.g. [log] 12. `need` > 0 turns it red when the player has less.
static func amount(id: String, qty: float, need := -1.0, size := 22) -> HBoxContainer:
	var h := hbox(4)
	var ic := icon(Data.item_icon(id), size)
	ic.tooltip_text = Data.item_name(id)
	ic.mouse_filter = Control.MOUSE_FILTER_PASS
	h.add_child(ic)
	var l := label(F.format_num(qty), "Num")
	l.add_theme_font_size_override("font_size", 15)
	if need >= 0.0:
		l.add_theme_color_override("font_color", Palette.TEXT if GameState.count(Game.state, id) + 1e-6 >= need else Palette.DANGER)
	h.add_child(l)
	h.tooltip_text = Data.item_name(id)
	return h


## A row of cost chips for {id: qty}.
static func cost_row(cost: Dictionary, size := 20) -> HFlowContainer:
	var f := flow(10, 4)
	for id in cost:
		f.add_child(amount(id, float(cost[id]), float(cost[id]), size))
	return f


static func type_badge(type_id: String, small := false) -> PanelContainer:
	var p := PanelContainer.new()
	var c := Data.type_color(type_id)
	var sb := ThemeFactory.box(Color(c, 0.22), 99, 1, Color(c, 0.7), 8)
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	var l := label(Data.types[type_id].name, "Small", c.lightened(0.35))
	if small:
		l.add_theme_font_size_override("font_size", 12)
	p.add_child(l)
	return p


static func rarity_badge(tier: int) -> PanelContainer:
	var p := PanelContainer.new()
	var c := Data.rarity_color(tier)
	var sb := ThemeFactory.box(Color(c, 0.18), 99, 1, Color(c, 0.75), 8)
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	p.add_theme_stylebox_override("panel", sb)
	p.add_child(label(Data.rarity(tier).name, "Small", c.lightened(0.2)))
	return p


static func badge(text: String, color: Color) -> PanelContainer:
	var p := PanelContainer.new()
	var sb := ThemeFactory.box(color, 99, 0, Palette.LINE, 6)
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	p.add_theme_stylebox_override("panel", sb)
	var l := label(text, "Small", Palette.INK)
	l.add_theme_font_size_override("font_size", 12)
	p.add_child(l)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return p


static func stat_line(icon_name: String, text: String, tip := "") -> HBoxContainer:
	var h := hbox(6, [icon(Data.ui_icon(icon_name), 18), label(text, "Num")])
	h.tooltip_text = tip
	return h


## Shows `text` as a heading with an optional sub line.
static func header(title: String, sub := "", tex: Texture2D = null, size := 44) -> HBoxContainer:
	var h := hbox(14)
	if tex:
		h.add_child(icon(tex, size))
	var v := vbox(0)
	v.add_child(label(title, "H1"))
	if sub != "":
		# wraps rather than widening the screen: a long subtitle must not push a side panel off screen
		var sl := wrap_label(sub, "Dim")
		sl.custom_minimum_size.x = 260
		v.add_child(sl)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	return h


static func tween_pop(node: Control, scale := 1.08, time := 0.12) -> void:
	if Options.get_value("reduce_motion"):
		return
	node.pivot_offset = node.size / 2.0
	var tw := node.create_tween()
	tw.tween_property(node, "scale", Vector2(scale, scale), time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", Vector2.ONE, time * 1.5).set_trans(Tween.TRANS_SINE)
