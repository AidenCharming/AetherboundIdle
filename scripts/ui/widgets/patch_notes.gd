class_name PatchNotes
extends PanelContainer
## The title screen's patch notes: every version from `data/patch_notes.json` (newest first) in one scrolling
## list, each change prefixed by the part of the game it touches ("UI:", "Nexus:") and grouped by kind. The
## chips along the top show one kind only.

## Kinds in the order they are listed: [key in the data, heading, colour].
const KINDS := [
	["New", "New features", Palette.AETHER],
	["QOL", "Quality of life", Palette.GOOD],
	["Bugfixes", "Bug fixes", Palette.DANGER],
	["Balancing", "Balancing", Palette.GOLD],
]
## Colours for the area prefixes; any other area uses the default.
const AREA_COLORS := {
	"UI": Color("b69cff"), "Nexus": Color("7ae8ff"), "Expeditions": Color("ff9e6b"), "Breeding": Color("ff8fc8"),
	"Market": Color("ffd166"), "Sanctum": Color("8fd6ff"), "Skills": Color("66e3a0"), "Inventory": Color("f5c77e"),
	"Options": Color("c3c8ea"), "Audio": Color("9be7c4"), "Saves": Color("a9b8ff"), "Game": Color("eef0ff"),
	"Crafting": Color("e8b27a"), "Cooking": Color("ffb38a"), "Aether-Log": Color("9ee86b"),
}
const ENTRY_WIDTH := 470

var _list: VBoxContainer
var _chips: Dictionary = {}   # kind key ("" = all) -> Button
var _kind := ""


func _init() -> void:
	theme_type_variation = "Glass"
	var v := UI.vbox(14)
	add_child(v)
	var head := UI.hbox(12)
	head.add_child(UI.icon(Data.ui_icon("upgrade"), 34))
	head.add_child(UI.label("Patch Notes", "H2"))
	head.add_child(UI.spacer())
	head.add_child(UI.chip("v%s" % ProjectSettings.get_setting("application/config/version"), Palette.AETHER, 16))
	v.add_child(head)
	var chips := UI.hbox(8)
	chips.add_child(_chip("", "All", Palette.TEXT_DIM))
	for k in KINDS:
		chips.add_child(_chip(k[0], k[0], k[2]))
	v.add_child(chips)
	v.add_child(UI.sep())
	_list = UI.vbox(16)
	v.add_child(UI.scroll(_list))
	_fill()


func _chip(key: String, text: String, col: Color) -> Button:
	var b := UI.button(text, "", func(): _pick(key))
	b.toggle_mode = true
	b.button_pressed = key == _kind
	b.add_theme_font_size_override("font_size", 16)
	b.add_theme_color_override("font_color", col.lightened(0.2))
	b.add_theme_color_override("font_pressed_color", Palette.INK)
	b.add_theme_color_override("font_hover_pressed_color", Palette.INK)
	b.add_theme_stylebox_override("normal", _chip_box(Color(col, 0.12), Color(col, 0.5)))
	b.add_theme_stylebox_override("hover", _chip_box(Color(col, 0.24), Color(col, 0.8)))
	b.add_theme_stylebox_override("pressed", _chip_box(col, col))
	b.add_theme_stylebox_override("hover_pressed", _chip_box(col.lightened(0.1), col))
	_chips[key] = b
	return b


func _chip_box(bg: Color, border: Color) -> StyleBoxFlat:
	var sb := ThemeFactory.box(bg, 119, 1, border, 0)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	return sb


func _pick(key: String) -> void:
	_kind = key
	for k in _chips:
		(_chips[k] as Button).set_pressed_no_signal(k == key)
	_fill()


func _fill() -> void:
	UI.clear(_list)
	var first := true
	for patch: Dictionary in Data.patch_notes:
		var card := _patch_card(patch, first)
		if card:
			_list.add_child(card)
			first = false
	if _list.get_child_count() == 0:
		_list.add_child(UI.label("Nothing of this kind yet.", "Faint"))


## One version's card, or null when the filter leaves it empty. The newest gets a brighter border.
func _patch_card(patch: Dictionary, newest: bool) -> Control:
	var notes: Dictionary = patch.get("notes", {})
	var body := UI.vbox(10)
	for k in KINDS:
		if _kind != "" and _kind != k[0]:
			continue
		var entries: Array = notes.get(k[0], [])
		if entries.is_empty():
			continue
		body.add_child(_kind_heading(k[1], k[2], entries.size()))
		for e: Array in entries:
			body.add_child(_entry(str(e[0]), str(e[1]), k[2]))
	if body.get_child_count() == 0:
		return null
	var card := UI.panel("Card")
	if newest:
		card.add_theme_stylebox_override("panel", ThemeFactory.box(Palette.CARD, 17, 2, Color(Palette.AETHER, 0.55), 14, 7))
	var v := UI.vbox(10)
	card.add_child(v)
	var top := UI.hbox(10)
	top.add_child(UI.chip("v" + str(patch.version), Palette.AETHER if newest else Palette.AETHER_DEEP.lightened(0.3), 16))
	var title := UI.label(str(patch.get("title", "")), "H3")
	title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.custom_minimum_size.x = 120
	top.add_child(title)
	if newest and _kind == "":
		top.add_child(UI.chip("Latest", Palette.GOLD, 13))
	top.add_child(UI.label(str(patch.get("date", "")), "Faint"))
	v.add_child(top)
	v.add_child(body)
	return card


func _kind_heading(text: String, col: Color, n: int) -> Control:
	var h := UI.hbox(8)
	var bar := ColorRect.new()
	bar.color = col
	bar.custom_minimum_size = Vector2(4, 20)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(bar)
	h.add_child(UI.label(text.to_upper(), "Small", col.lightened(0.15)))
	h.add_child(UI.label("%d" % n, "Faint"))
	return UI.margin(h, 0, 4, 0, 0)


func _entry(area: String, text: String, col: Color) -> Control:
	var area_col: Color = AREA_COLORS.get(area, Palette.TEXT)
	var h := UI.hbox(10)
	var dot := UI.label("•", "Dim", col)
	dot.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	dot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(dot)
	var r := UI.rich("[b][color=#%s]%s:[/color][/b] [color=#%s]%s[/color]" % [
		area_col.to_html(false), area, Palette.TEXT.to_html(false), text.replace("[", "[lb]")])
	r.custom_minimum_size.x = ENTRY_WIDTH
	r.add_theme_font_size_override("normal_font_size", 18)
	r.add_theme_font_size_override("bold_font_size", 18)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(r)
	return UI.margin(h, 12, 0, 0, 0)
