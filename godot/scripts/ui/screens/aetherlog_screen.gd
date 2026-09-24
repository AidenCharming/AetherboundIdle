class_name AetherlogScreen
extends Control
## The Aether-Log: the Creaturedex (silhouettes until found), the recipe book with hints, and the
## collection tracks with their milestone rewards.

static var tab := "dex"

var _body: VBoxContainer
var _tabs: HBoxContainer
var _completion: Label


func _ready() -> void:
	var v := UI.vbox(14)
	var m := UI.margin(v, 26, 10, 26, 20)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var head := UI.hbox(12)
	head.add_child(UI.header("Aether-Log", "Everything you have found, and a few hints about what you haven't.", Data.ui_icon("aetherlog")))
	head.add_child(UI.spacer())
	_completion = UI.label("", "H1", Palette.GOLD)
	head.add_child(_completion)
	v.add_child(head)
	_tabs = UI.hbox(8)
	v.add_child(_tabs)
	for pair in [["dex", "Creaturedex"], ["recipes", "Recipes"], ["milestones", "Milestones"]]:
		var b := UI.button(pair[1], "Chip")
		b.set_meta("tab", pair[0])
		b.pressed.connect(func():
			tab = pair[0]
			refresh())
		_tabs.add_child(b)
	_body = UI.vbox(14)
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
	for group in [["base", "Wild species"], ["hybrid", "Hybrids"], ["special", "Secret hybrids"]]:
		var list := Data.species_list.filter(func(sp): return sp.kind == group[0])
		var owned := list.filter(func(sp): return Collection.is_owned(s, sp.id)).size()
		_body.add_child(UI.hbox(10, [UI.label(group[1], "H2"), UI.label("%d / %d" % [owned, list.size()], "Dim")]))
		var f := UI.flow(10, 10)
		for sp in list:
			f.add_child(_entry(sp))
		_body.add_child(f)


func _entry(sp: Dictionary) -> Control:
	var s := Game.state
	var owned := Collection.is_owned(s, sp.id)
	var seen: bool = owned or s.collection.seen.has(sp.id)
	var entry: Dictionary = s.collection.species.get(sp.id, {})
	var card := UI.button("", "Tile")
	card.custom_minimum_size = Vector2(150, 206)
	card.pressed.connect(func(): _detail(sp))
	var v := UI.vbox(4)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 8
	v.offset_right = -8
	v.offset_top = 8
	v.offset_bottom = -8
	card.add_child(v)
	var num := UI.label("#%03d" % (Data.species_list.find(sp) + 1), "Faint")
	v.add_child(num)
	var best_form := 1
	for f in entry.get("forms", []):
		best_form = maxi(best_form, int(f))
	var p := CreaturePortrait.make(sp.id, best_form, 1, false, 110)
	p.bob = false
	p.set_silhouette(not owned)
	p.modulate.a = 1.0 if owned else (0.8 if seen else 0.45)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(p)
	var name_lbl := UI.label(sp.name if seen else "???", "H3")
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.clip_text = true
	v.add_child(name_lbl)
	# rarity dots and shiny star
	var dots := Control.new()
	dots.custom_minimum_size = Vector2(134, 12)
	var rar: Array = entry.get("rarities", [])
	var shiny: bool = entry.get("shiny", false)
	dots.draw.connect(func():
		var n := Data.max_rarity()
		for i in n:
			var c := Data.rarity_color(i + 1) if (i + 1) in rar else Color(1, 1, 1, 0.1)
			dots.draw_circle(Vector2(8 + i * 12.5, 6), 4.2, c)
		if shiny:
			dots.draw_circle(Vector2(8 + n * 12.5, 6), 4.6, Palette.GOLD))
	v.add_child(dots)
	card.tooltip_text = sp.name if seen else "Not found yet"
	return card


func _detail(sp: Dictionary) -> void:
	var s := Game.state
	var owned := Collection.is_owned(s, sp.id)
	var seen: bool = owned or s.collection.seen.has(sp.id)
	var entry: Dictionary = s.collection.species.get(sp.id, {})
	var v := UI.vbox(12)
	var forms := UI.hbox(18)
	forms.alignment = BoxContainer.ALIGNMENT_CENTER
	for f in [1, 2, 3]:
		var fv := UI.vbox(4)
		var have: bool = f in entry.get("forms", [])
		var p := CreaturePortrait.make(sp.id, f, 1, false, 170)
		p.set_silhouette(not have)
		fv.add_child(p)
		var l := UI.label(sp.forms[f - 1].name if have else "Form %d" % f, "H3")
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fv.add_child(l)
		if have and sp.forms[f - 1].has("desc"):
			var d := UI.wrap_label(sp.forms[f - 1].desc, "Faint", 170)
			d.custom_minimum_size.x = 170
			fv.add_child(d)
		forms.add_child(fv)
	v.add_child(forms)
	if not seen:
		v.add_child(UI.wrap_label(_where(sp), "Dim", 560))
		Modal.open(v, "???", 700)
		return
	var badges := UI.hbox(6)
	for t in sp.types:
		badges.add_child(UI.type_badge(t))
	badges.add_child(UI.label("Specialist: %s · Knack: %s · Leans %s" % [Data.skills[sp.primarySkill].name, Data.skills[sp.secondaryAptitude].name, sp.statLean.capitalize()], "Dim"))
	v.add_child(badges)
	if owned:
		var sig: Dictionary = Data.traits[sp.signatureTrait]
		var ab: Dictionary = Data.abilities[sp.ability]
		v.add_child(UI.rich("[b]%s[/b] (signature): %s\n[b]%s[/b] (%s): %s" % [sig.name, Traits.describe(sig.id, sig.strength), ab.name, ab.tempo, Describe.ability(ab)]))
		var rrow := UI.hbox(6, [UI.label("Rarities owned:", "Faint")])
		for r in range(1, Data.max_rarity() + 1):
			if r in entry.rarities:
				rrow.add_child(UI.rarity_badge(r))
		v.add_child(rrow)
		# shiny look
		var pal: Dictionary = Data.types[sp.types[0]].shiny
		var sh := UI.hbox(12)
		var sp_por := CreaturePortrait.make(sp.id, 1, 1, true, 110)
		sp_por.set_silhouette(not entry.shiny)
		sh.add_child(sp_por)
		var shv := UI.vbox(2)
		shv.add_child(UI.label("Shiny colours: %s" % pal.name, "H3", Color(pal.mid)))
		shv.add_child(UI.label("Caught!" if entry.shiny else "Not found yet. About 1 in %d encounters, 1 in %d hatches." % [roundi(1.0 / Data.tuning.shiny.encounterRate), roundi(1.0 / Data.tuning.shiny.hatchRate)], "Faint"))
		sh.add_child(shv)
		v.add_child(sh)
	v.add_child(UI.wrap_label(_where(sp), "Dim", 560))
	Modal.open(v, sp.name, 700)


func _where(sp: Dictionary) -> String:
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
	var g := UI.grid(3, 18, 10)
	for key in Data.default_hybrids:
		var id: String = Data.default_hybrids[key]
		var types: Array = key.split("+")
		var h := UI.hbox(8)
		h.add_child(UI.type_badge(types[0], true))
		h.add_child(UI.label("+", "Faint"))
		h.add_child(UI.type_badge(types[1], true))
		h.add_child(UI.label("makes", "Faint"))
		var known: bool = id in s.collection.recipes
		var p := CreaturePortrait.make(id, 1, 1, false, 44)
		p.bob = false
		p.set_silhouette(not known)
		h.add_child(p)
		h.add_child(UI.label(Data.species[id].name if known else "???", "H3" if known else "Dim"))
		g.add_child(UI.panel("CardFlat", h))
	_body.add_child(g)
	_body.add_child(UI.label("Secret recipes", "H2"))
	var found: int = s.collection.recipes.filter(func(id): return Data.species[id].kind == "special").size()
	_body.add_child(UI.wrap_label("%d of %d found. Each is one exact pair of species. Collection milestones reveal a few pairs outright." % [found, Data.special_list.size()], "Faint"))
	var f := UI.flow(12, 12)
	for r in Data.special_list:
		var known: bool = r.result in s.collection.recipes
		var revealed: bool = known or r.result in s.collection.revealed
		var card := UI.panel("Card")
		card.custom_minimum_size = Vector2(360, 120)
		var h := UI.hbox(12)
		var p := CreaturePortrait.make(r.result, 1, 1, false, 84)
		p.bob = false
		p.set_silhouette(not known)
		h.add_child(p)
		var cv := UI.vbox(4)
		cv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cv.add_child(UI.label(Data.species[r.result].name if known else "Secret hybrid", "H3" if known else "Dim"))
		var tp := UI.hbox(4)
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
		var v := UI.vbox(8)
		card.add_child(v)
		var h := UI.hbox(10)
		h.add_child(UI.label(t.name, "H2"))
		h.add_child(UI.label(t.blurb, "Faint"))
		h.add_child(UI.spacer())
		h.add_child(UI.label("%d / %d" % [p, total], "Num"))
		v.add_child(h)
		var bar := UI.bar(Palette.GOLD, 10)
		bar.value = float(p) / maxf(1.0, float(total))
		v.add_child(bar)
		var ms := UI.flow(10, 10)
		for i in t.milestones.size():
			var m: Dictionary = t.milestones[i]
			var target := Collection.milestone_target(t.id, m)
			var claimed := Collection.is_claimed(s, t.id, i)
			var mc := UI.panel("CardFlat")
			var mv := UI.vbox(4)
			mc.add_child(mv)
			mv.add_child(UI.label("All %d" % target if str(m.at) == "all" else "At %d" % target, "H3"))
			var rr := UI.flow(8, 4)
			var r: Dictionary = m.reward
			for k in ["aether", "gold"]:
				if r.has(k):
					rr.add_child(UI.amount(k, float(r[k]), -1, 18))
			for id in r.get("items", {}):
				rr.add_child(UI.amount(id, float(r.items[id]), -1, 18))
			if r.has("title"):
				rr.add_child(UI.label("Title: " + r.title, "Small", Palette.GOLD))
			if r.has("revealRecipe"):
				rr.add_child(UI.label("Reveals %d secret pair%s" % [int(r.revealRecipe), "" if int(r.revealRecipe) == 1 else "s"], "Small", Palette.AETHER))
			mv.add_child(rr)
			if claimed:
				mv.add_child(UI.label("Claimed", "Small", Palette.GOOD))
				mc.modulate.a = 0.6
			elif p >= target:
				mv.add_child(UI.button("Claim", "Gold", func(): Game.claim_milestone(t.id, i)))
			else:
				mv.add_child(UI.label("%d to go" % (target - p), "Faint"))
			ms.add_child(mc)
		v.add_child(ms)
		_body.add_child(card)
	if not s.collection.titles.is_empty():
		var tv := UI.hbox(10, [UI.label("Your title", "H3")])
		var ob := OptionButton.new()
		ob.add_item("None", 0)
		for i in s.collection.titles.size():
			ob.add_item(s.collection.titles[i], i + 1)
			if s.settings.title == s.collection.titles[i]:
				ob.selected = i + 1
		ob.item_selected.connect(func(i): Game.state.settings.title = "" if i == 0 else Game.state.collection.titles[i - 1])
		tv.add_child(ob)
		_body.add_child(UI.panel("Glass", tv))
