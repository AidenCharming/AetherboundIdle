class_name CreaturePicker
extends VBoxContainer
## Choose a creature: a filterable, sortable grid in a modal. `filter` decides who is listed, `note`
## (optional) gives the small line under each card, e.g. the speed they would work at. `sorts` (optional)
## replaces the "Best fit" button with the caller's own rankings.

var _filter: Callable
var _note: Callable
var _perks: Callable
var _sorts: Array = []   # [{id, label, tip, key: Callable(c) -> float (higher first), note: Callable(c) -> String}]
var _on_pick: Callable
var _grid: HFlowContainer
var _sort := "best"
var _modal: Modal
var _search: LineEdit
var _exclude_busy := false
var _busy_btn: Button


## `perks` (optional) returns lines of what a creature brings to this job, listed on its card.
static func pick(title: String, filter: Callable, on_pick: Callable, note: Callable = Callable(), sort := "best",
		perks: Callable = Callable(), sorts: Array = []) -> Modal:
	var p := CreaturePicker.new()
	p._filter = filter
	p._note = note
	p._perks = perks
	p._sorts = sorts
	p._on_pick = on_pick
	p._sort = sort
	p._build()
	p._modal = Modal.open(p, title, 980)
	return p._modal


func _build() -> void:
	add_theme_constant_override("separation", 12)
	custom_minimum_size = Vector2(920, 560)
	var bar := UI.hbox(8)
	_search = LineEdit.new()
	_search.placeholder_text = "Search by name…"
	_search.custom_minimum_size.x = 240
	_search.text_changed.connect(func(_t): _fill())
	bar.add_child(_search)
	var chips: Array = [["best", "Best fit", ""]] if _sorts.is_empty() else _sorts.map(func(o): return [o.id, o.label, o.get("tip", "")])
	chips.append_array([["rarity", "Rarity", ""], ["level", "Level", ""], ["name", "Name", ""]])
	for pair in chips:
		var b := UI.button(pair[1], "ChipOn" if _sort == pair[0] else "Chip")
		b.tooltip_text = pair[2]
		b.pressed.connect(func():
			_sort = pair[0]
			for sib in bar.get_children():
				if sib is Button and sib != _busy_btn:
					sib.theme_type_variation = "Chip"
			b.theme_type_variation = "ChipOn"
			_fill())
		bar.add_child(b)
	bar.add_child(UI.spacer())
	_busy_btn = UI.button("Hide busy", "Chip")
	_busy_btn.pressed.connect(func():
		_exclude_busy = not _exclude_busy
		_busy_btn.theme_type_variation = "ChipOn" if _exclude_busy else "Chip"
		_fill())
	bar.add_child(_busy_btn)
	add_child(bar)
	_grid = UI.flow(10, 10)
	var sc := UI.scroll(_grid)
	sc.custom_minimum_size.y = 500
	add_child(sc)
	_fill()


func _fill() -> void:
	UI.clear(_grid)
	CreatureCard.refresh_perched()
	var list: Array = Game.state.creatures.values().filter(func(c): return _filter.call(c))
	var q := _search.text.strip_edges().to_lower()
	if q != "":
		list = list.filter(func(c): return q in Creatures.display_name(c).to_lower() or q in Data.species[c.species].name.to_lower())
	if _exclude_busy:
		list = list.filter(func(c): return Creatures.is_benched(c))
	var custom := _custom_sort()
	if not custom.is_empty():
		var key: Callable = custom.key
		var keyed := list.map(func(c): return [float(key.call(c)), int(c.level), c])
		keyed.sort_custom(func(a, b): return [a[0], a[1]] > [b[0], b[1]])
		list = keyed.map(func(k): return k[2])
	else:
		match _sort:
			"rarity":
				list.sort_custom(func(a, b): return [int(a.rarity), int(a.level)] > [int(b.rarity), int(b.level)])
			"level":
				list.sort_custom(func(a, b): return int(a.level) > int(b.level))
			"name":
				list.sort_custom(func(a, b): return Creatures.display_name(a) < Creatures.display_name(b))
			_:
				list.sort_custom(func(a, b): return Creatures.power_rating(a) + int(a.rarity) * 5 > Creatures.power_rating(b) + int(b.rarity) * 5)
	if list.is_empty():
		_grid.add_child(UI.label("No Aetherling fits here yet.", "Dim"))
		return
	for c in list:
		var note: String = ""
		if custom.has("note"):
			note = custom.note.call(c)
		elif _note.is_valid():
			note = _note.call(c)
		var card := CreatureCard.make(c, false, note)
		if _perks.is_valid():
			card.add_perks(_perks.call(c))
		card.picked.connect(func(id):
			_on_pick.call(id)
			_modal.close())
		_grid.add_child(card)


func _custom_sort() -> Dictionary:
	for o in _sorts:
		if o.id == _sort:
			return o
	return {}
