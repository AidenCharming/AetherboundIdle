extends Control
## Expeditions: the islands, the live arena, the party, supplies and auto-bind rules.

var zone_id := ""
var _zones: VBoxContainer
var _arena_host: PanelContainer
var _arena: Arena
var _preview: VBoxContainer
var _right: VBoxContainer
var _log: VBoxContainer
var _log_top := -1.0
var _bind: VBoxContainer
var _controls: HBoxContainer
var _sky: SkyBackdrop
var _log_count := -1
var _party_locked := false
var _pending_count := -1
var _bottom_tab := "autobind"


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
	# auto-bind rules sit under the battle, in two columns
	_bind = UI.vbox(8)
	mid.add_child(UI.panel("Glass", _bind))
	# right: party and supplies on top, the expedition log filling the rest
	var rcol := UI.vbox(12)
	rcol.custom_minimum_size.x = 380
	row.add_child(rcol)
	_right = UI.vbox(12)
	rcol.add_child(_right)
	var logp := UI.panel("Glass")
	logp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lv := UI.vbox(8)
	logp.add_child(lv)
	lv.add_child(UI.hbox(8, [UI.icon(Data.ui_icon("aetherlog"), 22), UI.label("Expedition log", "H3")]))
	_log = UI.vbox(4)
	var lsc := UI.scroll(_log)
	lsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(lsc)
	rcol.add_child(logp)
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
		h.add_child(_fit(UI.label(z.name, "H3")))
		h.add_child(UI.type_badge(z.type, true))
		v.add_child(h)
		v.add_child(_fit(UI.label("Levels %d–%d · Boss: %s" % [int(z.levels[0]), int(z.levels[1]), z.boss.name], "Faint")))
		card.tooltip_text = "%s\nLevels %d–%d · Boss: %s" % [z.name, int(z.levels[0]), int(z.levels[1]), z.boss.name]
		var fill := Control.new()
		fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
		fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(fill)
		v.add_child(_zone_status(z, zs, unlocked))
		if not unlocked:
			card.modulate.a = 0.5
		_zones.add_child(card)


## Lets a card label shrink to the card, ending in "…", instead of spilling past its right edge.
func _fit(l: Label) -> Label:
	l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.custom_minimum_size.x = 40
	return l


## The bottom line of a zone card: a small dot and a word on where the player stands.
func _zone_status(z: Dictionary, zs: Dictionary, unlocked: bool) -> HBoxContainer:
	var text := ""
	var col := Palette.TEXT_DIM
	var dot := Palette.TEXT_FAINT
	var hollow := false
	if not unlocked:
		text = "Locked · defeat %s first" % Data.zones[z.unlockAfter].boss.name
		col = Palette.TEXT_FAINT
	elif zs.cleared:
		text = "Cleared · %d %s" % [int(zs.runs), "run" if int(zs.runs) == 1 else "runs"]
		col = Palette.GOOD
		dot = Palette.GOOD
	elif int(zs.bestWave) > 0:
		text = "Reached wave %d of %d" % [int(zs.bestWave), int(z.waves)]
		dot = Palette.AETHER
	else:
		text = "Not explored yet"
		dot = Palette.AETHER
		hollow = true
	var d := Panel.new()
	d.custom_minimum_size = Vector2(8, 8)
	d.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	d.mouse_filter = Control.MOUSE_FILTER_IGNORE
	d.add_theme_stylebox_override("panel", ThemeFactory.box(Color(dot, 0.0) if hollow else dot, 99, 2 if hollow else 0, dot, 0))
	var h := UI.hbox(7, [d, _fit(UI.label(text, "Faint", col))])
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


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
		if Collection.is_owned(s, id):
			p.add_child(UI.owned_mark(26, Vector2(84, 84)))
		var pl := UI.label(F.pct(float(z.species[id]) / total), "Faint")
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
	# shinies waiting for a vessel come first, with a pulsing gold edge, so they are never missed
	if not s.expedition.pending.is_empty():
		_right.add_child(_pending_panel())
	# party, compact: the log below gets the room
	var pv := UI.vbox(6)
	var party := GameState.party(s)
	var party_size: int = Data.tuning.combat.partySize
	var locked := Expedition.party_locked(s)
	_party_locked = locked
	var ph := UI.hbox(8, [UI.icon(Data.ui_icon("power"), 22), UI.label("Party", "H3")])
	if locked:
		ph.add_child(UI.spacer())
		ph.add_child(UI.icon(Data.ui_icon("lock"), 16))
		ph.add_child(UI.label("Locked during the run", "Faint"))
	pv.add_child(ph)
	if not locked:
		pv.add_child(UI.wrap_label("Up to three. Party members don't work or gather Aether while they explore.", "Faint", 320))
	for i in party_size:
		var h := UI.hbox(10)
		if i < party.size():
			var c: Dictionary = party[i]
			var por := CreaturePortrait.of(c, 50)
			por.bob = false
			h.add_child(por)
			var cv := UI.vbox(0)
			cv.add_child(UI.label(Creatures.display_name(c), "H3"))
			var st := Creatures.stats(c)
			cv.add_child(UI.label("Lv %d · HP %s · PWR %s · GRD %s" % [int(c.level), F.format_num(st.health), F.format_num(st.power), F.format_num(st.guard)], "Faint"))
			h.add_child(cv)
			h.add_child(UI.spacer())
			if not locked:
				h.add_child(UI.button("Swap", "Ghost", func(): _pick_party(i)))
				h.add_child(UI.button("Remove", "Ghost", func(): Game.bench(c.id)))
		elif not locked:
			var e := WorkerBubble.make({}, "woodcutting", 50)
			h.add_child(e)
			h.add_child(UI.button("Add an Aetherling", "", func(): _pick_party(i)))
		if h.get_child_count() > 0:
			pv.add_child(h)
		else:
			h.free()
	_right.add_child(UI.panel("Glass", pv))
	_fill_bottom()


## The panel under the battle: Auto-bind and Supplies, as two tabs.
func _fill_bottom() -> void:
	var s := Game.state
	UI.clear(_bind)
	var tabs := UI.hbox(8)
	for pair in [["autobind", "Auto-bind", "vessel"], ["supplies", "Supplies", "meal"]]:
		var b := UI.button(pair[1], "ChipOn" if _bottom_tab == pair[0] else "Chip", func():
			_bottom_tab = pair[0]
			_fill_bottom(), Data.ui_icon(pair[2]))
		tabs.add_child(b)
	_bind.add_child(tabs)
	if _bottom_tab == "supplies":
		var sv := UI.vbox(8)
		sv.add_child(UI.wrap_label("Between waves the party eats a meal when anyone drops below %d%% Health. Carries %d meals per run (Supply Crates raise it)." % [roundi(float(Data.tuning.combat.eatBelow) * 100), int(GameState.upgrade_value(s, "supply-crates"))], "Faint", 560))
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
		_bind.add_child(sv)
		return
	var ab: Dictionary = s.expedition.autobind
	var cols := UI.hbox(16)
	_bind.add_child(cols)
	var bv := UI.vbox(4)
	bv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(bv)
	var bv2 := UI.vbox(6)
	cols.add_child(bv2)
	var en := CheckButton.new()
	en.text = "Throw vessels"
	en.tooltip_text = "After a win the party can throw a vessel. The first of each type you've never owned binds free; shinies are always tried."
	en.button_pressed = bool(ab.get("enabled", true))
	en.toggled.connect(func(on): Game.state.expedition.autobind.enabled = on)
	bv.add_child(en)
	var ns := CheckButton.new()
	ns.text = "Always try new species"
	ns.button_pressed = bool(ab.get("newSpecies", true))
	ns.toggled.connect(func(on): Game.state.expedition.autobind.newSpecies = on)
	bv.add_child(ns)
	var best := Expedition.choose_vessel(s, {"shiny": true, "species": "", "rarity": 1})
	if best == "":
		bv.add_child(UI.wrap_label("No vessels! Fabrication makes them; the Market sells them.", "Small", 260))
		bv.get_child(bv.get_child_count() - 1).add_theme_color_override("font_color", Palette.DANGER)
	else:
		var line := []
		for r in [1, 2, 3, 4, 5]:
			line.append("%s %s" % [Data.rarity(r).name, F.pct(Expedition.bind_chance(s, best, r, GameState.party(s)))])
		bv.add_child(UI.wrap_label("Bind chance: " + " · ".join(line), "Faint", 260))
	var rb := _small_choice(bv2, "Only")
	for i in Data.rarities.size():
		rb.add_item("%s or better" % Data.rarities[i].name, i)
	rb.selected = int(ab.get("minRarity", 1)) - 1
	rb.item_selected.connect(func(i): Game.state.expedition.autobind.minRarity = i + 1)
	var cb := _small_choice(bv2, "Keep")
	cb.tooltip_text = "A copy rarer than your best one is always tried."
	var caps := [1, 3, 5, 10, 25, 999]
	for i in caps.size():
		cb.add_item("All of them" if caps[i] == 999 else "%d per species" % caps[i], i)
	cb.selected = maxi(0, caps.find(int(ab.get("maxCopies", 5))))
	cb.item_selected.connect(func(i): Game.state.expedition.autobind.maxCopies = caps[i])
	var vb := _small_choice(bv2, "Vessel")
	var vessel_ids := ["best", "cheapest"]
	vb.add_item("Best I have", 0)
	vb.add_item("Cheapest I have", 1)
	for it in Data.item_list:
		if it.category == "vessel":
			vessel_ids.append(it.id)
			vb.add_item("%s · %d" % [it.name, int(GameState.count(s, it.id))], vessel_ids.size() - 1)
	vb.selected = maxi(0, vessel_ids.find(ab.get("vessel", "best")))
	vb.item_selected.connect(func(i): Game.state.expedition.autobind.vessel = vessel_ids[i])


## A labelled, fixed-width dropdown row for the Auto-bind column.
func _small_choice(parent: Control, title: String) -> OptionButton:
	var l := UI.label(title, "Dim")
	l.custom_minimum_size.x = 56
	var o := OptionButton.new()
	o.custom_minimum_size.x = 200
	o.clip_text = true
	o.fit_to_longest_item = false
	parent.add_child(UI.hbox(8, [l, o]))
	return o


func _pending_panel() -> PanelContainer:
	var s := Game.state
	var pd := UI.vbox(8)
	var n: int = s.expedition.pending.size()
	var head := UI.hbox(8, [UI.icon(Data.ui_icon("shiny"), 24), UI.label("%d waiting to be bound" % n, "H3", Palette.GOLD)])
	head.add_child(UI.spacer())
	head.add_child(UI.button("Throw at all", "Gold", func():
		for i in range(Game.state.expedition.pending.size() - 1, -1, -1):
			var w: Dictionary = Game.state.expedition.pending[i]
			var v := Expedition.choose_vessel(Game.state, {"shiny": true, "species": w.species, "rarity": w.rarity})
			if v != "":
				Game.retry_pending(i, v)))
	pd.add_child(head)
	pd.add_child(UI.wrap_label("They wait until you throw a vessel. Out of vessels? Fabrication makes them; the Market sells them.", "Faint", 320))
	var grid := UI.flow(6, 6)
	for i in s.expedition.pending.size():
		var w: Dictionary = s.expedition.pending[i]
		var cell := UI.vbox(2)
		var por := CreaturePortrait.make(w.species, F.form_for_level(int(w.level)), int(w.rarity), bool(w.shiny), 52)
		por.bob = false
		por.tooltip_text = "%s%s %s" % ["Shiny " if w.shiny else "", Data.rarity(int(w.rarity)).name, Data.species[w.species].name]
		cell.add_child(por)
		var v := Expedition.choose_vessel(s, {"shiny": true, "species": w.species, "rarity": w.rarity})
		var b := UI.button("Throw", "Gold", func(): Game.retry_pending(i, v))
		b.disabled = v == ""
		cell.add_child(b)
		grid.add_child(cell)
	pd.add_child(grid)
	var panel := UI.panel("Glass", pd)
	var sb: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
	sb.border_color = Palette.GOLD
	sb.set_border_width_all(2)
	sb.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", sb)
	var tw := panel.create_tween().set_loops()
	tw.tween_method(func(k: float): sb.border_color = Palette.GOLD.lerp(Color(Palette.GOLD, 0.25), k), 0.0, 1.0, 0.6)
	tw.tween_method(func(k: float): sb.border_color = Palette.GOLD.lerp(Color(Palette.GOLD, 0.25), k), 1.0, 0.0, 0.6)
	return panel


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
	if Expedition.party_locked(s) != _party_locked or s.expedition.pending.size() != _pending_count:
		_pending_count = s.expedition.pending.size()
		_fill_right()  # a run ending on its own frees the party; a shiny may be waiting for a vessel
	_arena.visible = running_here
	var top: float = Game.battle_log[0].time if not Game.battle_log.is_empty() else -1.0
	if Game.battle_log.size() != _log_count or top != _log_top:
		_log_count = Game.battle_log.size()
		_log_top = top
		_render_log()


## The expedition log: each line a small card with an icon (a portrait for a capture), its text, and how long
## ago it happened, edged in the line's colour.
func _render_log() -> void:
	UI.clear(_log)
	if Game.battle_log.is_empty():
		_log.add_child(UI.wrap_label("The expedition log fills up as your party explores.", "Faint", 300))
		return
	var now := Game.now_sec()
	for e in Game.battle_log.slice(0, 40):
		var col: Color = e.color
		var card := PanelContainer.new()
		var sb := ThemeFactory.box(Color(col, 0.07), 8, 0, Palette.LINE, 0)
		sb.border_width_left = 3
		sb.border_color = Color(col, 0.8)
		sb.content_margin_left = 8
		sb.content_margin_right = 8
		sb.content_margin_top = 4
		sb.content_margin_bottom = 4
		card.add_theme_stylebox_override("panel", sb)
		var h := UI.hbox(8)
		if e.has("species"):
			var por := CreaturePortrait.make(e.species, 1, int(e.rarity), bool(e.shiny), 30)
			por.bob = false
			h.add_child(por)
		elif e.get("icon") != null:
			h.add_child(UI.icon(e.icon, 22))
		else:
			h.add_child(UI.icon(Data.ui_icon("expeditions"), 22))
		var l := UI.label(e.text, "", col)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.custom_minimum_size.x = 60
		l.tooltip_text = e.text
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		h.add_child(l)
		var ago := now - float(e.time)
		h.add_child(UI.label("now" if ago < 60 else F.format_seconds(ago), "Faint"))
		card.add_child(h)
		_log.add_child(card)
