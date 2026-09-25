class_name AetherlogScreen
extends Control
## The Aether-Log: the Creaturedex (silhouettes until found), the recipe book with hints, and the
## collection tracks with their milestone rewards.

static var tab := "dex"
## How the Creaturedex cards show each species: which form (0 = the highest found), and whether to show the
## highest rarity owned and the shiny look once caught.
static var show_form := 0
static var show_rarity := true
static var show_shiny := true

var _body: VBoxContainer
var _tabs: HBoxContainer
var _completion: Label


func _ready() -> void:
	var v := UI.vbox(17)
	var m := UI.margin(v, 31, 12, 31, 24)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var head := UI.hbox(14)
	head.add_child(UI.header("Aether-Log", "Everything you have found, and a few hints about what you haven't.", Data.ui_icon("aetherlog")))
	_completion = UI.label("", "H1", Palette.GOLD)
	head.add_child(_completion)
	v.add_child(head)
	_tabs = UI.hbox(10)
	v.add_child(_tabs)
	for pair in [["dex", "Creaturedex"], ["recipes", "Recipes"], ["milestones", "Milestones"]]:
		var b := UI.button(pair[1], "Chip")
		b.set_meta("tab", pair[0])
		b.pressed.connect(func():
			tab = pair[0]
			refresh())
		_tabs.add_child(b)
	_body = UI.vbox(17)
	v.add_child(UI.scroll(_body))
	refresh()


func refresh() -> void:
	if Game.state.is_empty():
		return
	_completion.text = "%s complete" % F.pct(Collection.completion(Game.state))
	var claim := Collection.claimable(Game.state).size()
	for b in _tabs.get_children():
		b.theme_type_variation = "ChipOn" if b.get_meta("tab") == tab else "Chip"
		if b.get_meta("tab") == "milestones":
			b.text = "Milestones" + ("  (%d to claim)" % claim if claim > 0 else "")
	UI.clear(_body)
	match tab:
		"dex":
			_dex()
		"recipes":
			_recipes()
		"milestones":
			_milestones()


# ---------------------------------------------------------------- dex

func _dex() -> void:
	var s := Game.state
	# every collection track at a glance; each counts toward the completion figure
	var stats := UI.flow(12, 10)
	for t in Data.collection.tracks:
		var p := Collection.progress(s, t.id)
		var total := Collection.total(t.id)
		var chip := UI.panel("Inset", UI.hbox(10, [UI.label(t.name, "Dim"), UI.label("%d / %d" % [p, total], "Num")]))
		chip.tooltip_text = t.blurb
		stats.add_child(chip)
	_body.add_child(stats)
	_body.add_child(_display_bar())
	for group in [["base", "Wild species"], ["hybrid", "Hybrids"], ["special", "Secret hybrids"]]:
		var list := Data.species_list.filter(func(sp): return sp.kind == group[0])
		var owned := list.filter(func(sp): return Collection.is_owned(s, sp.id)).size()
		_body.add_child(UI.hbox(12, [UI.label(group[1], "H2"), UI.label("%d / %d" % [owned, list.size()], "Dim")]))
		var f := UI.flow(12, 12)
		for sp in list:
			f.add_child(_entry(sp))
		_body.add_child(f)


## The display bar over the cards: Best form / Form 1-3, and the rarity and shiny looks on or off.
func _display_bar() -> Control:
	var bar := UI.hbox(8, [UI.label("Show:", "Faint")])
	for pair in [[0, "Best form"], [1, "Form 1"], [2, "Form 2"], [3, "Form 3"]]:
		var b := UI.button(pair[1], "ChipOn" if show_form == pair[0] else "Chip")
		b.set_meta("show_form", pair[0])
		b.pressed.connect(func():
			show_form = pair[0]
			refresh())
		bar.add_child(b)
	bar.add_child(UI.label("  ·  ", "Faint"))
	var rb := UI.button("Highest rarity", "ChipOn" if show_rarity else "Chip")
	rb.tooltip_text = "Show each species at the highest rarity you have owned, with its frame and effects."
	rb.pressed.connect(func():
		show_rarity = not show_rarity
		refresh())
	bar.add_child(rb)
	var sb := UI.button("Shiny", "ChipOn" if show_shiny else "Chip")
	sb.tooltip_text = "Show the shiny colours of species you have caught a shiny of."
	sb.pressed.connect(func():
		show_shiny = not show_shiny
		refresh())
	bar.add_child(sb)
	return bar


func _entry(sp: Dictionary) -> Control:
	var s := Game.state
	var owned := Collection.is_owned(s, sp.id)
	var seen: bool = owned or s.collection.seen.has(sp.id)
	var entry: Dictionary = s.collection.species.get(sp.id, {})
	var card := UI.button("", "Tile")
	card.custom_minimum_size = Vector2(180, 247)
	card.pressed.connect(func(): _detail(sp))
	var v := UI.vbox(5)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 10
	v.offset_right = -10
	v.offset_top = 10
	v.offset_bottom = -10
	card.add_child(v)
	# the dex number as a chip: the species' type colour once owned, grey until then
	var num_col := Data.type_color(sp.types[0]) if owned else (Palette.TEXT_DIM if seen else Palette.TEXT_FAINT)
	v.add_child(UI.chip("#%03d" % (Data.species_list.find(sp) + 1), num_col))
	var best_form := 1
	for f in entry.get("forms", []):
		best_form = maxi(best_form, int(f))
	# a species never seen shows only its Form 1 shape, whichever form the bar asks for
	var form := show_form if show_form > 0 and seen else best_form
	var have: bool = form in entry.get("forms", [])
	var top_rarity := 1
	if show_rarity and have:
		for r in entry.get("rarities", []):
			top_rarity = maxi(top_rarity, int(r))
	var p := CreaturePortrait.make(sp.id, form, top_rarity, show_shiny and have and entry.get("shiny", false), 132)
	p.bob = false
	p.set_meta("card_portrait", true)
	p.set_silhouette(not have)
	p.modulate.a = 1.0 if owned else (0.8 if seen else 0.45)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(p)
	# the name of the form the card shows, once that form is found
	var name_lbl := UI.label(sp.forms[form - 1].name if have else (sp.name if seen else "???"), "H3")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	v.add_child(name_lbl)
	# rarity dots and shiny star
	var dots := Control.new()
	dots.custom_minimum_size = Vector2(161, 14)
	var rar: Array = entry.get("rarities", [])
	var shiny: bool = entry.get("shiny", false)
	dots.draw.connect(func():
		var n := Data.max_rarity()
		for i in n:
			var c := Data.rarity_color(i + 1) if (i + 1) in rar else Color(1, 1, 1, 0.1)
			dots.draw_circle(Vector2(10 + i * 15.0, 7), 5.0, c, true, -1.0, true)
		if shiny:
			dots.draw_circle(Vector2(10 + n * 15.0, 7), 5.5, Palette.GOLD, true, -1.0, true))
	v.add_child(dots)
	card.tooltip_text = sp.name if seen else "Not found yet"
	return card


## The species page: one form at a time. A large portrait of the selected form on the left with the three
## forms as thumbnails under it, and the text at full width on the right. Opens on the highest form found.
static func _detail(sp: Dictionary) -> Modal:
	var s := Game.state
	var owned := Collection.is_owned(s, sp.id)
	var seen: bool = owned or s.collection.seen.has(sp.id)
	var entry: Dictionary = s.collection.species.get(sp.id, {})
	var row := UI.hbox(28)
	var left := UI.vbox(18)
	var big_box := UI.vbox(0)
	big_box.custom_minimum_size.y = 280   # the portrait's rarity pips draw a little past its 260 px box
	left.add_child(big_box)
	var thumbs := UI.hbox(4)
	thumbs.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_child(thumbs)
	row.add_child(left)
	var right := UI.vbox(12)
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var form_box := UI.vbox(6)
	right.add_child(form_box)
	row.add_child(right)
	var best_form := 1
	for f in entry.get("forms", []):
		best_form = maxi(best_form, int(f))
	var parts := {"big": big_box, "text": form_box, "thumbs": thumbs}
	# a species never seen keeps its later forms hidden: no thumbnails, just the Form 1 shape
	for f in ([1, 2, 3] if seen else []):
		# each thumbnail with the form's name under it (the number until that form is found)
		var col := UI.vbox(4)
		var b := UI.button("", "Tile")
		b.custom_minimum_size = Vector2(88, 88)
		b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		b.set_meta("form", f)
		var tp := CreaturePortrait.make(sp.id, f, 1, false, 72)
		tp.bob = false
		tp.set_silhouette(not (f in entry.get("forms", [])))
		tp.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tp.position = Vector2(8, 8)
		b.add_child(tp)
		b.pressed.connect(func(): _show_form(sp, f, parts))
		col.add_child(b)
		var nm := UI.label(sp.forms[f - 1].name if f in entry.get("forms", []) else "Form %d" % f, "Faint")
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.custom_minimum_size.x = 112
		nm.clip_text = true
		nm.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		nm.tooltip_text = nm.text
		nm.mouse_filter = Control.MOUSE_FILTER_PASS
		col.add_child(nm)
		thumbs.add_child(col)
	_show_form(sp, best_form, parts)
	if not seen:
		right.add_child(UI.wrap_label(_where(sp), "Dim", 560))
		return Modal.open(row, "", 1000)
	var badges := UI.hbox(7)
	for t in sp.types:
		badges.add_child(UI.type_badge(t))
	right.add_child(badges)
	right.add_child(UI.wrap_label("Specialist: %s · Knack: %s · Leans %s" % [Data.skills[sp.primarySkill].name, Data.skills[sp.secondaryAptitude].name, sp.statLean.capitalize()], "Dim", 560))
	if owned:
		var sig: Dictionary = Data.traits[sp.signatureTrait]
		var ab: Dictionary = Data.abilities[sp.ability]
		right.add_child(UI.rich("[b]%s[/b] (signature): %s
[b]%s[/b] (%s): %s" % [sig.name, Traits.describe(sig.id, sig.strength), ab.name, ab.tempo, Describe.ability(ab)]))
		var rrow := UI.hbox(7, [UI.label("Rarities owned:", "Faint")])
		for r in range(1, Data.max_rarity() + 1):
			if r in entry.rarities:
				rrow.add_child(UI.rarity_badge(r))
		right.add_child(rrow)
		# shiny look
		var pal: Dictionary = Data.types[sp.types[0]].shiny
		var sh := UI.hbox(14)
		var sp_por := CreaturePortrait.make(sp.id, 1, 1, true, 96)
		sp_por.set_silhouette(not entry.shiny)
		sh.add_child(sp_por)
		var shv := UI.vbox(2)
		shv.alignment = BoxContainer.ALIGNMENT_CENTER
		shv.add_child(UI.label("Shiny colours: %s" % pal.name, "H3", Color(pal.mid)))
		shv.add_child(UI.label("Caught!" if entry.shiny else "Not found yet. About 1 in %d encounters, 1 in %d hatches." % [roundi(1.0 / Data.tuning.shiny.encounterRate), roundi(1.0 / Data.tuning.shiny.hatchRate)], "Faint"))
		sh.add_child(shv)
		right.add_child(sh)
	right.add_child(UI.wrap_label(_where(sp), "Dim", 560))
	# no title: the selected form's name heads the text (the species' name is only its Form 1 name)
	return Modal.open(row, "", 1000)


## Shows form f on the species page: the large portrait, the thumbnail highlight, and the form's own text.
static func _show_form(sp: Dictionary, f: int, parts: Dictionary) -> void:
	var s := Game.state
	var seen: bool = Collection.is_owned(s, sp.id) or s.collection.seen.has(sp.id)
	var have: bool = f in s.collection.species.get(sp.id, {}).get("forms", [])
	UI.clear(parts.big)
	var p := CreaturePortrait.make(sp.id, f, 1, false, 260)
	p.set_silhouette(not have)
	p.set_meta("big", true)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER   # the column is wider than the portrait (the names)
	parts.big.add_child(p)
	for col in parts.thumbs.get_children():
		var b: Button = col.get_child(0)
		b.theme_type_variation = "TileOn" if b.get_meta("form") == f else "Tile"
	UI.clear(parts.text)
	var form: Dictionary = sp.forms[f - 1]
	var level: int = Data.tuning.creature.formLevels[f - 1]
	var mult: float = Data.tuning.creature.formStatMult[f - 1]
	parts.text.add_child(UI.label(form.name if have else ("Form %d" % f if seen else "???"), "H2"))
	var facts := "Form %d of 3 · the form it starts in" % f if f == 1 else "Form %d of 3 · grows into it at Lv %d · stats ×%.1f" % [f, level, mult]
	parts.text.add_child(UI.label(facts, "Faint"))
	if have and form.has("desc"):
		parts.text.add_child(UI.wrap_label(form.desc, "Dim", 560))
	elif not have:
		parts.text.add_child(UI.wrap_label("Form %d: not discovered yet." % f, "Dim", 560))


static func _where(sp: Dictionary) -> String:
	if sp.kind == "base":
		var zones := Data.zone_list.filter(func(z): return z.species.has(sp.id)).map(func(z): return z.name)
		return "Found wild on: " + ", ".join(zones) if not zones.is_empty() else "Not found in the wild."
	if sp.kind == "hybrid":
		var pair: Array = sp.types
		return "Bred from any %s and %s Aetherlings (unless the pair has a secret recipe)." % [Data.types[pair[0]].name, Data.types[pair[1]].name]
	for r in Data.special_list:
		if r.result == sp.id:
			var known: bool = sp.id in Game.state.collection.recipes or sp.id in Game.state.collection.revealed
			if known:
				return "Secret recipe: %s + %s." % [Data.species[r.parents[0]].name, Data.species[r.parents[1]].name]
			return "A secret recipe. Hint: \"%s\"" % r.hint
	return ""


# ---------------------------------------------------------------- recipes

func _recipes() -> void:
	var s := Game.state
	_body.add_child(UI.label("Type pairs", "H2"))
	_body.add_child(UI.wrap_label("Any two Aetherlings of these two types make the pair's hybrid, unless they are a secret pair.", "Faint"))
	var g := UI.grid(3, 22, 12)
	for key in Data.default_hybrids:
		var id: String = Data.default_hybrids[key]
		var types: Array = key.split("+")
		var h := UI.hbox(10)
		h.add_child(UI.type_badge(types[0], true))
		h.add_child(UI.label("+", "Faint"))
		h.add_child(UI.type_badge(types[1], true))
		h.add_child(UI.label("makes", "Faint"))
		var known: bool = id in s.collection.recipes
		var p := CreaturePortrait.make(id, 1, 1, false, 53)
		p.bob = false
		p.set_silhouette(not known)
		h.add_child(p)
		h.add_child(UI.label(Data.species[id].name if known else "???", "H3" if known else "Dim"))
		g.add_child(UI.panel("CardFlat", h))
	_body.add_child(g)
	_body.add_child(UI.label("Secret recipes", "H2"))
	var found: int = s.collection.recipes.filter(func(id): return Data.species[id].kind == "special").size()
	_body.add_child(UI.count_chip(found, Data.special_list.size(), 16))
	_body.add_child(UI.wrap_label("Each is one exact pair of species. Collection milestones reveal a few pairs outright.", "Dim"))
	var f := UI.flow(14, 14)
	for r in Data.special_list:
		var known: bool = r.result in s.collection.recipes
		var revealed: bool = known or r.result in s.collection.revealed
		var card := UI.panel("Card")
		card.custom_minimum_size = Vector2(432, 144)
		var h := UI.hbox(14)
		var p := CreaturePortrait.make(r.result, 1, 1, false, 101)
		p.bob = false
		p.set_silhouette(not known)
		h.add_child(p)
		var cv := UI.vbox(5)
		cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cv.add_child(UI.label(Data.species[r.result].name if known else "Secret hybrid", "H3" if known else "Dim"))
		var tp := UI.hbox(5)
		for t in Data.species[r.result].types:
			tp.add_child(UI.type_badge(t, true))
		cv.add_child(tp)
		if revealed:
			cv.add_child(UI.label("%s + %s" % [Data.species[r.parents[0]].name, Data.species[r.parents[1]].name], "", Palette.AETHER))
		cv.add_child(UI.wrap_label("\"%s\"" % r.hint, "Faint"))
		h.add_child(cv)
		card.add_child(h)
		f.add_child(card)
	_body.add_child(f)


# ---------------------------------------------------------------- milestones

func _milestones() -> void:
	var s := Game.state
	for t in Data.collection.tracks:
		var p := Collection.progress(s, t.id)
		var total := Collection.total(t.id)
		var card := UI.panel("Glass")
		var v := UI.vbox(10)
		card.add_child(v)
		var h := UI.hbox(12)
		var names := UI.vbox(0, [UI.label(t.name, "H2"), UI.label(t.blurb, "Faint")])
		h.add_child(names)
		h.add_child(UI.spacer())
		h.add_child(UI.label("%d / %d" % [p, total], "Num"))
		v.add_child(h)
		var bar := UI.bar(Palette.GOLD, 12)
		bar.value = float(p) / maxf(1.0, float(total))
		v.add_child(bar)
		var ms := UI.flow(17, 17)
		for i in t.milestones.size():
			var m: Dictionary = t.milestones[i]
			var target := Collection.milestone_target(t.id, m)
			var claimed := Collection.is_claimed(s, t.id, i)
			var claimable := not claimed and p >= target
			# one card per milestone: the goal on top, each reward on its own line, the state at the bottom
			var mc := PanelContainer.new()
			var sb := ThemeFactory.box(Color(1, 1, 1, 0.035) if not claimable else Color(Palette.GOLD, 0.10), 17, 1,
				Color(Palette.GOLD, 0.7) if claimable else Palette.LINE, 17)
			sb.content_margin_top = 14
			sb.content_margin_bottom = 14
			mc.add_theme_stylebox_override("panel", sb)
			mc.custom_minimum_size.x = 180
			var mv := UI.vbox(10)
			mc.add_child(mv)
			var title := UI.label("All %d" % target if str(m.at) == "all" else "At %d" % target, "H3", Palette.GOLD if claimable else Palette.TEXT)
			mv.add_child(title)
			var mbar := UI.bar(Palette.GOOD if claimed else Palette.AETHER, 5)
			mbar.value = clampf(float(p) / maxf(1.0, float(target)), 0.0, 1.0)
			mv.add_child(mbar)
			var rr := UI.vbox(7)
			var r: Dictionary = m.reward
			for k in ["aether", "gold"]:
				if r.has(k):
					rr.add_child(UI.amount(k, float(r[k]), -1, 24))
			for id in r.get("items", {}):
				rr.add_child(UI.amount(id, float(r.items[id]), -1, 24))
			if r.has("title"):
				rr.add_child(UI.wrap_label("Title: " + r.title, "Small", 146))
				(rr.get_child(rr.get_child_count() - 1) as Label).add_theme_color_override("font_color", Palette.GOLD)
			if r.has("revealRecipe"):
				rr.add_child(UI.wrap_label("Reveals %d secret pair%s" % [int(r.revealRecipe), "" if int(r.revealRecipe) == 1 else "s"], "Small", 146))
				(rr.get_child(rr.get_child_count() - 1) as Label).add_theme_color_override("font_color", Palette.AETHER)
			mv.add_child(rr)
			var foot := UI.spacer()
			foot.size_flags_vertical = Control.SIZE_EXPAND_FILL
			mv.add_child(foot)
			if claimed:
				mv.add_child(UI.label("✓ Claimed", "Small", Palette.GOOD))
				mc.modulate.a = 0.6
			elif claimable:
				mv.add_child(UI.button("Claim", "Gold", func(): Game.claim_milestone(t.id, i)))
			else:
				mv.add_child(UI.chip("%d to go" % (target - p), Palette.AETHER, 13))
			ms.add_child(mc)
		v.add_child(ms)
		_body.add_child(card)
	if not s.collection.titles.is_empty():
		var tv := UI.hbox(12, [UI.label("Your title", "H3")])
		var ob := OptionButton.new()
		ob.add_item("None", 0)
		for i in s.collection.titles.size():
			ob.add_item(s.collection.titles[i], i + 1)
			if s.settings.title == s.collection.titles[i]:
				ob.selected = i + 1
		ob.item_selected.connect(func(i): Game.state.settings.title = "" if i == 0 else Game.state.collection.titles[i - 1])
		tv.add_child(ob)
		_body.add_child(UI.panel("Glass", tv))
