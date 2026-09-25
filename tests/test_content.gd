extends RefCounted
## Content integrity: every id the data refers to exists.

var t


func test_species_counts() -> void:
	t.eq(Data.species_list.filter(func(s): return s.kind == "base").size(), 24, "base species")
	t.eq(Data.species_list.filter(func(s): return s.kind == "hybrid").size(), 15, "default hybrids")
	t.eq(Data.special_list.size(), 30, "special recipes")


func test_species_references() -> void:
	for sp in Data.species_list:
		t.ok(Data.abilities.has(sp.ability), sp.id + " ability")
		t.ok(Data.traits.has(sp.signatureTrait), sp.id + " trait")
		t.ok(Data.skills.has(sp.primarySkill), sp.id + " primary skill")
		t.ok(Data.skills.has(sp.secondaryAptitude), sp.id + " aptitude")
		t.eq(sp.forms.size(), 3, sp.id + " forms")
		for ty in sp.types:
			t.ok(Data.types.has(ty), sp.id + " type " + ty)


func test_base_species_have_all_three_sprites() -> void:
	for sp in Data.species_list:
		if sp.kind != "base":
			continue
		for f in [1, 2, 3]:
			t.ok(Data.creature_texture(sp.id, f) != null, "%s form %d sprite" % [sp.id, f])


func test_every_type_pair_has_a_default_hybrid() -> void:
	var ids := Data.type_list.map(func(x): return x.id)
	for i in ids.size():
		for j in range(i + 1, ids.size()):
			t.ok(Data.default_hybrids.has(Data.pair_key(ids[i], ids[j])), "%s/%s" % [ids[i], ids[j]])


func test_actions_reference_items() -> void:
	for skill in Data.skill_list:
		t.ok(Data.ui_icon(skill.id) != null, skill.id + " icon")
		for a in skill.actions:
			for id in a.get("inputs", {}):
				t.ok(id == "aether" or Data.items.has(id), "%s input %s" % [a.id, id])
			for id in a.outputs:
				t.ok(Data.items.has(id), "%s output %s" % [a.id, id])
			t.ok(Data.items.has(a.rare.item), a.id + " rare")


func test_items_have_icons() -> void:
	for it in Data.item_list:
		t.ok(Data.item_icon(it.id) != null, it.id + " icon")


func test_breeding_materials_exist_for_every_type_and_tier() -> void:
	for ty in Data.type_list:
		for tier in range(1, Breeding.tier_count() + 1):
			t.ok(Breeding.material(ty.id, tier) != "", "%s tier %d" % [ty.id, tier])


func test_zones_reference_species_and_items() -> void:
	for z in Data.zone_list:
		for sp in z.species:
			t.ok(Data.species.has(sp), z.id + " " + sp)
		t.ok(Data.species.has(z.boss.model), z.id + " boss model")
		t.ok(Data.abilities.has(z.boss.ability), z.id + " boss ability")
		for l in z.loot:
			t.ok(Data.items.has(l.item), z.id + " loot " + l.item)


func test_special_recipes_are_cross_type() -> void:
	for r in Data.special_list:
		var a: Dictionary = Data.species[r.parents[0]]
		var b: Dictionary = Data.species[r.parents[1]]
		t.ok(a.types[0] != b.types[0], r.result)
		t.eq(Data.species[r.result].kind, "special")


## Market rules (designer's): everything the Market sells sells back for a little less than it costs (no buy-
## and-resell loop, but not a big gap either), and crafting always adds value, so making something is cheaper
## than buying it and making and selling beats selling the inputs.
func test_market_prices() -> void:
	for it in Market.catalog():
		var buy := Market.buy_price(it.id)
		# a little less: at least 75% back (the cheapest things round up to a whole gold, so a 1-gold gap is fine)
		t.ok(int(it.sell) < buy and (float(it.sell) >= buy * 0.75 or buy - int(it.sell) <= 1), "%s sells for a little less than its price" % it.id)
	for skill in Data.skill_list:
		for a in skill.actions:
			var inputs: Dictionary = a.get("inputs", {})
			var in_value := 0.0
			for id in inputs:
				if Data.items.has(id):
					in_value += float(Data.items[id].sell) * float(inputs[id])
			if in_value <= 0.0:
				continue
			var out_value := 0.0
			for id in a.outputs:
				out_value += float(Data.items[id].sell) * float(a.outputs[id])
			t.ok(out_value >= in_value * 1.25, "%s/%s: output %d vs inputs %d" % [skill.id, a.id, out_value, in_value])


## Play-test feedback: Cooking opens with the first Pyric Aetherling (Smoldering Caldera), but fish only came
## from Fishing, which needs an Aqueous one from the island after it, so there were no meals for the Caldera
## boss. Every island up to the first Pyric one drops the fish for the first Cooking recipe.
func test_meals_can_be_cooked_before_the_first_aqueous_aetherling() -> void:
	var first_cook: Dictionary = {}
	for sk in Data.skill_list:
		if sk.id == "cooking":
			first_cook = sk.actions[0]
	var fish: String = first_cook.inputs.keys()[0]
	for z in Data.zone_list:
		t.ok(z.loot.any(func(l): return l.item == fish), "%s drops %s" % [z.id, fish])
		if z.type == "pyric":
			break


func test_patch_notes_are_well_formed_and_start_at_this_version() -> void:
	var notes: Array = Data.patch_notes
	t.ok(notes.size() > 0, "there are patch notes")
	t.eq(str(notes[0].version), str(ProjectSettings.get_setting("application/config/version")), "the newest is this build's version")
	var kinds := PatchNotes.KINDS.map(func(k): return k[0])
	var prev := ""
	for p: Dictionary in notes:
		t.ok(p.has("version") and p.has("date") and p.has("title") and p.has("notes"), "v%s has every field" % p.get("version"))
		if prev != "":
			t.ok(_version_less(str(p.version), prev), "v%s comes after v%s: newest first" % [p.version, prev])
		prev = str(p.version)
		for k: String in p.notes:
			t.ok(k in kinds, "v%s: %s is a known kind" % [p.version, k])
			for e: Array in p.notes[k]:
				t.ok(e.size() == 2 and str(e[0]) != "" and str(e[1]) != "", "v%s: an entry is [area, text]" % p.version)
				t.ok(PatchNotes.AREA_COLORS.has(e[0]), "v%s: area %s has a colour" % [p.version, e[0]])


func _version_less(a: String, b: String) -> bool:
	var x := a.split(".")
	var y := b.split(".")
	for i in 3:
		if int(x[i]) != int(y[i]):
			return int(x[i]) < int(y[i])
	return false
