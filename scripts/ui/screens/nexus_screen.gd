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
		var first := _sorted_list()
		selected = first[0].id if not first.is_empty() else ""
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
	# each key worked out once, not once per comparison (a big roster made this slow): same orders as before
	var order := {}
	for i in Data.species_list.size():
		order[Data.species_list[i].id] = i
	match _sort:
		"level":
			return UI.sort_by_key(list, func(c): return [int(c.level), int(c.rarity)])
		"species":
			return UI.sort_by_key(list, func(c): return [-int(order[c.species]), int(c.rarity), int(c.level)])
		"new":
			return UI.sort_by_key(list, func(c): return int(c.id.substr(1)))
		"power":
			return UI.sort_by_key(list, func(c): return Creatures.power_rating(c))
	return UI.sort_by_key(list, func(c): return [int(c.rarity), int(c.level)])


func _fill_grid() -> void:
	UI.clear(_grid)
	CreatureCard.refresh_perched()
	var list := _sorted_list()
	UI.clear(_count)
	_count.add_child(UI.chip("%d / %d shown" % [list.size(), Game.state.creatures.size()], Palette.TEXT_DIM, 12))
	_count.add_child(UI.chip("+%s Aether/min" % F.format_num(Economy.aether_per_min(Game.state)), Palette.AETHER, 12))
	UI.fill_paged(_grid, list, func(c):
		var card := CreatureCard.make(c, c.id == selected)
		card.picked.connect(func(id):
			selected = id
			for other in _grid.get_children():
				if other is CreatureCard:
					other.theme_type_variation = "TileOn" if other.cid == id else "Tile"
			_fill_detail())
		return card)


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
	if form < F.form_for_level(int(c.level)) and int(c.level) < int(Data.tuning.creature.maxLevel):
		lv.add_child(UI.chip("Evolves at its next level", Palette.GOLD, 11))
	elif form < levels.size():
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


## The last bulk release settings, kept while the game runs so the window opens the way you left it.
static var _bulk := {}


func _bulk_release() -> void:
	var o := Economy.BULK_DEFAULTS.duplicate()
	o.merge(_bulk, true)
	var v := UI.vbox(10)
	v.add_child(UI.wrap_label("Release many Aetherlings at once for Aether. Locked ones and the expedition party always stay, and so do the best of each species (as many as you choose).", "Dim", 700))
	var rar_pick := func(value: int) -> OptionButton:
		var ob := OptionButton.new()
		for i in Data.rarities.size():
			ob.add_item(Data.rarities[i].name, i)
		ob.selected = clampi(value, 1, Data.rarities.size()) - 1
		return ob
	var from: OptionButton = rar_pick.call(int(o.minRarity))
	var to: OptionButton = rar_pick.call(int(o.maxRarity))
	# the filters and the switches each sit on an inset card, like the Options pages
	var filters := UI.vbox(12)
	v.add_child(UI.panel("Inset", filters))
	filters.add_child(UI.hbox(8, [UI.label("Rarity from", "Dim"), from, UI.label("to", "Dim"), to]))
	var ty := OptionButton.new()
	ty.add_item("Any type")
	var type_ids: Array = Data.types.keys()
	for id in type_ids:
		ty.add_item(Data.types[id].name)
	ty.selected = type_ids.find(o.type) + 1
	var spo := OptionButton.new()
	spo.add_item("Any species")
	var owned: Array = Data.species_list.filter(func(sp): return Game.state.creatures.values().any(func(c): return c.species == sp.id)).map(func(sp): return sp.id)
	for id in owned:
		spo.add_item(Data.species[id].name)
	spo.selected = owned.find(o.species) + 1
	var lvl := SpinBox.new()
	lvl.min_value = 0
	lvl.max_value = Data.tuning.creature.maxLevel
	lvl.value = int(o.maxLevel)
	lvl.tooltip_text = "0 means any level"
	filters.add_child(UI.hbox(8, [UI.label("Type", "Dim"), ty, UI.label("Species", "Dim"), spo, UI.label("Up to level (0 = any)", "Dim"), lvl]))
	var keep := SpinBox.new()
	keep.min_value = 0
	keep.max_value = 10
	keep.value = int(o.keepPerSpecies)
	filters.add_child(UI.hbox(8, [UI.label("Keep the best", "Dim"), keep, UI.label("of each species (rarity, then level)", "Dim")]))
	var switches := UI.vbox(14)
	v.add_child(UI.panel("Inset", switches))
	var shinies := ToggleSwitch.new()
	shinies.text = "Release shinies too"
	shinies.tooltip_text = "Shinies stay unless this is on. Each shiny released also gives Aether Pearls."
	shinies.button_pressed = bool(o.shinies)
	shinies.focus_mode = Control.FOCUS_NONE
	switches.add_child(shinies)
	var working := ToggleSwitch.new()
	working.text = "Release working ones too (they leave their jobs)"
	working.button_pressed = bool(o.working)
	working.focus_mode = Control.FOCUS_NONE
	switches.add_child(working)
	var preview := UI.label("", "H3")
	v.add_child(preview)
	var kept_lbl := UI.wrap_label("", "Faint", 700)
	v.add_child(kept_lbl)
	var who := UI.flow(6, 6)
	var who_sc := UI.scroll(who)
	who_sc.custom_minimum_size = Vector2(700, 150)
	v.add_child(who_sc)
	var box := {}
	var go := UI.button("Release", "Danger")
	var opts := func() -> Dictionary:
		return {"minRarity": mini(from.selected, to.selected) + 1, "maxRarity": maxi(from.selected, to.selected) + 1,
			"type": "" if ty.selected <= 0 else type_ids[ty.selected - 1], "species": "" if spo.selected <= 0 else owned[spo.selected - 1],
			"maxLevel": int(lvl.value), "keepPerSpecies": int(keep.value), "shinies": shinies.button_pressed, "working": working.button_pressed}
	var upd := func(_x = null):
		var plan := Economy.bulk_release_plan(Game.state, opts.call())
		var list: Array = plan.list
		var total := 0
		var pearls := 0
		for c in list:
			total += Creatures.release_value(c)
			pearls += int(Data.rarity(int(c.rarity)).get("releasePearls", 0)) + (int(Data.tuning.pearls.shinyRelease) if c.shiny else 0)
		preview.text = "%d Aetherling%s · +%s Aether%s" % [list.size(), "" if list.size() == 1 else "s", F.format_num(total),
			" · +%d Aether Pearl%s" % [pearls, "" if pearls == 1 else "s"] if pearls > 0 else ""]
		var reasons: Array = plan.kept.keys().map(func(k): return "%d %s" % [int(plan.kept[k]), k])
		kept_lbl.text = ("Staying: " + ", ".join(reasons) + ".") if not reasons.is_empty() else ""
		if list.is_empty():
			kept_lbl.text = "Nobody matches these settings. " + kept_lbl.text
		UI.clear(who)
		UI.fill_paged(who, UI.sort_by_key(list, func(c): return [int(c.rarity), int(c.level)]), func(c):
			var por := CreaturePortrait.of(c, 44)
			por.bob = false
			por.tooltip_text = "%s · %s · Lv %d%s" % [Creatures.display_name(c), Data.rarity(int(c.rarity)).name, int(c.level), " · shiny" if c.shiny else ""]
			return por, 60)
		go.disabled = list.is_empty()
		_bulk = opts.call()
	for ob in [from, to, ty, spo]:
		ob.item_selected.connect(upd)
	for sb in [lvl, keep]:
		sb.value_changed.connect(upd)
	for cb in [shinies, working]:
		cb.toggled.connect(upd)
	upd.call()
	go.pressed.connect(func():
		box.m.close()
		Game.bulk_release(opts.call()))
	v.add_child(UI.hbox(8, [UI.spacer(), go]))
	box.m = Modal.open(v, "Bulk release", 760)


func _release(c: Dictionary) -> void:
	if c.get("locked", false):
		Game.warn("Unlock it first.")
		return
	Modal.confirm("Release %s?" % Creatures.display_name(c), "It returns to the wild and leaves %d Aether behind. This cannot be undone." % Creatures.release_value(c),
		"Release", func():
			Game.release(c.id)
			selected = "", true)


static func _mult(m: float) -> String:
	return str(snappedf(m, 0.01)).trim_suffix(".0")


func _attune(c: Dictionary) -> void:
	var v := UI.vbox(12)
	var locks := {}
	var body := UI.vbox(8)
	var at: Dictionary = Data.tuning.attunement
	v.add_child(UI.wrap_label("Attunement rerolls this Aetherling's pool traits with Aether. Lock up to %d traits to keep them. A lock multiplies the cost by its strength: Minor ×%s, Moderate ×%s, Major ×%s. The signature trait never changes." % [
		int(at.maxLocks), _mult(Traits.lock_mult("minor")), _mult(Traits.lock_mult("moderate")), _mult(Traits.lock_mult("major"))], "Dim", 520))
	v.add_child(body)
	var fill := func(fill_ref: Callable) -> void:
		UI.clear(body)
		var cr := GameState.creature(Game.state, c.id)
		if cr.traits.is_empty():
			body.add_child(UI.label("No pool traits yet.", "Faint"))
		for t in cr.traits:
			var trait_def: Dictionary = Data.traits[t.id]
			# a trait row: its name and strength, what it does, and a Lock pill that turns gold when locked
			var card := PanelContainer.new()
			card.theme_type_variation = "Inset"
			var row_t := UI.hbox(12)
			card.add_child(row_t)
			var txt := UI.vbox(2)
			txt.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var name_row := UI.hbox(8, [UI.label(trait_def.name), UI.chip(t.s.capitalize(), Palette.AETHER, 11)])
			txt.add_child(name_row)
			txt.add_child(UI.wrap_label(Traits.describe(t.id, t.s), "Dim", 360))
			row_t.add_child(txt)
			var locked_now := locks.has(t.id)
			var cb := UI.button("Locked ×%s" % _mult(Traits.lock_mult(t.s)) if locked_now else "Lock ×%s" % _mult(Traits.lock_mult(t.s)),
				"Gold" if locked_now else "Chip", Callable(), Data.ui_icon("lock"))
			cb.toggle_mode = true
			cb.button_pressed = locked_now
			cb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			cb.tooltip_text = "Keep this trait through the reroll (cost ×%s)." % _mult(Traits.lock_mult(t.s))
			row_t.add_child(cb)
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
			body.add_child(card)
		var cost := Traits.attune_cost(cr, locks.keys(), Game.state)
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
