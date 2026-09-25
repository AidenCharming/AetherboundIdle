extends Control
## One skill: level and XP, the work slots with their creatures, and a card per action tier.

var skill_id := "woodcutting"
var _skill: Dictionary
var _xp_bar: ProgressBar
var _xp_label: Label
var _level_label: Label
var _slots: HFlowContainer
var _actions: HFlowContainer
var _rate: VBoxContainer
var _slot_bars: Array = []   # [{cid, bar, label}]
var _have_labels: Array = []   # [{id, label, last}] item counts on the action cards, updated live
var _fx: Control


func setup(arg: String) -> void:
	skill_id = arg if Data.skills.has(arg) else "woodcutting"
	_skill = Data.skills[skill_id]


func _ready() -> void:
	var v := UI.vbox(16)
	var m := UI.margin(v, 26, 10, 26, 20)
	var sc := UI.scroll(m)
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sc)
	# header
	var head := UI.hbox(18)
	var hp := UI.panel("Glass", head)
	v.add_child(hp)
	head.add_child(UI.icon(Data.ui_icon(skill_id), 72))
	var hv := UI.vbox(6)
	hv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(hv)
	var title := UI.hbox(12)
	title.add_child(UI.label(_skill.name, "H1"))
	if _skill.type != null:
		title.add_child(UI.type_badge(_skill.type))
		title.add_child(UI.label("%s Aetherlings only" % Data.types[_skill.type].name, "Faint"))
	else:
		title.add_child(UI.label("Open to every Aetherling", "Faint"))
	hv.add_child(title)
	hv.add_child(UI.label(_skill.blurb, "Dim"))
	var xr := UI.hbox(12)
	_level_label = UI.label("", "H2", Palette.AETHER)
	xr.add_child(_level_label)
	_xp_bar = UI.bar(Data.type_color(_skill.type) if _skill.type != null else Palette.AETHER, 12)
	_xp_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	xr.add_child(_xp_bar)
	_xp_label = UI.label("", "Num", Palette.AETHER.lightened(0.2))
	_xp_label.add_theme_font_size_override("font_size", 15)
	xr.add_child(_xp_label)
	hv.add_child(xr)
	_rate = UI.vbox(4)
	_rate.custom_minimum_size.x = 260
	head.add_child(_rate)
	# slots
	v.add_child(UI.label("Work slots", "H2"))
	_slots = UI.flow(14, 14)
	v.add_child(_slots)
	v.add_child(UI.label("What to work on", "H2"))
	v.add_child(UI.label("Every worker in this skill does the selected task. Higher tiers open with skill level.", "Faint"))
	_actions = UI.flow(14, 14)
	v.add_child(_actions)
	_fx = Control.new()
	_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx)
	Game.event.connect(_on_event)
	refresh()


func refresh() -> void:
	if Game.state.is_empty():
		return
	_fill_slots()
	_fill_actions()
	_fill_rate()


func _fill_slots() -> void:
	var s := Game.state
	UI.clear(_slots)
	_slot_bars.clear()
	var ws := GameState.workers(s, skill_id)
	var open := GameState.slot_count(s, skill_id)
	var levels: Array = Data.tuning.skills.slotLevels
	var action := Skills.current_action(s, skill_id)
	var auras := Skills.active_auras(s)
	for i in maxi(levels.size(), open):
		var card := UI.panel("Card")
		card.custom_minimum_size = Vector2(250, 214)
		var cv := UI.vbox(6)
		card.add_child(cv)
		if i < ws.size():
			var c: Dictionary = ws[i]
			var top := UI.hbox(10)
			var bub := WorkerBubble.make(c, skill_id, 84)
			top.add_child(bub)
			var tv := UI.vbox(2)
			tv.add_child(UI.label(Creatures.display_name(c), "H3"))
			tv.add_child(UI.label("Lv %d · %s" % [int(c.level), Data.rarity(int(c.rarity)).name], "Faint", Data.rarity_color(int(c.rarity))))
			var cd := Skills.worker_cooldown(c, skill_id, action, auras, Skills.speed(s))
			tv.add_child(UI.label("Every %s" % F.format_ms(cd), "Dim"))
			var eff := Creatures.efficiency(c, skill_id)
			if eff > 1.001:
				tv.add_child(UI.label("Specialist +%s" % F.pct(eff - 1.0), "Faint", Palette.GOOD))
			elif eff < 0.999:
				tv.add_child(UI.label("Off-specialty −%s" % F.pct(1.0 - eff), "Faint", Palette.DANGER))
			top.add_child(tv)
			cv.add_child(top)
			var bar := UI.bar(Palette.AETHER, 8)
			cv.add_child(bar)
			var note := UI.label("", "Small", Palette.AETHER.lightened(0.15))
			cv.add_child(note)
			_slot_bars.append({"cid": c.id, "bar": bar, "label": note, "cd": cd})
			var row := UI.hbox(8)
			row.add_child(UI.button("Swap", "", func(): _pick(c.id)))
			row.add_child(UI.button("Rest", "Ghost", func(): Game.bench(c.id)))
			row.add_child(UI.spacer())
			row.add_child(UI.button("Details", "Ghost", func(): Main.go("nexus", c.id)))
			cv.add_child(row)
		elif i < open:
			cv.alignment = BoxContainer.ALIGNMENT_CENTER
			var usable: bool = _skill.type == null or Collection.owned_type(s, _skill.type)
			cv.add_child(UI.icon(Data.ui_icon("nexus"), 42))
			var l := UI.label("Empty slot", "H3")
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cv.add_child(l)
			if usable:
				var b := UI.button("Assign an Aetherling", "Primary", func(): _pick(""))
				cv.add_child(b)
			else:
				cv.add_child(UI.wrap_label("You need a %s Aetherling. Find one on the expedition islands." % Data.types[_skill.type].name, "Faint"))
		else:
			cv.alignment = BoxContainer.ALIGNMENT_CENTER
			card.custom_minimum_size.x = 150
			card.modulate.a = 0.5
			cv.add_child(UI.icon(Data.ui_icon("lock"), 36))
			var l := UI.chip("Opens at Lv %d" % int(levels[i]), Palette.AETHER, 12)
			l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			cv.add_child(l)
		_slots.add_child(card)
	# past the fifth, slots are bought in the Market; offer the next one here once the five are open
	var price := Market.next_slot_price(s, skill_id)
	if price >= 0 and int(s.skills[skill_id].level) >= int(Market.cfg().extraSlots.needLevel):
		var card := UI.panel("Card")
		card.custom_minimum_size = Vector2(170, 214)
		var cv := UI.vbox(8)
		cv.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(cv)
		var ic := UI.icon(Data.ui_icon("work-slot"), 44)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		cv.add_child(ic)
		var l := UI.label("Extra slot", "H3")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cv.add_child(l)
		var amt := UI.amount("gold", price, price, 18)
		amt.alignment = BoxContainer.ALIGNMENT_CENTER
		cv.add_child(amt)
		var b := UI.button("Buy", "Gold", func(): Modal.confirm("Buy a %s slot?" % _skill.name, "%s gold for one more work slot here, for good." % F.format_num(price), "Buy the slot", func(): Game.buy_slot(skill_id)))
		b.disabled = Market.slot_check(s, skill_id) != ""
		b.tooltip_text = Market.slot_check(s, skill_id)
		cv.add_child(b)
		_slots.add_child(card)


func _pick(replace_id: String) -> void:
	var s := Game.state
	var action := Skills.current_action(s, skill_id)
	var auras := Skills.active_auras(s)
	CreaturePicker.pick("Choose a worker for %s" % _skill.name,
		# party members on a running expedition can't be moved, so they aren't offered
		func(c): return Creatures.can_work(c, skill_id) and not (c.job.get("kind", "") == "skill" and c.job.id == skill_id) \
			and not (Creatures.job_kind(c) == "party" and Expedition.party_locked(Game.state)),
		func(cid):
			if replace_id != "":
				Game.bench(replace_id)
			Game.assign(cid, skill_id),
		func(c): return "Every %s here" % F.format_ms(Skills.worker_cooldown(c, skill_id, action, auras)),
		"output",
		func(c): return Skills.work_perks(c, skill_id, action).map(func(p): return Describe.work_perk(p)),
		_worker_sorts(action, auras))


## The worker picker's rankings for this task: fastest, most product, most secondary finds.
func _worker_sorts(action: Dictionary, auras: Array) -> Array:
	var rates := {}   # creature id -> Skills.work_rates, worked out once per creature
	var r := func(c: Dictionary) -> Dictionary:
		if not rates.has(c.id):
			rates[c.id] = Skills.work_rates(c, skill_id, action, auras)
		return rates[c.id]
	var out_name := Data.item_name(action.outputs.keys()[0])
	var finds := []
	for k in ["rare", "treasure"]:
		if action.has(k):
			finds.append(Data.item_name(action[k].item))
	return [
		{"id": "output", "label": "Best output", "tip": "Most %s per hour, counting speed and extra-output traits" % out_name,
			"key": func(c): return r.call(c).output,
			"note": func(c): return "%s %s/h" % [F.format_num(r.call(c).output), out_name]},
		{"id": "time", "label": "Best time", "tip": "Shortest time per task",
			"key": func(c): return -float(r.call(c).cooldown),
			"note": func(c): return "Every %s here" % F.format_ms(r.call(c).cooldown)},
		{"id": "secondary", "label": "Best secondary", "tip": "Most secondary finds per hour: %s" % ", ".join(finds + ["partner-element drops"]),
			"key": func(c): return r.call(c).secondary,
			"note": func(c): return "%s secondary finds/h" % F.format_num(r.call(c).secondary)},
	]


func _fill_actions() -> void:
	var s := Game.state
	UI.clear(_actions)
	_have_labels.clear()
	var current := Skills.current_action(s, skill_id)
	for a in _skill.actions:
		var unlocked := int(a.level) <= int(s.skills[skill_id].level)
		var selected: bool = a.id == current.id
		var card := UI.button("", "TileOn" if selected else "Tile")
		card.custom_minimum_size = Vector2(250, 236)
		card.disabled = not unlocked
		card.pressed.connect(func(): Game.set_action(skill_id, a.id))
		var cv := UI.vbox(6)
		cv.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		cv.offset_left = 14
		cv.offset_right = -14
		cv.offset_top = 12
		cv.offset_bottom = -12
		card.add_child(cv)
		var out: String = a.outputs.keys()[0]
		var top := UI.hbox(12)
		top.add_child(UI.icon(Data.item_icon(out), 56))
		var tv := UI.vbox(0)
		tv.add_child(UI.label(a.name, "H3"))
		tv.add_child(UI.label("Makes %s" % Data.item_name(out) if a.has("inputs") else Data.item_name(out), "Faint"))
		tv.add_child(UI.label("Level %d" % int(a.level), "Small", Palette.AETHER if unlocked else Palette.DANGER))
		top.add_child(tv)
		cv.add_child(top)
		var info := UI.hbox(14)
		info.add_child(UI.stat_line("time", F.format_ms(float(a.ms)), "Base time, before your worker's speed"))
		info.add_child(UI.stat_line("xp", "%d XP" % int(a.xp)))
		if a.has("gold"):
			info.add_child(UI.amount("gold", float(a.gold), -1, 18))
		cv.add_child(info)
		# the recipe, top to bottom: what one action uses, what it makes, what it can find besides; each line with
		# how many you hold (an input turns red when you have too few)
		cv.add_child(UI.spacer())
		var hv := UI.vbox(3)
		if a.has("inputs"):
			hv.add_child(_section_head("Uses each time"))
			for id in a.inputs:
				hv.add_child(_item_line(id, "×%d" % int(a.inputs[id]), Palette.TEXT_DIM, float(a.inputs[id])))
		hv.add_child(_section_head("Makes"))
		hv.add_child(_item_line(out, "×%d" % int(a.outputs[out]), Palette.GOOD))
		if a.has("rare") or a.has("treasure"):
			hv.add_child(_section_head("Sometimes finds"))
			if a.has("rare"):
				hv.add_child(_item_line(a.rare.item, F.pct(float(a.rare.chance)), Palette.GOLD))
			if a.has("treasure"):
				hv.add_child(_item_line(a.treasure.item, F.pct(float(a.treasure.chance)), Palette.GOLD))
		var hp := UI.panel("Inset", hv)
		hp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cv.add_child(hp)
		if not unlocked:
			card.tooltip_text = "Reach %s level %d" % [_skill.name, int(a.level)]
			card.modulate.a = 0.55
		_actions.add_child(card)
	_fit_cards.call_deferred()


## A small caps heading inside the recipe box.
func _section_head(text: String) -> Label:
	var l := UI.label(text.to_upper(), "Faint")
	l.add_theme_font_size_override("font_size", 11)
	return l


## One recipe line: item icon and name, a note (×2, or a drop chance) in `note_color`, and a live count of how
## many you hold on the right. With `need`, the count turns red while you hold fewer than one action uses.
func _item_line(id: String, note: String, note_color: Color, need := 0.0) -> HBoxContainer:
	var row := UI.hbox(6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(UI.icon(Data.item_icon(id), 22))
	var name_l := UI.label(Data.item_name(id), "Dim")
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_l.clip_text = true
	name_l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_l.custom_minimum_size.x = 60
	row.add_child(name_l)
	var nl := UI.label(note, "Small", note_color)
	nl.add_theme_font_override("font", ThemeFactory.bold_font())
	row.add_child(nl)
	var n := UI.label("", "Num")
	n.add_theme_font_size_override("font_size", 15)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	n.custom_minimum_size.x = 40
	n.tooltip_text = "You have this many"
	row.add_child(n)
	_have_labels.append({"id": id, "label": n, "last": -1.0, "need": need})
	_update_have()
	return row


## All action cards share the height of the tallest one so the row lines up.
func _fit_cards() -> void:
	var h := 236.0
	for card in _actions.get_children():
		if card.get_child_count() > 0:
			h = maxf(h, card.get_child(0).get_combined_minimum_size().y + 24.0)
	for card in _actions.get_children():
		card.custom_minimum_size.y = h


func _update_have() -> void:
	for e in _have_labels:
		var n := GameState.count(Game.state, e.id)
		if n == e.last:
			continue
		e.last = n
		e.label.text = F.format_num(n)
		var col := Palette.TEXT if n > 0 else Palette.TEXT_FAINT
		if float(e.get("need", 0.0)) > 0.0 and n < float(e.need):
			col = Palette.DANGER
		e.label.add_theme_color_override("font_color", col)


func _fill_rate() -> void:
	var s := Game.state
	UI.clear(_rate)
	var ws := GameState.workers(s, skill_id)
	if ws.is_empty():
		_rate.add_child(UI.label("Nobody working", "Dim"))
		return
	var action := Skills.current_action(s, skill_id)
	var per_h := 0.0
	var xp_h := 0.0
	for c in ws:
		var ph := Skills.per_hour(s, c, skill_id)
		per_h += ph.actions
		xp_h += ph.xp
	_rate.add_child(UI.label("Per hour", "Small", Palette.TEXT_DIM))
	for id in action.outputs:
		_rate.add_child(UI.amount(id, per_h * float(action.outputs[id])))
	for id in action.get("inputs", {}):
		var row := UI.hbox(6, [UI.label("uses", "Small", Palette.TEXT_DIM), UI.amount(id, per_h * float(action.inputs[id]))])
		_rate.add_child(row)
	_rate.add_child(UI.stat_line("xp", "%s XP/h" % F.format_num(xp_h)))
	if Skills.affordable(s, action) <= 0:
		_rate.add_child(UI.label("Waiting for materials", "Small", Palette.DANGER))


func _process(_d: float) -> void:
	if Game.state.is_empty():
		return
	_update_have()
	var sk: Dictionary = Game.state.skills[skill_id]
	var max_lv: int = Data.tuning.skills.maxLevel
	var lv := int(sk.level)
	_level_label.text = "Level %d" % lv
	_xp_bar.value = F.level_progress(F.skill_curve(), float(sk.xp), max_lv)
	if lv < max_lv:
		var a := F.xp_for_level(F.skill_curve(), lv, max_lv)
		var b := F.xp_for_level(F.skill_curve(), lv + 1, max_lv)
		_xp_label.text = "%s / %s XP" % [F.format_num(float(sk.xp) - a), F.format_num(b - a)]
	else:
		_xp_label.text = "Mastered"
	for sb in _slot_bars:
		var c := GameState.creature(Game.state, sb.cid)
		if c.is_empty():
			continue
		sb.bar.value = clampf(float(c.progress) / float(sb.cd), 0.0, 1.0)
		if c.get("stalled", false):
			sb.label.text = "Waiting for materials"
		elif int(c.level) >= int(Data.tuning.creature.maxLevel):
			sb.label.text = "Max level"
		else:
			sb.label.text = "%s of the way to Lv %d" % [F.pct(F.level_progress(F.creature_curve(), float(c.xp), Data.tuning.creature.maxLevel)), int(c.level) + 1]


func _on_event(e: Dictionary) -> void:
	if not is_visible_in_tree():
		return
	match e.type:
		"produced":
			if e.skill != skill_id:
				return
			for i in _slot_bars.size():
				if _slot_bars[i].cid == e.creature:
					var bar: ProgressBar = _slot_bars[i].bar
					var at := bar.global_position - _fx.global_position + Vector2(bar.size.x - 70.0, -96.0)
					var n := 0
					for id in e.items:
						if id.begins_with("_"):
							continue
						FloatText.spawn(_fx, at + Vector2(0, n * -24), "+%d" % int(e.items[id]), Palette.TEXT, Data.item_icon(id), 16)
						n += 1
					if e.items.has("_saved"):
						FloatText.spawn(_fx, at + Vector2(0, -24), "saved!", Palette.GOOD, null, 13)
		"skill_level", "slot_unlocked", "action_unlocked":
			if e.skill == skill_id:
				refresh()
		"creature_level":
			_fill_rate()
