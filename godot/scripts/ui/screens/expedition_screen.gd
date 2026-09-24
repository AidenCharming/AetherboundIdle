extends Control
## Expeditions: the islands, the live arena, the party, supplies and auto-bind rules.

var zone_id := ""
var _zones: VBoxContainer
var _arena_host: PanelContainer
var _arena: Arena
var _preview: VBoxContainer
var _right: VBoxContainer
var _log: VBoxContainer
var _controls: HBoxContainer
var _sky: SkyBackdrop
var _log_count := -1


func setup(arg: String) -> void:
	zone_id = arg


func _ready() -> void:
	var s := Game.state
	if zone_id == "":
		zone_id = s.expedition.zone if s.expedition.zone != "" else Data.zone_list[0].id
	var row := UI.hbox(16)
	var m := UI.margin(row, 22, 10, 22, 18)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	# zones
	var zl := UI.vbox(10)
	zl.custom_minimum_size.x = 268
	zl.add_child(UI.header("Expeditions", "", Data.ui_icon("expeditions"), 38))
	_zones = UI.vbox(8)
	zl.add_child(UI.scroll(_zones))
	row.add_child(zl)
	# centre: arena + log
	var mid := UI.vbox(12)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(mid)
	_arena_host = PanelContainer.new()
	var sb := ThemeFactory.box(Color(0, 0, 0, 0), 20, 1, Palette.LINE, 0, 14)
	_arena_host.add_theme_stylebox_override("panel", sb)
	_arena_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_arena_host.clip_contents = true
	mid.add_child(_arena_host)
	_sky = SkyBackdrop.new()
	_arena_host.add_child(_sky)
	_arena = Arena.new()
	_arena_host.add_child(_arena)
	_preview = UI.vbox(10)
	_arena_host.add_child(UI.margin(_preview, 28, 22, 28, 22))
	_controls = UI.hbox(10)
	mid.add_child(_controls)
	var logp := UI.panel("CardFlat")
	logp.custom_minimum_size.y = 150
	_log = UI.vbox(2)
	logp.add_child(UI.scroll(_log))
	mid.add_child(logp)
	# right: party and rules
	_right = UI.vbox(12)
	_right.custom_minimum_size.x = 320
	row.add_child(UI.scroll(_right))
	refresh()


func refresh() -> void:
	if Game.state.is_empty():
		return
	_fill_zones()
	_fill_preview()
	_fill_controls()
	_fill_right()


func _fill_zones() -> void:
	var s := Game.state
	UI.clear(_zones)
	for z in Data.zone_list:
		var unlocked := Expedition.zone_unlocked(s, z.id)
		var zs := Expedition.zone_state(s, z.id)
		var card := UI.button("", "TileOn" if z.id == zone_id else "Tile")
		card.custom_minimum_size = Vector2(262, 92)
		card.pressed.connect(func():
			zone_id = z.id
			refresh())
		var v := UI.vbox(3)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 14
		v.offset_right = -12
		v.offset_top = 10
		v.offset_bottom = -10
		card.add_child(v)
		var h := UI.hbox(8)
		h.add_child(UI.label(z.name, "H3"))
		h.add_child(UI.spacer())
		h.add_child(UI.type_badge(z.type, true))
		v.add_child(h)
		v.add_child(UI.label("Levels %d–%d · Boss: %s" % [int(z.levels[0]), int(z.levels[1]), z.boss.name], "Faint"))
		var status := ""
		if not unlocked:
			status = "Locked: defeat %s first" % Data.zones[z.unlockAfter].boss.name
		elif zs.cleared:
			status = "Cleared · %d runs" % int(zs.runs)
		else:
			status = "Best: wave %d" % int(zs.bestWave) if int(zs.bestWave) > 0 else "Unexplored"
		v.add_child(UI.label(status, "Small", Palette.GOOD if zs.cleared else (Palette.TEXT_FAINT if not unlocked else Palette.AETHER)))
		if not unlocked:
			card.modulate.a = 0.5
		_zones.add_child(card)


func _fill_preview() -> void:
	var s := Game.state
	var z: Dictionary = Data.zones[zone_id]
	var c := Data.type_color(z.type)
	_sky.set_colors(Color(0.03, 0.035, 0.09), c.darkened(0.78))
	_sky.tint(c.darkened(0.3), Color(0.3, 0.3, 0.8), 0.3)
	UI.clear(_preview)
	var running_here: bool = Expedition.is_running(s) and s.expedition.zone == zone_id
	_preview.visible = not running_here
	if running_here:
		return
	_preview.add_child(UI.label(z.name, "H1"))
	_preview.add_child(UI.wrap_label(z.blurb, "Dim"))
	_preview.add_child(UI.label("Aetherlings seen here", "H3"))
	var natives := UI.flow(10, 10)
	var total := 0.0
	for id in z.species:
		total += float(z.species[id])
	for id in z.species:
		var seen: bool = s.collection.seen.has(id)
		var v := UI.vbox(2)
		var p := CreaturePortrait.make(id, 1, 1, false, 84)
		p.bob = false
		p.set_silhouette(not seen)
		v.add_child(p)
		var l := UI.label(Data.species[id].name if seen else "???", "Small")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(l)
		var owned := Collection.is_owned(s, id)
		var pl := UI.label("%s%s" % [F.pct(float(z.species[id]) / total), "  · owned" if owned else ""], "Faint")
		pl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(pl)
		natives.add_child(v)
	_preview.add_child(natives)
	var boss := UI.hbox(14)
	var bp := CreaturePortrait.make(z.boss.model, int(z.boss.form), 3, false, 110)
	bp.set_silhouette(not Expedition.zone_state(s, z.id).cleared and int(Expedition.zone_state(s, z.id).bestWave) < int(z.waves))
	boss.add_child(bp)
	var bv := UI.vbox(2)
	bv.add_child(UI.label("Boss: " + z.boss.name, "H3", Palette.GOLD))
	bv.add_child(UI.label("Level %d · waits after %d waves" % [int(z.boss.level), int(z.waves)], "Dim"))
	var loot := UI.hbox(8, [UI.label("First-clear and repeat reward:", "Faint")])
	loot.add_child(UI.amount("gold", float(z.bossLoot.gold), -1, 18))
	for id in z.bossLoot.items:
		loot.add_child(UI.amount(id, float(z.bossLoot.items[id]), -1, 18))
	bv.add_child(loot)
	if z.has("firstClearCreature"):
		bv.add_child(UI.label("First clear also brings a Void Aetherling home.", "Faint", Data.type_color("void")))
	boss.add_child(bv)
	_preview.add_child(boss)
	var loot2 := UI.hbox(8, [UI.label("Found along the way:", "Faint")])
	loot2.add_child(UI.amount("gold", float(z.gold[1]), -1, 18))
	for l in z.loot:
		loot2.add_child(UI.icon(Data.item_icon(l.item), 22))
	_preview.add_child(loot2)


func _fill_controls() -> void:
	var s := Game.state
	UI.clear(_controls)
	var z: Dictionary = Data.zones[zone_id]
	var running: bool = Expedition.is_running(s)
	if running and s.expedition.zone == zone_id:
		_controls.add_child(UI.button("Stop the expedition", "Danger", func(): Game.stop_expedition()))
	elif Expedition.zone_unlocked(s, zone_id):
		var txt := "Explore %s" % z.name if not running else "Move the party to %s" % z.name
		var b := UI.button(txt, "Primary", func(): Game.start_expedition(zone_id))
		b.disabled = GameState.party(s).is_empty()
		if b.disabled:
			b.tooltip_text = "Choose a party on the right first."
		_controls.add_child(b)
	else:
		_controls.add_child(UI.label("Defeat %s to open this island." % Data.zones[z.unlockAfter].boss.name, "Dim"))
	var rep := CheckButton.new()
	rep.text = "Repeat runs automatically"
	rep.button_pressed = bool(s.expedition.autoRepeat)
	rep.toggled.connect(func(on):
		Game.state.expedition.autoRepeat = on)
	_controls.add_child(UI.spacer())
	_controls.add_child(rep)


func _fill_right() -> void:
	var s := Game.state
	UI.clear(_right)
	# party
	var pv := UI.vbox(8)
	pv.add_child(UI.hbox(8, [UI.icon(Data.ui_icon("power"), 22), UI.label("Party", "H3")]))
	pv.add_child(UI.wrap_label("Up to three. Party members don't work or gather Aether while they explore.", "Faint"))
	var party := GameState.party(s)
	var size: int = Data.tuning.combat.partySize
	for i in size:
		var h := UI.hbox(10)
		if i < party.size():
			var c: Dictionary = party[i]
			var por := CreaturePortrait.of(c, 64)
			por.bob = false
			h.add_child(por)
			var cv := UI.vbox(0)
			cv.add_child(UI.label(Creatures.display_name(c), "H3"))
			var st := Creatures.stats(c)
			cv.add_child(UI.label("Lv %d · %s" % [int(c.level), " / ".join(Creatures.types_of(c).map(func(t): return Data.types[t].name))], "Faint"))
			cv.add_child(UI.label("HP %s · PWR %s · GRD %s" % [F.format_num(st.health), F.format_num(st.power), F.format_num(st.guard)], "Faint"))
			h.add_child(cv)
			h.add_child(UI.spacer())
			h.add_child(UI.button("Swap", "Ghost", func(): _pick_party(i)))
			h.add_child(UI.button("Remove", "Ghost", func(): Game.bench(c.id)))
		else:
			var e := WorkerBubble.make({}, "woodcutting", 64)
			h.add_child(e)
			h.add_child(UI.button("Add an Aetherling", "", func(): _pick_party(i)))
		pv.add_child(h)
	_right.add_child(UI.panel("Glass", pv))
	# supplies
	var sv := UI.vbox(8)
	sv.add_child(UI.hbox(8, [UI.icon(Data.ui_icon("meal"), 22), UI.label("Supplies", "H3")]))
	sv.add_child(UI.wrap_label("Between waves the party eats a meal when anyone drops below %d%% Health. Carries %d meals per run (Supply Crates raise it)." % [roundi(float(Data.tuning.combat.eatBelow) * 100), int(GameState.upgrade_value(s, "supply-crates"))], "Faint"))
	var ob := OptionButton.new()
	ob.add_item("Best meal available", 0)
	var meals := Data.item_list.filter(func(it): return it.category == "meal")
	for i in meals.size():
		ob.add_item("%s (heals %d%%) · %d" % [meals[i].name, roundi(float(meals[i].heal) * 100), int(GameState.count(s, meals[i].id))], i + 1)
		if s.expedition.meal == meals[i].id:
			ob.selected = i + 1
	ob.item_selected.connect(func(i): Game.state.expedition.meal = "" if i == 0 else meals[i - 1].id)
	sv.add_child(ob)
	if GameState.count(s, Expedition.pick_meal(s)) < 1:
		sv.add_child(UI.label("No meals: cook some (Cooking needs a Pyric Aetherling)", "Small", Palette.DANGER))
	_right.add_child(UI.panel("Glass", sv))
	# auto-bind
	var bv := UI.vbox(8)
	var ab: Dictionary = s.expedition.autobind
	bv.add_child(UI.hbox(8, [UI.icon(Data.ui_icon("vessel"), 22), UI.label("Auto-bind", "H3")]))
	bv.add_child(UI.wrap_label("After a wild Aetherling is defeated, the party can throw a vessel to bind it. The first of each type you have never owned binds for free; shinies are always tried.", "Faint"))
	var en := CheckButton.new()
	en.text = "Throw vessels automatically"
	en.button_pressed = bool(ab.get("enabled", true))
	en.toggled.connect(func(on): Game.state.expedition.autobind.enabled = on)
	bv.add_child(en)
	var ns := CheckButton.new()
	ns.text = "Always try species I don't own"
	ns.button_pressed = bool(ab.get("newSpecies", true))
	ns.toggled.connect(func(on): Game.state.expedition.autobind.newSpecies = on)
	bv.add_child(ns)
	var rrow := UI.hbox(8, [UI.label("Otherwise, only", "Dim")])
	var rb := OptionButton.new()
	for i in Data.rarities.size():
		rb.add_item("%s or better" % Data.rarities[i].name, i)
	rb.selected = int(ab.get("minRarity", 1)) - 1
	rb.item_selected.connect(func(i): Game.state.expedition.autobind.minRarity = i + 1)
	rrow.add_child(rb)
	bv.add_child(rrow)
	var vrow := UI.hbox(8, [UI.label("Vessel", "Dim")])
	var vb := OptionButton.new()
	var vessel_ids := ["best", "cheapest"]
	vb.add_item("Best I have", 0)
	vb.add_item("Cheapest I have", 1)
	for it in Data.item_list:
		if it.category == "vessel":
			vessel_ids.append(it.id)
			vb.add_item("%s · %d" % [it.name, int(GameState.count(s, it.id))], vessel_ids.size() - 1)
	vb.selected = maxi(0, vessel_ids.find(ab.get("vessel", "best")))
	vb.item_selected.connect(func(i): Game.state.expedition.autobind.vessel = vessel_ids[i])
	vrow.add_child(vb)
	bv.add_child(vrow)
	var odds := UI.vbox(2)
	odds.add_child(UI.label("Bind chance with your best vessel", "Faint"))
	var best := Expedition.choose_vessel(s, {"shiny": true, "species": "", "rarity": 1})
	if best == "":
		odds.add_child(UI.label("You have no vessels. Fabrication makes Tinker's Vessels; the Market sells them.", "Small", Palette.DANGER))
	else:
		var line := []
		for r in [1, 2, 3, 4, 5]:
			line.append("%s %s" % [Data.rarity(r).name, F.pct(Expedition.bind_chance(s, best, r, party))])
		odds.add_child(UI.wrap_label(" · ".join(line), "Dim"))
	bv.add_child(odds)
	_right.add_child(UI.panel("Glass", bv))
	# pending shinies
	if not s.expedition.pending.is_empty():
		var pd := UI.vbox(8)
		pd.add_child(UI.label("Waiting to be bound", "H3", Palette.GOLD))
		for i in s.expedition.pending.size():
			var w: Dictionary = s.expedition.pending[i]
			var h := UI.hbox(8)
			h.add_child(CreaturePortrait.make(w.species, F.form_for_level(int(w.level)), int(w.rarity), bool(w.shiny), 56))
			h.add_child(UI.label("%s %s" % [Data.rarity(int(w.rarity)).name, Data.species[w.species].name], ""))
			h.add_child(UI.spacer())
			var v := Expedition.choose_vessel(s, {"shiny": true, "species": w.species, "rarity": w.rarity})
			var b := UI.button("Throw", "Gold", func(): Game.retry_pending(i, v))
			b.disabled = v == ""
			h.add_child(b)
			pd.add_child(h)
		_right.add_child(UI.panel("Glass", pd))


func _pick_party(slot: int) -> void:
	CreaturePicker.pick("Choose a party member",
		func(c): return Creatures.job_kind(c) != "party",
		func(cid): Game.set_party(slot, cid),
		func(c):
			var st := Creatures.stats(c)
			return "HP %s · PWR %s" % [F.format_num(st.health), F.format_num(st.power)],
		"best")


func _process(_d: float) -> void:
	var s := Game.state
	if s.is_empty():
		return
	var running_here: bool = Expedition.is_running(s) and s.expedition.zone == zone_id
	if _preview.visible == running_here:
		_fill_preview()
		_fill_controls()
	_arena.visible = running_here
	if Game.battle_log.size() != _log_count or (not Game.battle_log.is_empty() and _log.get_child_count() > 0 and _log.get_child(0).get_meta("t", 0.0) != Game.battle_log[0].time):
		_log_count = Game.battle_log.size()
		UI.clear(_log)
		if Game.battle_log.is_empty():
			_log.add_child(UI.label("The expedition log fills up as your party explores.", "Faint"))
		for e in Game.battle_log.slice(0, 20):
			var l := UI.label(e.text, "Dim", e.color)
			l.set_meta("t", e.time)
			_log.add_child(l)
