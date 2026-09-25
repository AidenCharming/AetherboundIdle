class_name ThemeFactory
extends RefCounted
## Builds the game's Theme in code: fonts, glass panels, cards, buttons and their variations.
## Variations (set a Control's theme_type_variation): Glass, Card, CardFlat, Inset, Pill, Primary, Gold,
## Danger, Ghost, Nav, NavActive, Chip, Title, H1, H2, Dim, Faint, Small.

const F_BODY := "res://assets/fonts/nunito-latin-600-normal.woff2"
const F_BODY_BOLD := "res://assets/fonts/nunito-latin-800-normal.woff2"
const F_HEAD := "res://assets/fonts/fredoka-latin-600-normal.woff2"
const F_HEAD_BOLD := "res://assets/fonts/fredoka-latin-700-normal.woff2"

static var _theme: Theme


static func font(path: String) -> Font:
	var f: FontFile = load(path)
	f.antialiasing = TextServer.FONT_ANTIALIASING_GRAY
	f.hinting = TextServer.HINTING_LIGHT
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO
	return f


static func head_font() -> Font:
	return font(F_HEAD)


static func bold_font() -> Font:
	return font(F_BODY_BOLD)


static func box(bg: Color, radius := 14, border := 0, border_color := Palette.LINE, margin := 12, shadow := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(border)
	sb.border_color = border_color
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = margin * 0.75
	sb.content_margin_bottom = margin * 0.75
	sb.anti_aliasing = true
	if shadow > 0:
		sb.shadow_size = shadow
		sb.shadow_color = Palette.SHADOW
		sb.shadow_offset = Vector2(0, shadow * 0.3)
	return sb


static func get_theme() -> Theme:
	if _theme:
		return _theme
	var t := Theme.new()
	t.default_font = font(F_BODY)
	t.default_font_size = 17

	# ---------------- labels
	t.set_color("font_color", "Label", Palette.TEXT)
	for v in [["Title", F_HEAD_BOLD, 40, Palette.TEXT], ["H1", F_HEAD, 28, Palette.TEXT], ["H2", F_HEAD, 21, Palette.TEXT],
			["H3", F_HEAD, 17, Palette.TEXT], ["Dim", F_BODY, 15, Palette.TEXT_DIM], ["Faint", F_BODY, 13, Palette.TEXT_FAINT],
			["Small", F_BODY_BOLD, 13, Palette.TEXT_DIM], ["Num", F_BODY_BOLD, 17, Palette.TEXT]]:
		t.set_type_variation(v[0], "Label")
		t.set_font(&"font", v[0], font(v[1]))
		t.set_font_size(&"font_size", v[0], v[2])
		t.set_color(&"font_color", v[0], v[3])

	# ---------------- panels
	t.set_stylebox("panel", "PanelContainer", box(Palette.PANEL, 18, 1, Palette.LINE, 16, 14))
	t.set_type_variation("Glass", "PanelContainer")
	t.set_stylebox("panel", "Glass", box(Palette.PANEL, 20, 1, Palette.LINE, 18, 18))
	t.set_type_variation("Card", "PanelContainer")
	t.set_stylebox("panel", "Card", box(Palette.CARD, 14, 1, Palette.LINE, 12, 6))
	t.set_type_variation("CardFlat", "PanelContainer")
	t.set_stylebox("panel", "CardFlat", box(Color(1, 1, 1, 0.035), 12, 1, Palette.LINE, 10))
	t.set_type_variation("Inset", "PanelContainer")
	t.set_stylebox("panel", "Inset", box(Color(0, 0, 0.05, 0.35), 12, 0, Palette.LINE, 10))
	t.set_type_variation("Pill", "PanelContainer")
	t.set_stylebox("panel", "Pill", box(Color(0.05, 0.06, 0.15, 0.75), 99, 1, Palette.LINE, 10))
	t.set_type_variation("Rail", "PanelContainer")
	t.set_stylebox("panel", "Rail", box(Color(0.045, 0.05, 0.12, 0.88), 0, 0, Palette.LINE, 10))
	t.set_type_variation("Modal", "PanelContainer")
	t.set_stylebox("panel", "Modal", box(Palette.PANEL_SOLID, 22, 1, Palette.LINE_STRONG, 22, 30))

	# ---------------- buttons
	_button(t, "Button", Palette.CARD, Palette.CARD_HOVER, Color(0.1, 0.1, 0.24), Palette.LINE, Palette.TEXT, 12)
	_button(t, "Primary", Color("5a4de0"), Color("6d60f2"), Color("4a3fc4"), Color(0.6, 0.9, 1.0, 0.5), Color.WHITE, 12, Palette.AETHER)
	_button(t, "Gold", Color("e2a93b"), Color("f2bd52"), Color("c99230"), Color(1, 0.9, 0.6, 0.6), Palette.INK, 12, Palette.GOLD)
	_button(t, "Danger", Color("b8445f"), Color("cf5572"), Color("9c3650"), Color(1, 0.6, 0.7, 0.4), Color.WHITE, 12)
	_button(t, "Ghost", Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.06), Color(1, 1, 1, 0.1), Color(1, 1, 1, 0), Palette.TEXT_DIM, 10)
	_button(t, "Nav", Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.05), Color(1, 1, 1, 0.08), Color(1, 1, 1, 0), Palette.TEXT_DIM, 10)
	_button(t, "NavActive", Color(0.42, 0.36, 1.0, 0.22), Color(0.42, 0.36, 1.0, 0.28), Color(0.42, 0.36, 1.0, 0.3), Color(0.5, 0.9, 1.0, 0.35), Palette.TEXT, 10)
	_button(t, "Chip", Color(0.05, 0.06, 0.15, 0.7), Color(0.12, 0.13, 0.3, 0.9), Color(0.2, 0.2, 0.45), Palette.LINE, Palette.TEXT_DIM, 99)
	_button(t, "ChipOn", Color(0.42, 0.36, 1.0, 0.35), Color(0.42, 0.36, 1.0, 0.45), Color(0.42, 0.36, 1.0, 0.5), Color(0.5, 0.9, 1.0, 0.5), Palette.TEXT, 99)
	_button(t, "Tile", Palette.CARD, Palette.CARD_HOVER, Color(0.1, 0.1, 0.24), Palette.LINE, Palette.TEXT, 16)
	_button(t, "TileOn", Color(0.2, 0.18, 0.45, 0.95), Color(0.24, 0.22, 0.5, 0.95), Color(0.2, 0.18, 0.45), Palette.AETHER, Palette.TEXT, 16)
	for v in ["Nav", "NavActive"]:
		t.set_font(&"font", v, font(F_BODY_BOLD))
		t.set_font_size(&"font_size", v, 16)
	for v in ["Primary", "Gold", "Danger"]:
		t.set_font(&"font", v, font(F_BODY_BOLD))
	for v in ["Chip", "ChipOn"]:
		t.set_font_size(&"font_size", v, 14)
		t.set_font(&"font", v, font(F_BODY_BOLD))

	# ---------------- progress bars
	t.set_stylebox("background", "ProgressBar", box(Color(0, 0, 0.05, 0.5), 99, 0, Palette.LINE, 0))
	t.set_stylebox("fill", "ProgressBar", box(Palette.AETHER, 99, 0, Palette.LINE, 0))
	t.set_font_size("font_size", "ProgressBar", 12)

	# ---------------- inputs
	var le := box(Color(0, 0, 0.05, 0.45), 10, 1, Palette.LINE, 10)
	t.set_stylebox("normal", "LineEdit", le)
	t.set_stylebox("focus", "LineEdit", box(Color(0, 0, 0.05, 0.55), 10, 1, Palette.AETHER, 10))
	t.set_color("font_color", "LineEdit", Palette.TEXT)
	t.set_color("font_placeholder_color", "LineEdit", Palette.TEXT_FAINT)
	t.set_color("caret_color", "LineEdit", Palette.AETHER)
	t.set_stylebox("normal", "TextEdit", le)
	t.set_stylebox("focus", "TextEdit", box(Color(0, 0, 0.05, 0.55), 10, 1, Palette.AETHER, 10))

	# sliders
	var track := box(Color(0, 0, 0.05, 0.55), 99, 0, Palette.LINE, 0)
	track.content_margin_top = 3
	track.content_margin_bottom = 3
	t.set_stylebox("slider", "HSlider", track)
	var fill := box(Palette.AETHER_DEEP, 99, 0, Palette.LINE, 0)
	fill.content_margin_top = 3
	fill.content_margin_bottom = 3
	t.set_stylebox("grabber_area", "HSlider", fill)
	t.set_stylebox("grabber_area_highlight", "HSlider", fill)
	var grab := _circle_texture(18, Palette.AETHER)
	t.set_icon("grabber", "HSlider", grab)
	t.set_icon("grabber_highlight", "HSlider", _circle_texture(20, Color.WHITE))

	# option buttons, popups, check buttons
	_button(t, "OptionButton", Palette.CARD, Palette.CARD_HOVER, Color(0.1, 0.1, 0.24), Palette.LINE, Palette.TEXT, 10)
	t.set_stylebox("panel", "PopupMenu", box(Palette.PANEL_SOLID, 12, 1, Palette.LINE_STRONG, 8, 10))
	t.set_stylebox("hover", "PopupMenu", box(Color(0.42, 0.36, 1.0, 0.3), 8, 0, Palette.LINE, 6))
	t.set_color("font_color", "PopupMenu", Palette.TEXT_DIM)
	t.set_color("font_hover_color", "PopupMenu", Palette.TEXT)
	t.set_constant("v_separation", "PopupMenu", 10)
	# menu icons (the skill list under Put to work) are painted at 512 px: draw them at text size
	t.set_constant("icon_max_width", "PopupMenu", 28)
	t.set_color("font_color", "CheckButton", Palette.TEXT)
	t.set_color("font_hover_color", "CheckButton", Palette.TEXT)
	t.set_color("font_pressed_color", "CheckButton", Palette.TEXT)
	t.set_color("font_hover_pressed_color", "CheckButton", Palette.TEXT)
	t.set_stylebox("normal", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("hover", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("pressed", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("hover_pressed", "CheckButton", StyleBoxEmpty.new())
	t.set_stylebox("focus", "CheckButton", StyleBoxEmpty.new())
	# ToggleSwitch paints the switch itself; the blank icons only keep its room beside the text
	var blank := _blank_texture(int(ToggleSwitch.W), int(ToggleSwitch.H))
	for icon_name in ["checked", "unchecked", "checked_disabled", "unchecked_disabled", "checked_mirrored", "unchecked_mirrored",
			"checked_disabled_mirrored", "unchecked_disabled_mirrored"]:
		t.set_icon(icon_name, "CheckButton", blank)

	# tooltips
	# tooltips: a small glass card with an aether edge on top and a soft drop shadow
	var tip := box(Color(0.10, 0.11, 0.25, 0.97), 12, 1, Palette.LINE_STRONG, 14, 0)
	tip.border_width_top = 3
	tip.border_color = Color(Palette.AETHER, 0.55)
	tip.shadow_color = Color(0, 0, 0.04, 0.6)
	tip.shadow_size = 14
	tip.shadow_offset = Vector2(0, 5)
	tip.content_margin_top = 10
	tip.content_margin_bottom = 10
	tip.anti_aliasing = true
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", Palette.TEXT)
	t.set_color("font_shadow_color", "TooltipLabel", Color(0, 0, 0, 0.35))
	t.set_constant("shadow_offset_y", "TooltipLabel", 1)
	t.set_font("font", "TooltipLabel", font(F_BODY_BOLD))
	t.set_font_size("font_size", "TooltipLabel", 14)
	t.set_constant("line_spacing", "TooltipLabel", 2)

	# scrollbars: thin and quiet
	var sbar := box(Color(1, 1, 1, 0.03), 99, 0, Palette.LINE, 0)
	sbar.content_margin_left = 3
	sbar.content_margin_right = 3
	var grabber := box(Color(1, 1, 1, 0.14), 99, 0, Palette.LINE, 0)
	grabber.content_margin_left = 3
	grabber.content_margin_right = 3
	t.set_stylebox("scroll", "VScrollBar", sbar)
	t.set_stylebox("grabber", "VScrollBar", grabber)
	t.set_stylebox("grabber_highlight", "VScrollBar", box(Color(1, 1, 1, 0.24), 99, 0, Palette.LINE, 0))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(Palette.AETHER, 99, 0, Palette.LINE, 0))
	t.set_stylebox("scroll", "HScrollBar", sbar)
	t.set_stylebox("grabber", "HScrollBar", grabber)

	# separators
	var sep := StyleBoxLine.new()
	sep.color = Palette.LINE
	sep.thickness = 1
	t.set_stylebox("separator", "HSeparator", sep)
	t.set_constant("separation", "HSeparator", 12)

	_theme = t
	return t


static func _button(t: Theme, v: String, normal: Color, hover: Color, pressed: Color, border: Color, text: Color, radius: int, glow := Color(0, 0, 0, 0)) -> void:
	if v != "Button" and v != "OptionButton":
		t.set_type_variation(v, "Button")
	var n := box(normal, radius, 1, border, 14)
	var h := box(hover, radius, 1, border.lightened(0.2), 14)
	var p := box(pressed, radius, 1, border, 14)
	var d := box(Color(normal, normal.a * 0.45), radius, 1, Color(border, border.a * 0.4), 14)
	var f := box(Color(0, 0, 0, 0), radius, 2, Palette.AETHER, 14)
	f.draw_center = false
	if glow.a > 0:
		for sb in [n, h]:
			sb.shadow_color = Color(glow, 0.28)
			sb.shadow_size = 8
	t.set_stylebox("normal", v, n)
	t.set_stylebox("hover", v, h)
	t.set_stylebox("pressed", v, p)
	t.set_stylebox("hover_pressed", v, p)
	t.set_stylebox("disabled", v, d)
	t.set_stylebox("focus", v, f)
	t.set_color("font_color", v, text)
	t.set_color("font_hover_color", v, text.lightened(0.1))
	t.set_color("font_pressed_color", v, text)
	t.set_color("font_hover_pressed_color", v, text)
	t.set_color("font_focus_color", v, text)
	t.set_color("font_disabled_color", v, Color(text, 0.45))
	t.set_color("icon_normal_color", v, Color.WHITE)
	t.set_color("icon_disabled_color", v, Color(1, 1, 1, 0.4))
	t.set_constant("h_separation", v, 8)
	t.set_constant("icon_max_width", v, 26)


static func _circle_texture(size: int, c: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var r := size / 2.0
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5 - r, y + 0.5 - r).length()
			var a := clampf(r - d, 0.0, 1.0)
			var col := c if d < r - 3.0 else Palette.INK
			img.set_pixel(x, y, Color(col, a))
	return ImageTexture.create_from_image(img)


static func _blank_texture(w: int, h: int) -> ImageTexture:
	return ImageTexture.create_from_image(Image.create(w, h, false, Image.FORMAT_RGBA8))
