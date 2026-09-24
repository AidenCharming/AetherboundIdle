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
var _have_labels: Dictionary = {}   # item id -> Label ("You have N"), updated live
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
	_xp_label = UI.label("", "Faint")
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
	for i in levels.size():
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
			var cd := Skills.worker_cooldown(c, skill_id, action, auras)
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
			var note := UI.label("", "Faint")
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
			var l := UI.label("Opens at level %d" % int(levels[i]), "Dim")
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			cv.add_child(l)
		_slots.add_child(card)


func _pick(replace_id: String) -> void:
	var s := Game.state
	var action := Skills.current_action(s, skill_id)
	var auras := Skills.active_auras(s)
	CreaturePicker.pick("Choose a worker for %s" % _skill.name,
		func(c): return Creatures.can_work(c, skill_id) and not (c.job.get("kind", "") == "skill" and c.job.id == skill_id),
		func(cid):
			if replace_id != "":
				Game.bench(replace_id)
			Game.assign(cid, skill_id),
		func(c): return "Every %s here" % F.format_ms(Skills.worker_cooldown(c, skill_id, action, auras)))


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
		if a.has("inputs"):
			var need := UI.hbox(6, [UI.label("Needs", "Faint")])
			for id in a.inputs:
				need.add_child(UI.amount(id, float(a.inputs[id]), float(a.inputs[id]), 20))
			cv.add_child(need)
		if a.has("rare"):
			var rr := UI.hbox(4, [UI.label("Rare:", "Faint"), UI.icon(Data.item_icon(a.rare.item), 18), UI.label("%s %s" % [Data.item_name(a.rare.item), F.pct(float(a.rare.chance))], "Faint")])
			cv.add_child(rr)
		if a.has("treasure"):
			cv.add_child(UI.hbox(4, [UI.label("Treasure:", "Faint"), UI.icon(Data.item_icon(a.treasure.item), 18), UI.label(F.pct(float(a.treasure.chance)), "Faint")]))
		var have := UI.label("", "Faint")
		_have_labels[out] = have
		cv.add_child(have)
		if not unlocked:
			card.tooltip_text = "Reach %s level %d" % [_skill.name, int(a.level)]
			card.modulate.a = 0.55
		_actions.add_child(card)


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
	_rate.add_child(UI.label("Per hour", "Faint"))
	for id in action.outputs:
		_rate.add_child(UI.amount(id, per_h * float(action.outputs[id])))
	for id in action.get("inputs", {}):
		var row := UI.hbox(6, [UI.label("uses", "Faint"), UI.amount(id, per_h * float(action.inputs[id]))])
		_rate.add_child(row)
	_rate.add_child(UI.label("%s XP/h" % F.format_num(xp_h), "Faint"))
	if Skills.affordable(s, action) <= 0:
		_rate.add_child(UI.label("Waiting for materials", "Small", Palette.DANGER))


func _process(_d: float) -> void:
	if Game.state.is_empty():
		return
	for id in _have_labels:
		_have_labels[id].text = "You have %s" % F.format_num(GameState.count(Game.state, id))
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
