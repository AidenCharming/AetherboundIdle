extends Control
## Sanctum Works: permanent upgrades built with gold and crafted parts.

var _list: HFlowContainer
var _builds: Dictionary = {}   # upgrade id -> its Build button, kept up to date in _process
var _levels_key := ""         # the upgrade levels the cards were built for
var _tick := 0.0


func _ready() -> void:
	var v := UI.vbox(19)
	var m := UI.margin(v, 31, 12, 31, 24)
	var sc := UI.scroll(m)
	sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sc)
	v.add_child(UI.header("Sanctum Works", "Build up the Sanctum itself: more pods, more perches, more Aether, longer time away.", Data.ui_icon("works")))
	_list = UI.flow(19, 19)
	v.add_child(_list)
	refresh()


## Rebuilds the cards only when an upgrade level changed. Game.changed fires on captures and level-ups too,
## and rebuilding then could free a Build button between mouse down and up, losing the click.
func refresh() -> void:
	var s := Game.state
	if s.is_empty():
		return
	var key := ",".join(Data.upgrade_list.map(func(u): return str(GameState.upgrade_level(s, u.id))))
	if key == _levels_key and not _builds.is_empty():
		_update_builds()
		return
	_levels_key = key
	_builds.clear()
	UI.clear(_list)
	for u in Data.upgrade_list:
		var lv := GameState.upgrade_level(s, u.id)
		var card := UI.panel("Glass")
		card.custom_minimum_size = Vector2(456, 300)
		var cv := UI.vbox(12)
		card.add_child(cv)
		var h := UI.hbox(14)
		var pearl: bool = u.get("pearl", false)
		h.add_child(UI.icon(Data.item_icon("aether-pearl") if pearl else Data.ui_icon(_icon(u.id)), 62))
		var tv := UI.vbox(0)
		tv.add_child(UI.label(u.name, "H2"))
		tv.add_child(UI.chip("Maxed" if lv >= u.levels.size() else "Level %d / %d" % [lv, u.levels.size()], Palette.GOOD if lv >= u.levels.size() else (Palette.AETHER if lv > 0 else Palette.AETHER_DEEP.lightened(0.3)), 14))
		h.add_child(tv)
		cv.add_child(h)
		cv.add_child(UI.wrap_label(u.blurb, "Dim"))
		if pearl and lv == 0 and GameState.count(s, "aether-pearl") < 1:
			cv.add_child(UI.wrap_label("Aether Pearls come from the last two islands' bosses (rarely), releasing Resplendent, Zenith and Aetheric Aetherlings, and finding or releasing shinies.", "Faint"))
		var pips := UI.hbox(5)
		for i in u.levels.size():
			var pip := ColorRect.new()
			pip.custom_minimum_size = Vector2(31, 7)
			pip.color = Palette.AETHER if i < lv else Color(1, 1, 1, 0.12)
			pips.add_child(pip)
		cv.add_child(pips)
		var now := GameState.upgrade_value(s, u.id)
		var nxt := Economy.next_upgrade(s, u.id)
		if nxt.is_empty():
			cv.add_child(UI.label("Complete: %s" % _fmt(u.id, now), "H3", Palette.GOOD))
		else:
			cv.add_child(UI.hbox(10, [UI.label(_fmt(u.id, now), "H3"), UI.label("next", "Faint"), UI.label(_fmt(u.id, float(nxt.value)), "H3", Palette.AETHER)]))
			cv.add_child(UI.cost_row(nxt.cost, 26))
			var b := UI.button("Build", "Primary", func(): Game.buy_upgrade(u.id))
			cv.add_child(b)
			_builds[u.id] = b
		_list.add_child(card)
	_update_builds()


## Gold and materials arrive without Game.changed (workers, the extractor), so whether each Build can be
## afforded is checked a few times a second rather than only when the page was built.
func _update_builds() -> void:
	var s := Game.state
	for id in _builds:
		var nxt := Economy.next_upgrade(s, id)
		var b: Button = _builds[id]
		b.disabled = nxt.is_empty() or not GameState.can_afford(s, nxt.cost)
		b.tooltip_text = "" if not b.disabled else "Not enough gold or materials yet."


func _process(delta: float) -> void:
	_tick -= delta
	if _tick <= 0.0 and not Game.state.is_empty():
		_tick = 0.25
		_update_builds()


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
