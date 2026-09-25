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
var _modal_seen: Dictionary = {}   # modal instance id -> msec first seen by "modals"


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
			return await _click_button(String(r.get("text", "")), int(r.get("index", 0)), bool(r.get("reveal", true)), String(r.get("cid", "")),
				bool(r.get("exact", false)))
		"goal":
			return {"ok": true, "goal": goal_info()}
		"player":
			return {"ok": true, "player": player_snapshot()}
		"modals":
			return {"ok": true, "modals": modals_info(), "reveal": reveal_info()}
		"focus":
			# play as a player looking at the window: lift the background frame-rate cap (Options)
			Options._focused = true
			Options.apply()
			return {"ok": true, "fps_cap": Engine.max_fps}
		"invariants":
			return {"ok": true, "breaks": invariants()}
		"breed_check":
			return {"ok": true, "results": breed_check(r.get("pairs", []), int(r.get("tier", 1)))}
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
			# report the time-away summary the player is shown (the game screen clears it once shown)
			var got := {}
			var grab := func(summary: Dictionary): got.merge(summary)
			Game.offline_summary.connect(grab)
			Game.dev_fast_forward(float(r.get("hours", 1.0)))
			Game.offline_summary.disconnect(grab)
			await get_tree().process_frame
			var short := {}
			for k in ["elapsed", "usedSeconds", "capped", "aether", "gold", "actions"]:
				if got.has(k):
					short[k] = got[k]
			short.levels = got.get("levels", {}).size()
			short.gained = got.get("gained", {}).size()
			short.events = got.get("events", []).size()
			return {"ok": true, "summary": short}
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
		"window": [get_window().size.x, get_window().size.y], "mode": get_window().mode,
		"focused": Options._focused, "fps_cap": Engine.max_fps, "renderer": RenderingServer.get_video_adapter_name(),
		"frame": Engine.get_frames_drawn(), "movie": "--write-movie" in OS.get_cmdline_args()}
	if Main.instance and is_instance_valid(Main.instance):
		out.screen = Main.instance.current
		out.screen_arg = Main.instance.current_arg
		out.reveal = reveal_info()
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
		var g := goal_info()
		out.goal = {"index": g.index, "id": g.id, "done": g.done}
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
	var top := _top_modal()
	var modal_open := top != null
	var rv := reveal_info()
	if rv.active and not modal_open:
		# a hatch or evolution reveal covers the screen and takes every click: only "continue" is there
		if rv.can_continue:
			var c := get_viewport().get_visible_rect().size / 2.0
			out.append({"text": "Click to continue", "disabled": false, "kind": "Reveal", "x": roundi(c.x), "y": roundi(c.y),
				"w": 200, "h": 40, "path": ""})
		return out
	var roots: Array = [top] if modal_open else [get_tree().root]   # a dialog covers everything under it
	var screen := Rect2(Vector2.ZERO, get_viewport().get_visible_rect().size)
	for root in roots:
		_collect(root, out, screen)
	return out


## The dialog on top (the last one opened that isn't closing), or null.
func _top_modal() -> Node:
	if Modal.layer == null or not is_instance_valid(Modal.layer):
		return null
	for i in range(Modal.layer.get_child_count() - 1, -1, -1):
		var m := Modal.layer.get_child(i)
		if m is Modal and m.is_open():
			return m
	return null


func _collect(n: Node, out: Array, screen: Rect2) -> void:
	if n is CanvasItem and not n.is_visible_in_tree():
		return
	if n is BaseButton:
		var b: BaseButton = n
		var rect := b.get_global_rect()
		if rect.size.x > 1.0 and rect.size.y > 1.0 and screen.intersects(rect) and _clickable(b):
			var entry := {"text": _label_of(b), "disabled": b.disabled, "kind": b.get_class(),
				"x": roundi(rect.get_center().x), "y": roundi(rect.get_center().y), "w": roundi(rect.size.x), "h": roundi(rect.size.y),
				"path": str(b.get_path())}
			if b.tooltip_text != "":
				entry.tip = b.tooltip_text.get_slice("\n", 0)
			if b.get("cid") is String:
				entry.cid = b.get("cid")   # a creature card: click it with {"cid": ...}
			out.append(entry)
	for c in n.get_children():
		_collect(c, out, screen)


## A button inside a scroll area can be clicked only while its centre (where a click lands) is in view.
func _clickable(b: Control) -> bool:
	var p := b.get_parent()
	var at := b.get_global_rect().get_center()
	while p:
		if p is ScrollContainer and not (p as Control).get_global_rect().has_point(at):
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

## Clicks the button whose text matches (exactly first, then its tooltip exactly, then case-insensitively
## containing), the index-th if several match, with a real mouse click at its centre, the same input a
## player's mouse makes. With `cid`, clicks the creature card of that Aetherling instead.
func _click_button(text: String, index: int, reveal := true, cid := "", exact_only := false) -> Dictionary:
	var all := _buttons()
	# an exact match comes first even when it's scrolled out of view: wheel to it rather than click a
	# visible button that merely contains the text ("Sanctum" is not "Sanctum Works")
	var hits := _matching(all, text, cid, true)
	var low := text.to_lower()
	if hits.is_empty() and reveal:
		var exact: Callable = func(btn: BaseButton) -> bool:
			return btn.get("cid") == cid if cid != "" else (_label_of(btn) == text or btn.tooltip_text.get_slice("\n", 0) == text)
		if await _reveal(exact):
			return await _click_button(text, index, false, cid, exact_only)
	if hits.is_empty() and cid == "" and not exact_only:
		hits = _matching(all, text, cid, false)
	if hits.is_empty() and reveal and cid == "" and not exact_only:
		var loose: Callable = func(btn: BaseButton) -> bool:
			return _label_of(btn).to_lower().contains(low) or btn.tooltip_text.to_lower().contains(low)
		if await _reveal(loose):
			return await _click_button(text, index, false, cid)
	if hits.is_empty():
		return _fail("no visible button says \"%s\"" % text if cid == "" else "no visible card for Aetherling %s" % cid)
	if index >= hits.size():
		return _fail("only %d buttons match \"%s\"" % [hits.size(), text])
	var b: Dictionary = hits[index]
	if b.disabled:
		return {"ok": false, "error": "that button is disabled", "button": b}
	await _real_click(Vector2(b.x, b.y), true)
	return {"ok": true, "clicked": b}


## Buttons matching `text`: exactly (its text, then its tooltip), or with `exact` false, containing it.
func _matching(all: Array, text: String, cid: String, exact: bool) -> Array:
	if cid != "":
		return all.filter(func(h): return h.get("cid", "") == cid)
	var low := text.to_lower()
	for pass_n in ([0, 1] if exact else [2, 3]):
		var hits := all.filter(func(h):
			var tip: String = h.get("tip", "")
			match pass_n:
				0:
					return h.text == text
				1:
					return tip == text
				2:
					return low in String(h.text).to_lower()
			return tip != "" and low in tip.to_lower())
		if not hits.is_empty():
			return hits
	return []


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
func _reveal(pred: Callable) -> bool:
	var target: BaseButton = null
	var root: Node = get_tree().root
	if _top_modal() != null:
		root = _top_modal()
	for b in _all_buttons(root):
		if b.is_visible_in_tree() and pred.call(b):
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
		var down := target.get_global_rect().get_center().y > sc.get_global_rect().get_center().y
		await _wheel(at, 1 if down else -1)
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


# ---------------------------------------------------------------- what a scripted player reads (read-only)

## Overseer Vance's active goal: its id, text, check, progress and whether it can be claimed.
func goal_info() -> Dictionary:
	var s := Game.state
	if s.is_empty():
		return {"index": -1, "id": "", "done": false}
	var g := Goals.current(s)
	if g.is_empty():
		return {"index": int(s.goals.index), "total": Data.goals.size(), "id": "", "done": false, "finished": true}
	var p := Goals.progress(s, g)
	return {"index": int(s.goals.index), "total": Data.goals.size(), "id": g.id, "text": g.text, "check": g.check,
		"have": p[0], "need": p[1], "done": Goals.is_done(s, g)}


## Everything a player can see on the screens, in one read: Aetherlings, skills and their tasks, the
## expedition and islands, pods, items, Sanctum Works and the Market's work slots.
func player_snapshot() -> Dictionary:
	var s := Game.state
	if s.is_empty():
		return {}
	var now := Game.now_sec()
	var perched := {}
	for c in Economy.perched(s):
		perched[c.id] = true
	var creatures := []
	for c in s.creatures.values():
		var sp: Dictionary = Data.species[c.species]
		creatures.append({"id": c.id, "species": c.species, "name": Creatures.display_name(c), "kind": sp.kind,
			"types": Creatures.types_of(c), "rarity": int(c.rarity), "level": int(c.level), "shiny": bool(c.shiny),
			"job": Creatures.job_kind(c), "skill": c.job.get("id", "") if Creatures.job_kind(c) == "skill" else "",
			"power": Creatures.power_rating(c), "locked": bool(c.get("locked", false)), "perched": perched.has(c.id)})
	var skills := {}
	for sk in Data.skill_list:
		var st: Dictionary = s.skills[sk.id]
		var actions := []
		for a in sk.actions:
			actions.append({"id": a.id, "name": a.name, "level": int(a.level), "unlocked": int(a.level) <= int(st.level),
				"inputs": a.get("inputs", {}), "output": a.outputs.keys()[0], "can_make": Skills.affordable(s, a) > 0})
		skills[sk.id] = {"name": sk.name, "type": sk.type, "level": int(st.level), "action": st.action,
			"usable": sk.type == null or Collection.owned_type(s, sk.type), "slots": GameState.slot_count(s, sk.id),
			"workers": GameState.workers(s, sk.id).map(func(c): return c.id), "actions": actions,
			"slot_price": Market.next_slot_price(s, sk.id), "slot_error": Market.slot_check(s, sk.id)}
	var zones := []
	for z in Data.zone_list:
		var zs := Expedition.zone_state(s, z.id)
		zones.append({"id": z.id, "name": z.name, "type": z.type, "levels": z.levels, "unlocked": Expedition.zone_unlocked(s, z.id),
			"cleared": bool(zs.cleared), "bestWave": int(zs.bestWave), "waves": int(z.waves)})
	var ex: Dictionary = s.expedition
	var pending_throwable := 0
	for w in ex.pending:
		if Expedition.choose_vessel(s, {"shiny": true, "species": w.species, "rarity": w.rarity}) != "":
			pending_throwable += 1
	var pods := []
	for i in s.pods.size():
		var egg: Dictionary = s.pods[i]
		if egg.is_empty():
			pods.append({"index": i, "empty": true})
		else:
			pods.append({"index": i, "empty": false, "ready": Breeding.is_ready(egg, now), "left": Breeding.remaining(egg, now),
				"speed_up": Breeding.speed_up_cost(egg, now), "species": egg.species})
	var items := {}
	var item_meta := {}   # held items: [name, category, element, sell price]
	for id in s.items:
		if float(s.items[id]) > 0.0:
			items[id] = float(s.items[id])
			if Data.items.has(id):
				var it: Dictionary = Data.items[id]
				item_meta[id] = [it.name, it.category, it.get("element", ""), float(it.get("sell", 0))]
	var upgrades := []
	for u in Data.upgrade_list:
		var nxt := Economy.next_upgrade(s, u.id)
		upgrades.append({"id": u.id, "name": u.name, "level": GameState.upgrade_level(s, u.id), "max": u.levels.size(),
			"affordable": not nxt.is_empty() and GameState.can_afford(s, nxt.cost), "cost": nxt.get("cost", {})})
	var vessels := 0.0
	var meals := 0.0
	for it in Data.item_list:
		if it.category == "vessel":
			vessels += GameState.count(s, it.id)
		elif it.category == "meal":
			meals += GameState.count(s, it.id)
	return {"gold": float(s.gold), "aether": float(s.aether), "vessels": vessels, "meals": meals, "creatures": creatures,
		"skills": skills, "items": items, "item_meta": item_meta, "upgrades": upgrades, "pods": pods, "counters": s.counters,
		"expedition": {"running": bool(ex.running), "zone": ex.zone, "party": ex.party.filter(func(id): return id != ""),
			"party_size": int(Data.tuning.combat.partySize), "pending": ex.pending.size(), "pending_throwable": pending_throwable,
			"autobind": ex.autobind, "zones": zones},
		"species_logged": s.collection.species.size(), "recipes": s.collection.recipes.size(),
		"milestones_to_claim": Collection.claimable(s).size(), "goal": goal_info(),
		"game_seconds": float(s.get("playSeconds", 0.0)) + float(s.get("awaySeconds", 0.0))}


## The dialogs open now, oldest first: title, how long each has been open (since this bridge first saw it)
## and its buttons.
func modals_info() -> Array:
	var out := []
	if Modal.layer == null or not is_instance_valid(Modal.layer):
		return out
	var now := Time.get_ticks_msec()
	var live := {}
	for m in Modal.layer.get_children():
		if not (m is Modal) or not m.is_open():
			continue
		var key := m.get_instance_id()
		live[key] = true
		if not _modal_seen.has(key):
			_modal_seen[key] = now
		var title := ""
		var head: Node = m.body.get_child(0) if m.body and m.body.get_child_count() > 1 else null
		if head is HBoxContainer and head.get_child_count() > 0 and head.get_child(0) is Label:
			title = (head.get_child(0) as Label).text
		var buttons := []
		for b in _all_buttons(m):
			if b.is_visible_in_tree():
				buttons.append(_label_of(b))
		out.append({"title": title, "age": (now - int(_modal_seen[key])) / 1000.0, "buttons": buttons})
	for key in _modal_seen.keys():
		if not live.has(key):
			_modal_seen.erase(key)
	return out


## The hatch or evolution reveal: whether it covers the screen and whether a click would move it on.
func reveal_info() -> Dictionary:
	if Main.instance == null or not is_instance_valid(Main.instance):
		return {"active": false, "can_continue": false}
	var rv: Reveal = Main.instance._reveal
	return {"active": rv.active, "can_continue": rv.active and rv._can_continue, "queued": rv._queue.size()}


## Rules the save must always keep. Returns one line per break (empty when all is well).
func invariants() -> Array:
	var s := Game.state
	var out := []
	if s.is_empty():
		return out
	for k in ["gold", "aether"]:
		var v := float(s[k])
		if is_nan(v) or is_inf(v) or v < -0.000001:
			out.append("%s is %s" % [k, str(v)])
	for id in s.items:
		var v := float(s.items[id])
		if is_nan(v) or is_inf(v) or v < -0.000001:
			out.append("item %s count is %s" % [id, str(v)])
	for sk in Data.skill_list:
		var ws := GameState.workers(s, sk.id)
		var slots := GameState.slot_count(s, sk.id)
		if ws.size() > slots:
			out.append("%s has %d workers in %d slots" % [sk.id, ws.size(), slots])
		var lv := int(s.skills[sk.id].level)
		if lv < 1 or lv > int(Data.tuning.skills.maxLevel) or is_nan(float(s.skills[sk.id].xp)):
			out.append("%s level %d, xp %s" % [sk.id, lv, str(s.skills[sk.id].xp)])
		for c in ws:
			if not Creatures.can_work(c, sk.id):
				out.append("%s (%s) works in %s but can't" % [c.id, c.species, sk.id])
	var party: Array = s.expedition.party.filter(func(id): return id != "")
	var seen := {}
	for id in party:
		if seen.has(id):
			out.append("%s is in the party twice" % id)
		seen[id] = true
		if not s.creatures.has(id):
			out.append("party member %s doesn't exist" % id)
		elif Creatures.job_kind(s.creatures[id]) != "party":
			out.append("party member %s has job %s" % [id, Creatures.job_kind(s.creatures[id])])
	if party.size() > int(Data.tuning.combat.partySize):
		out.append("party of %d" % party.size())
	if bool(s.expedition.running) and party.is_empty():
		out.append("an expedition runs with no party")
	for c in s.creatures.values():
		if Creatures.job_kind(c) == "party" and not seen.has(c.id):
			out.append("%s has a party job but isn't in the party" % c.id)
		if is_nan(float(c.xp)) or int(c.level) < 1 or int(c.level) > int(Data.tuning.creature.maxLevel):
			out.append("%s level %s, xp %s" % [c.id, str(c.level), str(c.xp)])
	if s.pods.size() != GameState.pod_count(s):
		out.append("%d pods, %d built" % [s.pods.size(), GameState.pod_count(s)])
	var gi := int(s.goals.index)
	if gi < 0 or gi > Data.goals.size():
		out.append("goals.index %d" % gi)
	return out


## Whether each pair could lay an egg at `tier`, what it costs and what could hatch (and whether that
## species is new to the Aether-Log).
func breed_check(pairs: Array, tier: int) -> Array:
	var s := Game.state
	var out := []
	if s.is_empty():
		return out
	tier = clampi(tier, 1, Breeding.tier_count())
	for p in pairs:
		if not (p is Array) or p.size() < 2:
			continue
		var a := GameState.creature(s, str(p[0]))
		var b := GameState.creature(s, str(p[1]))
		if a.is_empty() or b.is_empty():
			out.append({"a": p[0], "b": p[1], "tier": tier, "error": "no such Aetherling"})
			continue
		var offspring := Breeding.preview(s, a, b).map(func(o): return {"species": o.species, "chance": o.chance, "special": o.special,
			"hybrid": Data.species[o.species].kind != "base", "new": not s.collection.species.has(o.species)})
		out.append({"a": a.id, "b": b.id, "tier": tier, "error": Breeding.check(s, a, b, tier), "cost": Breeding.cost(a, b, tier),
			"offspring": offspring})
	return out
