extends Control
## The Sanctum: the home screen. Every skill is a station on the islands, with its workers and their
## progress; the side column holds the guidance goal, the perches, the expedition and the pods.

var _stations: Dictionary = {}   # skill id -> {card, bubbles: {cid: bubble}, level, xp}
var _side: VBoxContainer
var _fx: Control
var _perch_box: HFlowContainer
var _perch_rate: Label
var _exp_box: VBoxContainer
var _pods_box: VBoxContainer
var _goal_box: VBoxContainer
var _t := 0.0


func _ready() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/backgrounds/sanctum.jpg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(1, 1, 1, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var row := UI.hbox(18)
	var m := UI.margin(row, 24, 10, 24, 20)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var left := UI.vbox(14)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	left.add_child(UI.header("Your Sanctum", "Every station on the islands, and who is working it. Click a station to manage it.", Data.ui_icon("sanctum")))
	var flow := UI.flow(14, 14)
	left.add_child(UI.scroll(flow))
	for skill in Data.skill_list:
		flow.add_child(_station(skill))
	_side = UI.vbox(14)
	_side.custom_minimum_size.x = 360
	row.add_child(UI.scroll(_side))
	_goal_box = UI.vbox(8)
	_side.add_child(UI.panel("Glass", _goal_box))
	var perch := UI.vbox(8)
	var ph := UI.hbox(8, [UI.icon(Data.ui_icon("nexus"), 24), UI.label("Perches", "H3")])
	ph.add_child(UI.spacer())
	_perch_rate = UI.label("", "Num", Palette.AETHER)
	ph.add_child(_perch_rate)
	perch.add_child(ph)
	perch.add_child(UI.wrap_label("Resting Aetherlings sit on the perches and gather Aether. Rarer ones gather far more.", "Faint"))
	_perch_box = UI.flow(6, 6)
	perch.add_child(_perch_box)
	_side.add_child(UI.panel("Glass", perch))
	_exp_box = UI.vbox(8)
	_side.add_child(UI.panel("Glass", _exp_box))
	_pods_box = UI.vbox(8)
	_side.add_child(UI.panel("Glass", _pods_box))
	_fx = Control.new()
	_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx)
	Game.event.connect(_on_event)
	refresh()


func _station(skill: Dictionary) -> Control:
	var card := UI.button("", "Tile")
	card.custom_minimum_size = Vector2(300, 176)
	card.pressed.connect(func(): Main.go("skill", skill.id))
	var v := UI.vbox(8)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_right = -14
	v.offset_top = 12
	v.offset_bottom = -12
	card.add_child(v)
	var head := UI.hbox(10)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(UI.icon(Data.ui_icon(skill.id), 34))
	var tv := UI.vbox(0)
	tv.add_child(UI.label(skill.name, "H3"))
	var sub := UI.label("", "Faint")
	tv.add_child(sub)
	head.add_child(tv)
	head.add_child(UI.spacer())
	var lvl := UI.label("", "H2", Palette.AETHER)
	head.add_child(lvl)
	v.add_child(head)
	var xp := UI.bar(Data.type_color(skill.type) if skill.type != null else Palette.AETHER, 6)
	v.add_child(xp)
	var workers := UI.hbox(6)
	workers.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(workers)
	_stations[skill.id] = {"card": card, "workers": workers, "level": lvl, "xp": xp, "sub": sub, "bubbles": {}}
	return card


func refresh() -> void:
	if Game.state.is_empty():
		return
	var s := Game.state
	for id in _stations:
		var st: Dictionary = _stations[id]
		var skill: Dictionary = Data.skills[id]
		UI.clear(st.workers)
		st.bubbles.clear()
		var ws := GameState.workers(s, id)
		var usable: bool = skill.type == null or Collection.owned_type(s, skill.type)
		var action := Skills.current_action(s, id)
		if not usable:
			st.sub.text = "Needs a %s Aetherling" % Data.types[skill.type].name
			st.card.modulate = Color(1, 1, 1, 0.55)
		elif ws.is_empty():
			st.sub.text = "Idle · " + action.name
			st.card.modulate = Color(1, 1, 1, 0.85)
		else:
			st.sub.text = action.name
			st.card.modulate = Color.WHITE
		for c in ws:
			var b := WorkerBubble.make(c, id, 58)
			st.workers.add_child(b)
			st.bubbles[c.id] = b
		for i in GameState.slot_count(s, id) - ws.size():
			st.workers.add_child(WorkerBubble.make({}, id, 58))
		if ws.size() > 0:
			st.workers.add_child(UI.spacer())
			st.workers.add_child(UI.icon(Data.item_icon(action.outputs.keys()[0]), 30))
	_fill_side()


func _fill_side() -> void:
	var s := Game.state
	# guidance
	UI.clear(_goal_box)
	var g := Goals.current(s)
	var gh := UI.hbox(8, [UI.icon(Data.ui_icon("xp"), 22), UI.label("Overseer Vance", "H3")])
	_goal_box.add_child(gh)
	if g.is_empty():
		_goal_box.add_child(UI.wrap_label("You've done everything I had planned. The Sanctum is yours, Architect: chase the rarities and the hidden recipes.", "Dim"))
	else:
		_goal_box.add_child(UI.wrap_label(g.text, ""))
		var p := Goals.progress(s, g)
		var pb := UI.bar(Palette.GOLD, 8)
		pb.value = float(p[0]) / maxf(1.0, float(p[1]))
		_goal_box.add_child(pb)
		var rrow := UI.hbox(8)
		rrow.add_child(UI.label("Reward:", "Faint"))
		for k in g.reward:
			if k == "items":
				for id in g.reward.items:
					rrow.add_child(UI.amount(id, g.reward.items[id], -1, 18))
			else:
				rrow.add_child(UI.amount(k, g.reward[k], -1, 18))
		rrow.add_child(UI.spacer())
		if Goals.is_done(s, g):
			rrow.add_child(UI.button("Claim", "Gold", func(): Game.claim_goal()))
		else:
			rrow.add_child(UI.label("%d / %d" % p, "Faint"))
		_goal_box.add_child(rrow)
	# perches
	UI.clear(_perch_box)
	var perched := Economy.perched(s)
	for c in perched:
		var por := CreaturePortrait.of(c, 60)
		por.glow_scale = 0.6
		var wrapper := Control.new()
		wrapper.custom_minimum_size = Vector2(60, 60)
		wrapper.tooltip_text = "%s · %s Aether/min" % [Creatures.display_name(c), F.format_num(Creatures.bench_rate_per_min(c))]
		wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
		wrapper.add_child(por)
		_perch_box.add_child(wrapper)
	for i in int(GameState.upgrade_value(s, "perches")) - perched.size():
		var e := WorkerBubble.make({}, "woodcutting", 60)
		e.tooltip_text = "Empty perch: any resting Aetherling sits here"
		_perch_box.add_child(e)
	_perch_rate.text = "+%s/min" % F.format_num(Economy.aether_per_min(s))
	# expedition
	UI.clear(_exp_box)
	_exp_box.add_child(UI.hbox(8, [UI.icon(Data.ui_icon("expeditions"), 24), UI.label("Expedition", "H3")]))
	if Expedition.is_running(s) and not s.expedition.battle.is_empty():
		var b: Dictionary = s.expedition.battle
		var z: Dictionary = Data.zones[b.zone]
		var what := "Resting after a wipe" if b.phase == "rest" and not Combat.any_alive(b.allies) else "Wave %d of %d" % [int(b.wave), int(b.waves)]
		_exp_box.add_child(UI.label("%s · %s" % [z.name, what], "Dim"))
		var party := UI.hbox(6)
		for f in b.allies:
			var pv := UI.vbox(2)
			var por := CreaturePortrait.make(f.species, int(f.form), int(f.rarity), bool(f.shiny), 54)
			por.bob = false
			pv.add_child(por)
			var hp := UI.bar(Palette.GOOD, 5)
			hp.value = float(f.hp) / float(f.maxHp)
			hp.custom_minimum_size.x = 54
			pv.add_child(hp)
			party.add_child(pv)
		_exp_box.add_child(party)
		_exp_box.add_child(UI.button("Watch the battle", "", func(): Main.go("expeditions")))
	else:
		_exp_box.add_child(UI.wrap_label("No expedition running. Wild Aetherlings can only be found on the islands.", "Faint"))
		_exp_box.add_child(UI.button("Plan an expedition", "Primary", func(): Main.go("expeditions")))
	# pods
	UI.clear(_pods_box)
	_pods_box.add_child(UI.hbox(8, [UI.icon(Data.ui_icon("pods"), 24), UI.label("Genesis Pods", "H3")]))
	var now := Game.now_sec()
	var eggs := UI.hbox(8)
	for egg in s.pods:
		if egg.is_empty():
			var e := WorkerBubble.make({}, "woodcutting", 46)
			e.tooltip_text = "Empty pod"
			eggs.add_child(e)
		else:
			var ev := EggView.make(egg, 46)
			ev.tooltip_text = "Ready to hatch!" if Breeding.is_ready(egg, now) else "Hatches in " + F.format_seconds(Breeding.remaining(egg, now))
			eggs.add_child(ev)
	_pods_box.add_child(eggs)
	var ready_count := Game.ready_eggs().size()
	if ready_count > 0:
		_pods_box.add_child(UI.button("Hatch %d egg%s" % [ready_count, "" if ready_count == 1 else "s"], "Gold", func(): Main.go("pods")))
	else:
		_pods_box.add_child(UI.button("Breed Aetherlings", "", func(): Main.go("pods")))


func _process(delta: float) -> void:
	_t += delta
	if Game.state.is_empty():
		return
	for id in _stations:
		var st: Dictionary = _stations[id]
		var sk: Dictionary = Game.state.skills[id]
		st.level.text = str(int(sk.level))
		st.xp.value = F.level_progress(F.skill_curve(), float(sk.xp), Data.tuning.skills.maxLevel)
	if fmod(_t, 1.0) < delta:
		_perch_rate.text = "+%s/min" % F.format_num(Economy.aether_per_min(Game.state))


func _on_event(e: Dictionary) -> void:
	if not is_visible_in_tree():
		return
	match e.type:
		"produced":
			var st: Dictionary = _stations.get(e.skill, {})
			var b: WorkerBubble = st.get("bubbles", {}).get(e.creature)
			if b and is_instance_valid(b):
				var at := b.global_position - _fx.global_position + Vector2(b.size.x * 0.75, b.size.y * 0.35)
				for id in e.items:
					if id.begins_with("_"):
						continue
					FloatText.spawn(_fx, at, "+%d" % int(e.items[id]), Palette.TEXT, Data.item_icon(id), 15, 30.0)
					break
		"skill_level", "slot_unlocked", "captured", "evolved", "wiped", "run_complete":
			_fill_side()
		"wave", "boss_defeated":
			_fill_side()
