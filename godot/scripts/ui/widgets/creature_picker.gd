class_name CreaturePicker
extends VBoxContainer
## Choose a creature: a filterable, sortable grid in a modal. `filter` decides who is listed, `note`
## (optional) gives the small line under each card, e.g. the speed they would work at.

var _filter: Callable
var _note: Callable
var _on_pick: Callable
var _grid: HFlowContainer
var _sort := "best"
var _modal: Modal
var _search: LineEdit
var _exclude_busy := false
var _busy_btn: Button


static func pick(title: String, filter: Callable, on_pick: Callable, note: Callable = Callable(), sort := "best") -> Modal:
	var p := CreaturePicker.new()
	p._filter = filter
	p._note = note
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
	for pair in [["best", "Best fit"], ["rarity", "Rarity"], ["level", "Level"], ["name", "Name"]]:
		var b := UI.button(pair[1], "ChipOn" if _sort == pair[0] else "Chip")
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
		var note: String = _note.call(c) if _note.is_valid() else ""
		var card := CreatureCard.make(c, false, note)
		card.picked.connect(func(id):
			_on_pick.call(id)
			_modal.close())
		_grid.add_child(card)
