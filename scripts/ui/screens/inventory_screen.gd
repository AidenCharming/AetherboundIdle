class_name InventoryScreen
extends Control
## Inventory: every item by category, with selling (one item or in bulk), item locks, shattering Aether
## Crystals, and buying more of anything the Market stocks.

static var selected := ""
static var category := ""

const CATEGORIES := [["", "Everything"], ["log", "Logs"], ["herb", "Herbs"], ["ore", "Ores & gems"], ["fish", "Fish"],
	["salvage", "Salvage"], ["bar", "Bars"], ["meal", "Meals"], ["component", "Components"], ["thread", "Threads"],
	["vessel", "Vessels"], ["part", "Parts"], ["rare", "Rare finds"], ["treasure", "Treasure"]]

var _grid: HFlowContainer
var _detail: VBoxContainer
var _cats: HFlowContainer
var _worth: HBoxContainer
var _treasure: Button


func _ready() -> void:
	var row := UI.hbox(18)
	var m := UI.margin(row, 26, 10, 26, 20)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var left := UI.vbox(12)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var head := UI.hbox(10)
	head.add_child(UI.header("Inventory", "Sell what you don't need. Keep what the next tier needs.", Data.ui_icon("inventory")))
	head.add_child(UI.spacer())
	# the worth on top, the two ways to sell many at once under it
	var sells := UI.vbox(6)
	_worth = UI.hbox(6)
	_worth.alignment = BoxContainer.ALIGNMENT_END
	sells.add_child(_worth)
	_treasure = UI.button("Sell treasure", "", _sell_treasure, Data.ui_icon("gold"))
	_treasure.tooltip_text = "Sell every finding that no recipe, build or pod uses (locked ones stay)."
	sells.add_child(UI.hbox(8, [_treasure, UI.button("Sell in bulk…", "Gold", _bulk_sell, Data.ui_icon("gold"))]))
	head.add_child(sells)
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
	right.add_child(_market_links())
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
		b.custom_minimum_size = Vector2(112, 128)
		b.tooltip_text = it.name
		b.pressed.connect(func():
			selected = it.id
			refresh())
		var v := UI.vbox(2)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_top = 16
		v.offset_bottom = -6
		v.add_theme_constant_override("separation", 4)
		var ic := UI.icon(Data.item_icon(it.id), 58)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(ic)
		if Market.is_locked(s, it.id):
			var lk := UI.icon(Data.ui_icon("lock"), 18)
			lk.position = Vector2(86, 6)
			lk.mouse_filter = Control.MOUSE_FILTER_IGNORE
			b.add_child(lk)
		# the name: bright, bold and allowed two lines, so "Verdant Seedcache" isn't cut to "Verdant Seedcac…"
		var name_lbl := UI.label(it.name, "", Palette.TEXT if it.id == selected else Palette.TEXT_DIM.lightened(0.15))
		name_lbl.add_theme_font_override("font", ThemeFactory.bold_font())
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_constant_override("line_spacing", -2)
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_lbl.max_lines_visible = 2
		name_lbl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_lbl.custom_minimum_size = Vector2(100, 40)
		v.add_child(name_lbl)
		b.add_child(v)
		# how many, as a pill on the top-left corner of the tile
		var count := UI.chip(F.format_num(n), Palette.GOLD if it.category in ["rare", "treasure"] else Palette.AETHER, 12)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		count.position = Vector2(6, 6)
		b.add_child(count)
		_grid.add_child(b)
	if not any:
		_grid.add_child(UI.label("Nothing here yet.", "Dim"))
	var tv := Market.bulk_value(Market.treasure_candidates(s))
	_treasure.text = "Sell treasure (+%s)" % F.format_num(tv) if tv > 0 else "Sell treasure"
	_treasure.disabled = tv <= 0
	UI.clear(_worth)
	_worth.add_child(UI.label("Everything would sell for", "Dim"))
	_worth.add_child(UI.amount("gold", worth, -1, 20))


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
	hv.add_child(UI.hbox(6, [UI.chip("Tier %d" % int(it.tier), Palette.AETHER, 12), UI.chip(it.category.capitalize(), Palette.AETHER_DEEP.lightened(0.3), 12)]))
	hv.add_child(UI.label("You have %s" % F.format_num(n), "Dim"))
	h.add_child(hv)
	h.add_child(UI.spacer())
	var locked := Market.is_locked(s, selected)
	var lock_b := UI.button("Locked" if locked else "Lock", "ChipOn" if locked else "Chip", func(): Game.toggle_item_lock(selected), Data.ui_icon("lock"))
	lock_b.tooltip_text = "Locked items are never sold in bulk."
	lock_b.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	h.add_child(lock_b)
	_detail.add_child(h)
	if it.has("desc"):
		_detail.add_child(UI.wrap_label(it.desc, "Dim"))
	_detail.add_child(_uses_box(selected))
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
	_buy_row(it)
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
	_detail.add_child(UI.hbox(6, [UI.label("Sells for", "Dim"), UI.amount("gold", float(it.sell), -1, 18), UI.label("each", "Dim")]))


## What the item is for: each recipe (with its skill's icon and level), Works build, pod material, or a note that
## it's treasure, only worth its gold.
func _uses_box(id: String) -> Control:
	var v := UI.vbox(4)
	var used := Economy.uses(id)
	if used.is_empty():
		var row := UI.hbox(8, [UI.icon(Data.ui_icon("gold"), 20), UI.wrap_label("Treasure: nothing uses it, so sell it for gold. \"Sell treasure\" sells all of these at once.", "", 300)])
		(row.get_child(1) as Label).add_theme_color_override("font_color", Palette.GOLD)
		v.add_child(row)
		return v
	v.add_child(UI.label("Used for", "Small", Palette.AETHER))
	for u in used:
		var tex: Texture2D = Data.ui_icon("works")
		var line: String = u.name
		match u.kind:
			"recipe":
				tex = Data.ui_icon(u.skill)
				line = "%s · %s Lv %d (needs %d)" % [u.name, Data.skills[u.skill].name, int(u.level), int(u.qty)]
			"upgrade":
				line = "%s · Sanctum Works" % u.name
			"breeding":
				tex = Data.ui_icon("pods")
			"vessel":
				tex = Data.ui_icon("expeditions")
			"meal":
				tex = Data.ui_icon("health")
			"shatter":
				tex = Data.ui_icon("aether")
		v.add_child(UI.hbox(8, [UI.icon(tex, 18), UI.wrap_label(line, "Dim", 300)]))
	return v


func _sell_treasure() -> void:
	var cands := Market.treasure_candidates(Game.state)
	if cands.is_empty():
		return
	var names := cands.keys().map(func(id): return "%d× %s" % [int(cands[id]), Data.item_name(id)])
	Modal.confirm("Sell treasure?", "%s\nfor %s gold. Nothing uses these; locked items stay." % [", ".join(names), F.format_num(Market.bulk_value(cands))],
		"Sell", func(): Game.bulk_sell(cands))


## Buy more of this item from the Market, when it stocks it.
func _buy_row(it: Dictionary) -> void:
	if not Market.sells(it.id):
		return
	var s := Game.state
	var price := Market.buy_price(it.id)
	if not Market.for_sale(s, it.id):
		var need := Market.unlock_clears(it.id)
		_detail.add_child(UI.hbox(6, [UI.icon(Data.ui_icon("lock"), 16), UI.label("The Market stocks it once you clear %s" % Data.zone_list[mini(need, Data.zone_list.size()) - 1].name, "Faint")]))
		return
	var row := UI.hbox(8, [UI.label("Buy", "Dim"), UI.amount("gold", price, price, 18), UI.label("each", "Faint"), UI.spacer()])
	for n in [1, 10, 100]:
		var b := UI.button("+%d" % n, "", func(): Game.market_buy(it.id, n))
		b.disabled = float(s.gold) < price * n
		b.tooltip_text = "%s gold" % F.format_num(price * n)
		row.add_child(b)
	_detail.add_child(row)


## Sell many items at once: this category (or everything but vessels and rare finds), up to a tier, keeping
## some of each. Locked items always stay.
func _bulk_sell() -> void:
	var v := UI.vbox(12)
	var cat_name := "everything (but vessels and rare finds)"
	for pair in CATEGORIES:
		if pair[0] == category and category != "":
			cat_name = pair[1].to_lower()
	v.add_child(UI.wrap_label("Sells %s you have. Locked items always stay: lock one from its detail panel. Choose a category on the page first to sell only that." % cat_name, "Dim", 520))
	var row := UI.hbox(8, [UI.label("Tiers up to", "Dim")])
	var tier_ob := OptionButton.new()
	tier_ob.add_item("Every tier", 0)
	for t in range(1, 11):
		tier_ob.add_item("Tier %d" % t, t)
	row.add_child(tier_ob)
	row.add_child(UI.label("Keep", "Dim"))
	var keep_ob := OptionButton.new()
	var keeps: Array = Market.cfg().bulkSell.keepOptions
	for i in keeps.size():
		keep_ob.add_item("%s of each" % F.format_num(int(keeps[i])) if int(keeps[i]) > 0 else "None", i)
	keep_ob.selected = mini(1, keeps.size() - 1)
	row.add_child(keep_ob)
	v.add_child(row)
	var preview := UI.label("", "H3")
	v.add_child(preview)
	var icons := UI.flow(4, 4)
	v.add_child(icons)
	var box := {}
	var go := UI.button("Sell", "Gold")
	var cands := func() -> Dictionary:
		return Market.bulk_candidates(Game.state, category, tier_ob.get_selected_id(), int(keeps[keep_ob.selected]))
	var upd := func(_i := 0):
		var c: Dictionary = cands.call()
		var n := 0
		for id in c:
			n += int(c[id])
		preview.text = "%s items of %d kinds · %s gold" % [F.format_num(n), c.size(), F.format_num(Market.bulk_value(c))]
		UI.clear(icons)
		for id in c.keys().slice(0, 24):
			var ic := UI.icon(Data.item_icon(id), 28)
			ic.tooltip_text = "%s× %s" % [F.format_num(int(c[id])), Data.item_name(id)]
			icons.add_child(ic)
		go.disabled = c.is_empty()
	tier_ob.item_selected.connect(upd)
	keep_ob.item_selected.connect(upd)
	upd.call()
	go.pressed.connect(func():
		box.m.close()
		Game.bulk_sell(cands.call()))
	v.add_child(go)
	box.m = Modal.open(v, "Sell in bulk", 600)


func _market_links() -> Control:
	var v := UI.vbox(10)
	v.add_child(UI.hbox(8, [UI.icon(Data.ui_icon("market"), 22), UI.label("Market", "H3")]))
	v.add_child(UI.wrap_label("Vessels, materials, boosts, extra work slots and a stock that changes every few hours. Eggs have a market of their own.", "Faint", 320))
	v.add_child(UI.hbox(8, [UI.button("Open the Market", "Gold", func(): Main.go("market"), Data.ui_icon("market")),
		UI.button("Egg Market", "", func(): Main.go("eggmarket"), Data.ui_icon("egg-market"))]))
	return UI.panel("Glass", v)
