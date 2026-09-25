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
var _exp_status: Label
var _exp_hp: Array = []
var _exp_log: VBoxContainer
var _exp_log_top := -1.0
var _exp_key := ""
var _goal_key := ""   # the goal and its progress as shown: when it changes, the goal card is rebuilt


func _ready() -> void:
	var bg := TextureRect.new()
	bg.texture = load("res://assets/backgrounds/sanctum.jpg")
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.modulate = Color(1, 1, 1, 0.55)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	var row := UI.hbox(22)
	var m := UI.margin(row, 29, 12, 29, 24)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var left := UI.vbox(17)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	left.add_child(UI.header("Your Sanctum", "Every station on the islands, and who is working it. Click a station to manage it.", Data.ui_icon("sanctum")))
	var flow := UI.flow(17, 17)
	left.add_child(UI.scroll(flow))
	for skill in Data.skill_list:
		flow.add_child(_station(skill))
	_side = UI.vbox(17)
	_side.custom_minimum_size.x = 432
	row.add_child(UI.scroll(_side))
	_goal_box = UI.vbox(10)
	_side.add_child(UI.panel("Glass", _goal_box))
	var perch := UI.vbox(10)
	var ph := UI.hbox(10, [UI.icon(Data.ui_icon("nexus"), 29), UI.label("Perches", "H3")])
	ph.add_child(UI.spacer())
	_perch_rate = UI.label("", "Num", Palette.AETHER)
	ph.add_child(_perch_rate)
	perch.add_child(ph)
	perch.add_child(UI.wrap_label("Resting Aetherlings sit on the perches and gather Aether. Rarer ones gather far more.", "Faint"))
	_perch_box = UI.flow(7, 7)
	perch.add_child(_perch_box)
	_side.add_child(UI.panel("Glass", perch))
	_exp_box = UI.vbox(10)
	_side.add_child(UI.panel("Glass", _exp_box))
	_pods_box = UI.vbox(10)
	_side.add_child(UI.panel("Glass", _pods_box))
	_fx = Control.new()
	_fx.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx)
	Game.event.connect(_on_event)
	refresh()


func _station(skill: Dictionary) -> Control:
	var card := UI.button("", "Tile")
	card.custom_minimum_size = Vector2(346, 211)
	card.pressed.connect(func(): Main.go("skill", skill.id))
	var v := UI.vbox(10)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 14
	v.offset_right = -14
	v.offset_top = 12
	v.offset_bottom = -12
	card.add_child(v)
	var head := UI.hbox(12)
	head.mouse_filter = Control.MOUSE_FILTER_IGNORE
	head.add_child(UI.icon(Data.ui_icon(skill.id), 41))
	var tv := UI.vbox(0)
	tv.add_child(UI.label(skill.name, "H3"))
	var sub := UI.label("", "Faint")
	tv.add_child(sub)
	head.add_child(tv)
	head.add_child(UI.spacer())
	var lvl := UI.label("", "H2", Palette.AETHER)
	head.add_child(lvl)
	v.add_child(head)
	var xp := UI.bar(Data.type_color(skill.type) if skill.type != null else Palette.AETHER, 7)
	v.add_child(xp)
	var workers := UI.hbox(7)
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
		# up to five bubbles a row (bought slots make a second row); they shrink to fit a full row
		var n := GameState.slot_count(s, id)
		var cols := mini(n, 5)
		var room := 272 - (36 if ws.size() > 0 else 0)
		var px := clampi(int((room - 6 * (cols - 1)) / float(cols)), 34, 58)
		var grid := UI.grid(maxi(1, cols), 7, 7)
		grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		st.workers.add_child(grid)
		for c in ws:
			var b := WorkerBubble.make(c, id, px)
			grid.add_child(b)
			st.bubbles[c.id] = b
		for i in n - ws.size():
			grid.add_child(WorkerBubble.make({}, id, px))
		if ws.size() > 0:
			st.workers.add_child(UI.spacer())
			st.workers.add_child(UI.icon(Data.item_icon(action.outputs.keys()[0]), 36))
	_fill_side()


func _fill_side() -> void:
	var s := Game.state
	# only when the goal moved: rebuilding it on every change freed the Claim button mid-click
	if _goal_state() != _goal_key:
		_fill_goal()
	_fill_side_rest(s)


## Overseer Vance's card. Item and counter goals move without any structural change, so _process checks
## the progress every half second and rebuilds this card when it moved (else Claim never showed up).
func _goal_state() -> String:
	var s := Game.state
	var g := Goals.current(s)
	if g.is_empty():
		return "end"
	var p := Goals.progress(s, g)
	return "%s:%d/%d" % [g.id, int(p[0]), int(p[1])]


func _fill_goal() -> void:
	var s := Game.state
	_goal_key = _goal_state()
	UI.clear(_goal_box)
	var g := Goals.current(s)
	var gh := UI.hbox(10, [UI.icon(Data.ui_icon("xp"), 26), UI.label("Overseer Vance", "H3")])
	gh.add_child(UI.spacer())
	gh.add_child(UI.chip("Goal %d / %d" % [mini(int(s.goals.index) + 1, Data.goals.size()), Data.goals.size()], Palette.GOLD, 16))
	_goal_box.add_child(gh)
	if g.is_empty():
		_goal_box.add_child(UI.wrap_label("You've done everything I had planned. The Sanctum is yours, Architect: chase the rarities and the hidden recipes.", "Dim"))
	else:
		_goal_box.add_child(UI.wrap_label(g.text, ""))
		var p := Goals.progress(s, g)
		var pb := UI.bar(Palette.GOLD, 10)
		pb.value = float(p[0]) / maxf(1.0, float(p[1]))
		_goal_box.add_child(pb)
		var rrow := UI.hbox(10)
		rrow.add_child(UI.label("Reward", "Small", Palette.GOLD))
		for k in g.reward:
			if k == "items":
				for id in g.reward.items:
					rrow.add_child(UI.amount(id, g.reward.items[id], -1, 22))
			else:
				rrow.add_child(UI.amount(k, g.reward[k], -1, 22))
		rrow.add_child(UI.spacer())
		if Goals.is_done(s, g):
			rrow.add_child(UI.button("Claim", "Gold", func(): Game.claim_goal()))
		else:
			rrow.add_child(UI.count_chip(p[0], p[1], 16))
		_goal_box.add_child(rrow)


func _fill_side_rest(s: Dictionary) -> void:
	# perches
	UI.clear(_perch_box)
	var perched := Economy.perched(s)
	for c in perched:
		var por := CreaturePortrait.of(c, 72)
		por.glow_scale = 0.6
		var wrapper := Control.new()
		wrapper.custom_minimum_size = Vector2(72, 72)
		wrapper.tooltip_text = "%s · %s Aether/min" % [Creatures.display_name(c), F.format_num(Creatures.bench_rate_per_min(c))]
		wrapper.mouse_filter = Control.MOUSE_FILTER_PASS
		wrapper.add_child(por)
		_perch_box.add_child(wrapper)
	for i in int(GameState.upgrade_value(s, "perches")) - perched.size():
		var e := WorkerBubble.make({}, "woodcutting", 72)
		e.tooltip_text = "Empty perch: any resting Aetherling sits here"
		_perch_box.add_child(e)
	_perch_rate.text = "+%s/min" % F.format_num(Economy.aether_per_min(s))
	_fill_expedition()
	# pods
	UI.clear(_pods_box)
	_pods_box.add_child(UI.hbox(10, [UI.icon(Data.ui_icon("pods"), 29), UI.label("Genesis Pods", "H3")]))
	var now := Game.now_sec()
	var eggs := UI.hbox(10)
	for egg in s.pods:
		if egg.is_empty():
			var e := WorkerBubble.make({}, "woodcutting", 55)
			e.tooltip_text = "Empty pod"
			eggs.add_child(e)
		else:
			var ev := EggView.make(egg, 55)
			ev.tooltip_text = "Ready to hatch!" if Breeding.is_ready(egg, now) else "Hatches in " + F.format_seconds(Breeding.remaining(egg, now))
			eggs.add_child(ev)
	_pods_box.add_child(eggs)
	var ready_count := Game.ready_eggs().size()
	if ready_count > 0:
		_pods_box.add_child(UI.button("Hatch %d egg%s" % [ready_count, "" if ready_count == 1 else "s"], "Gold", func(): Main.go("pods")))
	else:
		_pods_box.add_child(UI.button("Breed Aetherlings", "", func(): Main.go("pods")))


## The expedition card: where the party is, their health and the newest log lines. It is kept live from
## _process, so it follows the run while the player stays on the Sanctum.
func _fill_expedition() -> void:
	var s := Game.state
	UI.clear(_exp_box)
	_exp_hp.clear()
	_exp_status = null
	_exp_log = null
	_exp_key = _expedition_key()
	_exp_box.add_child(UI.hbox(10, [UI.icon(Data.ui_icon("expeditions"), 29), UI.label("Expedition", "H3")]))
	if Expedition.is_running(s) and not s.expedition.battle.is_empty():
		var b: Dictionary = s.expedition.battle
		_exp_status = UI.label("", "Dim")
		_exp_box.add_child(_exp_status)
		var party := UI.hbox(7)
		for f in b.allies:
			var pv := UI.vbox(2)
			var por := CreaturePortrait.make(f.species, int(f.form), int(f.rarity), bool(f.shiny), 65)
			por.bob = false
			pv.add_child(por)
			var hp := UI.bar(Palette.GOOD, 6)
			hp.custom_minimum_size.x = 65
			pv.add_child(hp)
			_exp_hp.append(hp)
			party.add_child(pv)
		_exp_box.add_child(party)
		_exp_log = UI.vbox(2)
		_exp_box.add_child(_exp_log)
		_exp_log_top = -1.0
		_update_expedition()
		_exp_box.add_child(UI.button("Watch the battle", "", func(): Main.go("expeditions")))
	else:
		_exp_box.add_child(UI.wrap_label("No expedition running. Wild Aetherlings can only be found on the islands.", "Faint"))
		_exp_box.add_child(UI.button("Plan an expedition", "Primary", func(): Main.go("expeditions")))


## What decides the card's layout: whether a run is going, where, and with how many fighters.
func _expedition_key() -> String:
	var s := Game.state
	if not Expedition.is_running(s) or s.expedition.battle.is_empty():
		return "idle"
	return "%s|%d" % [s.expedition.battle.zone, s.expedition.battle.allies.size()]


## Refreshes the live parts of the card: status line, health bars, the newest log lines.
func _update_expedition() -> void:
	if _expedition_key() != _exp_key:
		_fill_expedition()
		return
	if _exp_status == null:
		return
	var b: Dictionary = Game.state.expedition.battle
	var z: Dictionary = Data.zones[b.zone]
	var what := ""
	if b.phase == "rest" and not Combat.any_alive(b.allies):
		what = "Resting after a wipe"
	elif int(b.wave) >= int(b.waves):
		what = "Boss: " + z.boss.name
	else:
		what = "Wave %d of %d" % [maxi(1, int(b.wave)), int(b.waves) - 1]
	_exp_status.text = "%s · %s" % [z.name, what]
	for i in mini(_exp_hp.size(), b.allies.size()):
		var f: Dictionary = b.allies[i]
		_exp_hp[i].value = float(f.hp) / maxf(1.0, float(f.maxHp))
	var top: float = Game.battle_log[0].time if not Game.battle_log.is_empty() else 0.0
	if top != _exp_log_top:
		_exp_log_top = top
		UI.clear(_exp_log)
		for e in Game.battle_log.slice(0, 3):
			var l := UI.label(e.text, "Faint", e.color)
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			l.custom_minimum_size.x = 48
			l.tooltip_text = e.text
			l.mouse_filter = Control.MOUSE_FILTER_PASS
			_exp_log.add_child(l)


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
	if fmod(_t, 0.25) < delta:
		_update_expedition()
	if fmod(_t, 0.5) < delta and _goal_state() != _goal_key:
		_fill_goal()


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
					FloatText.spawn(_fx, at, "+%d" % int(e.items[id]), Palette.TEXT, Data.item_icon(id), 18, 36.0)
					break
		"skill_level", "slot_unlocked", "captured", "evolved", "wiped", "run_complete":
			_fill_side()
		"wave", "boss_defeated":
			_fill_side()
