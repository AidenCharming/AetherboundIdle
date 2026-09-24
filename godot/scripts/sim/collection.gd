class_name Collection
extends RefCounted
## The Aether-Log: what the player has discovered, the collection tracks and their milestone rewards.
## state.collection = {species: {id: {forms, rarities, shiny}}, recipes: [hybrid ids], revealed: [special ids],
##                     claimed: {track: [milestone index]}, titles: [], seen: {species id: true}}


## Records a creature the player now owns. Returns events (new species, new recipe, discovery reward).
static func on_owned(s: Dictionary, c: Dictionary) -> Array:
	var events := []
	var col: Dictionary = s.collection
	var sp_id: String = c.species
	var sp: Dictionary = Data.species[sp_id]
	col.seen[sp_id] = true
	if not col.species.has(sp_id):
		col.species[sp_id] = {"forms": [], "rarities": [], "shiny": false}
		var reward: Dictionary = Data.collection.discovery[sp.kind]
		GameState.add_item(s, "aether", float(reward.aether))
		GameState.add_item(s, "gold", float(reward.gold))
		events.append({"type": "discovered", "species": sp_id, "reward": reward})
		if sp.kind != "base" and not (sp_id in col.recipes):
			col.recipes.append(sp_id)
			events.append({"type": "recipe", "species": sp_id})
	var entry: Dictionary = col.species[sp_id]
	var form := Creatures.form_of(c)
	for f in range(1, form + 1):
		if not (f in entry.forms):
			entry.forms.append(f)
	if not (int(c.rarity) in entry.rarities):
		entry.rarities.append(int(c.rarity))
	if c.shiny and not entry.shiny:
		entry.shiny = true
		events.append({"type": "shiny_logged", "species": sp_id})
	return events


static func on_evolved(s: Dictionary, c: Dictionary) -> void:
	var entry: Dictionary = s.collection.species.get(c.species, {})
	if entry.is_empty():
		return
	var form := Creatures.form_of(c)
	for f in range(1, form + 1):
		if not (f in entry.forms):
			entry.forms.append(f)


static func is_owned(s: Dictionary, species_id: String) -> bool:
	return s.collection.species.has(species_id)


static func owned_type(s: Dictionary, type_id: String) -> bool:
	for id in s.collection.species:
		if type_id in Data.species[id].types:
			return true
	return false


# ---------------------------------------------------------------- tracks

static func track(id: String) -> Dictionary:
	for t in Data.collection.tracks:
		if t.id == id:
			return t
	return {}


static func progress(s: Dictionary, track_id: String) -> int:
	var col: Dictionary = s.collection
	match track_id:
		"species":
			return col.species.size()
		"forms":
			var n := 0
			for e in col.species.values():
				n += e.forms.filter(func(f): return int(f) >= 2).size()
			return n
		"recipes":
			return col.recipes.size()
		"rarities":
			var n := 0
			for e in col.species.values():
				n += e.rarities.size()
			return n
		"shinies":
			var n := 0
			for e in col.species.values():
				if e.shiny:
					n += 1
			return n
	return 0


static func total(track_id: String) -> int:
	var n_species := Data.species_list.size()
	match track_id:
		"species":
			return n_species
		"forms":
			return n_species * 2
		"recipes":
			return Data.species_list.filter(func(sp): return sp.kind != "base").size()
		"rarities":
			return n_species * Data.max_rarity()
		"shinies":
			return n_species
	return 0


static func milestone_target(track_id: String, m: Dictionary) -> int:
	return total(track_id) if str(m.at) == "all" else int(m.at)


static func is_claimed(s: Dictionary, track_id: String, index: int) -> bool:
	return index in s.collection.claimed.get(track_id, [])


static func claimable(s: Dictionary) -> Array:
	var out := []
	for t in Data.collection.tracks:
		for i in t.milestones.size():
			if not is_claimed(s, t.id, i) and progress(s, t.id) >= milestone_target(t.id, t.milestones[i]):
				out.append({"track": t.id, "index": i})
	return out


static func claim(s: Dictionary, track_id: String, index: int, rng: RandomNumberGenerator) -> Dictionary:
	var t := track(track_id)
	var m: Dictionary = t.milestones[index]
	if is_claimed(s, track_id, index) or progress(s, track_id) < milestone_target(track_id, m):
		return {}
	var claimed: Array = s.collection.claimed.get(track_id, [])
	claimed.append(index)
	s.collection.claimed[track_id] = claimed
	var r: Dictionary = m.reward
	var result := {"revealed": []}
	if r.has("aether"):
		GameState.add_item(s, "aether", float(r.aether))
	if r.has("gold"):
		GameState.add_item(s, "gold", float(r.gold))
	for id in r.get("items", {}):
		GameState.add_item(s, id, float(r.items[id]))
	if r.has("title") and not (r.title in s.collection.titles):
		s.collection.titles.append(r.title)
	for i in int(r.get("revealRecipe", 0)):
		var hidden := Data.special_list.filter(func(x): return not (x.result in s.collection.recipes) and not (x.result in s.collection.revealed))
		if hidden.is_empty():
			break
		var rec: Dictionary = Rng.pick(rng, hidden)
		s.collection.revealed.append(rec.result)
		result.revealed.append(rec.result)
	return result


## Headline completion: every track's progress over its total, averaged.
static func completion(s: Dictionary) -> float:
	var sum := 0.0
	var n := 0
	for t in Data.collection.tracks:
		sum += float(progress(s, t.id)) / maxf(1.0, float(total(t.id)))
		n += 1
	return sum / maxf(1.0, float(n))
