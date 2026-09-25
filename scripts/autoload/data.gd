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
var goals: Array = []
var market: Dictionary = {}
var patch_notes: Array = []        # newest first, shown on the title screen

var _textures: Dictionary = {}
var _opaque: Dictionary = {}


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
	goals = _read("goals.json")
	market = _read("market.json")
	patch_notes = _read("patch_notes.json")
	var recipes: Dictionary = _read("recipes.json")
	default_hybrids = recipes.defaults
	special_list = recipes.special
	special_recipes.clear()
	for r in special_list:
		special_recipes[pair_key(r.parents[0], r.parents[1])] = r


func pair_key(a: String, b: String) -> String:
	return a + "+" + b if a < b else b + "+" + a


func _read(file: String) -> Variant:
	var text := FileAccess.get_file_as_string(DATA_DIR + file)
	# a JSON instance says where a parse failed; push_error still reports it in a release build, where assert is gone
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("Could not parse %s%s, line %d: %s" % [DATA_DIR, file, json.get_error_line(), json.get_error_message()])
		assert(false)
		return null
	return json.data


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


## The rarity colour as it should look right now: the top tiers are animated (`live` in rarities.json).
## Zenith and Aetheric cycle through a rainbow (Aetheric's is faster and richer), Resplendent and Brilliant
## pulse between their colour and a lighter one.
func rarity_color_live(tier: int) -> Color:
	var c := rarity_color(tier)
	var t := Time.get_ticks_msec() / 1000.0
	match str(rarity(tier).get("live", "")):
		"rainbow":
			var rich := int(rarity(tier).fx) >= 6
			return Color.from_hsv(fmod(t * (0.3 if rich else 0.18), 1.0), 0.55 if rich else 0.38, 1.0)
		"pulse":
			return c.lerp(c.lightened(0.45), 0.5 + 0.5 * sin(t * 3.0))
	return c


## Rarity tiers whose colour moves (they need redrawing every frame).
func rarity_animated(tier: int) -> bool:
	return rarity(tier).has("live")


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


## The part of a texture that is not transparent, as a fraction of its size (cached). Used to stand creature
## sprites on the ground no matter how much empty space their art has under the feet.
func opaque_rect(tex: Texture2D) -> Rect2:
	if tex == null:
		return Rect2(0, 0, 1, 1)
	var key := tex.resource_path if tex.resource_path != "" else str(tex.get_instance_id())
	if _opaque.has(key):
		return _opaque[key]
	var r := Rect2(0, 0, 1, 1)
	var img := tex.get_image()
	if img:
		if img.is_compressed():
			img.decompress()
		var used := img.get_used_rect()
		if used.size.x > 0 and used.size.y > 0:
			var sz := Vector2(img.get_width(), img.get_height())
			r = Rect2(Vector2(used.position) / sz, Vector2(used.size) / sz)
	_opaque[key] = r
	return r


## A zone's painted battle backdrop (assets/zones/<id>.jpg or .png), or null to use the drawn one.
func zone_backdrop(zone_id: String) -> Texture2D:
	var jpg := texture("res://assets/zones/%s.jpg" % zone_id)
	return jpg if jpg else texture("res://assets/zones/%s.png" % zone_id)


func item_icon(id: String) -> Texture2D:
	if id == "aether" or id == "gold":
		return ui_icon(id)
	return _icon("res://assets/icons/items/" + id)


func ui_icon(icon_name: String) -> Texture2D:
	return _icon("res://assets/icons/ui/" + icon_name)


## A painted PNG icon (from the art pipeline, tools/art/icon_runner.py) wins over the generated SVG placeholder.
func _icon(base: String) -> Texture2D:
	var png := base + ".png"
	if _textures.has(png) or ResourceLoader.exists(png):
		var tex := texture(png)
		if tex:
			return tex
	return texture(base + ".svg")


## The sprite for a species and form: res://assets/creatures/<id>-f<form>.png (or the file named by the
## species' "sprite" field). Null when there is no art yet, which shows the aether-blob placeholder, so new
## art only needs dropping into the folder.
func creature_texture(species_id: String, form: int) -> Texture2D:
	var sp: Dictionary = species.get(species_id, {})
	if sp.is_empty():
		return null
	var file: String = sp.sprite if sp.get("sprite") != null else species_id
	return texture("res://assets/creatures/%s-f%d.png" % [file, clampi(form, 1, 3)])
