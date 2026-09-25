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
