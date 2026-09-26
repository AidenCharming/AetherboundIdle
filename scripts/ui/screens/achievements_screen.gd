class_name AchievementsScreen
extends Control
## Achievements: every badge as a painted tile, filtered by category (Skills, Aetherlings & Nexus, Adventure,
## Breeding, Secret) and by earned or not. Secrets show only a hint until found.

const CATEGORY_NAMES := [["", "All"], ["skills", "Skills"], ["nexus", "Aetherlings & Nexus"], ["adventure", "Adventure"],
	["breeding", "Breeding"], ["secret", "Secret"]]
const SHOW_NAMES := [["all", "All"], ["unlocked", "Earned"], ["locked", "Not yet"]]

static var category := ""
static var shown := "all"

var _grid: HFlowContainer
var _cats: HBoxContainer
var _shows: HBoxContainer
var _summary: Label
var _key := ""
var _tick := 0.0


func _ready() -> void:
	var v := UI.vbox(17)
	var m := UI.margin(v, 31, 12, 31, 24)
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(m)
	var head := UI.hbox(14)
	head.add_child(UI.header("Achievements", "Badges for everything you do, and a few secrets to stumble upon.", Data.ui_icon("achievements")))
	_summary = UI.label("", "H1", Palette.GOLD)
	head.add_child(_summary)
	v.add_child(head)
	_cats = UI.hbox(10)
	v.add_child(_cats)
	for pair in CATEGORY_NAMES:
		var b := UI.button(pair[1], "Chip")
		b.set_meta("category", pair[0])
		b.pressed.connect(func():
			category = pair[0]
			refresh())
		_cats.add_child(b)
	_shows = UI.hbox(8, [UI.label("Show:", "Faint")])
	v.add_child(_shows)
	for pair in SHOW_NAMES:
		var b := UI.button(pair[1], "Chip")
		b.set_meta("show", pair[0])
		b.pressed.connect(func():
			shown = pair[0]
			refresh())
		_shows.add_child(b)
	_grid = UI.flow(14, 14)
	v.add_child(UI.scroll(_grid))
	refresh()


func _exit_tree() -> void:
	if not Game.state.is_empty():
		Game.mark_achievements_seen()


## Progress bars move with play: update them now and then without rebuilding the tiles.
func _process(delta: float) -> void:
	_tick -= delta
	if _tick > 0.0:
		return
	_tick = 1.0
	for tile in _grid.get_children():
		if tile is AchievementTile:
			tile.update_progress()


func refresh() -> void:
	var s := Game.state
	if s.is_empty():
		return
	var earned := Achievements.count_unlocked(s)
	_summary.text = "%d / %d" % [earned, Achievements.count_total()]
	for b in _cats.get_children():
		var cat: String = b.get_meta("category")
		b.theme_type_variation = "ChipOn" if cat == category else "Chip"
		var name_text: String = CATEGORY_NAMES.filter(func(p): return p[0] == cat)[0][1]
		b.text = "%s  %d/%d" % [name_text, Achievements.count_unlocked(s, cat), Achievements.count_total(cat)]
	for b in _shows.get_children():
		if b is Button:
			b.theme_type_variation = "ChipOn" if b.get_meta("show") == shown else "Chip"
	# rebuild only when what is shown changes (a new unlock or another filter), so a click is never lost
	var key := "%s|%s|%d" % [category, shown, earned]
	if key == _key:
		return
	_key = key
	UI.clear(_grid)
	for a in Data.achievement_list:
		if category != "" and a.category != category:
			continue
		var done := Achievements.is_unlocked(s, a.id)
		if (shown == "unlocked" and not done) or (shown == "locked" and done):
			continue
		var tile := AchievementTile.make(a)
		_grid.add_child(tile)
		if done and not s.achievements.seen.has(a.id):
			tile.add_child(_new_dot())


func _new_dot() -> Control:
	var dot := UI.chip("NEW", Palette.GOLD, 12)
	dot.position = Vector2(8, 8)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return dot
