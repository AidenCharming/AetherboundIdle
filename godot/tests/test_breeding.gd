extends RefCounted
## Breeding, eggs, hatching, traits, collection and goals.

var t


func _rng(seed_value := 11) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func _c(s: Dictionary, sp: String, rarity := 1, traits: Array = []) -> Dictionary:
	var c := Creatures.make(s, sp, rarity, 10, false, traits, "test")
	s.creatures[c.id] = c
	return c


func _species(opts: Array) -> Array:
	var out := opts.map(func(o): return o.species)
	out.sort()
	return out


func test_offspring_rules() -> void:
	var s := GameState.new_game()
	t.eq(_species(Breeding.offspring(_c(s, "sproutlet"), _c(s, "sproutlet"))), ["sproutlet"], "same species")
	t.eq(_species(Breeding.offspring(_c(s, "sproutlet"), _c(s, "mossgear"))), ["mossgear", "sproutlet"], "same type")
	t.eq(_species(Breeding.offspring(_c(s, "sproutlet"), _c(s, "emberfang"))), ["ashwood"], "default hybrid")
	t.eq(_species(Breeding.offspring(_c(s, "sproutlet"), _c(s, "tuskcub"))), ["sorrelcliff"], "special recipe beats the default")
	t.eq(_species(Breeding.offspring(_c(s, "tuskcub"), _c(s, "sproutlet"))), ["sorrelcliff"], "order does not matter")
	t.eq(_species(Breeding.offspring(_c(s, "ashwood"), _c(s, "dewdrop"))), ["ashwood", "dewdrop"], "hybrid parents breed true")


func test_rarity_odds_sum_to_one_and_respect_the_ceiling() -> void:
	var s := GameState.new_game()
	var a := _c(s, "sproutlet", 1)
	var b := _c(s, "sproutlet", 1)
	for tier in range(1, Breeding.tier_count() + 1):
		var odds := Breeding.rarity_odds(a, b, tier)
		var sum := 0.0
		var top := 0
		for i in odds.size():
			sum += odds[i]
			if odds[i] > 0.0:
				top = i + 1
		t.near(sum, 1.0, 0.0001, "tier %d sums" % tier)
		t.ok(top <= mini(Breeding.ceiling(tier) + 2, Data.max_rarity()), "tier %d max %d" % [tier, top])
		t.ok(top > Breeding.ceiling(tier) or Breeding.ceiling(tier) == Data.max_rarity(), "mutation can pass the ceiling")


func test_rarer_parents_shift_the_odds_up() -> void:
	var s := GameState.new_game()
	var low := Breeding.rarity_odds(_c(s, "sproutlet", 1), _c(s, "sproutlet", 1), 3)
	var high := Breeding.rarity_odds(_c(s, "sproutlet", 4), _c(s, "sproutlet", 4), 3)
	var mean := func(o: Array) -> float:
		var m := 0.0
		for i in o.size():
			m += o[i] * (i + 1)
		return m
	t.ok(mean.call(high) > mean.call(low) + 1.0)


func test_one_rarer_parent_raises_the_odds() -> void:
	var s := GameState.new_game()
	var dim := _c(s, "sproutlet", 1)
	var faint := _c(s, "mossgear", 2)
	var dd := Breeding.rarity_odds(dim, _c(s, "sproutlet", 1), 1)
	var df := Breeding.rarity_odds(dim, faint, 1)
	var ff := Breeding.rarity_odds(faint, _c(s, "mossgear", 2), 1)
	t.near(dd[1], 0.25, 0.02, "two Dims make a Faint about a quarter of the time (%.3f)" % dd[1])
	t.ok(df[1] > dd[1] + 0.15, "a Faint parent lifts the Faint chance (%.3f vs %.3f)" % [df[1], dd[1]])
	t.ok(df[0] < dd[0] and df[0] > 0.0, "and lowers Dim without ruling it out")
	t.eq(ff[0], 0.0, "two Faints never make a Dim")


func test_breed_pays_and_hatch_waits_for_the_timer() -> void:
	var s := GameState.new_game()
	var a := _c(s, "sproutlet")
	var b := _c(s, "emberfang")
	var rng := _rng()
	t.ok(Breeding.breed(s, a, b, 1, rng, 1000.0).has("error"), "can't afford")
	for id in Breeding.cost(a, b, 1):
		GameState.add_item(s, id, 1000)
	var aether_before := float(s.aether)
	var res := Breeding.breed(s, a, b, 1, rng, 1000.0)
	t.ok(not res.has("error"), str(res.get("error", "")))
	t.near(aether_before - float(s.aether), 100.0, 0.01, "aether cost")
	t.eq(s.pods[res.pod].species, "ashwood")
	t.ok(Breeding.hatch(s, res.pod, 1001.0).is_empty(), "not ready yet")
	var h := Breeding.hatch(s, res.pod, 1000.0 + 3600.0)
	t.eq(h.creature.species, "ashwood")
	t.eq(int(h.creature.level), 1)
	t.ok("ashwood" in s.collection.recipes, "recipe logged")
	t.ok(s.pods[res.pod].is_empty(), "pod emptied")


func test_pods_fill_up() -> void:
	var s := GameState.new_game()
	var a := _c(s, "sproutlet")
	var b := _c(s, "mossgear")
	for id in Breeding.cost(a, b, 1):
		GameState.add_item(s, id, 10000)
	var rng := _rng()
	for i in s.pods.size():
		t.ok(not Breeding.breed(s, a, b, 1, rng, 0.0).has("error"))
	t.ok(Breeding.breed(s, a, b, 1, rng, 0.0).has("error"), "no free pod")


func test_inherited_traits_are_valid() -> void:
	var s := GameState.new_game()
	var rng := _rng()
	var a := _c(s, "eclipsa", 1, [{"id": "aether-drenched", "s": "major"}, {"id": "lucky", "s": "minor"}, {"id": "scholar", "s": "moderate"}])
	var b := _c(s, "sproutlet", 1, [{"id": "green-thumb", "s": "moderate"}])
	for i in 200:
		var got := Breeding.inherit(rng, a, b, ["verdant"])
		t.ok(got.size() <= 3)
		var ids := got.map(func(x): return x.id)
		t.ok(not ("aether-drenched" in ids), "void-only trait never lands on a non-Void creature")
		for x in got:
			t.ok(Data.traits.has(x.id) and x.s in Traits.STRENGTHS)


## Designer's rule: a trait passed down keeps its strength or grows a step; it never comes out weaker.
func test_inherited_traits_never_weaken() -> void:
	var s := GameState.new_game()
	var rng := _rng()
	var a := _c(s, "sproutlet", 1, [{"id": "lucky", "s": "moderate"}, {"id": "scholar", "s": "major"}])
	var b := _c(s, "sproutlet", 1, [{"id": "green-thumb", "s": "minor"}])
	var parent := {"lucky": "moderate", "scholar": "major", "green-thumb": "minor"}
	var grew := 0
	for i in 400:
		for x in Breeding.inherit(rng, a, b, ["verdant"]):
			if parent.has(x.id):
				var was := Traits.STRENGTHS.find(parent[x.id])
				var now := Traits.STRENGTHS.find(x.s)
				t.ok(now >= was, "%s came out %s from a %s parent" % [x.id, x.s, parent[x.id]])
				if now > was:
					grew += 1
	t.ok(grew > 0, "and sometimes grows a step (%d times)" % grew)


func test_attunement_keeps_locked_traits_and_charges_more() -> void:
	var s := GameState.new_game()
	var c := _c(s, "sproutlet", 3, [{"id": "lucky", "s": "major"}, {"id": "scholar", "s": "minor"}])
	t.near(float(Traits.attune_cost(c, 2)), float(Traits.attune_cost(c, 0)) * 9.0, 9.0, "two locks cost about nine times as much")
	GameState.add_item(s, "aether", 100000)
	var rng := _rng()
	for i in 20:
		t.eq(Traits.attune(s, c, ["lucky"], rng), "")
		t.ok(c.traits.any(func(x): return x.id == "lucky" and x.s == "major"), "locked trait kept")


func test_collection_tracks_and_claims() -> void:
	var s := GameState.new_game()
	var rng := _rng()
	for sp in ["brambletrundle", "mossgear", "buzzbud", "tuskcub"]:
		Collection.on_owned(s, _c(s, sp))
	t.eq(Collection.progress(s, "species"), 5)
	var claim := Collection.claimable(s)
	t.ok(claim.any(func(c): return c.track == "species" and c.index == 0))
	var before := GameState.count(s, "tinkerers-vessel")
	Collection.claim(s, "species", 0, rng)
	t.ok(GameState.count(s, "tinkerers-vessel") > before)
	t.ok(Collection.claim(s, "species", 0, rng).is_empty(), "cannot claim twice")


func test_goal_chain_advances() -> void:
	var s := GameState.new_game()
	t.eq(Goals.current(s).id, "work")
	t.ok(Goals.claim(s).is_empty(), "not done yet")
	Skills.assign(s, s.creatures.values()[0], "woodcutting")
	t.ok(not Goals.claim(s).is_empty())
	t.eq(Goals.current(s).id, "logs")


func test_every_goal_check_is_understood() -> void:
	var s := GameState.new_game()
	for g in Data.goals:
		var p := Goals.progress(s, g)
		t.ok(p[1] >= 1, g.id)


func test_better_materials_lift_the_odds_and_zenith_needs_the_top_tier() -> void:
	var s := GameState.new_game()
	var mean := func(odds: Array) -> float:
		var m := 0.0
		for i in odds.size():
			m += odds[i] * (i + 1)
		return m
	var a := _c(s, "sproutlet", 2)
	var b := _c(s, "sproutlet", 2)
	for tier in range(2, Breeding.tier_count() + 1):
		t.ok(mean.call(Breeding.rarity_odds(a, b, tier)) > mean.call(Breeding.rarity_odds(a, b, tier - 1)) - 1e-9,
			"tier %d is at least as good as tier %d" % [tier, tier - 1])
	t.eq(Breeding.ceiling(Breeding.tier_count()), Data.max_rarity(), "the top tier reaches the top rarity")
	for tier in range(1, Breeding.tier_count()):
		t.ok(Breeding.ceiling(tier) < Data.max_rarity(), "only the top tier's ceiling is the top rarity (tier %d)" % tier)
	var r8a := _c(s, "sproutlet", 8)
	var r8b := _c(s, "sproutlet", 8)
	var z: float = Breeding.rarity_odds(r8a, r8b, Breeding.tier_count())[Data.max_rarity() - 1]
	t.ok(z > 0.35 and z < 0.7, "two top-but-one parents on the top tier: about a coin flip (%.2f)" % z)


## Shiny parents lift the egg's shiny chance a little: one shiny parent by half, two by double.
func test_shiny_parents_raise_shiny_chance_slightly() -> void:
	var s := GameState.new_game()
	var a := _c(s, "sproutlet", 1, [])
	var b := _c(s, "sproutlet", 1, [])
	var base := Breeding.hatch_chance_shiny(s, a, b)
	a.shiny = true
	var one := Breeding.hatch_chance_shiny(s, a, b)
	b.shiny = true
	var two := Breeding.hatch_chance_shiny(s, a, b)
	t.near(one, base * 1.5, 0.00001, "one shiny parent: x1.5")
	t.near(two, base * 2.0, 0.00001, "two shiny parents: x2")
	t.ok(two < 0.02, "still rare (%.2f%%)" % (two * 100.0))
