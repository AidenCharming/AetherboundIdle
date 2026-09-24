class_name InventoryScreen
extends Control
## Inventory & Market: every item by category, with selling, shattering Aether Crystals, and the
## vessel shop.

static var selected := ""
static var category := ""

const CATEGORIES := [["", "Everything"], ["log", "Logs"], ["herb", "Herbs"], ["ore", "Ores & gems"], ["fish", "Fish"],
	["salvage", "Salvage"], ["bar", "Bars"], ["meal", "Meals"], ["component", "Components"], ["thread", "Threads"],
	["vessel", "Vessels"], ["part", "Parts"], ["rare", "Rare finds"], ["treasure", "Treasure"]]

var _grid: HFlowContainer
var _detail: VBoxContainer
var _cats: HFlowContainer
var _worth: Label


func _ready() -> void:
	var row := UI.hbox(18)
	var m := UI.margin(row, 26, 10, 26, 20)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var left := UI.vbox(12)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var head := UI.hbox(10)
	head.add_child(UI.header("Inventory & Market", "Sell what you don't need. Keep what the next tier needs.", Data.ui_icon("inventory")))
	head.add_child(UI.spacer())
	_worth = UI.label("", "Dim")
	head.add_child(_worth)
	left.add_child(head)
	_cats = UI.flow(6, 6)
	left.add_child(_cats)
	_grid = UI.flow(10, 10)
	left.add_child(UI.scroll(_grid))
	var right := UI.vbox(14)
	right.custom_minimum_size.x = 380
	row.add_child(right)
	var dp := UI.panel("Glass")
	_detail = UI.vbox(10)
	dp.add_child(_detail)
	right.add_child(dp)
	right.add_child(_shop())
	refresh()


func refresh() -> void:
	if Game.state.is_empty():
		return
	UI.clear(_cats)
	for pair in CATEGORIES:
		var b := UI.button(pair[1], "ChipOn" if pair[0] == category else "Chip")
		b.pressed.connect(func():
			category = pair[0]
			refresh())
		_cats.add_child(b)
	_fill_grid()
	_fill_detail()


func _fill_grid() -> void:
	var s := Game.state
	UI.clear(_grid)
	var worth := 0.0
	var any := false
	for it in Data.item_list:
		var n := GameState.count(s, it.id)
		if n <= 0:
			continue
		worth += n * float(it.sell)
		if category != "" and it.category != category:
			continue
		any = true
		var b := UI.button("", "TileOn" if it.id == selected else "Tile")
		b.custom_minimum_size = Vector2(112, 124)
		b.tooltip_text = it.name
		b.pressed.connect(func():
			selected = it.id
			refresh())
		var v := UI.vbox(2)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_top = 10
		v.offset_bottom = -8
		var ic := UI.icon(Data.item_icon(it.id), 58)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		var nl := UI.label(F.format_num(n), "Num")
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(nl)
		var name := UI.label(it.name, "Faint")
		name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name.clip_text = true
		name.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(name)
		b.add_child(v)
		_grid.add_child(b)
	if not any:
		_grid.add_child(UI.label("Nothing here yet.", "Dim"))
	_worth.text = "Everything would sell for %s gold" % F.format_num(worth)


func _fill_detail() -> void:
	var s := Game.state
	UI.clear(_detail)
	if selected == "" or not Data.items.has(selected) or GameState.count(s, selected) <= 0:
		_detail.add_child(UI.label("Choose an item.", "Dim"))
		return
	var it: Dictionary = Data.items[selected]
	var n := int(GameState.count(s, selected))
	var h := UI.hbox(14)
	h.add_child(UI.icon(Data.item_icon(selected), 84))
	var hv := UI.vbox(2)
	hv.add_child(UI.label(it.name, "H2"))
	hv.add_child(UI.label("Tier %d · %s" % [int(it.tier), it.category.capitalize()], "Faint"))
	hv.add_child(UI.label("You have %s" % F.format_num(n), "Dim"))
	h.add_child(hv)
	_detail.add_child(h)
	if it.has("desc"):
		_detail.add_child(UI.wrap_label(it.desc, "Dim"))
	if it.has("element"):
		_detail.add_child(UI.wrap_label("Breeding material for %s Aetherlings (tier %d)." % [Data.types[it.element].name, int(it.tier)], "Faint"))
	var uses := []
	for skill in Data.skill_list:
		for a in skill.actions:
			if a.get("inputs", {}).has(selected):
				uses.append("%s (%s)" % [a.name, skill.name])
	if not uses.is_empty():
		_detail.add_child(UI.wrap_label("Used in: " + ", ".join(uses), "Faint"))
	if it.has("vessel"):
		var line := []
		for r in [1, 3, 5, 7]:
			line.append("%s %s" % [Data.rarity(r).name, F.pct(Expedition.bind_chance(s, selected, r, []))])
		_detail.add_child(UI.wrap_label("Bind chance: " + " · ".join(line), "Faint"))
	_detail.add_child(UI.sep())
	if it.has("aether"):
		var row := UI.hbox(8)
		row.add_child(UI.button("Shatter 1", "Primary", func(): Game.shatter(selected, 1)))
		row.add_child(UI.button("Shatter all (+%s Aether)" % F.format_num(float(it.aether) * n), "", func(): Game.shatter(selected, n)))
		_detail.add_child(row)
		return
	if int(it.sell) <= 0:
		return
	var qty := SpinBox.new()
	qty.min_value = 1
	qty.max_value = n
	qty.value = n
	qty.custom_minimum_size.x = 120
	var price := UI.label("", "Num", Palette.GOLD)
	var upd := func(v: float): price.text = "= %s gold" % F.format_num(float(it.sell) * v)
	upd.call(qty.value)
	qty.value_changed.connect(upd)
	_detail.add_child(UI.hbox(10, [UI.label("Sell", "Dim"), qty, price]))
	var row2 := UI.hbox(8)
	row2.add_child(UI.button("Sell", "Gold", func(): Game.sell(selected, int(qty.value))))
	row2.add_child(UI.button("Sell all but 10", "", func(): Game.sell(selected, maxi(0, n - 10))))
	_detail.add_child(row2)
	_detail.add_child(UI.label("%d gold each" % int(it.sell), "Faint"))


func _shop() -> Control:
	var v := UI.vbox(10)
	v.add_child(UI.hbox(8, [UI.icon(Data.ui_icon("gold"), 22), UI.label("Market", "H3")]))
	v.add_child(UI.wrap_label("The travelling tinker always has basic vessels, so you're never stuck.", "Faint"))
	for offer in Data.tuning.shop.vessels:
		var it: Dictionary = Data.items[offer.item]
		var h := UI.hbox(10)
		h.add_child(UI.icon(Data.item_icon(it.id), 40))
		var tv := UI.vbox(0)
		tv.add_child(UI.label(it.name, "H3"))
		tv.add_child(UI.amount("gold", float(offer.gold), float(offer.gold), 18))
		h.add_child(tv)
		h.add_child(UI.spacer())
		h.add_child(UI.button("Buy 1", "", func(): Game.buy_vessel(it.id, 1)))
		h.add_child(UI.button("Buy 5", "Gold", func(): Game.buy_vessel(it.id, 5)))
		v.add_child(h)
	return UI.panel("Glass", v)
