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
	var top := UI.hbox(5)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var lv := UI.chip("Lv %d" % int(c.level), Palette.AETHER, 13)
	top.add_child(lv)
	top.add_child(UI.spacer())
	if c.shiny:
		top.add_child(UI.icon(Data.ui_icon("shiny"), 19))
	if c.get("locked", false):
		top.add_child(UI.icon(Data.ui_icon("lock"), 17))
	v.add_child(top)
	var por := CreaturePortrait.of(c, w - 41)
	por.bob = false
	por.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(por)
	var name_lbl := UI.label(Creatures.display_name(c), "H3")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_lbl.clip_text = true
	if compact:
		name_lbl.add_theme_font_size_override("font_size", 18)
	v.add_child(name_lbl)
	var r := UI.label(Data.rarity(int(c.rarity)).name, "Faint", Data.rarity_color(int(c.rarity)))
	r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(r)
	if not compact:
		# a picker's note (what a pair would make, how fast it would work) comes first, and what the
		# Aetherling is doing now stays under it, so a busy one is never picked by surprise
		var lines := [[status_text(c), status_color(c)]]
		if note != "":
			lines.push_front([note, Palette.TEXT_DIM])
			custom_minimum_size.y += 22.0
		for pair in lines:
			var st := UI.label(pair[0], "Faint", pair[1])
			st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			st.clip_text = true
			st.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			v.add_child(st)
	tooltip_text = "%s · %s %s" % [Creatures.display_name(c), Data.rarity(int(c.rarity)).name, Data.species[c.species].name]


## Extra lines under the card (trait bonuses for a job, in the worker picker). The card grows to fit; every
## card in such a picker gets this call, so they share the wider size even with no lines.
func add_perks(lines: Array) -> void:
	custom_minimum_size.x = maxf(custom_minimum_size.x, 211.0)
	if lines.is_empty():
		return
	var v: VBoxContainer = get_child(0)
	for line in lines:
		var l := UI.label(line, "Small", Palette.GOOD)
		l.add_theme_font_size_override("font_size", 14)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.clip_text = true
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(l)
	custom_minimum_size.y += 22.0 * lines.size() + 5.0
	tooltip_text += "\n" + "\n".join(lines)


static func status_text(c: Dictionary) -> String:
	match Creatures.job_kind(c):
		"skill":
			return "Working: " + Data.skills[c.job.id].name
		"party":
			return "On an expedition"
	if perched_ids.has(c.id):
		return "Perched · +%s/min" % F.format_num(Creatures.bench_rate_per_min(c))
	return "Resting"


## The status line's colour: green at work, gold on an expedition, aether on a perch, soft indigo at rest.
static func status_color(c: Dictionary) -> Color:
	match Creatures.job_kind(c):
		"skill":
			return Palette.GOOD
		"party":
			return Palette.GOLD
	if perched_ids.has(c.id):
		return Palette.AETHER
	return Palette.TEXT_DIM
