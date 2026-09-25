class_name RarityPreview
extends RefCounted
## Developer tools: every rarity's frame and shader effect side by side, plain and shiny, for any species and
## form, plus a button for every sound. The real entrances (burst, "Shiny!" and their sounds) are seen in the
## arena with "Next wave: a shiny" / "the rarest rarity".


static func open() -> void:
	var v := UI.vbox(12)
	var pick := UI.hbox(10)
	var sp := OptionButton.new()
	for i in Data.species_list.size():
		sp.add_item(Data.species_list[i].name, i)
	var form := OptionButton.new()
	for f in 3:
		form.add_item("Form %d" % (f + 1), f)
	pick.add_child(UI.label("Species", "Dim"))
	pick.add_child(sp)
	pick.add_child(form)
	v.add_child(pick)
	var grid := GridContainer.new()
	grid.columns = Data.rarities.size()
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 7)
	var sc := UI.scroll(grid)
	sc.custom_minimum_size = Vector2(1320, 396)
	v.add_child(sc)
	var fill := func(_x = null):
		UI.clear(grid)
		var id: String = Data.species_list[sp.selected].id
		for shiny in [false, true]:
			for r in range(1, Data.rarities.size() + 1):
				var cell := UI.vbox(2)
				cell.add_child(CreaturePortrait.make(id, form.selected + 1, r, shiny, 115))
				var l := UI.label(Data.rarity(r).name + (" ✦" if shiny else ""), "Small", Data.rarity_color(r))
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				cell.add_child(l)
				grid.add_child(cell)
	sp.item_selected.connect(fill)
	form.item_selected.connect(fill)
	fill.call()
	v.add_child(UI.label("Sounds", "H3"))
	var sounds := UI.flow(7, 7)
	var names: Array = Sfx.sound_names()
	names.sort()
	for sound in names:
		sounds.add_child(UI.button(sound, "Chip", func(): Sfx.play(sound, 1.0, true)))
	v.add_child(sounds)
	Modal.open(v, "Rarity preview", 1392)
