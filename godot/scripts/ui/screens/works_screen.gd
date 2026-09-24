extends Control
## Sanctum Works: permanent upgrades built with gold and crafted parts.

var _list: HFlowContainer


func _ready() -> void:
	var v := UI.vbox(16)
	var m := UI.margin(v, 26, 10, 26, 20)
	var sc := UI.scroll(m)
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sc)
	v.add_child(UI.header("Sanctum Works", "Build up the Sanctum itself: more pods, more perches, more Aether, longer time away.", Data.ui_icon("works")))
	_list = UI.flow(16, 16)
	v.add_child(_list)
	refresh()


func refresh() -> void:
	var s := Game.state
	if s.is_empty():
		return
	UI.clear(_list)
	for u in Data.upgrade_list:
		var lv := GameState.upgrade_level(s, u.id)
		var card := UI.panel("Glass")
		card.custom_minimum_size = Vector2(380, 250)
		var cv := UI.vbox(10)
		card.add_child(cv)
		var h := UI.hbox(12)
		h.add_child(UI.icon(Data.ui_icon(_icon(u.id)), 52))
		var tv := UI.vbox(0)
		tv.add_child(UI.label(u.name, "H2"))
		tv.add_child(UI.label("Level %d of %d" % [lv, u.levels.size()], "Faint"))
		h.add_child(tv)
		cv.add_child(h)
		cv.add_child(UI.wrap_label(u.blurb, "Dim"))
		var pips := UI.hbox(4)
		for i in u.levels.size():
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(26, 6)
			pip.color = Palette.AETHER if i < lv else Color(1, 1, 1, 0.12)
			pips.add_child(pip)
		cv.add_child(pips)
		var now := GameState.upgrade_value(s, u.id)
		var nxt := Economy.next_upgrade(s, u.id)
		if nxt.is_empty():
			cv.add_child(UI.label("Complete: %s" % _fmt(u.id, now), "H3", Palette.GOOD))
		else:
			cv.add_child(UI.hbox(8, [UI.label(_fmt(u.id, now), "H3"), UI.label("next", "Faint"), UI.label(_fmt(u.id, float(nxt.value)), "H3", Palette.AETHER)]))
			cv.add_child(UI.cost_row(nxt.cost, 22))
			var b := UI.button("Build", "Primary", func(): Game.buy_upgrade(u.id))
			b.disabled = not GameState.can_afford(s, nxt.cost)
			cv.add_child(b)
		_list.add_child(card)


func _icon(id: String) -> String:
	return {"genesis-pods": "pods", "perches": "nexus", "extractor": "aether", "offline-cap": "time", "supply-crates": "meal"}.get(id, "upgrade")


func _fmt(id: String, v: float) -> String:
	match id:
		"genesis-pods":
			return "%d pods" % int(v)
		"perches":
			return "%d perches" % int(v)
		"extractor":
			return "+%d Aether/min" % int(v)
		"offline-cap":
			return "%d hours" % int(v)
		"supply-crates":
			return "%d meals per run" % int(v)
	return str(v)
