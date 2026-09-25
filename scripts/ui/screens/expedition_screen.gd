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
var _tabs_box: HBoxContainer
var _controls: HBoxContainer
var _sky: SkyBackdrop
var _log_count := -1
var _log_whens: Array = []   # [{label, tile, time}] the log's "how long ago" texts, refreshed once a second
var _whens_left := 0.0
var _party_locked := false
var _pending_count := -1
var _bottom_tab := "party"
var _folds := {}          # "zones"/"log" -> [full panel, folded strip]
var _log_strip: VBoxContainer
var _log_mini: VBoxContainer  # the folded log strip's column of recent entries, as small icon cards
var _xp_rows: Array = []      # the party cards' live XP: [{cid, bar, lv (chip), tip (Control)}]


func setup(arg: String) -> void:
	zone_id = arg


func _ready() -> void:
	var s := Game.state
	if zone_id == "":
		zone_id = s.expedition.zone if s.expedition.zone != "" else Data.zone_list[0].id
	var row := UI.hbox(10)
	var m := UI.margin(row, 12, 8, 12, 10)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	# zones: a list that folds to a slim strip (the choice is remembered in Options)
	var zl := UI.vbox(8)
	zl.custom_minimum_size.x = 268
	var zh := UI.hbox(6)
	zh.add_child(UI.header("Expeditions", "", Data.ui_icon("expeditions"), 38))
	zh.get_child(0).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var zfold := _fold_button("‹", func(): _set_open("exp_zones_open", false))
	zfold.tooltip_text = "Hide the island list"
	zh.add_child(zfold)
	zl.add_child(zh)
	_zones = UI.vbox(8)
	zl.add_child(UI.scroll(_zones))
	row.add_child(zl)
	var zstrip := _strip("›", "Show the island list", Data.ui_icon("expeditions"), func(): _set_open("exp_zones_open", true))
	row.add_child(zstrip)
	_folds.zones = [zl, zstrip]
	# centre: arena + log
	var mid := UI.vbox(8)
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
	# under the battle: one panel with the tabs (Party, Auto-bind, Supplies) and the run controls on the same row
	var bottom := UI.vbox(8)
	var top := UI.hbox(8)
	_tabs_box = UI.hbox(8)
	top.add_child(_tabs_box)
	top.add_child(UI.spacer())
	_controls = UI.hbox(10)
	top.add_child(_controls)
	bottom.add_child(top)
	_bind = UI.vbox(8)
	bottom.add_child(_bind)
	mid.add_child(UI.panel("Glass", bottom))
	# right: shinies waiting for a vessel, then the expedition log filling the column; it folds to a strip
	var rcol := UI.vbox(8)
	rcol.custom_minimum_size.x = 340
	row.add_child(rcol)
	_right = UI.vbox(12)
	rcol.add_child(_right)
	var logp := UI.panel("Glass")
	logp.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lv := UI.vbox(8)
	logp.add_child(lv)
	var lh := UI.hbox(8, [UI.icon(Data.ui_icon("aetherlog"), 22), UI.label("Expedition log", "H3"), UI.spacer()])
	var lfold := _fold_button("›", func(): _set_open("exp_log_open", false))
	lfold.tooltip_text = "Hide the log"
	lh.add_child(lfold)
	lv.add_child(lh)
	_log_strip = _strip("‹", "Show the log", Data.ui_icon("aetherlog"), func(): _set_open("exp_log_open", true))
	# folded, the log still shows its latest lines as icons; hover one for its text, click to unfold
	var clip := Control.new()
	clip.clip_contents = true
	clip.size_flags_vertical = Control.SIZE_EXPAND_FILL
	clip.custom_minimum_size.x = 44
	_log_mini = UI.vbox(6)
	_log_mini.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	clip.add_child(_log_mini)
	_log_strip.add_child(clip)
	row.add_child(_log_strip)
	_folds.log = [rcol, _log_strip]
	_log = UI.vbox(4)
	var lsc := UI.scroll(_log)
	lsc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lv.add_child(lsc)
	rcol.add_child(logp)
	refresh()


func refresh() -> void:
	if Game.state.is_empty():
		return
	_apply_folds()
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
		var zl := UI.hbox(6, [UI.chip("Lv %d–%d" % [int(z.levels[0]), int(z.levels[1])], Data.type_color(z.type), 11), _fit(UI.label("Boss: %s" % z.boss.name, "Small", Palette.TEXT_DIM))])
		v.add_child(zl)
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
		var stop := UI.button("Stop", "Danger", func(): Game.stop_expedition())
		stop.tooltip_text = "Stop the expedition"
		_controls.add_child(stop)
	elif Expedition.zone_unlocked(s, zone_id):
		var b := UI.button("Explore" if not running else "Move here", "Primary", func(): Game.start_expedition(zone_id))
		b.tooltip_text = ("Explore %s" if not running else "Move the party to %s") % z.name
		b.disabled = GameState.party(s).is_empty()
		if b.disabled:
			b.tooltip_text = "Choose a party on the right first."
		_controls.add_child(b)
	else:
		var lk := UI.label("Locked", "Dim")
		lk.tooltip_text = "Defeat %s to open this island." % Data.zones[z.unlockAfter].boss.name
		lk.mouse_filter = Control.MOUSE_FILTER_PASS
		_controls.add_child(UI.hbox(6, [UI.icon(Data.ui_icon("lock"), 16), lk]))
	var rep := ToggleSwitch.new()
	rep.text = "Repeat"
	rep.tooltip_text = "Start the next run by itself when one ends."
	rep.button_pressed = bool(s.expedition.autoRepeat)
	rep.toggled.connect(func(on):
		Game.state.expedition.autoRepeat = on)
	_controls.add_child(rep)


func _fill_right() -> void:
	var s := Game.state
	UI.clear(_right)
	_party_locked = Expedition.party_locked(s)
	# shinies waiting for a vessel come first, with a pulsing gold edge, so they are never missed
	if not s.expedition.pending.is_empty():
		_right.add_child(_pending_panel())
	# the folded log strip shows the waiting count too
	var badge: Label = _log_strip.get_node_or_null("Badge")
	if badge:
		badge.text = "%d!" % s.expedition.pending.size() if not s.expedition.pending.is_empty() else ""
	_fill_bottom()


## A slim strip standing in for a folded panel: an unfold button and the panel's icon.
func _strip(arrow: String, tip: String, tex: Texture2D, on_open: Callable) -> VBoxContainer:
	var v := UI.vbox(10)
	v.custom_minimum_size.x = 44
	# one button: the panel's icon with a small arrow on its corner, pointing the way the panel opens
	var b := _fold_button("", on_open)
	b.custom_minimum_size = Vector2(42, 46)
	b.tooltip_text = tip
	var center := CenterContainer.new()
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(center)
	var ic := UI.icon(tex, 26)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(ic)
	var arr := UI.label(arrow, "", Palette.AETHER)
	arr.add_theme_font_size_override("font_size", 18)
	arr.add_theme_constant_override("outline_size", 6)
	arr.add_theme_color_override("font_outline_color", Palette.BG_DEEP)
	arr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arr.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arr.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if arrow == "‹" else HORIZONTAL_ALIGNMENT_RIGHT
	arr.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	arr.offset_left = 2
	arr.offset_right = -2
	arr.offset_bottom = 2
	b.add_child(arr)
	v.add_child(b)
	var badge := UI.label("", "Small", Palette.GOLD)
	badge.name = "Badge"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(badge)
	return v


## The small square button that folds or unfolds a panel.
func _fold_button(arrow: String, on_press: Callable) -> Button:
	var b := UI.button(arrow, "Chip", on_press)
	b.add_theme_font_size_override("font_size", 22)
	b.custom_minimum_size = Vector2(38, 38)
	return b


func _set_open(key: String, open: bool) -> void:
	Options.set_value(key, open)
	_apply_folds()


## Shows each foldable panel or its strip, as remembered in Options.
func _apply_folds() -> void:
	for pair in [["zones", "exp_zones_open"], ["log", "exp_log_open"]]:
		if not _folds.has(pair[0]):
			continue
		var open := bool(Options.get_value(pair[1]))
		_folds[pair[0]][0].visible = open
		_folds[pair[0]][1].visible = not open


func _party_tab() -> VBoxContainer:
	var s := Game.state
	var pv := UI.vbox(6)
	var party := GameState.party(s)
	var party_size: int = Data.tuning.combat.partySize
	var locked := Expedition.party_locked(s)
	if locked:
		pv.add_child(UI.hbox(6, [UI.icon(Data.ui_icon("lock"), 16), UI.label("Locked during the run: stop it to change the party.", "Faint")]))
	else:
		pv.add_child(UI.label("Up to three. Party members don't work or gather Aether while they explore.", "Faint"))
	var row := UI.hbox(10)
	_xp_rows.clear()
	for i in party_size:
		var card := UI.vbox(4)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if i < party.size():
			var c: Dictionary = party[i]
			var h := UI.hbox(8)
			var por := CreaturePortrait.of(c, 50)
			por.bob = false
			h.add_child(por)
			var cv := UI.vbox(0)
			var nm := UI.label(Creatures.display_name(c), "H3")
			nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			nm.custom_minimum_size.x = 60
			cv.add_child(nm)
			var st := Creatures.stats(c)
			var lv := UI.chip("Lv %d" % int(c.level), Data.rarity_color(int(c.rarity)), 11)
			cv.add_child(UI.hbox(8, [lv, _mini_stat("health", st.health)]))
			cv.add_child(UI.hbox(10, [_mini_stat("power", st.power), _mini_stat("guard", st.guard)]))
			cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(cv)
			card.add_child(h)
			# XP toward the next level, filling with every kill
			var xb := UI.bar(Palette.AETHER, 6)
			xb.mouse_filter = Control.MOUSE_FILTER_STOP
			card.add_child(xb)
			_xp_rows.append({"cid": c.id, "bar": xb, "lv": lv, "level": -1})
			_update_xp_row(_xp_rows[-1])
			if not locked:
				card.add_child(UI.hbox(4, [UI.button("Swap", "Ghost", func(): _pick_party(i)), UI.button("Remove", "Ghost", func(): Game.bench(c.id))]))
		elif not locked:
			card.add_child(UI.button("Add an Aetherling", "", func(): _pick_party(i)))
		else:
			card.add_child(UI.label("Empty", "Faint"))
		row.add_child(UI.panel("Inset", card))
	pv.add_child(row)
	return pv


## The panel under the battle: Party, Auto-bind and Supplies, as tabs.
func _fill_bottom() -> void:
	UI.clear(_bind)
	UI.clear(_tabs_box)
	var tabs := _tabs_box
	for pair in [["party", "Party", "power"], ["autobind", "Auto-bind", "vessel"], ["supplies", "Supplies", "meal"]]:
		var b := UI.button(pair[1], "ChipOn" if _bottom_tab == pair[0] else "Chip", func():
			_bottom_tab = pair[0]
			_fill_bottom(), Data.ui_icon(pair[2]))
		tabs.add_child(b)
	# every tab is built and the panel keeps the tallest one's height, so switching tabs doesn't resize it
	for tab in ["party", "autobind", "supplies"]:
		var box := UI.vbox(8)
		box.visible = tab == _bottom_tab
		_bind.add_child(box)
		_bottom_into(tab, box)
	_fit_bottom.call_deferred()


func _fit_bottom() -> void:
	if not is_instance_valid(_bind):
		return
	var h := 0.0
	for c in _bind.get_children():
		h = maxf(h, (c as Control).get_combined_minimum_size().y)
	_bind.custom_minimum_size.y = h


## One tab's content under the battle.
func _bottom_into(tab: String, parent: VBoxContainer) -> void:
	var s := Game.state
	if tab == "party":
		parent.add_child(_party_tab())
		return
	if tab == "supplies":
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
			var nm := UI.wrap_label("No meals. Cook some in Cooking (a Pyric Aetherling): the first islands' wild Aetherlings drop Minnows and Sunfish, and the Market sells fish and meals.", "Small", 560)
			nm.add_theme_color_override("font_color", Palette.DANGER)
			sv.add_child(nm)
		parent.add_child(sv)
		return
	var ab: Dictionary = s.expedition.autobind
	var cols := UI.hbox(16)
	parent.add_child(cols)
	var bv := UI.vbox(4)
	bv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cols.add_child(bv)
	var bv2 := UI.vbox(6)
	cols.add_child(bv2)
	var en := ToggleSwitch.new()
	en.text = "Throw vessels"
	en.tooltip_text = "After a win the party can throw a vessel. The first of each type you've never owned binds free; shinies are always tried."
	en.button_pressed = bool(ab.get("enabled", true))
	en.toggled.connect(func(on): Game.state.expedition.autobind.enabled = on)
	bv.add_child(en)
	var ns := ToggleSwitch.new()
	ns.text = "Always try new species"
	ns.button_pressed = bool(ab.get("newSpecies", true))
	ns.toggled.connect(func(on): Game.state.expedition.autobind.newSpecies = on)
	bv.add_child(ns)
	var best := Expedition.choose_vessel(s, {"shiny": true, "species": "", "rarity": 1})
	if best == "":
		bv.add_child(UI.wrap_label("No vessels! Fabrication makes them; the Market sells them.", "Small", 260))
		bv.get_child(bv.get_child_count() - 1).add_theme_color_override("font_color", Palette.DANGER)
	else:
		# the chance per rarity, each a pill in that rarity's colour
		bv.add_child(UI.hbox(6, [UI.label("Bind chance with", "Faint"), UI.icon(Data.item_icon(best), 18), UI.label(Data.item_name(best), "Faint")]))
		var flow := HFlowContainer.new()
		flow.name = "BindChances"
		flow.custom_minimum_size.x = 260
		flow.add_theme_constant_override("h_separation", 6)
		flow.add_theme_constant_override("v_separation", 6)
		for r in [1, 2, 3, 4, 5]:
			var c := UI.chip("%s %s" % [Data.rarity(r).name, F.pct(Expedition.bind_chance(s, best, r, GameState.party(s)))], Data.rarity_color(r), 13)
			c.tooltip_text = "Chance a %s vessel binds a %s Aetherling" % [Data.item_name(best), Data.rarity(r).name]
			c.mouse_filter = Control.MOUSE_FILTER_STOP
			flow.add_child(c)
		bv.add_child(flow)
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
		var por := CreaturePortrait.make(w.species, maxi(F.form_for_level(int(w.level)), int(w.get("form", 1))), int(w.rarity), bool(w.shiny), 52)
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


func _process(d: float) -> void:
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
	for r in _xp_rows:
		_update_xp_row(r)
	var top: float = Game.battle_log[0].time if not Game.battle_log.is_empty() else -1.0
	if Game.battle_log.size() != _log_count or top != _log_top:
		_log_count = Game.battle_log.size()
		_log_top = top
		_render_log()
	_whens_left -= d
	if _whens_left <= 0.0:
		_whens_left = 1.0
		_update_whens()


## Brings the log's "now" / "3m" texts up to date without rebuilding the cards.
func _update_whens() -> void:
	var now := Game.now_sec()
	for w in _log_whens:
		if w.label != null and is_instance_valid(w.label):
			w.label.text = _when(now, w.time)
		if w.tile != null and is_instance_valid(w.tile):
			w.tile.tooltip_text = "%s  (%s)" % [w.text, _when(now, w.time) + ("" if now - w.time < 60 else " ago")]


static func _when(now: float, time: float) -> String:
	return "now" if now - time < 60 else F.format_seconds(now - time)


## The expedition log: each line a small card with an icon (a portrait for a capture), its text, and how long
## ago it happened, edged in the line's colour. The folded strip shows the same lines as icon-only cards.
func _render_log() -> void:
	UI.clear(_log)
	UI.clear(_log_mini)
	_log_whens.clear()
	_whens_left = 1.0
	if Game.battle_log.is_empty():
		_log.add_child(UI.wrap_label("The expedition log fills up as your party explores.", "Faint", 300))
		return
	var now := Game.now_sec()
	for e in Game.battle_log.slice(0, 40):
		var col: Color = e.color
		var card := _log_card(col, 8)
		var h := UI.hbox(8)
		h.add_child(_log_icon(e, 30, 22))
		var l := UI.label(e.text, "", col)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		l.custom_minimum_size.x = 60
		l.tooltip_text = e.text
		l.mouse_filter = Control.MOUSE_FILTER_PASS
		h.add_child(l)
		var when := UI.label(_when(now, float(e.time)), "Faint")
		_log_whens.append({"label": when, "tile": null, "time": float(e.time), "text": e.text})
		h.add_child(when)
		card.add_child(h)
		_log.add_child(card)
	for e in Game.battle_log.slice(0, 16):
		var tile := _log_card(e.color, 3)
		tile.tooltip_text = "%s  (%s)" % [e.text, _when(now, float(e.time)) + ("" if now - float(e.time) < 60 else " ago")]
		_log_whens.append({"label": null, "tile": tile, "time": float(e.time), "text": e.text})
		tile.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tile.gui_input.connect(func(ev: InputEvent):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				_set_open("exp_log_open", true))
		var ic := _log_icon(e, 26, 22)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		tile.add_child(ic)
		_log_mini.add_child(tile)


## A log line's card, edged on the left in the line's colour.
func _log_card(col: Color, pad: int) -> PanelContainer:
	var card := PanelContainer.new()
	var sb := ThemeFactory.box(Color(col, 0.07), 8, 0, Palette.LINE, 0)
	sb.border_width_left = 3
	sb.border_color = Color(col, 0.8)
	sb.content_margin_left = pad
	sb.content_margin_right = pad
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	card.add_theme_stylebox_override("panel", sb)
	return card


## A log line's icon: the Aetherling's portrait for a capture, else the line's own icon.
func _log_icon(e: Dictionary, portrait: int, icon: int) -> Control:
	var c: Control
	if e.has("species"):
		var por := CreaturePortrait.make(e.species, 1, int(e.rarity), bool(e.shiny), portrait)
		por.bob = false
		c = por
	elif e.get("icon") != null:
		c = UI.icon(e.icon, icon)
	else:
		c = UI.icon(Data.ui_icon("expeditions"), icon)
	c.mouse_filter = Control.MOUSE_FILTER_PASS
	return c


## A small icon and number for the party cards (health, power, guard).
func _update_xp_row(r: Dictionary) -> void:
	var c: Dictionary = Game.state.creatures.get(r.cid, {})
	if c.is_empty() or not is_instance_valid(r.bar):
		return
	var max_lv: int = Data.tuning.creature.maxLevel
	r.bar.value = F.level_progress(F.creature_curve(), float(c.xp), max_lv)
	if int(c.level) != int(r.level):
		r.level = int(c.level)
		UI.set_chip(r.lv, "Lv %d" % int(c.level), Data.rarity_color(int(c.rarity)))
	var tip := "Max level" if int(c.level) >= max_lv else "%s / %s XP to level %d" % [
		F.format_num(float(c.xp) - F.xp_for_level(F.creature_curve(), int(c.level), max_lv)),
		F.format_num(F.xp_for_level(F.creature_curve(), int(c.level) + 1, max_lv) - F.xp_for_level(F.creature_curve(), int(c.level), max_lv)),
		int(c.level) + 1]
	if r.bar.tooltip_text != tip:
		r.bar.tooltip_text = tip


func _mini_stat(icon_name: String, value: float) -> HBoxContainer:
	var l := UI.label(F.format_num(value), "Small", Palette.TEXT)
	return UI.hbox(3, [UI.icon(Data.ui_icon(icon_name), 14), l])
