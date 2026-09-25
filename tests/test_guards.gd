extends RefCounted
## Actions refuse bad ids, indices and tiers instead of erroring (the UI never sends them; the bridge can).

var t


func test_bad_inputs_are_refused() -> void:
	var s := GameState.new_game()
	var rng := RandomNumberGenerator.new()
	var ids: Array = s.creatures.keys()
	var a: Dictionary = s.creatures[ids[0]]
	var b := Creatures.make(s, a.species, 1, 1, false, [], "test")
	s.creatures[b.id] = b
	for tier in [0, -1, 99]:
		t.eq(Breeding.check(s, a, b, tier), "No such breeding tier.", "breeding tier %d" % tier)
	t.eq(Market.egg_check(s, "verdant", -1), "No such egg.", "a negative egg grade")
	t.eq(Market.egg_check(s, "nope", 0), "No such egg.", "an unknown egg type")
	t.eq(Collection.claim(s, "no-such-track", 0, rng), {}, "an unknown milestone track")
	t.eq(Collection.claim(s, Data.collection.tracks[0].id, -1, rng), {}, "a negative milestone index")
	t.eq(Collection.claim(s, Data.collection.tracks[0].id, 9999, rng), {}, "a milestone index past the end")
	t.eq(Traits.attune(s, {}, [], rng), "No such Aetherling.", "attuning nobody")
	t.eq(Market.buy_offer(s, -1, 0.0, rng), "That offer is gone.", "a negative offer index")
