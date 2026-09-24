extends Node
## Content database. Loads every JSON file under res://data once and indexes it by id.
## Nothing here changes during play: all mutable state lives in Game.state.

const DATA_DIR := "res://data/"

var tuning: Dictionary = {}
var species: Dictionary = {}        # id -> species
var species_list: Array = []        # in file order (base, hybrids, specials)
var items: Dictionary = {}
var item_list: Array = []
var skills: Dictionary = {}
var skill_list: Array = []
var actions: Dictionary = {}        # skill id -> {action id -> action}
var traits: Dictionary = {}
var pool_traits: Array = []
var abilities: Dictionary = {}
var types: Dictionary = {}
var type_list: Array = []
var rarities: Array = []            # index = tier - 1
var zones: Dictionary = {}
var zone_list: Array = []
var upgrades: Dictionary = {}
var upgrade_list: Array = []
var collection: Dictionary = {}
var default_hybrids: Dictionary = {} # "typeA+typeB" (sorted) -> species id
var special_recipes: Dictionary = {} # "speciesA+speciesB" (sorted) -> recipe
var special_list: Array = []

var _textures: Dictionary = {}


func _init() -> void:
	load_all()


func load_all() -> void:
	tuning = _read("tuning.json")
	species_list = _read("species.json")
	species = _index(species_list)
	item_list = _read("items.json")
	items = _index(item_list)
	skill_list = _read("skills.json")
	skills = _index(skill_list)
	actions.clear()
	for s in skill_list:
		actions[s.id] = _index(s.actions)
	var trait_list: Array = _read("traits.json")
	traits = _index(trait_list)
	pool_traits = trait_list.filter(func(t): return t.kind == "pool")
	abilities = _index(_read("abilities.json"))
	type_list = _read("types.json")
	types = _index(type_list)
	rarities = _read("rarities.json")
	zone_list = _read("zones.json")
	zones = _index(zone_list)
	upgrade_list = _read("upgrades.json")
	upgrades = _index(upgrade_list)
	collection = _read("collection.json")
	var recipes: Dictionary = _read("recipes.json")
	default_hybrids = recipes.defaults
	special_list = recipes.special
	special_recipes.clear()
	for r in special_list:
		special_recipes[pair_key(r.parents[0], r.parents[1])] = r


static func pair_key(a: String, b: String) -> String:
	return a + "+" + b if a < b else b + "+" + a


func _read(file: String) -> Variant:
	var text := FileAccess.get_file_as_string(DATA_DIR + file)
	var parsed: Variant = JSON.parse_string(text)
	assert(parsed != null, "Could not parse " + file)
	return parsed


func _index(list: Array) -> Dictionary:
	var d := {}
	for e in list:
		d[e.id] = e
	return d


# ---------------------------------------------------------------- lookups

func rarity(tier: int) -> Dictionary:
	return rarities[clampi(tier, 1, rarities.size()) - 1]


func max_rarity() -> int:
	return rarities.size()


func type_color(type_id: String) -> Color:
	if types.has(type_id):
		return Color(types[type_id].color)
	return Color("#9aa3b5")


func rarity_color(tier: int) -> Color:
	return Color(rarity(tier).color)


func item_name(id: String) -> String:
	if id == "aether":
		return "Aether"
	if id == "gold":
		return "Gold"
	return items[id].name if items.has(id) else id


func form_name(species_id: String, form: int) -> String:
	var sp: Dictionary = species[species_id]
	return sp.forms[clampi(form, 1, 3) - 1].name


# ---------------------------------------------------------------- textures (cached)

func texture(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		tex = load(path)
	_textures[path] = tex
	return tex


func item_icon(id: String) -> Texture2D:
	if id == "aether" or id == "gold":
		return ui_icon(id)
	return texture("res://assets/icons/items/%s.svg" % id)


func ui_icon(name: String) -> Texture2D:
	return texture("res://assets/icons/ui/%s.svg" % name)


## The approved sprite for a species and form, or null when the species has no art yet (hybrids).
func creature_texture(species_id: String, form: int) -> Texture2D:
	var sp: Dictionary = species.get(species_id, {})
	if sp.is_empty() or sp.get("sprite") == null:
		return null
	return texture("res://assets/creatures/%s-f%d.png" % [sp.sprite, clampi(form, 1, 3)])
