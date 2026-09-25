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
var _count: HBoxContainer
var _filter_bar: HBoxContainer
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
	_count = UI.hbox(6)
	head.add_child(_count)
	head.add_child(UI.button("Bulk release", "", _bulk_release))
	left.add_child(head)
	# search and the three choices on one row (play-test feedback: three rows of chips took a third of the
	# column): type, what it's doing, and the order
	var filters := UI.panel("CardFlat")
	_filter_bar = UI.hbox(8)
	filters.add_child(_filter_bar)
	_search = LineEdit.new()
	_search.placeholder_text = "Search…"
	_search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_search.custom_minimum_size.x = 140
	_search.text_changed.connect(func(_t): _fill_grid())
	_filter_bar.add_child(_search)
	var types := [["All types", ""]]
	for ty in Data.type_list:
		types.append([ty.name, ty.id])
	_dropdown("Type", types, "type")
	_dropdown("Show", [["Everyone", ""], ["Working", "skill"], ["On an expedition", "party"], ["Resting", "rest"], ["Shiny", "shiny"], ["Locked", "locked"]], "status")
	_dropdown("Sort", [["Rarity", "rarity"], ["Level", "level"], ["Species", "species"], ["Newest", "new"], ["Power", "power"]], "sort")
	left.add_child(filters)
	_grid = UI.flow(12, 12)
	left.add_child(UI.scroll(_grid))
	var dp := UI.panel("Glass")
	dp.custom_minimum_size.x = 430
	_detail = UI.vbox(10)
	dp.add_child(UI.scroll(_detail))
	row.add_child(dp)
	refresh()


## One filter as a dropdown: `pairs` are [label, value]; `group` is type, status or sort.
func _dropdown(title: String, pairs: Array, group: String) -> void:
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
	ob.tooltip_text = title
	var cur: String = {"type": _filter_type, "status": _filter_status, "sort": _sort}[group]
	for i in pairs.size():
		ob.add_item(("Sort: " if group == "sort" else "") + pairs[i][0], i)
		if pairs[i][1] == cur:
			ob.selected = i
	ob.item_selected.connect(func(i):
		var value: String = pairs[i][1]
		match group:
			"type":
				_filter_type = value
			"status":
				_filter_status = value
			"sort":
				_sort = value
		_fill_grid())
	_filter_bar.add_child(ob)


func refresh() -> void:
	if Game.state.is_empty():
		return
	if selected != "" and GameState.creature(Game.state, selected).is_empty():
		selected = ""
	if selected == "" and not Game.state.creatures.is_empty():
		selected = _sorted_list()[0].id if not _sorted_list().is_empty() else ""
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
	UI.clear(_count)
	_count.add_child(UI.chip("%d / %d shown" % [list.size(), Game.state.creatures.size()], Palette.TEXT_DIM, 12))
	_count.add_child(UI.chip("+%s Aether/min" % F.format_num(Economy.aether_per_min(Game.state)), Palette.AETHER, 12))
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
	var status := UI.chip(CreatureCard.status_text(c), CreatureCard.status_color(c), 13)
	status.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_detail.add_child(status)
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
		lv.add_child(UI.chip("Evolves at Lv %d" % int(levels[form]), Palette.GOLD, 11))
	_detail.add_child(lv)
	# stats
	var st := Creatures.stats(c)
	var sr := UI.hbox(18)
	sr.alignment = BoxContainer.ALIGNMENT_CENTER
	sr.add_child(UI.stat_line("health", F.format_num(st.health), "Health"))
	sr.add_child(UI.stat_line("power", F.format_num(st.power), "Power"))
	sr.add_child(UI.stat_line("guard", F.format_num(st.guard), "Guard"))
	sr.add_child(UI.chip("Leans %s" % sp.statLean.capitalize(), Palette.AETHER_DEEP.lightened(0.3), 11))
	_detail.add_child(UI.panel("Inset", sr))
	# jobs
	_detail.add_child(UI.label("Work", "H3"))
	var wk := UI.vbox(4)
	wk.add_child(UI.stat_line(sp.primarySkill, "Best at %s" % Data.skills[sp.primarySkill].name, "Its specialty: it works fastest here"))
	wk.add_child(UI.stat_line(sp.secondaryAptitude, "Good at %s, +%s speed" % [Data.skills[sp.secondaryAptitude].name, F.pct(Data.tuning.skills.secondaryAptitudeBonus)]))
	_detail.add_child(wk)
	var actions := UI.flow(8, 8)
	var assign := MenuButton.new()
	assign.text = "Put to work"
	assign.theme_type_variation = "Primary"
	assign.flat = false
	assign.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var pm := assign.get_popup()
	assign.tooltip_text = "Choose a skill to work in"
	var eligible := Data.skill_list.filter(func(sk): return Creatures.can_work(c, sk.id))
	for i in eligible.size():
		var sk: Dictionary = eligible[i]
		var used := GameState.workers(Game.state, sk.id).size()
		var slots := GameState.slot_count(Game.state, sk.id)
		var here: bool = c.job.get("kind", "") == "skill" and c.job.id == sk.id
		var tag := " · specialty" if sk.id == sp.primarySkill else ""
		pm.add_icon_item(Data.ui_icon(sk.id), "%s   %d/%d%s%s" % [sk.name, used, slots, tag, " · working here" if here else (" · full" if used >= slots else "")], i)
		# the icons are painted large: keep them the size of the text (they once filled the menu)
		pm.set_item_icon_max_width(i, 22)
		pm.set_item_disabled(i, here or used >= slots)
	pm.id_pressed.connect(func(i): Game.assign(c.id, eligible[i].id))
	actions.add_child(assign)
	# the party is fixed while an expedition runs
	var party_locked := Expedition.party_locked(Game.state)
	var in_party := Creatures.job_kind(c) == "party"
	if in_party and party_locked:
		assign.disabled = true
		assign.tooltip_text = Expedition.PARTY_LOCKED
	if not in_party:
		var join := UI.button("Join the party", "", func(): _join_party(c))
		join.disabled = party_locked
		if party_locked:
			join.tooltip_text = Expedition.PARTY_LOCKED
		actions.add_child(join)
	if not Creatures.is_benched(c):
		var rest := UI.button("Rest", "", func(): Game.bench(c.id))
		rest.disabled = in_party and party_locked
		if rest.disabled:
			rest.tooltip_text = Expedition.PARTY_LOCKED
		actions.add_child(rest)
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
		var trait_def: Dictionary = Data.traits[t.id]
		var col: String = {"minor": "#a9aed6", "moderate": "#62b6ff", "major": "#ffd166"}[t.s]
		_detail.add_child(UI.rich("[b]%s[/b] [color=%s](%s)[/color]\n%s" % [trait_def.name, col, t.s.capitalize(), Traits.describe(t.id, t.s)]))
	var bottom := UI.hbox(8)
	bottom.add_child(UI.button("Attune traits", "", func(): _attune(c)))
	bottom.add_child(UI.spacer())
	bottom.add_child(UI.button("Release (+%d Aether)" % Creatures.release_value(c), "Danger", func(): _release(c)))
	_detail.add_child(UI.sep())
	_detail.add_child(bottom)


func _join_party(c: Dictionary) -> void:
	var party: Array = Game.state.expedition.party
	var party_size: int = Data.tuning.combat.partySize
	if party.size() >= party_size:
		Game.warn("The party is full (%d). Swap someone out on the Expeditions screen." % party_size)
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
	var box := {}  # holds the modal: lambdas capture locals by value, a Dictionary by reference
	var row := UI.hbox(8)
	row.add_child(UI.button("Clear nickname", "Ghost", func():
		box.m.close()
		Game.rename(c.id, "")))
	row.add_child(UI.spacer())
	row.add_child(UI.button("Save", "Primary", func():
		box.m.close()
		Game.rename(c.id, le.text)))
	v.add_child(row)
	le.text_submitted.connect(func(t):
		box.m.close()
		Game.rename(c.id, t))
	box.m = Modal.open(v, "Nickname", 420)
	le.grab_focus.call_deferred()


func _bulk_release() -> void:
	var v := UI.vbox(12)
	v.add_child(UI.wrap_label("Release many duplicates at once for Aether. Only resting Aetherlings go: working ones, the party, locked ones and shinies are always kept, and so is the best one of every species.", "Dim", 520))
	var row := UI.hbox(8, [UI.label("Release up to", "Dim")])
	var ob := OptionButton.new()
	for i in 4:
		ob.add_item(Data.rarities[i].name, i)
	row.add_child(ob)
	# a friend's request: clear out the low-level ones only
	row.add_child(UI.label("of", "Dim"))
	var lv := OptionButton.new()
	var levels := [0, 5, 10, 15, 20, 30, 40, 50, 75]
	for i in levels.size():
		lv.add_item("any level" if levels[i] == 0 else "under level %d" % levels[i], i)
	row.add_child(lv)
	v.add_child(row)
	var preview := UI.label("", "H3")
	v.add_child(preview)
	var box := {}
	var go := UI.button("Release", "Danger")
	var upd := func(_i := 0):
		var list := Economy.bulk_release_candidates(Game.state, ob.selected + 1, levels[lv.selected])
		var total := 0
		for c in list:
			total += Creatures.release_value(c)
		preview.text = "%d Aetherlings · +%s Aether" % [list.size(), F.format_num(total)]
		go.disabled = list.is_empty()
	ob.item_selected.connect(upd)
	lv.item_selected.connect(upd)
	upd.call()
	go.pressed.connect(func():
		box.m.close()
		Game.bulk_release(ob.selected + 1, levels[lv.selected]))
	v.add_child(go)
	box.m = Modal.open(v, "Bulk release", 580)


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
	var body := UI.vbox(8)
	v.add_child(UI.wrap_label("Attunement rerolls this Aetherling's pool traits with Aether. Lock up to two traits to keep them; each lock triples the cost. The signature trait never changes.", "Dim", 520))
	v.add_child(body)
	var fill := func(fill_ref: Callable) -> void:
		UI.clear(body)
		var cr := GameState.creature(Game.state, c.id)
		if cr.traits.is_empty():
			body.add_child(UI.label("No pool traits yet.", "Faint"))
		for t in cr.traits:
			var trait_def: Dictionary = Data.traits[t.id]
			var cb := CheckButton.new()
			cb.text = "%s (%s): %s" % [trait_def.name, t.s.capitalize(), Traits.describe(t.id, t.s)]
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
		var cost := Traits.attune_cost(cr, locks.size(), Game.state)
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
	var m := Modal.open(v, "Attune %s" % Creatures.display_name(c), 620)
	m.closed.connect(func(): _fill_detail())
