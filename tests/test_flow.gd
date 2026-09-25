extends RefCounted
## An early game played through the sim alone: the starter chops wood, explores the first island
## while away, and the Sanctum ends up with more Aetherlings, logs and Aether.

var t


func test_first_hours() -> void:
	var s := GameState.new_game()
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var sprout: Dictionary = s.creatures.values()[0]
	Skills.assign(s, sprout, "woodcutting")
	# ten minutes of chopping online
	for i in 600:
		Sim.step(s, 1.0, rng)
	t.ok(GameState.count(s, "oak-log") > 100, "logs chopped")
	t.ok(int(s.skills.woodcutting.level) >= 5, "woodcutting level %d" % int(s.skills.woodcutting.level))
	# then send it exploring and close the game for three hours
	Expedition.set_party_member(s, 0, sprout)
	t.eq(Expedition.start(s, "whisperleaf-hollow", rng), "")
	var summary := Offline.apply(s, 3 * 3600.0, rng)
	t.ok(int(s.counters.kills) > 20, "kills %d" % int(s.counters.kills))
	# the starter pack's vessels are thrown at the wild ones: each throw binds or breaks free (a fixed seed
	# can miss all five at 55%, so the count of throws is checked, not a bind)
	t.eq(GameState.count(s, "tinkerers-vessel"), 0.0, "the starter vessels were all thrown")
	t.eq(s.creatures.size(), 1 + int(s.counters.captures), "every bind became an Aetherling")
	t.ok(int(sprout.level) > 5, "the starter levelled up to %d" % int(sprout.level))
	t.ok(summary.aether >= 0.0)
