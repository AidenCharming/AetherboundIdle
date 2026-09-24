extends Control
## Genesis Pods: choose two parents and a material tier, see every odd, lay an egg, hatch it.

static var parent_a := ""
static var parent_b := ""
static var tier := 1

var _bench: VBoxContainer
var _pods: HFlowContainer
var _pod_views: Array = []   # [{egg, bar, label, button}]


func _ready() -> void:
	var v := UI.vbox(16)
	var m := UI.margin(v, 26, 10, 26, 20)
	var sc := UI.scroll(m)
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sc)
	v.add_child(UI.header("Genesis Pods", "Pair two Aetherlings to lay an egg. Materials set how rare it can be; the parents' own rarity sets the odds.", Data.ui_icon("pods")))
	_bench = UI.vbox(14)
	v.add_child(UI.panel("Glass", _bench))
	var ph := UI.hbox(10)
	ph.add_child(UI.label("Pods", "H2"))
	ph.add_child(UI.spacer())
	v.add_child(ph)
	_pods = UI.flow(14, 14)
	v.add_child(_pods)
	refresh()


func refresh() -> void:
	if Game.state.is_empty():
		return
	if GameState.creature(Game.state, parent_a).is_empty():
		parent_a = ""
	if GameState.creature(Game.state, parent_b).is_empty():
		parent_b = ""
	_fill_bench()
	_fill_pods()


# ---------------------------------------------------------------- the breeding bench

func _fill_bench() -> void:
	var s := Game.state
	UI.clear(_bench)
	var row := UI.hbox(22)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_bench.add_child(row)
	row.add_child(_parent_slot(0))
	var mid := UI.vbox(6)
	mid.custom_minimum_size.x = 330
	mid.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(mid)
	row.add_child(_parent_slot(1))
	var a := GameState.creature(s, parent_a)
	var b := GameState.creature(s, parent_b)
	if a.is_empty() or b.is_empty():
		var hint := UI.wrap_label("Choose two parents. Two of the same species make that species. Two of one type make one of the pair. Two different types make a hybrid, and certain exact pairs make a secret hybrid of their own.", "Dim")
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mid.add_child(hint)
		return
	# offspring
	mid.add_child(UI.label("Could hatch", "Faint"))
	var outs := UI.hbox(12)
	outs.alignment = BoxContainer.ALIGNMENT_CENTER
	for o in Breeding.preview(s, a, b):
		var ov := UI.vbox(2)
		var p := CreaturePortrait.make(o.species, 1, 1, false, 92)
		p.set_silhouette(not o.known)
		ov.add_child(p)
		var nm: String = Data.species[o.species].name if o.known else ("A secret hybrid!" if o.special else "An unknown hybrid")
		var l := UI.label(nm, "H3" if o.known else "Dim")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ov.add_child(l)
		var cl := UI.label(F.pct(o.chance), "Faint")
		cl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ov.add_child(cl)
		outs.add_child(ov)
	mid.add_child(outs)
	# tiers
	_bench.add_child(UI.sep())
	var tr := UI.hbox(10)
	tr.add_child(UI.label("Materials", "H3"))
	for t in range(1, 6):
		var cost := Breeding.cost(a, b, t)
		var ok := GameState.can_afford(s, cost)
		var btn := UI.button("Tier %d · up to %s" % [t, Data.rarity(Breeding.ceiling(t)).name], "ChipOn" if t == tier else "Chip")
		btn.add_theme_color_override("font_color", Palette.TEXT if ok else Palette.TEXT_FAINT)
		btn.pressed.connect(func():
			tier = t
			_fill_bench())
		tr.add_child(btn)
	_bench.add_child(tr)
	var cost := Breeding.cost(a, b, tier)
	var cr := UI.hbox(14)
	cr.add_child(UI.label("Cost", "Faint"))
	cr.add_child(UI.cost_row(cost, 24))
	cr.add_child(UI.spacer())
	var secs := Breeding.hatch_seconds(a, b, tier)
	cr.add_child(UI.stat_line("time", "Hatches in " + F.format_seconds(secs)))
	_bench.add_child(cr)
	# odds
	var odds := Breeding.rarity_odds(a, b, tier)
	_bench.add_child(_odds_bar(odds))
	var legend := UI.flow(14, 4)
	for i in odds.size():
		if odds[i] > 0.00005:
			legend.add_child(UI.label("%s %s" % [Data.rarities[i].name, F.pct(odds[i]) if odds[i] >= 0.001 else "<0.1%"], "Small", Data.rarity_color(i + 1)))
	legend.add_child(UI.label("Shiny %s" % F.pct(Breeding.hatch_chance_shiny(s)), "Small", Palette.GOLD))
	var mb := Breeding.mutation_bonus(a, b)
	if mb > 0:
		legend.add_child(UI.label("Geneticist +%s mutation" % F.pct(mb), "Small", Palette.AETHER))
	_bench.add_child(legend)
	var go := UI.hbox(10)
	go.add_child(UI.wrap_label("Materials: %s for %s parents. Parents aren't used up and keep their jobs." % [
		", ".join([Data.types[Data.species[a.species].types[0]].name, Data.types[Data.species[b.species].types[0]].name]), "both"], "Faint"))
	var err := Breeding.check(s, a, b, tier)
	var lay := UI.button("Lay an egg", "Primary", func():
		if Game.breed(parent_a, parent_b, tier):
			refresh())
	lay.custom_minimum_size = Vector2(200, 46)
	lay.disabled = err != ""
	lay.tooltip_text = err
	go.add_child(lay)
	_bench.add_child(go)
	if err != "":
		var el := UI.label(err, "Small", Palette.DANGER)
		el.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_bench.add_child(el)


func _parent_slot(which: int) -> Control:
	var id := parent_a if which == 0 else parent_b
	var c := GameState.creature(Game.state, id)
	var card := UI.button("", "Tile")
	card.custom_minimum_size = Vector2(210, 250)
	card.pressed.connect(func(): _pick(which))
	var v := UI.vbox(4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_top = 12
	v.offset_bottom = -12
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(v)
	if c.is_empty():
		var e := WorkerBubble.make({}, "woodcutting", 150)
		e.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		e.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(e)
		var l := UI.label("Choose parent %s" % ("A" if which == 0 else "B"), "H3")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
	else:
		var p := CreaturePortrait.of(c, 160)
		p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(p)
		var l := UI.label(Creatures.display_name(c), "H3")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		var r := UI.label("%s · Lv %d" % [Data.rarity(int(c.rarity)).name, int(c.level)], "Faint", Data.rarity_color(int(c.rarity)))
		r.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(r)
		var tl := UI.label("%d pool trait%s" % [c.traits.size(), "" if c.traits.size() == 1 else "s"], "Faint")
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(tl)
	return card


func _pick(which: int) -> void:
	var other := parent_b if which == 0 else parent_a
	var oc := GameState.creature(Game.state, other)
	CreaturePicker.pick("Choose parent %s" % ("A" if which == 0 else "B"),
		func(c): return c.id != other,
		func(cid):
			if which == 0:
				parent_a = cid
			else:
				parent_b = cid
			refresh(),
		func(c):
			if oc.is_empty():
				return "%d pool traits" % c.traits.size()
			var opts := Breeding.preview(Game.state, oc, c)
			if opts.size() == 1:
				return "Makes " + (Data.species[opts[0].species].name if opts[0].known else "??? (new!)")
			return "Makes one of %d" % opts.size(),
		"rarity")


func _odds_bar(odds: Array) -> Control:
	var bar := Control.new()
	bar.custom_minimum_size = Vector2(0, 18)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.draw.connect(func():
		var w := bar.size.x
		var x := 0.0
		for i in odds.size():
			var seg: float = odds[i] * w
			if seg <= 0.0:
				continue
			bar.draw_rect(Rect2(x, 0, maxf(seg, 2.0), bar.size.y), Data.rarity_color(i + 1))
			x += seg
		bar.draw_rect(Rect2(Vector2.ZERO, bar.size), Color(1, 1, 1, 0.15), false, 1.0))
	return bar


# ---------------------------------------------------------------- pods

func _fill_pods() -> void:
	var s := Game.state
	UI.clear(_pods)
	_pod_views.clear()
	var now := Game.now_sec()
	var ready := Game.ready_eggs()
	if ready.size() >= 2:
		var all := UI.button("Hatch all %d" % ready.size(), "Gold", func():
			for i in Game.ready_eggs():
				Game.hatch(i))
		all.custom_minimum_size = Vector2(180, 200)
		_pods.add_child(all)
	for i in s.pods.size():
		var egg: Dictionary = s.pods[i]
		var card := UI.panel("Card")
		card.custom_minimum_size = Vector2(220, 280)
		var v := UI.vbox(6)
		v.alignment = BoxContainer.ALIGNMENT_CENTER
		card.add_child(v)
		v.add_child(UI.label("Pod %d" % (i + 1), "Faint"))
		if egg.is_empty():
			var e := WorkerBubble.make({}, "woodcutting", 120)
			e.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			v.add_child(e)
			var l := UI.label("Empty", "Dim")
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(l)
		else:
			var ev := EggView.make(egg, 150)
			ev.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
			v.add_child(ev)
			var tl := UI.label("", "Dim")
			tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			v.add_child(tl)
			var bar := UI.bar(Palette.AETHER, 8)
			v.add_child(bar)
			var btn := UI.button("", "Gold")
			btn.pressed.connect(func():
				if Breeding.is_ready(Game.state.pods[i], Game.now_sec()):
					Game.hatch(i)
				else:
					Game.speed_up(i))
			v.add_child(btn)
			_pod_views.append({"index": i, "label": tl, "bar": bar, "button": btn, "egg": ev})
		_pods.add_child(card)
	var more := Economy.next_upgrade(s, "genesis-pods")
	if not more.is_empty():
		var lock := UI.panel("CardFlat")
		lock.custom_minimum_size = Vector2(220, 280)
		var lv := UI.vbox(8)
		lv.alignment = BoxContainer.ALIGNMENT_CENTER
		lock.add_child(lv)
		lv.add_child(UI.icon(Data.ui_icon("lock"), 36))
		var l := UI.wrap_label("Build another pod in Sanctum Works", "Faint")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lv.add_child(l)
		lv.add_child(UI.button("Sanctum Works", "", func(): Main.go("works")))
		_pods.add_child(lock)


func _process(_d: float) -> void:
	var s := Game.state
	if s.is_empty():
		return
	var now := Game.now_sec()
	for pv in _pod_views:
		var egg: Dictionary = s.pods[pv.index]
		if egg.is_empty():
			continue
		var total := maxf(1.0, float(egg.readyAt) - float(egg.laidAt))
		var left := Breeding.remaining(egg, now)
		pv.bar.value = 1.0 - left / total
		if left <= 0.0:
			pv.label.text = "Ready!"
			pv.button.text = "Hatch"
			pv.button.theme_type_variation = "Gold"
			if not pv.has("wobble") and not Options.get_value("reduce_motion"):
				pv.wobble = true
				var e: Control = pv.egg
				e.pivot_offset = e.size / 2.0
				var tw := e.create_tween().set_loops()
				tw.tween_property(e, "rotation", 0.08, 0.12)
				tw.tween_property(e, "rotation", -0.08, 0.24)
				tw.tween_property(e, "rotation", 0.0, 0.12)
				tw.tween_interval(1.2)
		else:
			pv.label.text = "Hatches in " + F.format_seconds(left)
			pv.button.text = "Speed up · %d Aether" % Breeding.speed_up_cost(egg, now)
			pv.button.theme_type_variation = ""
	if Engine.get_process_frames() % 60 == 0:
		var ready := Game.ready_eggs().size()
		var shown := _pod_views.filter(func(pv): return pv.label.text == "Ready!").size()
		if ready != shown:
			_fill_pods()
