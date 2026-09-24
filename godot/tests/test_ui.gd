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
