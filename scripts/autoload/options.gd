extends Node
## Game options (audio, display, interface), shared by every save slot and stored in
## user://options.cfg. apply() pushes them to the audio buses, the window and the renderer.

signal options_changed

const PATH := "user://options.cfg"
const RESOLUTIONS := [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1600, 900), Vector2i(1920, 1080),
	Vector2i(2560, 1440), Vector2i(3840, 2160)]
const FPS_CAPS := [30, 60, 90, 120, 144, 165, 240, 0]   # 0 = unlimited
const WINDOW_MODES := ["Windowed", "Borderless fullscreen", "Exclusive fullscreen"]
const UI_SCALES := [0.85, 1.0, 1.15, 1.3]
const WINDOW_KEYS := ["window_mode", "resolution"]   ## only these move or resize the window

var values := {
	"master": 0.8,
	"music": 0.55,
	"sfx": 0.7,
	"sfx_rare": true,     # the kinds of sound effect, each with its own switch (Sfx.GROUPS)
	"sfx_notify": true,
	"sfx_battle": true,
	"sfx_ui": true,
	"mute_unfocused": true,
	"window_mode": 0,
	"resolution": 2,
	"vsync": true,
	"fps_cap": 1,
	"background_fps": 10,
	"ui_scale": 1,
	"reduce_motion": false,
	"damage_numbers": true,
	"screen_shake": true,
	"toasts": true,
	"dev_tools": false,
	"exp_zones_open": true,   # Expeditions page: the island list is shown (or folded to a strip)
	"exp_log_open": true,     # Expeditions page: the log column is shown (or folded to a strip)
	"keybinds": {},           # tab -> keycode, only where the player changed it (0 = no key); see keybind()
}

## The rail's tabs other than the skills, in rail order, with their names. Skills sit after the Sanctum.
const TABS := [["nexus", "Nexus"], ["pods", "Genesis Pods"], ["expeditions", "Expeditions"], ["aetherlog", "Aether-Log"],
	["inventory", "Inventory"], ["market", "Market"], ["eggmarket", "Egg Market"], ["works", "Sanctum Works"]]
## Keys a tab can't take: Esc opens the menu, and modifiers alone aren't keys.
const RESERVED_KEYS := [KEY_ESCAPE, KEY_F11, KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK]

var _focused := true
## Played by the test bridge: a run left behind other windows keeps the full frame rate (it still mutes), so its
## FPS numbers mean something.
var full_fps_in_background := false
var _last_fullscreen := 1   # the fullscreen mode Alt+Enter / F11 goes back to
var save_delay := 0.4   ## seconds of quiet before a change is written (a dragged slider changes every frame)
var _save_timer: Timer
var save_count := 0   ## writes of options.cfg so far (the tests check the debounce with it)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.timeout.connect(save_options)
	add_child(_save_timer)
	load_options()
	apply()
	_apply_window()


func _ensure_buses() -> void:
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			var i := AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, "Master")


func get_value(key: String) -> Variant:
	return values[key]


func set_value(key: String, v: Variant) -> void:
	values[key] = v
	apply()
	if key in WINDOW_KEYS:
		_apply_window(key == "resolution")   # picking a size is a request to leave a maximized window
	_save_timer.start(save_delay)   # restarts on every change: one write once the player lets go
	options_changed.emit()


# ---------------------------------------------------------------- page shortcuts

## Every tab of the rail in order, as [tab, name]: "sanctum", "skill:<id>" for each skill, then the rest.
## A tab is what Main.show_screen takes ("skill:mining" is show_screen("skill", "mining")).
func tab_list() -> Array:
	var out: Array = [["sanctum", "Sanctum"]]
	for sk in Data.skill_list:
		out.append(["skill:" + sk.id, sk.name])
	out.append_array(TABS)
	return out


## The default keys: 1 to 9 for the Sanctum and the other pages in rail order, F1 onwards for the skills
## (skipping F11, which toggles fullscreen).
func default_keybind(tab: String) -> int:
	if tab == "sanctum":
		return KEY_1
	if tab.begins_with("skill:"):
		var i := Data.skill_list.map(func(sk): return "skill:" + sk.id).find(tab)
		var fkeys := [KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F12]
		return fkeys[i] if i >= 0 and i < fkeys.size() else 0
	for i in TABS.size():
		if TABS[i][0] == tab:
			return KEY_2 + i if i < 8 else 0
	return 0


## The key that opens a tab now (0 if none).
func keybind(tab: String) -> int:
	var own: Dictionary = values.keybinds
	return int(own[tab]) if own.has(tab) else default_keybind(tab)


## Gives a tab a key (0 clears it). A key belongs to one tab: whichever tab had it loses it.
func set_keybind(tab: String, code: int) -> void:
	var own: Dictionary = values.keybinds.duplicate()
	if code != 0:
		for pair in tab_list():
			if pair[0] != tab and keybind(pair[0]) == code:
				own[pair[0]] = 0
	own[tab] = code
	values.keybinds = own
	save_options()
	options_changed.emit()


func reset_keybinds() -> void:
	values.keybinds = {}
	save_options()
	options_changed.emit()


## The tab a key opens, or "".
func tab_for_key(code: int) -> String:
	if code == 0:
		return ""
	for pair in tab_list():
		if keybind(pair[0]) == code:
			return pair[0]
	return ""


## A key's name as printed on a keycap: "7", "F1", "Q".
func key_name(code: int) -> String:
	return OS.get_keycode_string(code) if code != 0 else ""


## True while a change waits for the debounce timer to write it.
func save_pending() -> bool:
	return _save_timer != null and not _save_timer.is_stopped()


## Writes a waiting change now (on quit, so it isn't lost with the timer).
func flush() -> void:
	if save_pending():
		_save_timer.stop()
		save_options()


## First run: the largest window that fits the screen with room to spare (1920x1080 at most, the layout's own
## size), and larger text when that window is smaller, since the 1920x1080 layout shrinks with it (to 83% at
## 1600x900, the usual pick on a 1080p screen, and 67% at 1280x720).
func first_run_defaults(screen: Vector2i) -> Dictionary:
	var res := 0
	for i in RESOLUTIONS.size():
		var r: Vector2i = RESOLUTIONS[i]
		if r.x <= 1920 and r.x <= screen.x * 0.9 and r.y <= screen.y * 0.9:
			res = i
	return {"resolution": res, "ui_scale": 2 if RESOLUTIONS[res].y < 1080 else 1}


func load_options() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		if DisplayServer.get_name() != "headless":
			var screen := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen()).size
			values.merge(first_run_defaults(screen), true)
		return
	for k in values:
		if cfg.has_section_key("options", k):
			values[k] = cfg.get_value("options", k)


func save_options() -> void:
	save_count += 1
	var cfg := ConfigFile.new()
	for k in values:
		cfg.set_value("options", k, values[k])
	cfg.save(PATH)


func apply() -> void:
	_apply_audio()
	_apply_display()


func _apply_audio() -> void:
	var master: float = values.master
	if values.mute_unfocused and not _focused:
		master = 0.0
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, master)))
	AudioServer.set_bus_mute(0, master <= 0.001)
	for pair in [["Music", values.music], ["SFX", values.sfx]]:
		var i := AudioServer.get_bus_index(pair[0])
		AudioServer.set_bus_volume_db(i, linear_to_db(maxf(0.0001, float(pair[1]))))
		AudioServer.set_bus_mute(i, float(pair[1]) <= 0.001)


## VSync, the frame-rate cap and the interface scale: safe to apply on any change or focus change, since none
## of them touches the window itself (that would undo a window the player maximized).
func _apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if values.vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = FPS_CAPS[clampi(int(values.fps_cap), 0, FPS_CAPS.size() - 1)] if _focused or full_fps_in_background else int(values.background_fps)
	var tree := get_tree()
	if tree and tree.root:
		tree.root.content_scale_factor = UI_SCALES[clampi(int(values.ui_scale), 0, UI_SCALES.size() - 1)]


## The window mode and size: at start-up and when the player changes one of them, never on other options or on
## alt-tab. A maximized window stays maximized.
func _apply_window(resize_maximized := false) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var mode := int(values.window_mode)
	match mode:
		0:
			var now := DisplayServer.window_get_mode()
			if now == DisplayServer.WINDOW_MODE_MINIMIZED or (now == DisplayServer.WINDOW_MODE_MAXIMIZED and not resize_maximized):
				return   # the player's own maximize (or a minimized window) wins over the size setting
			if now != DisplayServer.WINDOW_MODE_WINDOWED:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var res: Vector2i = RESOLUTIONS[clampi(int(values.resolution), 0, RESOLUTIONS.size() - 1)]
			var screen := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
			res = Vector2i(mini(res.x, screen.size.x), mini(res.y, screen.size.y))
			if DisplayServer.window_get_size() != res:
				DisplayServer.window_set_size(res)
				DisplayServer.window_set_position(screen.position + Vector2i(Vector2(screen.size - res) * 0.5))
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)


## Alt+Enter and F11 switch between a window and fullscreen (the fullscreen kind last used, borderless at first).
func toggle_fullscreen() -> void:
	var mode := int(values.window_mode)
	if mode != 0:
		_last_fullscreen = mode
		set_value("window_mode", 0)
	else:
		set_value("window_mode", _last_fullscreen)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11 or (event.keycode == KEY_ENTER and event.alt_pressed):
			get_viewport().set_input_as_handled()
			toggle_fullscreen()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_focused = false
			apply()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_focused = true
			apply()
		NOTIFICATION_WM_CLOSE_REQUEST, NOTIFICATION_EXIT_TREE:
			flush()   # the window is closing or a Quit button called get_tree().quit()


## Size of the screen the window is on (the fullscreen size).
func screen_size() -> Vector2i:
	if DisplayServer.get_name() == "headless":
		return Vector2i(1920, 1080)
	return DisplayServer.screen_get_size(DisplayServer.window_get_current_screen())


func refresh_rate_text() -> String:
	if DisplayServer.get_name() == "headless":
		return "unknown"
	var hz := DisplayServer.screen_get_refresh_rate()
	return "%d Hz" % roundi(hz) if hz > 0 else "unknown"
