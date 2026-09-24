class_name WorkerBubble
extends Control
## A working creature's portrait with a ring that fills as its current action progresses.
## Empty bubble (cid == "") shows a dashed slot.

var cid := ""
var skill_id := ""
var _portrait: CreaturePortrait
var _ring_color := Palette.AETHER
var _frac := 0.0
var _stalled := false


static func make(c: Dictionary, skill: String, px: float) -> WorkerBubble:
	var w := WorkerBubble.new()
	w.custom_minimum_size = Vector2(px, px)
	w.skill_id = skill
	w.mouse_filter = Control.MOUSE_FILTER_PASS
	if not c.is_empty():
		w.cid = c.id
		w._portrait = CreaturePortrait.of(c, px - 10)
		w._portrait.position = Vector2(5, 5)
		w._portrait.glow_scale = 0.5
		w.add_child(w._portrait)
		w.tooltip_text = "%s · Lv %d" % [Creatures.display_name(c), int(c.level)]
		var t: Variant = Data.skills[skill].type
		w._ring_color = Data.type_color(t) if t != null else Palette.AETHER
	return w


func _process(_d: float) -> void:
	if cid == "" or not is_visible_in_tree():
		return
	var c := GameState.creature(Game.state, cid)
	if c.is_empty():
		return
	var action := Skills.current_action(Game.state, skill_id)
	var cd := Skills.worker_cooldown(c, skill_id, action, _auras(), Skills.speed(Game.state))
	_frac = clampf(float(c.progress) / cd, 0.0, 1.0)
	_stalled = c.get("stalled", false)
	queue_redraw()


## Auras are shared by every bubble; recomputed at most once a frame.
static var _aura_cache: Array = []
static var _aura_frame := -1


static func _auras() -> Array:
	var f := Engine.get_process_frames()
	if f != _aura_frame:
		_aura_frame = f
		_aura_cache = Skills.active_auras(Game.state)
	return _aura_cache


func _draw() -> void:
	var s := size.x
	var c := Vector2(s, s) / 2.0
	var r := s / 2.0 - 2.0
	if cid == "":
		for i in 16:
			var a0 := TAU * i / 16.0
			draw_arc(c, r - 4, a0, a0 + TAU / 32.0, 6, Color(1, 1, 1, 0.22), 2.0, true)
		return
	draw_arc(c, r, 0, TAU, 48, Color(0, 0, 0, 0.35), 4.0, true)
	var col := Palette.DANGER if _stalled else _ring_color
	if _frac > 0.0:
		draw_arc(c, r, -PI / 2, -PI / 2 + TAU * _frac, 48, col, 4.0, true)
