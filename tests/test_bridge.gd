extends RefCounted
## The test bridge stays off unless the game is started with -- --bridge.

var t


func test_bridge_is_off_by_default() -> void:
	t.ok(not TestBridge.enabled, "no --bridge, no listening port")
	t.ok(not TestBridge.is_processing(), "and it does nothing each frame")


func test_bridge_invariants_catch_a_broken_save() -> void:
	var keep := Game.state
	Game.state = GameState.new_game()
	t.eq(TestBridge.invariants(), [], "a new game breaks nothing")
	Game.state.gold = -5.0
	var c: Dictionary = Game.state.creatures.values()[0]
	c.job = {"kind": "party"}
	var breaks := TestBridge.invariants()
	t.ok(breaks.any(func(b): return b.begins_with("gold")), "negative gold is caught: %s" % [breaks])
	t.ok(breaks.any(func(b): return "party job" in b), "a party job outside the party is caught: %s" % [breaks])
	Game.state = keep


func test_bridge_player_snapshot_and_goal() -> void:
	var keep := Game.state
	Game.state = GameState.new_game()
	var p := TestBridge.player_snapshot()
	t.eq(p.creatures.size(), 1, "the starting Sproutlet")
	t.eq(p.goal.id, Data.goals[0].id, "the first goal")
	t.ok(p.skills.woodcutting.usable and p.skills.woodcutting.actions[0].unlocked, "Woodcutting's first task is open")
	t.ok(not p.skills.mining.usable, "Mining needs a Telluric Aetherling")
	var cid: String = p.creatures[0].id
	var r := TestBridge.breed_check([[cid, cid]], 1)
	t.eq(r[0].error, "Choose two different Aetherlings.", "breed_check reports why a pair can't breed")
	Game.state = keep
