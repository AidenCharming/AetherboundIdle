extends Control
## The Nexus: every Aetherling the player owns, with filters and sorting, and a detail panel for the
## selected one (stats, traits, ability, jobs, rename, lock, attunement, release).

var selected := ""
var _grid: HFlowContainer
var _detail: VBoxContainer
var _filter_type := ""
var _filter_status := ""
var _sort := "rarity"
var _search: LineEdit
var _count: Label
var _type_row: HFlowContainer
var _status_row: HFlowContainer
var _sort_row: HFlowContainer
var _xp_bar: ProgressBar


func setup(arg: String) -> void:
	selected = arg


func _ready() -> void:
	var row := UI.hbox(18)
	var m := UI.margin(row, 26, 10, 26, 20)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var left := UI.vbox(12)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var head := UI.hbox(12)
	head.add_child(UI.header("Nexus", "Every Aetherling you have. Resting ones sit on the perches and gather Aether.", Data.ui_icon("nexus")))
	head.add_child(UI.spacer())
	_count = UI.label("", "Dim")
	head.add_child(_count)
	left.add_child(head)
	var filters := UI.panel("CardFlat")
	var fv := UI.vbox(8)
	filters.add_child(fv)
	_type_row = UI.flow(6, 6)
	fv.add_child(_type_row)
	_status_row = UI.flow(6, 6)
	fv.add_child(_status_row)
	_sort_row = UI.flow(6, 6)
	fv.add_child(_sort_row)
	_search = LineEdit.new()
	_search.placeholder_text = "Search…"
	_search.custom_minimum_size.x = 180
	_search.text_changed.connect(func(_t): _fill_grid())
	_type_row.add_child(_search)
	_chip(_type_row, "All types", "", "type")
	for t in Data.type_list:
		_chip(_type_row, t.name, t.id, "type")
	for pair in [["All", ""], ["Working", "skill"], ["Expedition", "party"], ["Resting", "rest"], ["Shiny", "shiny"], ["Locked", "locked"]]:
		_chip(_status_row, pair[0], pair[1], "status")
	_sort_row.add_child(UI.label("Sort by", "Faint"))
	for pair in [["Rarity", "rarity"], ["Level", "level"], ["Species", "species"], ["Newest", "new"], ["Power", "power"]]:
		_chip(_sort_row, pair[0], pair[1], "sort")
	left.add_child(filters)
	_grid = UI.flow(12, 12)
	left.add_child(UI.scroll(_grid))
	var dp := UI.panel("Glass")
	dp.custom_minimum_size.x = 430
	_detail = UI.vbox(10)
	dp.add_child(UI.scroll(_detail))
	row.add_child(dp)
	refresh()


func _chip(parent: Container, text: String, value: String, group: String) -> void:
	var b := UI.button(text, "Chip")
	b.set_meta("group", group)
	b.set_meta("value", value)
	b.pressed.connect(func():
		match group:
			"type":
				_filter_type = value
			"status":
				_filter_status = value
			"sort":
				_sort = value
		_update_chips()
		_fill_grid())
	parent.add_child(b)


func _update_chips() -> void:
	for row in [_type_row, _status_row, _sort_row]:
		for b in row.get_children():
			if not (b is Button):
				continue
			var cur: String = {"type": _filter_type, "status": _filter_status, "sort": _sort}[b.get_meta("group")]
			b.theme_type_variation = "ChipOn" if b.get_meta("value") == cur else "Chip"


func refresh() -> void:
	if Game.state.is_empty():
		return
	if selected != "" and GameState.creature(Game.state, selected).is_empty():
		selected = ""
	if selected == "" and not Game.state.creatures.is_empty():
		selected = _sorted_list()[0].id if not _sorted_list().is_empty() else ""
	_update_chips()
	_fill_grid()
	_fill_detail()


func _sorted_list() -> Array:
	var list: Array = Game.state.creatures.values()
	if _filter_type != "":
		list = list.filter(func(c): return _filter_type in Creatures.types_of(c))
	match _filter_status:
		"skill", "party":
			list = list.filter(func(c): return Creatures.job_kind(c) == _filter_status)
		"rest":
			list = list.filter(func(c): return Creatures.is_benched(c))
		"shiny":
			list = list.filter(func(c): return c.shiny)
		"locked":
			list = list.filter(func(c): return c.get("locked", false))
	var q := _search.text.strip_edges().to_lower() if _search else ""
	if q != "":
		list = list.filter(func(c): return q in Creatures.display_name(c).to_lower() or q in Data.species[c.species].name.to_lower())
	match _sort:
		"level":
			list.sort_custom(func(a, b): return int(a.level) > int(b.level) if a.level != b.level else int(a.rarity) > int(b.rarity))
		"species":
			list.sort_custom(func(a, b): return Data.species_list.find(Data.species[a.species]) < Data.species_list.find(Data.species[b.species]))
		"new":
			list.sort_custom(func(a, b): return int(a.id.substr(1)) > int(b.id.substr(1)))
		"power":
			list.sort_custom(func(a, b): return Creatures.power_rating(a) > Creatures.power_rating(b))
		_:
			list.sort_custom(func(a, b): return [int(a.rarity), int(a.level)] > [int(b.rarity), int(b.level)])
	return list


func _fill_grid() -> void:
	UI.clear(_grid)
	CreatureCard.refresh_perched()
	var list := _sorted_list()
	_count.text = "%d of %d shown · %s Aether/min" % [list.size(), Game.state.creatures.size(), F.format_num(Economy.aether_per_min(Game.state))]
	for c in list:
		var card := CreatureCard.make(c, c.id == selected)
		card.picked.connect(func(id):
			selected = id
			for other in _grid.get_children():
				if other is CreatureCard:
					other.theme_type_variation = "TileOn" if other.cid == id else "Tile"
			_fill_detail())
		_grid.add_child(card)


# ---------------------------------------------------------------- detail panel

func _fill_detail() -> void:
	UI.clear(_detail)
	var c := GameState.creature(Game.state, selected)
	if c.is_empty():
		_detail.add_child(UI.label("Choose an Aetherling.", "Dim"))
		return
	var sp: Dictionary = Data.species[c.species]
	var form := Creatures.form_of(c)
	var por := CreaturePortrait.of(c, 230)
	por.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_detail.add_child(por)
	var name_row := UI.hbox(8)
	name_row.alignment = BoxContainer.ALIGNMENT_CENTER
	name_row.add_child(UI.label(Creatures.display_name(c), "H1"))
	var rn := UI.button("Rename", "Ghost", func(): _rename(c))
	name_row.add_child(rn)
	_detail.add_child(name_row)
	var sub := "%s · Form %d of 3" % [sp.name, form] if c.get("nick", "") == "" else "%s (%s) · Form %d of 3" % [Data.form_name(c.species, form), sp.name, form]
	var sl := UI.label(sub, "Dim")
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail.add_child(sl)
	var badges := UI.hbox(6)
	badges.alignment = BoxContainer.ALIGNMENT_CENTER
	badges.add_child(UI.rarity_badge(int(c.rarity)))
	for t in sp.types:
		badges.add_child(UI.type_badge(t))
	if c.shiny:
		badges.add_child(UI.badge("SHINY", Palette.GOLD))
	if sp.kind == "special":
		badges.add_child(UI.badge("SECRET RECIPE", Palette.AETHER))
	_detail.add_child(badges)
	var desc: String = sp.forms[form - 1].get("desc", "")
	if desc != "":
		var dl := UI.wrap_label(desc, "Faint")
		dl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_detail.add_child(dl)
	# level
	var lv := UI.hbox(10)
	lv.add_child(UI.label("Level %d" % int(c.level), "H3"))
	_xp_bar = UI.bar(Palette.AETHER, 8)
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_xp_bar.value = F.level_progress(F.creature_curve(), float(c.xp), Data.tuning.creature.maxLevel)
	lv.add_child(_xp_bar)
	var levels: Array = Data.tuning.creature.formLevels
	if form < 3:
		lv.add_child(UI.label("Evolves at %d" % int(levels[form]), "Faint"))
	_detail.add_child(lv)
	# stats
	var st := Creatures.stats(c)
	var sr := UI.hbox(18)
	sr.alignment = BoxContainer.ALIGNMENT_CENTER
	sr.add_child(UI.stat_line("health", F.format_num(st.health), "Health"))
	sr.add_child(UI.stat_line("power", F.format_num(st.power), "Power"))
	sr.add_child(UI.stat_line("guard", F.format_num(st.guard), "Guard"))
	sr.add_child(UI.label("Leans %s" % sp.statLean.capitalize(), "Faint"))
	_detail.add_child(UI.panel("Inset", sr))
	# jobs
	_detail.add_child(UI.label("Work", "H3"))
	var wk := UI.vbox(4)
	wk.add_child(UI.stat_line(sp.primarySkill, "Specialist: %s" % Data.skills[sp.primarySkill].name, "Works fastest here"))
	wk.add_child(UI.stat_line(sp.secondaryAptitude, "Knack for %s (+%s speed)" % [Data.skills[sp.secondaryAptitude].name, F.pct(Data.tuning.skills.secondaryAptitudeBonus)]))
	var can := Data.skill_list.filter(func(sk): return Creatures.can_work(c, sk.id)).map(func(sk): return sk.name)
	wk.add_child(UI.wrap_label("Can work: " + ", ".join(can), "Faint"))
	wk.add_child(UI.label("Status: " + CreatureCard.status_text(c), "Dim"))
	_detail.add_child(wk)
	var actions := UI.flow(8, 8)
	var assign := MenuButton.new()
	assign.text = "Put to work"
	assign.theme_type_variation = "Primary"
	assign.flat = false
	assign.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var pm := assign.get_popup()
	var eligible := Data.skill_list.filter(func(sk): return Creatures.can_work(c, sk.id))
	for i in eligible.size():
		var sk: Dictionary = eligible[i]
		pm.add_icon_item(Data.ui_icon(sk.id), "%s  (%d/%d slots)" % [sk.name, GameState.workers(Game.state, sk.id).size(), GameState.slot_count(Game.state, sk.id)], i)
	pm.id_pressed.connect(func(i): Game.assign(c.id, eligible[i].id))
	actions.add_child(assign)
	if Creatures.job_kind(c) != "party":
		actions.add_child(UI.button("Join the party", "", func(): _join_party(c)))
	if not Creatures.is_benched(c):
		actions.add_child(UI.button("Rest", "", func(): Game.bench(c.id)))
	actions.add_child(UI.button("Unlock" if c.get("locked", false) else "Lock", "", func(): Game.toggle_lock(c.id), Data.ui_icon("lock")))
	_detail.add_child(actions)
	# ability
	var ab: Dictionary = Data.abilities[sp.ability]
	_detail.add_child(UI.label("Ability", "H3"))
	_detail.add_child(UI.rich("[b]%s[/b] · %s\n%s" % [ab.name, ab.tempo.capitalize(), Describe.ability(ab)]))
	# traits
	_detail.add_child(UI.label("Traits", "H3"))
	var sig: Dictionary = Data.traits[sp.signatureTrait]
	_detail.add_child(UI.rich("[b]%s[/b] [color=#7ae8ff](signature)[/color]\n%s" % [sig.name, Traits.describe(sig.id, sig.strength)]))
	if c.traits.is_empty():
		_detail.add_child(UI.label("No pool traits yet. Attunement can roll some.", "Faint"))
	for t in c.traits:
		var tr: Dictionary = Data.traits[t.id]
		var col: String = {"minor": "#a9aed6", "moderate": "#62b6ff", "major": "#ffd166"}[t.s]
		_detail.add_child(UI.rich("[b]%s[/b] [color=%s](%s)[/color]\n%s" % [tr.name, col, t.s.capitalize(), Traits.describe(t.id, t.s)]))
	var bottom := UI.hbox(8)
	bottom.add_child(UI.button("Attune traits", "", func(): _attune(c)))
	bottom.add_child(UI.spacer())
	bottom.add_child(UI.button("Release (+%d Aether)" % Creatures.release_value(c), "Danger", func(): _release(c)))
	_detail.add_child(UI.sep())
	_detail.add_child(bottom)


func _join_party(c: Dictionary) -> void:
	var party: Array = Game.state.expedition.party
	var size: int = Data.tuning.combat.partySize
	if party.size() >= size:
		Game.warn("The party is full (%d). Swap someone out on the Expeditions screen." % size)
		return
	Game.set_party(party.size(), c.id)
	Game.info("%s joined the expedition party" % Creatures.display_name(c))


func _rename(c: Dictionary) -> void:
	var v := UI.vbox(12)
	var le := LineEdit.new()
	le.text = c.get("nick", "")
	le.placeholder_text = Data.form_name(c.species, Creatures.form_of(c))
	le.max_length = 20
	v.add_child(le)
	var m: Modal
	var row := UI.hbox(8)
	row.add_child(UI.button("Clear nickname", "Ghost", func():
		Game.rename(c.id, "")
		m.close()))
	row.add_child(UI.spacer())
	row.add_child(UI.button("Save", "Primary", func():
		Game.rename(c.id, le.text)
		m.close()))
	v.add_child(row)
	le.text_submitted.connect(func(t):
		Game.rename(c.id, t)
		m.close())
	m = Modal.open(v, "Nickname", 420)
	le.grab_focus.call_deferred()


func _release(c: Dictionary) -> void:
	if c.get("locked", false):
		Game.warn("Unlock it first.")
		return
	Modal.confirm("Release %s?" % Creatures.display_name(c), "It returns to the wild and leaves %d Aether behind. This cannot be undone." % Creatures.release_value(c),
		"Release", func():
			Game.release(c.id)
			selected = "", true)


func _attune(c: Dictionary) -> void:
	var v := UI.vbox(12)
	var locks := {}
	var m: Modal
	var body := UI.vbox(8)
	v.add_child(UI.wrap_label("Attunement rerolls this Aetherling's pool traits with Aether. Lock up to two traits to keep them; each lock triples the cost. The signature trait never changes.", "Dim", 520))
	v.add_child(body)
	var fill := func(fill_ref: Callable) -> void:
		UI.clear(body)
		var cr := GameState.creature(Game.state, c.id)
		if cr.traits.is_empty():
			body.add_child(UI.label("No pool traits yet.", "Faint"))
		for t in cr.traits:
			var tr: Dictionary = Data.traits[t.id]
			var cb := CheckButton.new()
			cb.text = "%s (%s): %s" % [tr.name, t.s.capitalize(), Traits.describe(t.id, t.s)]
			cb.button_pressed = locks.has(t.id)
			cb.toggled.connect(func(on):
				if on:
					if locks.size() >= int(Data.tuning.attunement.maxLocks):
						cb.set_pressed_no_signal(false)
						Game.warn("Two locks at most.")
						return
					locks[t.id] = true
				else:
					locks.erase(t.id)
				fill_ref.call(fill_ref))
			body.add_child(cb)
		var cost := Traits.attune_cost(cr, locks.size())
		var row := UI.hbox(10)
		row.add_child(UI.label("Cost", "Faint"))
		row.add_child(UI.amount("aether", cost, cost))
		row.add_child(UI.spacer())
		row.add_child(UI.button("Attune", "Primary", func():
			if Game.attune(c.id, locks.keys()):
				var now_traits: Array = GameState.creature(Game.state, c.id).traits.map(func(x): return x.id)
				for k in locks.keys():
					if not (k in now_traits):
						locks.erase(k)
				fill_ref.call(fill_ref)))
		body.add_child(row)
	fill.call(fill)
	m = Modal.open(v, "Attune %s" % Creatures.display_name(c), 620)
	m.closed.connect(func(): _fill_detail())
