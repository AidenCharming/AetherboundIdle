class_name CreatureCard
extends Button
## A creature as a clickable card: portrait, name, level, rarity and what it is doing.

signal picked(cid: String)

const W := 150.0
const H := 214.0

var cid := ""

## Ids of perched creatures; screens call refresh_perched() once before building many cards.
static var perched_ids: Dictionary = {}


static func refresh_perched() -> void:
	perched_ids.clear()
	for c in Economy.perched(Game.state):
		perched_ids[c.id] = true


static func make(c: Dictionary, selected := false, note := "", compact := false) -> CreatureCard:
	var card := CreatureCard.new()
	card.build(c, selected, note, compact)
	return card


func build(c: Dictionary, selected: bool, note: String, compact: bool) -> void:
	cid = c.id
	theme_type_variation = "TileOn" if selected else "Tile"
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var w := W * (0.82 if compact else 1.0)
	var h := H * (0.82 if compact else 1.0)
	custom_minimum_size = Vector2(w, h)
	pressed.connect(func(): picked.emit(cid))
	var v := UI.vbox(2)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 8
	v.offset_right = -8
	v.offset_top = 8
	v.offset_bottom = -8
	add_child(v)
	var top := UI.hbox(4)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lv := UI.label("Lv %d" % int(c.level), "Small")
	top.add_child(lv)
	top.add_child(UI.spacer())
	if c.shiny:
		top.add_child(UI.icon(Data.ui_icon("shiny"), 16))
	if c.get("locked", false):
		top.add_child(UI.icon(Data.ui_icon("lock"), 14))
	v.add_child(top)
	var por := CreaturePortrait.of(c, w - 34)
	por.bob = false
	por.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(por)
	var name_lbl := UI.label(Creatures.display_name(c), "H3")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.clip_text = true
	if compact:
		name_lbl.add_theme_font_size_override("font_size", 15)
	v.add_child(name_lbl)
	var r := UI.label(Data.rarity(int(c.rarity)).name, "Faint", Data.rarity_color(int(c.rarity)))
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(r)
	if not compact:
		var st := UI.label(note if note != "" else status_text(c), "Faint")
		st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		st.clip_text = true
		st.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(st)
	tooltip_text = "%s · %s %s" % [Creatures.display_name(c), Data.rarity(int(c.rarity)).name, Data.species[c.species].name]


static func status_text(c: Dictionary) -> String:
	match Creatures.job_kind(c):
		"skill":
			return "Working: " + Data.skills[c.job.id].name
		"party":
			return "On an expedition"
	if perched_ids.has(c.id):
		return "Perched · %s Aether/min" % F.format_num(Creatures.bench_rate_per_min(c))
	return "Resting"
