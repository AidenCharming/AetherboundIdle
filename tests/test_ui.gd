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


func test_worker_picker_sorts_by_output_and_secondary() -> void:
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
	t.ok(_find_button(m, "Best time") == null, "Best time is gone (play-test feedback)")
	_find_button(m, "Best secondary").pressed.emit()
	t.eq(order.call()[0], ids.lucky, "the luckiest first")
	var first: CreatureCard = picker._grid.get_children().filter(func(n): return n is CreatureCard)[0]
	t.ok(first.find_children("*", "Label", true, false).any(func(l): return "secondary finds/h" in l.text), "cards show the figure being sorted by")
	main.free()
	_teardown()


## Every screen fits the 1920-wide base layout next to the sidebar. A long header once made the Nexus's left
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
		t.ok(rail_w + widest <= 1920.0, "%s needs %d px beside a %d px sidebar" % [screen[0], widest, rail_w])
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


## The Put to work menu drew its skill icons at their painted 512 px, filling the screen.
func test_menu_icons_are_drawn_small() -> void:
	_setup()
	var main := _main()
	_teardown()
	var w: int = main.get_theme_constant("icon_max_width", "PopupMenu")
	t.ok(w > 0 and w <= 38, "PopupMenu icons capped at %d px" % w)
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


## Bridge bug: after a picker closed, the next rail click did nothing. The fading dialog (0.1 s) still took
## every click and still counted as open, so the bridge clicked its Close again, which landed on the page
## (opening another picker). A closing dialog now lets clicks through and isn't open.
func test_a_closing_dialog_lets_clicks_through() -> void:
	_setup()
	var m := Modal.open(UI.label("Pick one"), "Choose parent B")
	t.ok(Modal.any_open() and m.is_open(), "open")
	t.eq(m.mouse_filter, Control.MOUSE_FILTER_STOP, "an open dialog covers the page")
	m.close()
	t.ok(not Modal.any_open(), "a closing dialog no longer counts as open")
	t.ok(not m.is_open())
	t.eq(m.mouse_filter, Control.MOUSE_FILTER_IGNORE, "clicks pass it while it fades")
	t.eq(m.mouse_behavior_recursive, Control.MOUSE_BEHAVIOR_DISABLED, "and pass its buttons and dim too")
	var closes := {"n": 0}
	m.closed.connect(func(): closes.n += 1)
	m.close()
	t.eq(closes.n, 0, "a second close does nothing")
	_teardown()


## A dialog belongs to its page: changing page closes it, so a picker can't outlive the Pods screen and
## call back into it (every pick then errored and the picker stayed open for good).
func test_changing_page_closes_its_dialogs() -> void:
	_setup()
	var main := _main()
	_teardown()
	main.show_screen("pods")
	PodsScreen.parent_a = ""
	main._screen._pick(1)
	t.ok(Modal.any_open(), "the parent picker is open")
	main.show_screen("sanctum")
	t.ok(not Modal.any_open(), "going to the Sanctum closed it")


## During the fade back to the title the state is empty; a worker bubble on the open skill page must not read it.
func test_worker_bubble_waits_out_an_empty_state() -> void:
	_setup()
	var keep := Game.state
	var c: Dictionary = keep.creatures.values()[0]
	var bubble := WorkerBubble.make(c, "woodcutting", 58)
	_layer.add_child(bubble)
	Game.state = {}
	bubble._process(0.016)
	t.ok(true, "no error with an empty state")
	Game.state = keep
	_teardown()


## The parents picked in Genesis Pods belong to one save: another save opens the page with nothing picked.
func test_pods_forget_the_parents_of_another_save() -> void:
	_setup()
	var scr: Node = preload("res://scripts/ui/screens/pods_screen.gd").new()
	_layer.add_child(scr)
	var starter: String = Game.state.creatures.keys()[0]
	PodsScreen.parent_a = starter
	PodsScreen.parent_b = starter
	scr.refresh()
	t.eq(PodsScreen.parent_a, starter, "kept within the same save")
	var other := GameState.new_game()
	other.created = int(Game.state.created) + 1
	Game.state = other
	scr.refresh()
	t.eq(PodsScreen.parent_a, "", "parent A cleared")
	t.eq(PodsScreen.parent_b, "", "parent B cleared")
	_teardown()


## Dragging a slider changes an option every frame; options.cfg is written once, after the changes stop.
func test_option_changes_are_saved_once_after_they_stop() -> void:
	var key := "music"
	var was: float = Options.get_value(key)
	var writes := Options.save_count
	for i in 20:
		Options.set_value(key, was)   # the same value, so the player's options.cfg ends up unchanged
	t.eq(Options.save_count, writes, "nothing written while the changes keep coming")
	t.ok(Options.save_pending(), "a write is waiting")
	Options.flush()   # what the timer does when it runs (the runner can't wait for it)
	t.eq(Options.save_count, writes + 1, "written once")
	t.ok(not Options.save_pending(), "nothing left waiting")
	Options.flush()
	t.eq(Options.save_count, writes + 1, "and not again")


## A capture or level-up while the mouse button is down must not rebuild the screen under the click (the button
## would be freed between press and release and the click lost). The rebuild waits for the release.
func test_screen_waits_for_the_mouse_before_rebuilding() -> void:
	_setup()
	var main := _main()
	_teardown()
	var screens := ["skill", "pods", "works", "market"]
	for scr_id in screens:
		main.show_screen(scr_id, "woodcutting" if scr_id == "skill" else "")
		var btn := _first_button(main._screen)
		t.ok(btn != null, "%s has a button" % scr_id)
		if btn == null:
			continue
		var down := InputEventMouseButton.new()
		down.button_index = MOUSE_BUTTON_LEFT
		down.pressed = true
		main._input(down)
		Game.changed.emit()
		t.ok(btn.is_inside_tree() and not btn.is_queued_for_deletion(), "%s: the button survives a change mid-click" % scr_id)
		var up := InputEventMouseButton.new()
		up.button_index = MOUSE_BUTTON_LEFT
		up.pressed = false
		main._input(up)
		t.ok(main._refresh_waiting, "%s: the rebuild is still owed until after the release" % scr_id)
		main._refresh_screen()
		t.ok(not main._refresh_waiting, "%s: and then done" % scr_id)
		Game.changed.emit()
		if scr_id in ["pods", "market"]:   # Works and the skill page's header keep their buttons on purpose
			t.ok(not btn.is_inside_tree(), "%s: with the button up, a change rebuilds at once" % scr_id)
	main.free()
	_teardown()


## Bridge bugs: a Build click in Sanctum Works did nothing (the page rebuilt on a capture between mouse down
## and up), and Build stayed disabled after the gold arrived (gold from work doesn't emit Game.changed).
func test_works_build_buttons_stay_put_and_follow_the_gold() -> void:
	_setup()
	var s := Game.state
	var works: Control = load("res://scripts/ui/screens/works_screen.gd").new()
	_layer.add_child(works)
	var b: Button = works._builds["genesis-pods"]
	s.items.clear()
	s.gold = 0.0
	works._update_builds()
	t.ok(b.disabled, "can't build with nothing")
	works.refresh()   # what Main does on Game.changed (a capture, a level-up)
	t.ok(works._builds["genesis-pods"] == b, "a capture or level-up doesn't replace the Build button")
	var nxt := Economy.next_upgrade(s, "genesis-pods")
	for id in nxt.cost:
		GameState.add_item(s, id, float(nxt.cost[id]))
	works._process(1.0)
	t.ok(not b.disabled, "Build enables once the cost is there, with no Game.changed")
	var before := GameState.upgrade_level(s, "genesis-pods")
	Game.buy_upgrade("genesis-pods")
	t.eq(GameState.upgrade_level(s, "genesis-pods"), before + 1, "built")
	works.refresh()
	t.ok(works._builds.get("genesis-pods") != b, "a new level rebuilds the card")
	works.free()
	_teardown()


## Play-test feedback: 6-9 were out of the sidebar's order, and every page should have a key you can change,
## shown on its tab. Defaults follow the rail (1-9), the skills take F1 onwards.
func test_page_keys_follow_the_rail_and_can_be_changed() -> void:
	_setup()
	var saved: Dictionary = Options.values.keybinds.duplicate()
	Options.reset_keybinds()
	var order := ["sanctum", "nexus", "pods", "expeditions", "aetherlog", "inventory", "market", "eggmarket", "works"]
	for i in order.size():
		t.eq(Options.keybind(order[i]), KEY_1 + i, "%s is %d" % [order[i], i + 1])
	t.eq(Options.keybind("skill:" + Data.skill_list[0].id), KEY_F1, "the first skill is F1")
	t.eq(Options.tab_for_key(KEY_F2), "skill:" + Data.skill_list[1].id)
	var main := _main()
	_teardown()
	var press := func(code: int):
		var e := InputEventKey.new()
		e.keycode = code as Key
		e.pressed = true
		main._unhandled_input(e)
	press.call(KEY_7)
	t.eq(main.current, "market", "7 opens the Market")
	press.call(KEY_F1)
	t.eq([main.current, main.current_arg], ["skill", Data.skill_list[0].id], "F1 opens the first skill")
	var cap: Control = main._nav_buttons["market:"].keycap
	t.ok(cap.visible and (cap.get_child(0) as Label).text == "7", "the Market's tab shows its key")
	Options.set_keybind("market", KEY_M)
	t.eq((cap.get_child(0) as Label).text, "M", "the keycap follows a change")
	Options.set_keybind("works", KEY_M)
	t.eq(Options.keybind("market"), 0, "a key moves: the Market lost M")
	t.ok(not cap.visible, "and its keycap hides")
	press.call(KEY_M)
	t.eq(main.current, "works", "M opens Sanctum Works now")
	main.free()
	Options.values.keybinds = saved
	Options.save_options()
	_teardown()


## Options > Controls: click a key, press a new one; Esc cancels without closing the dialog.
func test_controls_page_captures_a_key() -> void:
	_setup()
	var saved: Dictionary = Options.values.keybinds.duplicate()
	Options.reset_keybinds()
	var p := OptionsPanel.new()
	_layer.add_child(p)
	p._current = "controls"
	p._rebuild()
	var b := _find_button(p, "7")
	t.ok(b != null, "the Market's row shows 7")
	b.pressed.emit()
	t.eq(p._capturing, "market")
	var key := func(code: int):
		var e := InputEventKey.new()
		e.keycode = code as Key
		e.pressed = true
		p._input(e)
	key.call(KEY_SHIFT)
	t.eq(p._capturing, "market", "a modifier alone waits for the real key")
	key.call(KEY_Q)
	t.eq(Options.keybind("market"), KEY_Q, "Q is the Market's key")
	t.eq(p._capturing, "")
	_find_button(p, "Q").pressed.emit()
	key.call(KEY_ESCAPE)
	t.eq(Options.keybind("market"), KEY_Q, "Esc cancels")
	_find_button(p, "Q").pressed.emit()
	key.call(KEY_BACKSPACE)
	t.eq(Options.keybind("market"), 0, "Backspace clears it")
	p.free()
	Options.values.keybinds = saved
	Options.save_options()
	_teardown()


## Play-test feedback: the breeding picker's cards said what a pair would make but not what each Aetherling
## was doing. A card with a note shows its status too.
func test_picker_cards_show_status_under_the_note() -> void:
	_setup()
	var c: Dictionary = Game.state.creatures.values()[0]
	Skills.assign(Game.state, c, "woodcutting")
	var card := CreatureCard.make(c, false, "Makes Sproutlet")
	var texts := card.find_children("*", "Label", true, false).map(func(l): return l.text)
	t.ok("Makes Sproutlet" in texts, "the note")
	t.ok(("Working: " + Data.skills.woodcutting.name) in texts, "and what it's doing: %s" % [texts])
	card.free()
	_teardown()


## Play-test feedback: one button fills a skill's empty slots with the best resting Aetherlings.
func test_fill_empty_slots() -> void:
	_setup()
	var s := Game.state
	s.skills.woodcutting.level = 10   # two slots
	var starter: Dictionary = s.creatures.values()[0]
	var plain := Creatures.make(s, "sproutlet", 1, 1, false, [], "test")
	var bountiful := Creatures.make(s, "sproutlet", 1, 1, false, [{"id": "bountiful", "s": "major"}], "test")
	var busy := Creatures.make(s, "sproutlet", 1, 30, false, [], "test")
	var pyric := Creatures.make(s, "emberfang", 1, 30, false, [], "test")
	for c in [plain, bountiful, busy, pyric]:
		s.creatures[c.id] = c
	Skills.assign(s, busy, "herbalism")
	Skills.assign(s, starter, "woodcutting")
	var main := _main()
	_teardown()
	main.show_screen("skill", "woodcutting")
	var fb: Button = main._screen._fill_btn
	t.ok(fb.visible and not fb.disabled, "a slot is free and someone can fill it")
	fb.pressed.emit()
	t.eq(GameState.workers(s, "woodcutting").size(), 2, "the free slot is filled")
	t.eq(bountiful.job.get("id", ""), "woodcutting", "by the best producer")
	t.ok(Creatures.is_benched(plain), "the weaker one keeps resting")
	t.eq(busy.job.id, "herbalism", "a worker elsewhere isn't moved")
	main._on_changed()
	t.ok(not main._screen._fill_btn.visible, "no empty slot, no button")


func _first_button(root: Node) -> Button:
	if root is Button and root.visible:
		return root
	for c in root.get_children():
		var b := _first_button(c)
		if b:
			return b
	return null


## Alt+Enter / F11 flip between a window and the fullscreen kind used last, and back.
func test_fullscreen_toggle_goes_back_and_forth() -> void:
	var was: int = Options.get_value("window_mode")
	Options.values.window_mode = 2
	Options.toggle_fullscreen()
	t.eq(int(Options.get_value("window_mode")), 0, "to a window")
	Options.toggle_fullscreen()
	t.eq(int(Options.get_value("window_mode")), 2, "back to the same fullscreen")
	var key := InputEventKey.new()
	key.keycode = KEY_F11
	key.pressed = true
	Options._input(key)
	t.eq(int(Options.get_value("window_mode")), 0, "F11 does it too")
	Options.values.window_mode = was
	Options.flush()


## The mouse's back and forward buttons walk the pages visited, like a browser.
func test_mouse_back_and_forward_walk_the_pages() -> void:
	_setup()
	var main := _main()
	_teardown()
	main.show_screen("expeditions")
	main.show_screen("skill", "woodcutting")
	var back := InputEventMouseButton.new()
	back.button_index = MOUSE_BUTTON_XBUTTON1
	back.pressed = true
	main._input(back)
	t.eq(main.current, "expeditions", "back")
	var fwd := InputEventMouseButton.new()
	fwd.button_index = MOUSE_BUTTON_XBUTTON2
	fwd.pressed = true
	main._input(fwd)
	t.eq([main.current, main.current_arg], ["skill", "woodcutting"], "forward")
	main.history_step(-1)
	main.show_screen("nexus")
	main.history_step(1)
	t.eq(main.current, "nexus", "a new page drops the forward history")
	t.eq((main._nav_buttons["nexus:"].keycap.get_child(0) as Label).text, "2", "the rail shows the shortcut")
	main.free()
	_teardown()


## Play-test feedback: the Nexus filters took three rows of chips, and the Put-to-work menu showed each skill's
## icon at its painted size. Filters are one row of dropdowns; the menu's icons are text-sized, and a full
## skill can't be chosen.
func test_nexus_filters_and_put_to_work_menu() -> void:
	_setup()
	var s := Game.state
	var starter: Dictionary = s.creatures.values()[0]
	var ember := Creatures.make(s, "emberfang", 1, 5, false, [], "test")
	s.creatures[ember.id] = ember
	var main := _main()
	_teardown()
	main.show_screen("nexus", starter.id)
	var nexus: Node = main._screen
	var drops: Array = nexus._filter_bar.get_children().filter(func(n): return n is OptionButton)
	t.eq(drops.size(), 3, "type, show and sort dropdowns on one row")
	var type_drop: OptionButton = drops[0]
	var pyric := -1
	for i in type_drop.item_count:
		if type_drop.get_item_text(i) == Data.types.pyric.name:
			pyric = i
	type_drop.select(pyric)
	type_drop.item_selected.emit(pyric)
	var shown: Array = nexus._grid.get_children().filter(func(n): return n is CreatureCard).map(func(n): return n.cid)
	t.eq(shown, [ember.id], "the Pyric filter shows only the Pyric one")
	var mb: MenuButton = nexus._detail.find_children("*", "MenuButton", true, false)[0]
	var pm := mb.get_popup()
	t.ok(pm.item_count > 0)
	for i in pm.item_count:
		t.eq(pm.get_item_icon_max_width(i), 26, "%s's icon is text-sized" % pm.get_item_text(i))
	Skills.assign(s, starter, "woodcutting")   # woodcutting's one slot is now taken, by this one
	nexus._fill_detail()
	pm = (nexus._detail.find_children("*", "MenuButton", true, false)[0] as MenuButton).get_popup()
	for i in pm.item_count:
		if pm.get_item_text(i).begins_with(Data.skills.woodcutting.name):
			t.ok(pm.is_item_disabled(i), "can't pick the skill it already works in")
	main.free()
	_teardown()


## Designer's request: idle motion on the creature sprites. They breathe and sway from the feet, and hop now
## and then; on the arena's ground (no plate) the feet stay planted between hops.
func test_idle_motion_breathes_from_the_feet() -> void:
	var lifts := []
	var stretch := []
	var sways := []
	for i in 60:
		var m := CreaturePortrait.idle_motion(i * 0.1, 1.3, false)
		lifts.append(m.x)
		stretch.append(m.y)
		sways.append(m.z)
	t.ok(lifts.all(func(v): return v == 0.0), "on the ground the feet stay put")
	t.ok(stretch.max() > 1.01 and stretch.min() < 0.99, "it breathes")
	t.ok(absf(sways.max()) > 0.01 and absf(sways.max()) < 0.05, "a slight sway")
	t.ok(CreaturePortrait.idle_motion(0.7, 1.3, true).x != 0.0, "on a plate it floats a little")
	var peak := 0.0
	for i in 56:
		peak = maxf(peak, CreaturePortrait.hop_motion(i * 0.01).x)
	t.ok(peak > 0.03, "a hop leaves the ground")
	t.eq(CreaturePortrait.hop_motion(CreaturePortrait.HOP_TIME).x, 0.0, "and lands")
	var p := CreaturePortrait.make("sproutlet", 1, 1, false, 120)
	p.size = Vector2(120, 120)
	p._layout()
	t.eq(p._art.pivot_offset.y, p._art.size.y, "the art pivots on its feet")
	p.free()


## An item's tooltip is a card saying what the item is for, or that it only sells.
func test_item_tooltips_say_what_an_item_is_for() -> void:
	_setup()
	var row := UI.amount("oak-log", 3)
	t.ok(row is ItemTip, "cost chips carry a rich tooltip")
	var card: Control = row._make_custom_tooltip("")
	var texts := _texts(card)
	t.ok(texts.any(func(x): return x.begins_with("• ")), "oak logs list their uses: %s" % [texts])
	var only_gold := ""
	for it in Data.item_list:
		if Economy.uses(it.id).is_empty():
			only_gold = it.id
			break
	if only_gold != "":
		var tip := UI.item_tooltip(only_gold)
		t.ok(_texts(tip).any(func(x): return x.begins_with("Only worth its gold")), "%s says it only sells" % only_gold)
		tip.free()
	card.free()
	row.free()
	_teardown()


func _texts(root: Node) -> Array:
	var out := []
	if root is Label:
		out.append(root.text)
	for c in root.get_children():
		out.append_array(_texts(c))
	return out


func test_patch_notes_list_every_version_and_filter_by_kind() -> void:
	var pn := PatchNotes.new()
	t.add_child(pn)
	t.eq(pn._list.get_child_count(), Data.patch_notes.size(), "a card for every version")
	pn._pick("Bugfixes")
	var with_fixes := Data.patch_notes.filter(func(p): return not p.notes.get("Bugfixes", []).is_empty()).size()
	t.eq(pn._list.get_child_count(), with_fixes, "only versions with bug fixes")
	t.ok(pn._chips["Bugfixes"].button_pressed and not pn._chips[""].button_pressed, "the chip shows the filter")
	pn._pick("")
	t.eq(pn._list.get_child_count(), Data.patch_notes.size(), "All shows them all again")
	pn.free()


func test_rail_says_when_a_goal_is_ready_to_claim() -> void:
	_setup()
	var main := _main()
	_teardown()
	var s := Game.state
	s.goals.index = 0   # the first goal: put the Sproutlet to work in Woodcutting
	main._refresh_rail()
	var sn: Dictionary = main._nav_buttons["sanctum:"]
	t.ok(not sn.extra.visible and sn.button.tooltip_text == "", "nothing to claim yet")
	Game.assign(str(s.creatures.keys()[0]), "woodcutting")
	main._refresh_rail()
	t.ok(sn.extra.visible, "a claim chip on the Sanctum")
	t.ok(sn.button.tooltip_text.contains(Data.goals[0].text), "the tooltip names the goal: %s" % sn.button.tooltip_text)
	main.free()
	_teardown()


## Designer's request: the Aether-Log species page shows one form at a time, a large portrait with the three
## forms as thumbnails, opening on the highest form found; a thumbnail click swaps the portrait and the text.
func test_aetherlog_species_page_shows_one_form_at_a_time() -> void:
	_setup()
	var s := Game.state
	var big_form := func(md: Modal) -> int:
		for p in md.find_children("*", "CreaturePortrait", true, false):
			if p.has_meta("big"):
				return p.form
		return 0
	var thumbs := func(md: Modal) -> Array:
		return md.find_children("*", "Button", true, false).filter(func(b): return b.has_meta("form"))
	# unseen: silhouettes and ???, on Form 1
	var sp: Dictionary = Data.species.emberfang
	s.collection.seen.erase(sp.id)
	s.collection.species.erase(sp.id)
	var m: Modal = AetherlogScreen._detail(sp)
	t.eq(big_form.call(m), 1, "an unseen species opens on Form 1")
	t.eq(thumbs.call(m).size(), 0, "no thumbnails: its later forms stay hidden")
	t.ok(_find_label(m, sp.forms[0].name) == null, "an unseen species keeps its name hidden")
	_teardown()
	# seen, not owned
	s.collection.seen[sp.id] = true
	m = AetherlogScreen._detail(sp)
	t.eq(big_form.call(m), 1, "a seen species opens on Form 1")
	t.eq(thumbs.call(m).size(), 3, "three form thumbnails")
	t.ok(_find_label(m, "Form 1") != null, "a form not found yet is named by its number")
	_teardown()
	# owned up to Form 2: opens there, its description is shown, and a click on Form 3 swaps
	var c := Creatures.make(s, sp.id, 1, 25, false, [], "test")
	s.creatures[c.id] = c
	Collection.on_owned(s, c)
	m = AetherlogScreen._detail(sp)
	t.eq(big_form.call(m), 2, "opens on the highest form found")
	t.ok(_find_label(m, sp.forms[1].desc) != null, "Form 2's description is shown")
	var t3: Button = thumbs.call(m)[2]
	t3.pressed.emit()
	t.eq(big_form.call(m), 3, "a thumbnail click swaps the portrait")
	t.eq(t3.theme_type_variation, "TileOn", "the chosen thumbnail is highlighted")
	t.ok(_find_label(m, "Form 3: not discovered yet.") != null, "an undiscovered form says so")
	t.ok(_find_label(m, sp.forms[1].desc) == null, "the text swaps with it")
	_teardown()


func _find_label(root: Node, text: String) -> Label:
	for l in root.find_children("*", "Label", true, false):
		if l.text == text:
			return l
	return null


## Designer's request: the Creaturedex cards can show Form 1, 2 or 3 (or the best found), at the highest rarity
## owned with its effects, and shiny once one was caught.
func test_aetherlog_cards_show_chosen_form_rarity_and_shiny() -> void:
	_setup()
	var s := Game.state
	var c := Creatures.make(s, "emberfang", 3, 25, true, [], "test")
	s.creatures[c.id] = c
	Collection.on_owned(s, c)
	AetherlogScreen.tab = "dex"
	var main := _main()
	_teardown()
	main.show_screen("aetherlog")
	var screen: Node = main._screen
	var card := func() -> CreaturePortrait:
		for p in screen.find_children("*", "CreaturePortrait", true, false):
			if p.has_meta("card_portrait") and p.species == "emberfang" and p.is_inside_tree() and not p.is_queued_for_deletion():
				return p
		return null
	var p: CreaturePortrait = card.call()
	t.eq([p.form, p.rarity, p.shiny, p.silhouette], [2, 3, true, false], "best form, highest rarity, shiny")
	_find_button(screen, "Form 3").pressed.emit()
	p = card.call()
	t.eq([p.form, p.silhouette, p.shiny], [3, true, false], "a form not found is a plain silhouette")
	var unseen: Array = screen.find_children("*", "CreaturePortrait", true, false).filter(func(x): return x.has_meta("card_portrait") and not x.is_queued_for_deletion() and not s.collection.seen.has(x.species))
	t.ok(not unseen.is_empty() and unseen.all(func(x): return x.form == 1), "a species never seen keeps its Form 1 shape")
	_find_button(screen, "Form 1").pressed.emit()
	_find_button(screen, "Highest rarity").pressed.emit()
	_find_button(screen, "Shiny").pressed.emit()
	p = card.call()
	t.eq([p.form, p.rarity, p.shiny, p.silhouette], [1, 1, false, false], "rarity and shiny looks switch off")
	AetherlogScreen.show_form = 0
	AetherlogScreen.show_rarity = true
	AetherlogScreen.show_shiny = true
	main.free()
	_teardown()
