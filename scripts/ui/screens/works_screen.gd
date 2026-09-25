extends Control
## Sanctum Works: permanent upgrades built with gold and crafted parts.

var _list: HFlowContainer
var _levels := []        ## upgrade levels the cards were built for: they're rebuilt only when these change
var _builds := {}        ## upgrade id -> its Build button, whose enabled state is kept current in place
var _poll := 0.0


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


## Rebuilding on every Game.changed (a capture mid-expedition) freed a Build button between mouse down and up,
## losing the click; and gold earned by work never re-enabled one. So the cards are rebuilt only when an
## upgrade level changes, and the Build buttons follow what you can afford a few times a second.
func refresh() -> void:
	var s := Game.state
	if s.is_empty():
		return
	var levels := Data.upgrade_list.map(func(u): return GameState.upgrade_level(s, u.id))
	if levels == _levels and _list.get_child_count() > 0:
		_update_builds()
		return
	_levels = levels
	_builds.clear()
	UI.clear(_list)
	for u in Data.upgrade_list:
		var lv := GameState.upgrade_level(s, u.id)
		var card := UI.panel("Glass")
		card.custom_minimum_size = Vector2(380, 250)
		var cv := UI.vbox(10)
		card.add_child(cv)
		var h := UI.hbox(12)
		var pearl: bool = u.get("pearl", false)
		h.add_child(UI.icon(Data.item_icon("aether-pearl") if pearl else Data.ui_icon(_icon(u.id)), 52))
		var tv := UI.vbox(0)
		tv.add_child(UI.label(u.name, "H2"))
		tv.add_child(UI.chip("Maxed" if lv >= u.levels.size() else "Level %d / %d" % [lv, u.levels.size()], Palette.GOOD if lv >= u.levels.size() else (Palette.AETHER if lv > 0 else Palette.AETHER_DEEP.lightened(0.3)), 12))
		h.add_child(tv)
		cv.add_child(h)
		cv.add_child(UI.wrap_label(u.blurb, "Dim"))
		if pearl and lv == 0 and GameState.count(s, "aether-pearl") < 1:
			cv.add_child(UI.wrap_label("Aether Pearls come from the last two islands' bosses (rarely), releasing Resplendent and Zenith Aetherlings, and finding or releasing shinies.", "Faint"))
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
			_builds[u.id] = b
			cv.add_child(b)
		_list.add_child(card)


func _process(delta: float) -> void:
	_poll -= delta
	if _poll <= 0.0:
		_poll = 0.25
		refresh()


func _update_builds() -> void:
	for id in _builds:
		var nxt := Economy.next_upgrade(Game.state, id)
		_builds[id].disabled = nxt.is_empty() or not GameState.can_afford(Game.state, nxt.cost)


func _icon(id: String) -> String:
	return {"genesis-pods": "pods", "perches": "nexus", "extractor": "aether", "offline-cap": "time", "supply-crates": "meal"}.get(id, "upgrade")


func _fmt(id: String, v: float) -> String:
	var pt: Dictionary = Data.tuning.pearls
	match id:
		"pearl-lens":
			return "+%s shiny on eggs" % F.pct(float(pt.lensHatchPerLevel) * v)
		"pearl-resonator":
			return "+%d%% mutation" % roundi(float(pt.mutationPerLevel) * v * 100.0)
		"pearl-crucible":
			return "-%d%% attunement cost" % roundi(float(pt.attuneCostPerLevel) * v * 100.0)
		"pearl-incubator":
			return "-%d%% hatch time" % roundi(float(pt.hatchTimePerLevel) * v * 100.0)
		"pearl-vessel":
			return "+%d%% bind chance" % roundi(float(pt.bindPerLevel) * v * 100.0)
		"pearl-hourglass":
			return "+%dh time away" % roundi(float(pt.offlineHoursPerLevel) * v)
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
