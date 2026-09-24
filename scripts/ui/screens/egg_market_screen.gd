extends Control
## The Egg Market: eggs of the types you own, in grades that open up as islands are cleared, and a featured
## egg (a named Aetherling, a grade above the best on sale) that changes with the Market's stock.

static var grade := -1   # -1: the best grade on sale

var _body: VBoxContainer
var _gold: Label
var _pods: Label
var _clock: Label


func _ready() -> void:
	var v := UI.vbox(14)
	var m := UI.margin(v, 26, 10, 26, 20)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var head := UI.hbox(12)
	head.add_child(UI.header("Egg Market", "Buy an egg of a type you own. It hatches in a Genesis Pod like any bred egg.", Data.ui_icon("egg-market")))
	head.add_child(UI.spacer())
	_pods = UI.label("", "Dim")
	head.add_child(UI.hbox(6, [UI.icon(Data.ui_icon("pods"), 22), _pods]))
	_gold = UI.label("", "Num", Palette.GOLD)
	_gold.add_theme_font_size_override("font_size", 22)
	head.add_child(UI.hbox(8, [UI.icon(Data.ui_icon("gold"), 26), _gold]))
	v.add_child(head)
	_body = UI.vbox(16)
	var sc := UI.scroll(_body)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	refresh()


func refresh() -> void:
	var s := Game.state
	if s.is_empty():
		return
	UI.clear(_body)
	var best := Market.best_grade(s)
	if grade < 0 or grade > best:
		grade = best
	var f: Dictionary = Market.stock(s, Game.now_sec()).featured
	if not f.is_empty():
		_body.add_child(_featured_card(f))
	# grade chips: the ones on sale, then the next one locked
	var chips := UI.flow(6, 6)
	chips.add_child(UI.label("Grade", "Dim"))
	var grades := Market.grades()
	for i in grades.size():
		var g: Dictionary = grades[i]
		if i <= best:
			chips.add_child(UI.button("%s · %s+" % [g.name, Data.rarity(int(g.floor)).name], "ChipOn" if i == grade else "Chip", func():
				grade = i
				refresh()))
		elif int(g.minClears) < 99:
			var lock := UI.button("%s · clear %d islands" % [g.name, int(g.minClears)], "Chip", Callable(), Data.ui_icon("lock"))
			lock.disabled = true
			chips.add_child(lock)
			break
	_body.add_child(chips)
	var flow := UI.flow(16, 16)
	for t in Data.type_list:
		flow.add_child(_egg_card(t.id))
	_body.add_child(flow)
	_body.add_child(UI.wrap_label("A market egg holds a random base Aetherling of its type, with fresh traits. Its grade sets the lowest rarity it can be. Market eggs can hatch shiny at the usual chance, but they don't count toward the shiny pity.", "Faint", 760))
	_tick()


func _process(_delta: float) -> void:
	_tick()


func _tick() -> void:
	var s := Game.state
	if s.is_empty():
		return
	_gold.text = F.format_num(float(s.gold))
	var free := 0
	for p in s.pods:
		if p.is_empty():
			free += 1
	_pods.text = "%d of %d pods free" % [free, s.pods.size()]
	if _clock and is_instance_valid(_clock):
		_clock.text = "A new featured egg in %s" % F.format_seconds(Market.window_ends(Game.now_sec()) - Game.now_sec())


## The chance of each rarity as pills in the rarity colours.
func _odds_row(g: int) -> HFlowContainer:
	var row := UI.flow(4, 4)
	var odds := Market.egg_odds(g)
	var total := 0.0
	for w in odds:
		total += float(w)
	for i in odds.size():
		if float(odds[i]) > 0.0:
			row.add_child(UI.chip("%s %d%%" % [Data.rarity(i + 1).name, roundi(float(odds[i]) / total * 100.0)], Data.rarity_color(i + 1), 11))
	return row


func _egg(type_id: String, px: int, shiny := false) -> TextureRect:
	var ic := UI.icon(Data.ui_icon("pods"), px)
	ic.modulate = Color(1.0, 0.95, 0.75) if shiny else Data.type_color(type_id).lightened(0.35)
	ic.pivot_offset = Vector2(px, px) * 0.5
	return ic


func _egg_card(type_id: String) -> Control:
	var s := Game.state
	var owned := type_id in Market.egg_types(s)
	var card := UI.panel("Glass")
	card.custom_minimum_size = Vector2(330, 0)
	var cv := UI.vbox(8)
	card.add_child(cv)
	var h := UI.hbox(14)
	var egg := _egg(type_id, 72)
	h.add_child(egg)
	var tv := UI.vbox(4)
	tv.add_child(UI.label("%s egg" % Data.types[type_id].name, "H2", Data.type_color(type_id).lightened(0.3)))
	var badge := UI.type_badge(type_id, true)
	badge.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	tv.add_child(badge)
	var mates := UI.hbox(2)
	for sp in Market.base_species(type_id):
		var por := CreaturePortrait.make(sp, 1, 1, false, 34)
		por.bob = false
		por.tooltip_text = Data.species[sp].name
		mates.add_child(por)
	tv.add_child(mates)
	h.add_child(tv)
	cv.add_child(h)
	if not owned:
		cv.add_child(UI.hbox(6, [UI.icon(Data.ui_icon("lock"), 16), UI.label("Own a %s Aetherling first" % Data.types[type_id].name, "Faint")]))
		card.modulate.a = 0.5
		return card
	var g: Dictionary = Market.grades()[grade]
	cv.add_child(_odds_row(grade))
	cv.add_child(UI.stat_line("time", "Hatches in %s" % F.format_seconds(float(g.minutes) * 60.0)))
	var price := Market.egg_price(grade)
	var row := UI.hbox(8, [UI.amount("gold", price, price, 20), UI.spacer()])
	var err := Market.egg_check(s, type_id, grade)
	var b := UI.button("Buy egg", "Gold", func(): Game.buy_egg(type_id, grade))
	b.disabled = err != ""
	b.tooltip_text = err
	row.add_child(b)
	cv.add_child(row)
	return card


## The featured egg: a named Aetherling, a grade up, with the flashy frame while it's still for sale.
func _featured_card(f: Dictionary) -> Control:
	var s := Game.state
	var card := PanelContainer.new()
	var sb := ThemeFactory.box(Color(0.12, 0.08, 0.2, 0.92), 14, 0, Palette.LINE, 0)
	for side in ["left", "right"]:
		sb.set("content_margin_" + side, 22)
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", sb)
	var h := UI.hbox(20)
	card.add_child(h)
	var egg := _egg(f.type, 96)
	h.add_child(egg)
	var sold := int(f.left) <= 0
	if not sold and not Options.values.get("reduce_motion", false):
		var tw := egg.create_tween().set_loops()
		tw.tween_property(egg, "rotation", 0.08, 0.35).set_trans(Tween.TRANS_SINE)
		tw.tween_property(egg, "rotation", -0.08, 0.7).set_trans(Tween.TRANS_SINE)
		tw.tween_property(egg, "rotation", 0.0, 0.35).set_trans(Tween.TRANS_SINE)
		tw.tween_interval(1.2)
	var por := CreaturePortrait.make(f.species, 1, int(Market.grades()[int(f.grade)].floor), false, 72)
	h.add_child(por)
	var tv := UI.vbox(4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.hbox(8, [UI.chip("FEATURED", Palette.GOLD, 12), UI.chip("1 only", Palette.AETHER, 12)]))
	var g: Dictionary = Market.grades()[int(f.grade)]
	tv.add_child(UI.label("A %s %s egg" % [g.name, Data.species[f.species].name], "H2", Palette.GOLD))
	tv.add_child(UI.wrap_label("Holds a %s for certain, %s or rarer." % [Data.species[f.species].name, Data.rarity(int(g.floor)).name], "Dim", 420))
	tv.add_child(_odds_row(int(f.grade)))
	_clock = UI.label("", "Faint", Palette.GOLD)
	tv.add_child(_clock)
	h.add_child(tv)
	var bv := UI.vbox(8)
	bv.alignment = BoxContainer.ALIGNMENT_CENTER
	bv.add_child(UI.amount("gold", float(f.gold), float(f.gold), 24))
	var b := UI.button("Snapped up" if sold else "Buy now", "Gold", func(): Game.buy_featured_egg())
	b.custom_minimum_size.x = 160
	b.disabled = sold or float(s.gold) < float(f.gold) or Breeding.free_pod(s) < 0
	if Breeding.free_pod(s) < 0 and not sold:
		b.tooltip_text = "Every Genesis Pod is busy."
	bv.add_child(b)
	h.add_child(bv)
	if sold:
		card.modulate.a = 0.55
		return card
	return ShineFrame.wrap(card, 14)
