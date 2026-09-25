extends RefCounted
## Presses real buttons in the dialogs, checking each one does its job and closes its dialog. This catches the
## GDScript trap where a lambda captures a local variable by value before the variable is assigned (the dialog
## buttons once did that with their own modal, so every button that closed its dialog errored).
## Uses an in-memory game with no save slot, so nothing on disk is touched.

var t
var _layer: Control


func _setup() -> void:
	Game.slot = 0          # save_game() does nothing without a slot
	Game.state = GameState.new_game()
	if _layer == null or not is_instance_valid(_layer):
		_layer = Control.new()
		t.add_child(_layer)
	Modal.layer = _layer


func _teardown() -> void:
	for c in _layer.get_children():
		c.free()


func _find_button(root: Node, text: String) -> Button:
	if root is Button and root.text == text:
		return root
	for c in root.get_children():
		var b := _find_button(c, text)
		if b:
			return b
	return null


func _open_modals() -> Array:
	return _layer.get_children().filter(func(c): return c is Modal)


## Presses the button and reports whether the modal holding it closed.
func _press_closes(m: Modal, text: String) -> bool:
	var b := _find_button(m, text)
	if b == null:
		t.ok(false, "no button '%s'" % text)
		return false
	var state := {"closed": false}
	m.closed.connect(func(): state.closed = true)
	b.pressed.emit()
	return state.closed


func test_confirm_yes_runs_the_action_and_closes() -> void:
	_setup()
	var ran := {"yes": false}
	var m := Modal.confirm("Delete?", "Really?", "Delete", func(): ran.yes = true, true)
	t.ok(_press_closes(m, "Delete"), "the dialog closed")
	t.ok(ran.yes, "the action ran")
	_teardown()


func test_confirm_cancel_closes_without_the_action() -> void:
	_setup()
	var ran := {"yes": false}
	var m := Modal.confirm("Delete?", "Really?", "Delete", func(): ran.yes = true, true)
	t.ok(_press_closes(m, "Cancel"), "the dialog closed")
	t.ok(not ran.yes, "the action did not run")
	_teardown()


func _main() -> Node:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	t.add_child(main)
	Modal.layer = _layer  # main sets its own overlay as the modal layer; the test keeps its own
	return main


func test_pause_menu_resume_closes() -> void:
	_setup()
	var main := _main()
	_teardown()  # drop the welcome dialog a new game opens
	main.open_pause_menu()
	var m: Modal = _open_modals().back()
	t.ok(_press_closes(m, "Resume"), "Resume closed the menu")
	main.free()
	_teardown()


func test_welcome_button_closes_and_opens_woodcutting() -> void:
	_setup()
	var main := _main()
	_teardown()
	main._welcome()
	var m: Modal = _open_modals().back()
	t.ok(_press_closes(m, "Let's start: open Woodcutting"), "welcome closed")
	t.eq(main.current, "skill")
	t.eq(main.current_arg, "woodcutting")
	main.free()
	_teardown()


func test_nexus_rename_and_bulk_release_close() -> void:
	_setup()
	var main := _main()
	_teardown()
	var c: Dictionary = Game.state.creatures.values()[0]
	for i in 3:
		Game.dev_grant("sproutlet", 1, 1, false)
	main.show_screen("nexus", c.id)
	var nexus: Node = main._screen
	nexus._rename(c)
	var m: Modal = _open_modals().back()
	var le: LineEdit = m.find_children("*", "LineEdit", true, false)[0]
	le.text = "Leafy"
	t.ok(_press_closes(m, "Save"), "rename closed")
	t.eq(Game.creature(c.id).nick, "Leafy")
	_teardown()
	var before: int = Game.state.creatures.size()
	nexus._bulk_release()
	m = _open_modals().back()
	t.ok(_press_closes(m, "Release"), "bulk release closed")
	t.ok(Game.state.creatures.size() < before, "released some")
	main.free()
	_teardown()


func test_party_changes_are_refused_mid_run_without_restarting_it() -> void:
	_setup()
	var starter: Dictionary = Game.state.creatures.values()[0]
	Game.dev_grant("sproutlet", 1, 1, false)
	var other: Dictionary = Game.state.creatures.values().filter(func(c): return c.id != starter.id)[0]
	Game.set_party(0, starter.id)
	Game.start_expedition("whisperleaf-hollow")
	for i in 40:
		Expedition.step(Game.state, 250.0, Game.rng)
	var battle: Dictionary = Game.state.expedition.battle
	Game.set_party(1, other.id)
	Game.bench(starter.id)
	t.ok(not Game.assign(starter.id, "woodcutting"), "assigning a party member is refused")
	Game.release(starter.id)
	t.ok(Game.state.expedition.battle == battle, "the same run is still going")
	t.eq(GameState.party(Game.state).size(), 1)
	t.eq(Creatures.job_kind(starter), "party")
	t.ok(Game.state.creatures.has(starter.id), "not released")
	Game.stop_expedition()
	Game.set_party(1, other.id)
	t.eq(GameState.party(Game.state).size(), 2, "the party opens up once stopped")
	_teardown()


func test_dialogs_draw_above_the_battle() -> void:
	_setup()
	var main := _main()
	_teardown()
	main.show_screen("expeditions", "whisperleaf-hollow")
	t.ok(main._content.find_children("*", "", true, false).any(func(n): return n is Arena), "the arena is on screen")
	var arena_top := 0
	for n in main._content.find_children("*", "", true, false):
		if n is CanvasItem:
			arena_top = maxi(arena_top, n.z_index)
	t.ok(main._overlay.z_index > arena_top + 20, "overlay z %d vs screens %d" % [main._overlay.z_index, arena_top])
	main.free()
	_teardown()


func test_action_cards_show_what_you_hold() -> void:
	_setup()
	var main := _main()
	_teardown()
	var a: Dictionary = Data.skills.woodcutting.actions[0]
	var out: String = a.outputs.keys()[0]
	GameState.add_item(Game.state, out, 15)
	GameState.add_item(Game.state, a.rare.item, 3)
	main.show_screen("skill", "woodcutting")
	var sk: Node = main._screen
	sk._process(0.0)
	var shown := {}
	for e in sk._have_labels:
		shown[e.id] = e.label.text
	t.eq(shown.get(out, ""), "15", "the product count")
	t.eq(shown.get(a.rare.item, ""), "3", "the rare drop count")
	GameState.add_item(Game.state, a.rare.item, 1)
	sk._process(0.0)
	t.eq(sk._have_labels.filter(func(e): return e.id == a.rare.item)[0].label.text, "4", "counts update live")
	main.free()
	_teardown()


## Runs every tween in the tree to its end, so a reveal reaches its sound cue within one test call.
func _finish_tweens() -> void:
	for i in 4:
		for tw in t.get_tree().get_processed_tweens():
			tw.custom_step(30.0)


func test_evolution_plays_its_own_sound() -> void:
	_setup()
	var main := _main()
	_teardown()
	var c: Dictionary = Game.state.creatures.values()[0]
	Sfx.last_played = ""
	main._reveal._play_evolve({"creature": c.id, "species": c.species, "from": 1, "form": 2})
	_finish_tweens()
	t.eq(Sfx.last_played, "evolve", "the evolution reveal ends on the evolve sound")
	main.free()
	_teardown()


func test_boss_fight_switches_to_boss_music_and_back() -> void:
	_setup()
	var main := _main()
	_teardown()
	Game.set_party(0, Game.state.creatures.keys()[0])
	Game.start_expedition("whisperleaf-hollow")
	var b: Dictionary = Game.state.expedition.battle
	# frames on whatever expedition page is showing (a holder, since lambdas capture locals by value)
	var view := {"main": main}
	var tick := func():
		var screen: Node = view.main._screen
		screen._process(0.0)
		screen._arena._process(0.0)
	main.show_screen("expeditions", "whisperleaf-hollow")
	tick.call()
	t.eq(Music.wanted(), "expedition", "a normal wave keeps the calm track")
	b.wave = b.waves
	b.phase = "fight"
	tick.call()
	t.eq(Music.wanted(), "boss", "the boss wave switches to the boss track")
	t.ok(main._screen._arena._banner.text.begins_with("BOSS"), "with the boss banner")
	b.phase = "rest"   # what the sim does when the boss falls or the party wipes
	tick.call()
	t.eq(Music.wanted(), "expedition", "the calm track returns once the fight resolves")
	b.phase = "fight"
	tick.call()
	t.eq(Music.wanted(), "boss")
	main.show_screen("expeditions", "fractured-quarry")   # another island's page hides this fight
	tick.call()
	t.eq(Music.wanted(), "expedition", "another island's page plays the calm track")
	main.show_screen("expeditions", "whisperleaf-hollow")
	tick.call()
	t.eq(Music.wanted(), "boss", "coming back to the fight brings the boss track back")
	Game.stop_expedition()
	tick.call()
	t.eq(Music.wanted(), "expedition", "stopping the run mid-boss ends the boss track")
	main.show_screen("sanctum")
	t.eq(Music.wanted(), "sanctum")
	main.free()
	_teardown()


func test_worker_picker_sorts_by_time_output_and_secondary() -> void:
	_setup()
	var main := _main()
	_teardown()
	var s := Game.state
	var ids := {}
	for pair in [["plain", []], ["swift", [{"id": "swift-worker", "s": "major"}]], ["bountiful", [{"id": "bountiful", "s": "major"}]], ["lucky", [{"id": "lucky", "s": "major"}]]]:
		var c := Creatures.make(s, "sproutlet", 1, 1, false, pair[1], "test")
		s.creatures[c.id] = c
		ids[pair[0]] = c.id
	main.show_screen("skill", "woodcutting")
	main._screen._pick("")
	var m: Modal = _open_modals().back()
	var picker: CreaturePicker = m.find_children("*", "", true, false).filter(func(n): return n is CreaturePicker)[0]
	var order := func() -> Array:
		return picker._grid.get_children().filter(func(n): return n is CreatureCard).map(func(n): return n.cid)
	t.ok(_find_button(m, "Best fit") == null, "the general Best fit button is replaced")
	t.eq(picker._sort, "output", "opens on Best output")
	var o: Array = order.call()
	t.ok(o.find(ids.bountiful) < o.find(ids.plain) and o.find(ids.bountiful) < o.find(ids.lucky), "bountiful out-produces plain and lucky")
	_find_button(m, "Best time").pressed.emit()
	t.eq(order.call()[0], ids.swift, "the fastest first")
	_find_button(m, "Best secondary").pressed.emit()
	t.eq(order.call()[0], ids.lucky, "the luckiest first")
	var first: CreatureCard = picker._grid.get_children().filter(func(n): return n is CreatureCard)[0]
	t.ok(first.find_children("*", "Label", true, false).any(func(l): return "secondary finds/h" in l.text), "cards show the figure being sorted by")
	main.free()
	_teardown()


## Every screen fits the 1600-wide base layout next to the sidebar. A long header once made the Nexus's left
## column so wide that its detail panel was pushed off the right edge.
func test_screens_fit_the_base_width() -> void:
	_setup()
	var main := _main()
	_teardown()
	var s := Game.state
	for sp in ["brambletrundle", "mossgear", "sproutlet"]:
		var c := Creatures.make(s, sp, 2, 4, false, [], "test")
		s.creatures[c.id] = c
	var rail: Control = main.get_child(1).get_child(0)
	var rail_w := rail.get_combined_minimum_size().x
	for screen in [["sanctum", ""], ["skill", "woodcutting"], ["nexus", s.creatures.keys()[0]], ["pods", ""],
			["expeditions", "fractured-quarry"], ["aetherlog", ""], ["inventory", ""], ["works", ""]]:
		main.show_screen(screen[0], screen[1])
		var widest := 0.0
		for c in main._screen.get_children():
			if c is Control:
				widest = maxf(widest, c.get_combined_minimum_size().x)
		t.ok(rail_w + widest <= 1600.0, "%s needs %d px beside a %d px sidebar" % [screen[0], widest, rail_w])
	main.free()
	_teardown()


## A lone enemy is drawn at the same size as each of three allies: sprites keep one size all run long.
func test_arena_fighters_keep_one_size() -> void:
	_setup()
	var s := Game.state
	var slot := 0
	for sp in ["brambletrundle", "mossgear", "sproutlet"]:
		var c := Creatures.make(s, sp, 1, 3, false, [], "test")
		s.creatures[c.id] = c
		Expedition.set_party_member(s, slot, c)
		slot += 1
	var rng := RandomNumberGenerator.new()
	Expedition.start(s, "whisperleaf-hollow", rng)
	var b: Dictionary = s.expedition.battle
	for i in 200:   # walk to the first wave
		if not b.enemies.is_empty():
			break
		Expedition.step(s, 250.0, rng)
		b = s.expedition.battle
	t.ok(not b.enemies.is_empty(), "a wave has appeared")
	b.enemies = [b.enemies[0]]
	var arena := Arena.new()
	_layer.add_child(arena)
	arena.size = Vector2(510, 585)
	arena._build(b)
	var ally: Vector2 = arena._allies[0].portrait.size
	var foe: Vector2 = arena._enemies[0].portrait.size
	t.eq(arena._allies.size(), 3)
	t.near(foe.x, ally.x, 0.5, "one enemy (%d px) is as big as one of three allies (%d px)" % [foe.x, ally.x])
	for f in arena._allies:
		t.near(f.portrait.size.x, ally.x, 0.5, "front and back row the same size")
	_teardown()


## Species you own carry the owned badge in an island's list of Aetherlings; others don't.
func test_island_preview_marks_owned_species() -> void:
	_setup()
	var main := _main()
	_teardown()
	var s := Game.state
	var c := Creatures.make(s, "mossgear", 1, 1, false, [], "test")
	s.creatures[c.id] = c
	Collection.on_owned(s, c)
	main.show_screen("expeditions", "whisperleaf-hollow")
	var marks: Array = main._screen._preview.find_children("*", "TextureRect", true, false).filter(
		func(n): return n.tooltip_text == "You own this species")
	var owned: Array = Data.zones["whisperleaf-hollow"].species.keys().filter(func(id): return Collection.is_owned(s, id))
	t.ok(owned.has("mossgear"), "Mossgear is owned")
	t.eq(marks.size(), owned.size(), "one badge per owned species")
	main.free()
	_teardown()


## The Sanctum's expedition card follows the run live: new log lines and health changes show up without
## the player opening the Expeditions page.
func test_sanctum_expedition_card_follows_the_run() -> void:
	_setup()
	var main := _main()
	_teardown()
	Game.battle_log.clear()
	Game.set_party(0, Game.state.creatures.keys()[0])
	Game.start_expedition("whisperleaf-hollow")
	main.show_screen("sanctum")
	var screen: Node = main._screen
	var b: Dictionary = Game.state.expedition.battle
	t.ok(screen._exp_status != null, "the card shows the running expedition")
	t.eq(screen._exp_hp.size(), b.allies.size(), "a health bar per party member")
	Game.battle_log.push_front({"text": "Bound a Dim Mossgear", "color": Palette.TEXT, "time": Game.now_sec() + 1.0})
	b.allies[0].hp = float(b.allies[0].maxHp) * 0.5
	screen._update_expedition()
	var lines: Array = screen._exp_log.get_children().map(func(l): return l.text)
	t.ok("Bound a Dim Mossgear" in lines, "the newest log line appears: %s" % [lines])
	t.near(screen._exp_hp[0].value, 0.5, 0.01, "health follows the fight")
	Game.stop_expedition()
	screen._update_expedition()
	t.ok(screen._exp_status == null, "the card goes back to 'no expedition' when the run stops")
	Game.battle_log.clear()
	main.free()
	_teardown()


## Fighters face each other: sprites are painted facing left, so the party (left side) is mirrored to look
## right and wild Aetherlings (right side) are drawn as painted. A form can override its facing.
func test_fighters_face_each_other() -> void:
	t.ok(Arena._needs_flip("sproutlet", 1, 0), "the party is mirrored to face right")
	t.ok(not Arena._needs_flip("sproutlet", 1, 1), "wild Aetherlings face left as painted")
	var fd: Dictionary = Data.species["sproutlet"].forms[0]
	fd.facing = "right"
	t.ok(not Arena._needs_flip("sproutlet", 1, 0) and Arena._needs_flip("sproutlet", 1, 1), "a right-facing sprite flips the other way")
	fd.facing = "front"
	t.ok(not Arena._needs_flip("sproutlet", 1, 0) and not Arena._needs_flip("sproutlet", 1, 1), "a front-facing sprite never flips")
	fd.erase("facing")


## Numbers landing on one fighter close together start in different places, so they never overlap.
func test_damage_numbers_spread_out() -> void:
	var arena := Arena.new()
	var root := Control.new()
	root.size = Vector2(90, 90)
	var rec := {"root": root}
	var spots := []
	for i in 5:
		spots.append(arena._number_at(rec))
	for i in spots.size():
		for j in range(i + 1, spots.size()):
			t.ok(spots[i].distance_to(spots[j]) > 12.0, "numbers %d and %d are apart: %s / %s" % [i, j, spots[i], spots[j]])
	t.eq(Arena._num(8.8), "9", "whole numbers")
	t.eq(Arena._num(0.2), "1", "never 0")
	root.free()
	arena.free()


## A save slot can be named ("Dev Save") and the title screen's slot info reports the name.
func test_save_slots_can_be_renamed() -> void:
	var n := 3
	var had := FileAccess.file_exists(Game.slot_path(n))
	var backup := FileAccess.get_file_as_string(Game.slot_path(n)) if had else ""
	FileAccess.open(Game.slot_path(n), FileAccess.WRITE).store_string(JSON.stringify(GameState.new_game()))
	Game.rename_slot(n, "  Dev Save  ")
	t.eq(Game.slot_info(n).get("name"), "Dev Save", "named and trimmed")
	Game.rename_slot(n, "")
	t.eq(Game.slot_info(n).get("name"), "", "cleared")
	if had:
		FileAccess.open(Game.slot_path(n), FileAccess.WRITE).store_string(backup)
	else:
		DirAccess.remove_absolute(Game.slot_path(n))


## Party members on a running expedition are not offered as workers (they can't be moved mid-run).
func test_worker_picker_hides_the_locked_party() -> void:
	_setup()
	var main := _main()
	_teardown()
	var s := Game.state
	var fighter := Creatures.make(s, "sproutlet", 1, 3, false, [], "test")
	s.creatures[fighter.id] = fighter
	var idle := Creatures.make(s, "sproutlet", 1, 3, false, [], "test")
	s.creatures[idle.id] = idle
	Game.set_party(0, fighter.id)
	Game.start_expedition("whisperleaf-hollow")
	main.show_screen("skill", "woodcutting")
	main._screen._pick("")
	var m: Modal = _open_modals().back()
	var picker: CreaturePicker = m.find_children("*", "", true, false).filter(func(n): return n is CreaturePicker)[0]
	var ids: Array = picker._grid.get_children().filter(func(n): return n is CreatureCard).map(func(n): return n.cid)
	t.ok(not ids.has(fighter.id), "the party member on the run is not offered")
	t.ok(ids.has(idle.id), "an idle Aetherling is")
	Game.stop_expedition()
	main.free()
	_teardown()


## Shinies waiting for a vessel get their own panel at the top of the Expeditions page.
func test_waiting_shinies_are_shown_first() -> void:
	_setup()
	var main := _main()
	_teardown()
	Game.state.expedition.pending.append({"species": "buzzbud", "level": 3, "rarity": 2, "shiny": true})
	main.show_screen("expeditions", "whisperleaf-hollow")
	var first: Node = main._screen._right.get_child(0)
	t.ok(_find_button(first, "Throw at all") != null, "the waiting panel comes first, with Throw at all")
	Game.state.expedition.pending.clear()
	main.free()
	_teardown()


## The Market's tabs, the Egg Market and the bulk-sell dialog all open, and buying from them works.
func test_market_pages() -> void:
	_setup()
	var main := _main()
	_teardown()
	var s := Game.state
	s.gold = 1e9
	for i in 10:
		Expedition.zone_state(s, Data.zone_list[i].id).cleared = true
	main.show_screen("market")
	var scr: Node = main._screen
	for tab in ["stock", "vessels", "materials", "boosts", "slots"]:
		scr.tab = tab
		scr.refresh()
		t.ok(scr._body.get_child_count() > 0, "the %s tab has content" % tab)
	scr.tab = "vessels"
	scr.refresh()
	var buy := _find_button(scr, "Buy 1")
	t.ok(buy != null and not buy.disabled, "a vessel to buy")
	var before := GameState.count(s, "tinkerers-vessel")
	buy.pressed.emit()
	t.eq(GameState.count(s, "tinkerers-vessel"), before + 1.0, "bought a vessel")
	t.ok(main._nav_buttons.has("market:") and main._nav_buttons.has("eggmarket:"), "both markets in the menu")
	main.show_screen("eggmarket")
	var egg := _find_button(main._screen, "Buy egg")
	t.ok(egg != null and not egg.disabled, "an egg to buy")
	egg.pressed.emit()
	t.ok(s.pods.any(func(p): return not p.is_empty() and p.has("market")), "the egg is in a pod")
	GameState.add_item(s, "oak-log", 40)
	main.show_screen("inventory")
	main._screen._bulk_sell()
	t.ok(_find_button(_layer, "Sell") != null, "the bulk-sell dialog opens")
	main.free()
	_teardown()


## The Auto-bind tab shows each rarity's bind chance as a pill in that rarity's colour.
func test_bind_chances_in_rarity_colours() -> void:
	_setup()
	var main := _main()
	_teardown()
	GameState.add_item(Game.state, "tinkerers-vessel", 5)
	main.show_screen("expeditions", "whisperleaf-hollow")
	var scr: Node = main._screen
	scr._bottom_tab = "autobind"
	scr._fill_bottom()
	var flow: Node = scr.find_child("BindChances", true, false)
	t.ok(flow != null and flow.get_child_count() == 5, "five bind-chance pills")
	if flow:
		var l: Label = flow.get_child(1).get_child(0)
		t.ok(l.text.begins_with(Data.rarity(2).name), "each pill names its rarity")
		t.ok(l.get_theme_color("font_color").is_equal_approx(Data.rarity_color(2).lightened(0.3)), "in the rarity's colour")
	main.free()
	_teardown()


## The Expeditions page's island list and log fold to slim strips, and the choice is remembered.
func test_expedition_panels_fold() -> void:
	_setup()
	var main := _main()
	_teardown()
	var was_z: bool = Options.values.exp_zones_open
	var was_l: bool = Options.values.exp_log_open
	main.show_screen("expeditions", "whisperleaf-hollow")
	var scr: Node = main._screen
	scr._set_open("exp_zones_open", false)
	t.ok(not scr._folds.zones[0].visible and scr._folds.zones[1].visible, "the island list folds to a strip")
	scr._set_open("exp_log_open", false)
	t.ok(not scr._folds.log[0].visible and scr._folds.log[1].visible, "the log folds to a strip")
	Game.battle_log.push_front({"text": "The boss appears!", "color": Palette.GOLD, "time": Game.now_sec(), "icon": Data.ui_icon("power")})
	scr._render_log()
	var tile: Control = scr._log_mini.get_child(0)
	t.ok(tile.tooltip_text.begins_with("The boss appears!"), "the folded log still shows its latest lines as icons, with their text on hover")
	Game.battle_log.pop_front()
	main.show_screen("expeditions", "whisperleaf-hollow")
	t.ok(not main._screen._folds.zones[0].visible, "folded panels stay folded when the page opens again")
	Options.set_value("exp_zones_open", was_z)
	Options.set_value("exp_log_open", was_l)
	main.free()
	_teardown()


## An item goal finishes without any structural change (no Game.changed): the Sanctum's goal card must
## still show Claim while the player watches it (the bugtest benchmark found it never did).
func test_sanctum_goal_card_shows_claim_when_an_item_goal_finishes() -> void:
	_setup()
	var main := _main()
	_teardown()
	Game.state.goals.index = Goals.index_of("logs")
	Game.state.goals.id = "logs"
	main.show_screen("sanctum")
	var screen: Node = main._screen
	t.ok(_find_button(screen._goal_box, "Claim") == null, "no Claim before the logs are in")
	GameState.add_item(Game.state, "oak-log", 10)
	screen._process(0.6)
	var claim := _find_button(screen._goal_box, "Claim")
	t.ok(claim != null, "Claim appears once the goal is done, without a refresh")
	Game.changed.emit()
	t.ok(is_instance_valid(claim) and not claim.is_queued_for_deletion(), "an unrelated change doesn't rebuild the card mid-click")
	main.free()
	_teardown()


## Play-test feedback: XP seemed to come only from the boss. A party member's nameplate has an XP bar that
## moves with every kill, and its level chip follows a mid-run level-up.
func test_arena_shows_party_xp_from_each_kill() -> void:
	_setup()
	var s := Game.state
	var c := Creatures.make(s, "sproutlet", 1, 3, false, [], "test")
	s.creatures[c.id] = c
	Expedition.set_party_member(s, 0, c)
	var rng := RandomNumberGenerator.new()
	Expedition.start(s, "whisperleaf-hollow", rng)
	var b: Dictionary = s.expedition.battle
	for i in 200:
		if not b.enemies.is_empty():
			break
		Expedition.step(s, 250.0, rng)
		b = s.expedition.battle
	var arena := Arena.new()
	_layer.add_child(arena)
	arena.size = Vector2(510, 585)
	arena._build(b)
	var v: Dictionary = arena._allies[0]
	t.ok(v.xp != null, "the party member has an XP bar")
	t.ok(arena._enemies.all(func(e): return e.get("xp") == null), "wild Aetherlings don't")
	arena._update(b)
	var before: float = v.xp.value
	var ev := []
	Expedition.defeated_wild(s, Data.zones["whisperleaf-hollow"], {"species": "sproutlet", "level": 2, "rarity": 1, "shiny": false}, [c], rng, ev, b)
	arena._update(b)
	t.ok(v.xp.value > before or int(c.level) > 3, "the bar moved after one kill (%.3f -> %.3f)" % [before, v.xp.value])
	c.xp = F.xp_for_level(F.creature_curve(), 7, Data.tuning.creature.maxLevel) - 0.5
	Expedition.defeated_wild(s, Data.zones["whisperleaf-hollow"], {"species": "sproutlet", "level": 2, "rarity": 1, "shiny": false}, [c], rng, ev, b)
	arena._update(b)
	t.eq(v.lv.text, "Lv %d" % int(c.level), "the level chip follows")
	t.eq(int(b.allies[0].level), int(c.level), "and so does the fighter")
	_teardown()
