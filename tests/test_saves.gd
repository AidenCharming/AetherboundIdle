extends RefCounted
## Save files: atomic writes, the backup and .tmp fallbacks, renaming and deleting a slot. Uses slot 99 only and
## deletes it after every test, so the player's slots 1 to 3 are never touched. Parsing a broken file on purpose
## may print a script error; that is expected output.

const N := 99

var t


func _begin() -> Dictionary:
	var keep := {"slot": Game.slot, "state": Game.state}
	Game.delete_slot(N)
	Game.slot = N
	Game.rng.seed = 777
	Game.state = GameState.new_game()
	return keep


func _end(keep: Dictionary) -> void:
	Game.delete_slot(N)
	Game.slot = keep.slot
	Game.state = keep.state


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _parses(path: String) -> bool:
	var json := JSON.new()
	return FileAccess.file_exists(path) and json.parse(FileAccess.get_file_as_string(path)) == OK \
		and json.data is Dictionary and json.data.has("version")


## The generator state is saved, so a reload rolls the same next number (the no-re-roll rule).
func test_reload_keeps_the_next_roll() -> void:
	var keep := _begin()
	Game.save_game()
	var expected := Game.rng.randf()
	t.ok(Game.load_game(), "loaded")
	t.eq(Game.rng.randf(), expected, "same roll after a reload")
	_end(keep)


## A main file cut off mid-write loads from the backup, and saving again never overwrites the good backup.
func test_half_written_main_falls_back_to_the_backup() -> void:
	var keep := _begin()
	Game.state.gold = 1234
	Game.save_game()
	Game.save_game()   # the second save makes the first one the backup
	_write(Game.slot_path(N), "{\"version\": 1, \"creat")
	Game.state = {}
	t.ok(Game.load_game(), "recovered")
	t.eq(int(Game.state.gold), 1234, "from the backup")
	Game.save_game()
	t.ok(_parses(Game.backup_path(N)), "the backup still parses after saving again")
	t.ok(_parses(Game.slot_path(N)), "and the main file is whole")
	_end(keep)


## A leftover .tmp (a crash between removing main and renaming) is the newest save and is what loads.
func test_leftover_tmp_is_loaded_when_main_is_missing() -> void:
	var keep := _begin()
	Game.state.gold = 10
	Game.save_game()
	Game.save_game()
	var newer: Dictionary = Game.state.duplicate(true)
	newer.gold = 999
	_write(Game.tmp_path(N), JSON.stringify(newer))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(Game.slot_path(N)))
	t.ok(Game.load_game(), "loaded")
	t.eq(int(Game.state.gold), 999, "the .tmp save won over the backup")
	_end(keep)


## A slot that is not loaded can be named; the name is trimmed, the backup stays readable, "" clears it.
func test_save_slots_can_be_renamed() -> void:
	var keep := _begin()
	Game.save_game()
	Game.save_game()
	Game.slot = 0
	Game.state = {}
	Game.rename_slot(N, "  X  ")
	t.eq(Game.slot_info(N).get("name"), "X", "named and trimmed")
	t.ok(_parses(Game.backup_path(N)), "backup readable")
	Game.rename_slot(N, "  Dev Save  ")
	t.eq(Game.slot_info(N).get("name"), "Dev Save")
	Game.rename_slot(N, "")
	t.eq(Game.slot_info(N).get("name"), "", "cleared")
	_end(keep)


## Deleting a slot leaves no main, backup or .tmp file behind.
func test_delete_slot_removes_every_file() -> void:
	var keep := _begin()
	Game.save_game()
	Game.save_game()
	_write(Game.tmp_path(N), "{}")
	Game.delete_slot(N)
	for path in [Game.slot_path(N), Game.backup_path(N), Game.tmp_path(N)]:
		t.ok(not FileAccess.file_exists(path), "%s removed" % path)
	t.eq(Game.slot_info(N), {}, "the slot reads as empty")
	_end(keep)


## The session-start copy is the last fallback: it still loads when the main file, .tmp and .bak are all gone.
func test_session_copy_is_the_last_fallback() -> void:
	var keep := _begin()
	Game.state.aether = 4321
	Game.save_game()
	DirAccess.copy_absolute(ProjectSettings.globalize_path(Game.slot_path(N)), ProjectSettings.globalize_path(Game.session_path(N)))
	for path in [Game.slot_path(N), Game.backup_path(N), Game.tmp_path(N)]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Game.state = GameState.new_game()
	t.ok(Game.load_game(), "loads from the session copy")
	t.eq(int(Game.state.aether), 4321, "the session copy's Aether")
	_end(keep)


## An import keeps the game it replaced, and a save that migrates into the wrong shape is refused untouched.
func test_import_keeps_the_old_game_and_refuses_damage() -> void:
	var keep := _begin()
	Game.state.aether = 111
	var damaged: Dictionary = GameState.new_game()
	damaged.expedition = "broken"
	t.ok(Game.import_text(JSON.stringify(damaged)) != "", "a damaged save is refused")
	t.eq(int(Game.state.aether), 111, "the game in play is untouched")
	# shapes that would stop migrate itself with an error are refused before it runs (review 3 #2)
	var listed: Dictionary = GameState.new_game()
	listed.creatures = []
	t.ok(Game.import_text(JSON.stringify(listed)) != "", "creatures as a list are refused")
	var bad_one: Dictionary = GameState.new_game()
	bad_one.creatures = {"c1": 5}
	t.ok(Game.import_text(JSON.stringify(bad_one)) != "", "a creature that is not a record is refused")
	t.eq(int(Game.state.aether), 111, "still untouched")
	var other: Dictionary = GameState.new_game()
	other.aether = 999
	t.eq(Game.import_text(JSON.stringify(other)), "", "a good save imports")
	t.eq(int(Game.state.aether), 999, "and is in play")
	var json := JSON.new()
	t.ok(json.parse(FileAccess.get_file_as_string(Game.pre_import_path(N))) == OK and int(json.data.aether) == 111, "the old game was kept")
	Game.delete_slot(N)
	t.ok(not FileAccess.file_exists(Game.pre_import_path(N)), "deleting the slot removes the pre-import copy")
	_end(keep)


## Each launch keeps the previous session copy too, so a bad state saved and then relaunched can still be undone
## from a launch earlier; a load that falls back to a session copy tells the player (review 3 #3).
func test_session_copies_rotate_and_a_fallback_is_announced() -> void:
	var keep := _begin()
	var was_running := Game.running
	Game.state.aether = 1000
	Game.save_game()
	Game.start_slot(N)            # launch 1: session = 1000
	Game.state.aether = 2000
	Game.save_game()
	Game.start_slot(N)            # launch 2: session = 2000, prev = 1000
	var json := JSON.new()
	t.ok(json.parse(FileAccess.get_file_as_string(Game.session_prev_path(N))) == OK and int(json.data.aether) == 1000, "the previous session copy is kept")
	t.eq(Game.notifications.size(), 0, "a normal load says nothing")
	for path in [Game.slot_path(N), Game.backup_path(N), Game.tmp_path(N)]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	Game.start_slot(N)
	t.eq(int(Game.state.aether), 2000, "loaded from the session copy")
	t.ok(Game.notifications.size() > 0 and "could not be read" in str(Game.notifications[0].text), "and the player is told")
	Game.delete_slot(N)
	t.ok(not FileAccess.file_exists(Game.session_prev_path(N)), "deleting the slot removes the previous session copy")
	Game.running = was_running
	Game.set_process(was_running)
	Game.notifications.clear()
	Game.unread = 0
	_end(keep)
