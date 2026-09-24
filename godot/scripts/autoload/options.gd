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

var values := {
	"master": 0.8,
	"music": 0.55,
	"sfx": 0.7,
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
}

var _focused := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_buses()
	load_options()
	apply()


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
	save_options()
	options_changed.emit()


func load_options() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	for k in values:
		if cfg.has_section_key("options", k):
			values[k] = cfg.get_value("options", k)


func save_options() -> void:
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


func _apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if values.vsync else DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = FPS_CAPS[clampi(int(values.fps_cap), 0, FPS_CAPS.size() - 1)] if _focused else int(values.background_fps)
	var mode := int(values.window_mode)
	match mode:
		0:
			if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var res: Vector2i = RESOLUTIONS[clampi(int(values.resolution), 0, RESOLUTIONS.size() - 1)]
			var screen := DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())
			res = Vector2i(mini(res.x, screen.size.x), mini(res.y, screen.size.y))
			if DisplayServer.window_get_size() != res:
				DisplayServer.window_set_size(res)
				DisplayServer.window_set_position(screen.position + (screen.size - res) / 2)
		1:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		2:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	var tree := get_tree()
	if tree and tree.root:
		tree.root.content_scale_factor = UI_SCALES[clampi(int(values.ui_scale), 0, UI_SCALES.size() - 1)]


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_focused = false
			apply()
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_focused = true
			apply()


func refresh_rate_text() -> String:
	if DisplayServer.get_name() == "headless":
		return "unknown"
	var hz := DisplayServer.screen_get_refresh_rate()
	return "%d Hz" % roundi(hz) if hz > 0 else "unknown"
