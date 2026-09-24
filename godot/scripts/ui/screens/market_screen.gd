class_name MarketScreen
extends Control
## The Market: today's stock (it rotates every few hours, sometimes with a rare limited offer), vessels,
## materials, short boosts and extra work slots. Everything sells back for a little less than it costs here.

static var tab := "stock"
static var mat_cat := "log"

const TABS := [["stock", "Today's stock", "market"], ["vessels", "Vessels", "vessel"], ["materials", "Materials", "inventory"],
	["boosts", "Boosts", "boost-brew"], ["slots", "Work slots", "work-slot"]]
const MAT_CATS := [["log", "Logs"], ["herb", "Herbs"], ["ore", "Ores & gems"], ["fish", "Fish"], ["salvage", "Salvage"],
	["bar", "Bars"], ["meal", "Meals"], ["component", "Components"], ["thread", "Threads"], ["part", "Parts"]]

var _tabs: HBoxContainer
var _body: VBoxContainer
var _gold: Label
var _clocks: Array = []   # [{label, fmt}] countdowns to the next stock
var _boost_bars: Array = []   # [{id, bar, label}]


func _ready() -> void:
	var v := UI.vbox(14)
	var m := UI.margin(v, 26, 10, 26, 20)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var head := UI.hbox(12)
	head.add_child(UI.header("Market", "Buy what you need. Everything sells back for a little less, so crafting stays the cheaper way.", Data.ui_icon("market")))
	head.add_child(UI.spacer())
	_gold = UI.label("", "Num", Palette.GOLD)
	_gold.add_theme_font_size_override("font_size", 22)
	head.add_child(UI.hbox(8, [UI.icon(Data.ui_icon("gold"), 26), _gold]))
	v.add_child(head)
	_tabs = UI.hbox(8)
	v.add_child(_tabs)
	_body = UI.vbox(14)
	var sc := UI.scroll(_body)
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(sc)
	if not Game.state.is_empty():
		Market.state(Game.state).seenWindow = Market.window(Game.now_sec())
	refresh()


func refresh() -> void:
	var s := Game.state
	if s.is_empty():
		return
	UI.clear(_tabs)
	for t in TABS:
		var b := UI.button(t[1], "ChipOn" if tab == t[0] else "Chip", func():
			tab = t[0]
			refresh(), Data.ui_icon(t[2]))
		if t[0] == "stock" and Market.has_limited(s, Game.now_sec()):
			b.text += "  ✦"
			b.add_theme_color_override("font_color", Palette.GOLD)
		_tabs.add_child(b)
	UI.clear(_body)
	_clocks.clear()
	_boost_bars.clear()
	match tab:
		"stock":
			_fill_stock()
		"vessels":
			_fill_wares(Market.catalog("vessel"), [1, 10, 100])
		"materials":
			var cats := UI.flow(6, 6)
			for c in MAT_CATS:
				cats.add_child(UI.button(c[1], "ChipOn" if mat_cat == c[0] else "Chip", func():
					mat_cat = c[0]
					refresh()))
			_body.add_child(cats)
			_fill_wares(Market.catalog(mat_cat), [10, 100, 1000])
		"boosts":
			_fill_boosts()
		"slots":
			_fill_slots()
	_tick()


func _process(_delta: float) -> void:
	_tick()


func _tick() -> void:
	var s := Game.state
	if s.is_empty():
		return
	_gold.text = F.format_num(float(s.gold))
	var left := Market.window_ends(Game.now_sec()) - Game.now_sec()
	for c in _clocks:
		if is_instance_valid(c.label):
			c.label.text = c.fmt % F.format_seconds(left)
	if left <= 0.5:
		refresh.call_deferred()
	for bb in _boost_bars:
		var secs := Market.boost_left(s, bb.id)
		bb.bar.value = secs / (float(Market.cfg().boosts.maxHours) * 3600.0) * 100.0
		bb.label.text = "%s left" % F.format_seconds(secs) if secs > 0.0 else "Not running"


# ---------------------------------------------------------------- today's stock

func _fill_stock() -> void:
	var s := Game.state
	var st := Market.stock(s, Game.now_sec())
	var clock := UI.label("", "Dim")
	_clocks.append({"label": clock, "fmt": "New stock in %s"})
	_body.add_child(UI.hbox(8, [UI.icon(Data.ui_icon("time"), 20), clock]))
	var flow := UI.flow(16, 16)
	for i in st.offers.size():
		var o: Dictionary = st.offers[i]
		if o.get("limited", false):
			_body.add_child(_limited_card(o, i))
		else:
			flow.add_child(_offer_card(o, i))
	_body.add_child(flow)
	_body.add_child(UI.wrap_label("Each offer can be bought a few times until the stock changes. Now and then a rare limited offer turns up: one only, and gone when the stock turns over.", "Faint", 600))


func _offer_icon(o: Dictionary, px: int) -> Control:
	match o.kind:
		"item":
			return UI.icon(Data.item_icon(o.item), px)
		"boost":
			return UI.icon(Data.ui_icon(Market.boost_def(o.boost).icon), px)
		"egg":
			var ic := UI.icon(Data.ui_icon("pods"), px)
			ic.modulate = Color(1.0, 0.95, 0.75) if o.get("shiny", false) else Data.type_color(o.type).lightened(0.35)
			return ic
	return UI.icon(Data.ui_icon("market"), px)


func _offer_title(o: Dictionary) -> String:
	match o.kind:
		"item":
			return "%s× %s" % [F.format_num(int(o.qty)), Data.item_name(o.item)]
		"boost":
			return "%s (%d min)" % [Market.boost_def(o.boost).name, int(Market.boost_def(o.boost).minutes)]
		"egg":
			return "%s %s egg" % [Market.grades()[int(o.grade)].name, Data.types[o.type].name]
	return "?"


func _offer_card(o: Dictionary, i: int) -> Control:
	var card := UI.panel("Card")
	card.custom_minimum_size = Vector2(300, 0)
	var cv := UI.vbox(8)
	card.add_child(cv)
	var h := UI.hbox(12)
	h.add_child(_offer_icon(o, 52))
	var tv := UI.vbox(2)
	var title := UI.label(_offer_title(o), "H3")
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = 190
	tv.add_child(title)
	if o.kind == "boost":
		tv.add_child(UI.wrap_label(Market.boost_def(o.boost).desc, "Faint", 190))
	elif o.kind == "item" and o.item == "aether-crystal":
		tv.add_child(UI.label("= %s Aether" % F.format_num(int(o.qty) * float(Data.items[o.item].aether)), "Faint", Palette.AETHER))
	h.add_child(tv)
	cv.add_child(h)
	var row := UI.hbox(8)
	row.add_child(UI.amount("gold", float(o.gold), float(o.gold), 20))
	if float(o.get("discount", 0.0)) > 0.0:
		row.add_child(UI.chip("-%d%%" % roundi(float(o.discount) * 100.0), Palette.GOOD, 12))
	row.add_child(UI.spacer())
	row.add_child(UI.label("%d left" % int(o.left), "Faint"))
	cv.add_child(row)
	var b := UI.button("Buy" if int(o.left) > 0 else "Sold out", "Gold", func(): Game.buy_offer(i))
	b.disabled = int(o.left) <= 0 or float(Game.state.gold) < float(o.gold)
	cv.add_child(b)
	if int(o.left) <= 0:
		card.modulate.a = 0.55
	return card


## A rare limited offer: a wide card with a running rainbow-gold frame and sparkles.
func _limited_card(o: Dictionary, i: int) -> Control:
	var card := PanelContainer.new()
	var sb := ThemeFactory.box(Color(0.16, 0.12, 0.05, 0.92), 14, 0, Palette.LINE, 0)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 16
	sb.content_margin_bottom = 16
	card.add_theme_stylebox_override("panel", sb)
	var h := UI.hbox(18)
	card.add_child(h)
	var ic := _offer_icon(o, 84)
	h.add_child(ic)
	if int(o.left) > 0 and not Options.values.get("reduce_motion", false):
		var tw := ic.create_tween().set_loops()
		ic.pivot_offset = Vector2(42, 42)
		tw.tween_property(ic, "scale", Vector2(1.08, 1.08), 0.7).set_trans(Tween.TRANS_SINE)
		tw.tween_property(ic, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE)
	var tv := UI.vbox(4)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tv.add_child(UI.hbox(8, [UI.chip("LIMITED", Palette.GOLD, 12), UI.chip("1 only", Palette.AETHER, 12)]))
	var name_l := UI.label(o.name, "H2", Palette.GOLD)
	tv.add_child(name_l)
	tv.add_child(UI.wrap_label(_offer_title(o) + " · " + String(o.blurb), "Dim", 420))
	var clock := UI.label("", "Faint", Palette.GOLD)
	_clocks.append({"label": clock, "fmt": "Gone in %s"})
	tv.add_child(clock)
	h.add_child(tv)
	var bv := UI.vbox(8)
	bv.alignment = BoxContainer.ALIGNMENT_CENTER
	bv.add_child(UI.amount("gold", float(o.gold), float(o.gold), 24))
	var b := UI.button("Buy now" if int(o.left) > 0 else "Snapped up", "Gold", func(): Game.buy_offer(i))
	b.custom_minimum_size.x = 160
	b.disabled = int(o.left) <= 0 or float(Game.state.gold) < float(o.gold)
	bv.add_child(b)
	h.add_child(bv)
	if int(o.left) <= 0:
		card.modulate.a = 0.55
		return card
	return ShineFrame.wrap(card, 14)


# ---------------------------------------------------------------- vessels and materials

func _fill_wares(list: Array, amounts: Array) -> void:
	var s := Game.state
	var flow := UI.flow(14, 14)
	for it in list:
		var open := Market.for_sale(s, it.id)
		var card := UI.panel("Card")
		card.custom_minimum_size = Vector2(290, 0)
		var cv := UI.vbox(6)
		card.add_child(cv)
		var h := UI.hbox(10)
		h.add_child(UI.icon(Data.item_icon(it.id), 44))
		var tv := UI.vbox(0)
		tv.add_child(UI.label(it.name, "H3"))
		tv.add_child(UI.label("Tier %d · you have %s" % [int(it.tier), F.format_num(GameState.count(s, it.id))], "Faint"))
		h.add_child(tv)
		cv.add_child(h)
		if it.has("vessel"):
			var chances := UI.flow(4, 4)
			for r in [1, 3, 5, 7, 9]:
				chances.add_child(UI.chip("%s %s" % [Data.rarity(r).name, F.pct(Expedition.bind_chance(s, it.id, r, []))], Data.rarity_color(r), 11))
			cv.add_child(chances)
		if not open:
			var need := Market.unlock_clears(it.id)
			var zone_name: String = Data.zone_list[mini(need, Data.zone_list.size()) - 1].name
			cv.add_child(UI.hbox(6, [UI.icon(Data.ui_icon("lock"), 16), UI.label("Clear %s to stock it" % zone_name, "Faint")]))
			card.modulate.a = 0.5
			flow.add_child(card)
			continue
		var price := Market.buy_price(it.id)
		cv.add_child(UI.hbox(8, [UI.amount("gold", price, price, 18), UI.label("each · sells for %d" % int(it.sell), "Faint")]))
		var row := UI.hbox(6)
		for n in amounts:
			var b := UI.button("Buy %s" % F.format_num(n), "Gold" if n == amounts[0] else "", func(): Game.market_buy(it.id, n))
			b.disabled = float(s.gold) < price * n
			b.tooltip_text = "%s gold" % F.format_num(price * n)
			row.add_child(b)
		cv.add_child(row)
		flow.add_child(card)
	_body.add_child(flow)


# ---------------------------------------------------------------- boosts

func _fill_boosts() -> void:
	var s := Game.state
	_body.add_child(UI.wrap_label("Short boosts start the moment you buy them and keep running while you're away. Buying again adds more time, up to %d hours. Prices grow as the islands open up." % int(Market.cfg().boosts.maxHours), "Dim", 700))
	var flow := UI.flow(16, 16)
	for b in Market.cfg().boosts.list:
		var card := UI.panel("Glass")
		card.custom_minimum_size = Vector2(340, 0)
		var cv := UI.vbox(8)
		card.add_child(cv)
		var h := UI.hbox(12)
		h.add_child(UI.icon(Data.ui_icon(b.icon), 56))
		var tv := UI.vbox(2)
		tv.add_child(UI.label(b.name, "H2"))
		tv.add_child(UI.wrap_label(b.desc, "Dim", 230))
		h.add_child(tv)
		cv.add_child(h)
		var bar := UI.bar(Palette.AETHER, 8)
		cv.add_child(bar)
		var left := UI.label("", "Faint")
		cv.add_child(left)
		_boost_bars.append({"id": b.id, "bar": bar, "label": left})
		var price := Market.boost_price(s, b.id)
		var row := UI.hbox(8, [UI.amount("gold", price, price, 20), UI.spacer()])
		var buy := UI.button("Buy (+%d min)" % int(b.minutes), "Gold", func(): Game.buy_boost(b.id))
		buy.disabled = float(s.gold) < price or Market.boost_full(s, b.id)
		if Market.boost_full(s, b.id):
			buy.tooltip_text = "Already stocked up for %d hours." % int(Market.cfg().boosts.maxHours)
		row.add_child(buy)
		cv.add_child(row)
		flow.add_child(ShineFrame.wrap(card, 16) if Market.boost_left(s, b.id) > 0.0 else card)
	_body.add_child(flow)


# ---------------------------------------------------------------- work slots

func _fill_slots() -> void:
	var s := Game.state
	var need := int(Market.cfg().extraSlots.needLevel)
	_body.add_child(UI.wrap_label("Past the fifth, a skill's work slots are bought, one skill at a time. A skill needs its five slots open (level %d) first." % need, "Dim", 700))
	var flow := UI.flow(14, 14)
	for skill in Data.skill_list:
		var card := UI.panel("Card")
		card.custom_minimum_size = Vector2(330, 0)
		var cv := UI.vbox(6)
		card.add_child(cv)
		var h := UI.hbox(10)
		h.add_child(UI.icon(Data.ui_icon(skill.id), 40))
		var tv := UI.vbox(0)
		tv.add_child(UI.label(skill.name, "H3"))
		tv.add_child(UI.label("Level %d · %d slots (%d bought)" % [int(s.skills[skill.id].level), GameState.slot_count(s, skill.id), Market.extra_slots(s, skill.id)], "Faint"))
		h.add_child(tv)
		cv.add_child(h)
		var price := Market.next_slot_price(s, skill.id)
		if price < 0:
			cv.add_child(UI.label("Every extra slot is open", "H3", Palette.GOOD))
		else:
			var row := UI.hbox(8, [UI.amount("gold", price, price, 20), UI.spacer()])
			var err := Market.slot_check(s, skill.id)
			var b := UI.button("Buy a slot", "Gold", func(): _confirm_slot(skill.id, price))
			b.disabled = err != ""
			b.tooltip_text = err
			row.add_child(b)
			cv.add_child(row)
			if int(s.skills[skill.id].level) < need:
				card.modulate.a = 0.6
		flow.add_child(card)
	_body.add_child(flow)


func _confirm_slot(skill_id: String, price: int) -> void:
	Modal.confirm("Buy a %s slot?" % Data.skills[skill_id].name, "%s gold for one more work slot in %s, for good." % [F.format_num(price), Data.skills[skill_id].name],
		"Buy the slot", func(): Game.buy_slot(skill_id))
