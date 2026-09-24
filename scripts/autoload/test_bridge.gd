extends Node
## Test bridge: lets a script (tools/bridge.py, or a local Claude session) drive the running game for bug
## testing. Off unless the game is started with `-- --bridge` on a debug build (the editor or a debug export);
## a release export never opens it. It listens on 127.0.0.1 only (port 47625, or `--bridge-port=N`).
##
## Protocol: one JSON object per line, {"cmd": "...", ...args}; one JSON line back, {"ok": true, ...} or
## {"ok": false, "error": "..."}. See docs/TEST_BRIDGE.md for every command.

const DEFAULT_PORT := 47625
const SLOT := 2                      ## the bridge plays in save slot 2 unless told otherwise (designer's choice)
const SLOT_NAME := "Autoplay Slot"
const MAX_ERRORS := 400

var enabled := false
var _server: TCPServer
var _peers: Array = []   # [{peer, buf}]
var _errors: Array = []  # [{time, text}], newest last
var _error_total := 0
var _mutex := Mutex.new()
var _logger: BridgeLogger


## Collects engine and script errors (any thread) so `errors` can report them.
class BridgeLogger extends Logger:
	var bridge: Node

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool,
			error_type: int, script_backtraces: Array[ScriptBacktrace]) -> void:
		var kind: String = ["error", "warning", "script error", "shader error"][clampi(error_type, 0, 3)]
		var text := "%s: %s (%s:%d in %s)" % [kind, rationale if rationale != "" else code, file, line, function]
		for bt in script_backtraces:
			if bt and not bt.is_empty():
				text += "\n" + bt.format(2, 4)
				break
		bridge._add_error(text)

	func _log_message(message: String, error: bool) -> void:
		if error:
			bridge._add_error(message.strip_edges())


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	enabled = OS.is_debug_build() and "--bridge" in args
	if not enabled:
		set_process(false)
		return
	var port := DEFAULT_PORT
	for a in args:
		if a.begins_with("--bridge-port="):
			port = int(a.get_slice("=", 1))
	_logger = BridgeLogger.new()
	_logger.bridge = self
	OS.add_logger(_logger)
	_server = TCPServer.new()
	var err := _server.listen(port, "127.0.0.1")
	if err != OK:
		push_warning("Test bridge: could not listen on port %d (%s)" % [port, error_string(err)])
		set_process(false)
		return
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("Test bridge listening on 127.0.0.1:%d" % port)


func _add_error(text: String) -> void:
	_mutex.lock()
	_error_total += 1
	_errors.append({"time": Time.get_unix_time_from_system(), "n": _error_total, "text": text})
	if _errors.size() > MAX_ERRORS:
		_errors.pop_front()
	_mutex.unlock()


func _process(_delta: float) -> void:
	while _server.is_connection_available():
		var p := _server.take_connection()
		p.set_no_delay(true)
		_peers.append({"peer": p, "buf": ""})
	for entry in _peers.duplicate():
		var p: StreamPeerTCP = entry.peer
		p.poll()
		if p.get_status() != StreamPeerTCP.STATUS_CONNECTED:
			_peers.erase(entry)
			continue
		var n := p.get_available_bytes()
		if n > 0:
			entry.buf += p.get_utf8_string(n)
		while "\n" in entry.buf:
			var line: String = entry.buf.get_slice("\n", 0)
			entry.buf = entry.buf.substr(line.length() + 1)
			if line.strip_edges() != "":
				_run(p, line)


func _run(p: StreamPeerTCP, line: String) -> void:
	var req: Variant = JSON.parse_string(line)
	var res: Dictionary
	if not (req is Dictionary) or not req.has("cmd"):
		res = {"ok": false, "error": "send one JSON object per line with a \"cmd\""}
	else:
		res = await _handle(req)
	if p.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		p.put_data((JSON.stringify(res) + "\n").to_utf8_buffer())


func _fail(msg: String) -> Dictionary:
	return {"ok": false, "error": msg}


func _handle(r: Dictionary) -> Dictionary:
	match String(r.cmd):
		"ping":
			return {"ok": true, "pong": true, "scene": _scene_name()}
		"state":
			return _state()
		"get":
			return _get_path(String(r.get("path", "")))
		"errors":
			return _errors_since(int(r.get("since", 0)))
		"buttons":
			return {"ok": true, "buttons": _buttons()}
		"click":
			return await _click_button(String(r.get("text", "")), int(r.get("index", 0)), bool(r.get("reveal", true)))
		"scroll":
			await _wheel(Vector2(float(r.get("x", 800)), float(r.get("y", 450))), int(r.get("steps", 3)))
			return {"ok": true}
		"click_at":
			# canvas: x, y in the game's 1600x900 layout (as "buttons" reports them); otherwise window pixels
			await _real_click(Vector2(float(r.get("x", 0)), float(r.get("y", 0))), bool(r.get("canvas", false)))
			return {"ok": true}
		"key":
			return await _key(String(r.get("key", "")))
		"screenshot":
			return await _screenshot(String(r.get("path", "")))
		"go":
			if Main.instance == null:
				return _fail("not in a game: use \"new\" or \"load\" first")
			Main.go(String(r.get("screen", "sanctum")), String(r.get("arg", "")))
			await get_tree().process_frame
			return {"ok": true, "screen": Main.instance.current}
		"new", "load":
			return await _start(int(r.get("slot", SLOT)), String(r.cmd) == "new")
		"title":
			Game.leave()
			get_tree().change_scene_to_file("res://scenes/title.tscn")
			await get_tree().create_timer(0.5).timeout
			return {"ok": true}
		"skip":
			if not Game.running:
				return _fail("not in a game")
			Game.dev_fast_forward(float(r.get("hours", 1.0)))
			await get_tree().process_frame
			return {"ok": true}
		"game":
			return _call_game(String(r.get("method", "")), r.get("args", []))
		"eval":
			return _eval(String(r.get("expr", "")))
		"wait":
			await get_tree().create_timer(clampf(float(r.get("seconds", 1.0)), 0.0, 600.0)).timeout
			return {"ok": true}
		"quit":
			get_tree().quit.call_deferred()
			return {"ok": true}
	return _fail("unknown command \"%s\" (see docs/TEST_BRIDGE.md)" % r.cmd)


# ---------------------------------------------------------------- reading the game

func _scene_name() -> String:
	var sc := get_tree().current_scene
	return sc.scene_file_path.get_file().get_basename() if sc else ""


func _state() -> Dictionary:
	var out := {"ok": true, "scene": _scene_name(), "fps": Engine.get_frames_per_second(),
		"memory_mb": snappedf(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0, 0.1),
		"errors": _error_total, "modals": Modal.layer.get_child_count() if Modal.layer and is_instance_valid(Modal.layer) else 0,
		"window": [get_window().size.x, get_window().size.y], "mode": get_window().mode}
	if Main.instance and is_instance_valid(Main.instance):
		out.screen = Main.instance.current
		out.screen_arg = Main.instance.current_arg
	var s := Game.state
	if not s.is_empty():
		out.slot = Game.slot
		out.gold = float(s.gold)
		out.aether = float(s.aether)
		out.creatures = s.creatures.size()
		var skills := {}
		for id in s.skills:
			skills[id] = {"level": int(s.skills[id].level), "workers": GameState.workers(s, id).size(), "slots": GameState.slot_count(s, id)}
		out.skills = skills
		var ex: Dictionary = s.expedition
		out.expedition = {"running": bool(ex.running), "zone": ex.zone, "pending": ex.pending.size(),
			"wave": int(ex.battle.get("wave", 0)) if ex.battle is Dictionary else 0}
		out.pods = s.pods.map(func(p): return {} if p.is_empty() else {"species": p.species, "readyIn": maxf(0.0, float(p.readyAt) - Game.now_sec())})
		out.boosts = s.get("market", {}).get("boosts", {})
	return out


## A value from the save by dotted path: "gold", "skills.mining.level", "expedition.party".
func _get_path(path: String) -> Dictionary:
	var v: Variant = Game.state
	if path != "":
		for key in path.split("."):
			if v is Dictionary and v.has(key):
				v = v[key]
			elif v is Array and key.is_valid_int() and int(key) < v.size():
				v = v[int(key)]
			else:
				return _fail("no \"%s\" in the save" % path)
	return {"ok": true, "value": v}


func _errors_since(since: int) -> Dictionary:
	_mutex.lock()
	var list := _errors.filter(func(e): return int(e.n) > since)
	var total := _error_total
	_mutex.unlock()
	return {"ok": true, "total": total, "errors": list}


## Every button a player could click right now: visible, on screen, not hidden behind an open dialog.
func _buttons() -> Array:
	var out := []
	var modal_open: bool = Modal.layer != null and is_instance_valid(Modal.layer) and Modal.layer.get_child_count() > 0
	var roots: Array = [Modal.layer] if modal_open else [get_tree().root]
	var screen := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	for root in roots:
		_collect(root, out, screen)
	return out


func _collect(n: Node, out: Array, screen: Rect2) -> void:
	if n is CanvasItem and not n.is_visible_in_tree():
		return
	if n is BaseButton:
		var b: BaseButton = n
		var rect := b.get_global_rect()
		if rect.size.x > 1.0 and rect.size.y > 1.0 and screen.intersects(rect) and _clickable(b):
			out.append({"text": _label_of(b), "disabled": b.disabled, "kind": b.get_class(),
				"x": roundi(rect.get_center().x), "y": roundi(rect.get_center().y), "w": roundi(rect.size.x), "h": roundi(rect.size.y),
				"path": str(b.get_path())})
	for c in n.get_children():
		_collect(c, out, screen)


## A button inside a scroll area that has scrolled out of view can't be clicked.
func _clickable(b: Control) -> bool:
	var p := b.get_parent()
	var rect := b.get_global_rect()
	while p:
		if p is ScrollContainer and not (p as Control).get_global_rect().intersects(rect):
			return false
		p = p.get_parent()
	return true


## What a button says: its own text, else the first label inside it, else its tooltip.
func _label_of(b: BaseButton) -> String:
	if b is Button and (b as Button).text.strip_edges() != "":
		return (b as Button).text.strip_edges()
	var l := _first_label(b)
	if l != "":
		return l
	return b.tooltip_text


func _first_label(n: Node) -> String:
	for c in n.get_children():
		if c is Label and (c as Label).text.strip_edges() != "":
			return (c as Label).text.strip_edges()
		var inner := _first_label(c)
		if inner != "":
			return inner
	return ""


# ---------------------------------------------------------------- acting on the game

## Clicks the button whose text matches (exactly first, then case-insensitively containing), the index-th
## if several match, with a real mouse click at its centre, the same input a player's mouse makes.
func _click_button(text: String, index: int, reveal := true) -> Dictionary:
	var all := _buttons()
	var hits := all.filter(func(h): return h.text == text)
	if hits.is_empty():
		hits = all.filter(func(h): return text.to_lower() in String(h.text).to_lower())
	if hits.is_empty() and reveal and await _reveal(text):
		return await _click_button(text, index, false)
	if hits.is_empty():
		return _fail("no visible button says \"%s\"" % text)
	if index >= hits.size():
		return _fail("only %d buttons match \"%s\"" % [hits.size(), text])
	var b: Dictionary = hits[index]
	if b.disabled:
		return {"ok": false, "error": "that button is disabled", "button": b}
	await _real_click(Vector2(b.x, b.y), true)
	return {"ok": true, "clicked": b}


## Moves the mouse there, presses and releases the left button a frame apart, then waits a frame.
func _real_click(pos: Vector2, canvas_coords: bool) -> void:
	var at := get_viewport().get_screen_transform() * pos if canvas_coords else pos
	var move := InputEventMouseMotion.new()
	move.position = at
	move.global_position = at
	Input.parse_input_event(move)
	await get_tree().process_frame
	for pressed in [true, false]:
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		e.position = at
		e.global_position = at
		Input.parse_input_event(e)
		await get_tree().process_frame
	await get_tree().process_frame


## A button that exists but sits scrolled out of view: wheel its scroll area (as a player would) until it shows.
func _reveal(text: String) -> bool:
	var target: BaseButton = null
	for b in _all_buttons(get_tree().root):
		if _label_of(b).to_lower().contains(text.to_lower()) and b.is_visible_in_tree():
			target = b
			break
	if target == null:
		return false
	var sc: ScrollContainer = null
	var p := target.get_parent()
	while p and sc == null:
		if p is ScrollContainer:
			sc = p
		p = p.get_parent()
	if sc == null:
		return false
	var at := sc.get_global_rect().get_center()
	for i in 40:
		if _clickable(target):
			return true
		var down := target.get_global_rect().position.y > sc.get_global_rect().position.y
		await _wheel(at, 2 if down else -2)
	return _clickable(target)


func _all_buttons(n: Node, out: Array = []) -> Array:
	if n is BaseButton:
		out.append(n)
	for c in n.get_children():
		_all_buttons(c, out)
	return out


## Real mouse-wheel turns at a point in the game's layout: positive steps scroll down.
func _wheel(pos: Vector2, steps: int) -> void:
	var at := get_viewport().get_screen_transform() * pos
	for i in absi(steps):
		for pressed in [true, false]:
			var e := InputEventMouseButton.new()
			e.button_index = MOUSE_BUTTON_WHEEL_DOWN if steps > 0 else MOUSE_BUTTON_WHEEL_UP
			e.pressed = pressed
			e.factor = 1.0
			e.position = at
			e.global_position = at
			Input.parse_input_event(e)
		await get_tree().process_frame
	await get_tree().process_frame


func _key(key_name: String) -> Dictionary:
	var code := OS.find_keycode_from_string(key_name)
	if code == KEY_NONE:
		return _fail("unknown key \"%s\" (try Escape, Enter, 1, F11)" % key_name)
	for pressed in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = pressed
		Input.parse_input_event(e)
		await get_tree().process_frame
	return {"ok": true}


func _screenshot(path: String) -> Dictionary:
	await RenderingServer.frame_post_draw
	if path == "":
		DirAccess.make_dir_recursive_absolute("user://bridge")
		path = "user://bridge/shot_%d.png" % Time.get_ticks_msec()
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	if err != OK:
		return _fail("could not save %s (%s)" % [path, error_string(err)])
	return {"ok": true, "path": ProjectSettings.globalize_path(path), "size": [img.get_width(), img.get_height()]}


## Starts a slot fresh ("new") or from its save ("load") and opens the game screen. The slot is named
## "Autoplay Slot" so it's easy to tell apart on the title screen.
func _start(slot: int, fresh: bool) -> Dictionary:
	if Game.running:
		Game.leave()
	Game.start_slot(slot, fresh)
	Game.rename_slot(slot, SLOT_NAME)
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	await get_tree().create_timer(0.6).timeout
	return {"ok": true, "slot": slot, "fresh": fresh}


func _call_game(method: String, args: Variant) -> Dictionary:
	if method == "" or not Game.has_method(method):
		return _fail("Game has no method \"%s\"" % method)
	var v: Variant = Game.callv(method, args if args is Array else [args])
	return {"ok": true, "value": v if typeof(v) in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_DICTIONARY, TYPE_ARRAY] else str(v)}


## Evaluates a GDScript expression with Game, Data, the save (S) and the game screen (M) to hand, e.g.
## "S.gold", "Game.dev_add('gold', 5000)", "M.current".
func _eval(expr: String) -> Dictionary:
	var e := Expression.new()
	var err := e.parse(expr, ["Game", "Data", "S", "M"])
	if err != OK:
		return _fail(e.get_error_text())
	var v: Variant = e.execute([Game, Data, Game.state, Main.instance], self)
	if e.has_execute_failed():
		return _fail(e.get_error_text())
	return {"ok": true, "value": v if typeof(v) in [TYPE_NIL, TYPE_BOOL, TYPE_INT, TYPE_FLOAT, TYPE_STRING, TYPE_DICTIONARY, TYPE_ARRAY] else str(v)}
