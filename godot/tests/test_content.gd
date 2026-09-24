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
		for tier in range(1, 6):
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
