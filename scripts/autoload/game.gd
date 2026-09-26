extends Node
## Owns the live game: the state Dictionary, the random generator, the frame loop, saving and every
## player action. Screens read `Game.state` and call the action methods here; they never change the
## state themselves. The rules live in scripts/sim/.

signal event(e: Dictionary)                 ## every sim event, for animations
signal toast(text: String, icon: Texture2D, color: Color)
signal changed                              ## something structural changed (jobs, creatures, pods...)
signal offline_summary(summary: Dictionary)
signal reveal_requested(kind: String, data: Dictionary)  ## hatch or evolution reveal
signal notifications_changed

const SLOTS := 3
const ACHIEVEMENT_TOASTS := 3   ## more unlocks than this at once make one summary toast

var slot := 0   ## 1..SLOTS while playing, 0 on the title screen

var state: Dictionary = {}
var rng := RandomNumberGenerator.new()
var running := false
var notifications: Array = []   ## [{text, icon, time}] newest first, not saved
var last_offline_summary: Dictionary = {}  ## kept until the game screen shows it
var battle_log: Array = []   ## recent expedition lines [{text, color}], newest first, not saved
var unread := 0

var _last_tick := 0.0
var _autosave_left := 0.0
var _night_owl_left := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func slot_path(n: int) -> String:
	return "user://slot_%d.json" % n


func backup_path(n: int) -> String:
	return "user://slot_%d.bak.json" % n


func tmp_path(n: int) -> String:
	return "user://slot_%d.tmp.json" % n


## The save as it was when this session started. Autosaves never touch it, so a bad restore or a bug that
## corrupts the state can still be undone after the rolling .bak has been overwritten.
func session_path(n: int) -> String:
	return "user://slot_%d.session.json" % n


## The session copy before this one: if a bug saved a bad state and the game was restarted, the newer session
## copy holds the bad state too, and this one is still a launch older.
func session_prev_path(n: int) -> String:
	return "user://slot_%d.session.prev.json" % n


## The game as it was just before an import replaced it.
func pre_import_path(n: int) -> String:
	return "user://slot_%d.pre-import.json" % n


## Where a slot's save can be, in the order to try them. A .tmp only survives when a crash hit between
## removing the main file and renaming .tmp into place, and then it is the newest good save.
func _slot_paths(n: int) -> Array:
	return [slot_path(n), tmp_path(n), backup_path(n), session_path(n), session_prev_path(n)]


## Starts playing a save slot: loads it, or begins a new game there when it is empty or `fresh` is set.
## Applies offline progress and starts the clock.
func start_slot(n: int, fresh := false) -> void:
	slot = n
	last_offline_summary = {}
	battle_log.clear()
	notifications.clear()
	unread = 0
	_main_ok.erase(n)
	if fresh or not load_game():
		new_game()
	elif _readable(slot_path(n)):
		if _readable(session_path(n)):
			DirAccess.copy_absolute(ProjectSettings.globalize_path(session_path(n)), ProjectSettings.globalize_path(session_prev_path(n)))
		DirAccess.copy_absolute(ProjectSettings.globalize_path(slot_path(n)), ProjectSettings.globalize_path(session_path(n)))
	if loaded_from in [session_path(n), session_prev_path(n)]:
		# the main save and its backup could not be read: say that progress since then is gone
		var which := "the start of your last session" if loaded_from == session_path(n) else "the start of the session before last"
		_notify("Your save could not be read, so it was loaded from %s. Progress since then is lost." % which, Data.ui_icon("bell"), Palette.GOLD)
	var now := now_sec()
	var away := now - float(state.lastSeen)
	_last_tick = now
	running = true
	set_process(true)
	if away > float(Data.tuning.offline.awayThresholdSec):
		_apply_offline(away)
	_claim_pending_secrets()
	var quiet := int(state.achievements.get("quiet", 0))
	if quiet > 0:
		state.achievements.quiet = 0
		_notify("%d achievement%s unlocked from your past progress" % [quiet, "" if quiet == 1 else "s"], Data.ui_icon("achievements"), Palette.GOLD)
	changed.emit()


func now_sec() -> float:
	return Time.get_unix_time_from_system()


func new_game() -> void:
	rng.randomize()
	state = GameState.new_game(0)
	_store_rng()
	notifications.clear()
	save_game()


# ---------------------------------------------------------------- the clock

func _process(_delta: float) -> void:
	if not running:
		return
	var now := now_sec()
	var dt := now - _last_tick
	_last_tick = now
	if dt <= 0.0:
		return
	if dt > float(Data.tuning.offline.awayThresholdSec):
		# the window was asleep or suspended: treat the gap as time away
		_apply_offline(dt)
	else:
		var t0 := Perf.begin()
		var events := Sim.step(state, dt, rng)
		var t1 := Perf.begin()
		_handle(events)
		Perf.end("game.events", t1)
		Perf.end("game.tick", t0)
	state.lastSeen = now
	_night_owl_left -= dt
	if _night_owl_left <= 0.0:
		_night_owl_left = 60.0
		if Time.get_datetime_dict_from_system().hour == 3:
			note_secret("night_owl")
	_autosave_left -= dt
	if _autosave_left <= 0.0:
		_autosave_left = float(Data.tuning.save.autosaveSec)
		save_game()


func _apply_offline(seconds: float) -> void:
	var t0 := Perf.begin()
	var summary := Offline.apply(state, seconds, rng)
	Perf.end("game.offline", t0)
	state.lastSeen = now_sec()
	last_offline_summary = summary
	var shown := 0
	for e in summary.events:
		if e.type == "evolved" and shown < 5:
			reveal_requested.emit("evolve", e)
			shown += 1
	offline_summary.emit(summary)
	_handle(Achievements.check(state))
	changed.emit()
	save_game()


func _log_battle(e: Dictionary) -> void:
	var line := ""
	var col := Palette.TEXT_DIM
	var icon: Texture2D = null
	match e.type:
		"captured":
			line = "Bound a %s %s%s%s%s" % [Data.rarity(e.rarity).name, Data.species[e.species].name, " (shiny!)" if e.shiny else "",
				" · first of its type, free" if e.how == "guaranteed" else "", _chance_note(e)]
			col = Palette.GOLD if e.shiny else Data.rarity_color(e.rarity)
		"escaped":
			line = "A %s %s broke free%s%s" % [Data.rarity(e.rarity).name, Data.species[e.species].name, " of a " + Data.item_name(e.vessel) if e.has("vessel") else "", _chance_note(e)]
			col = Palette.TEXT_FAINT
			icon = Data.item_icon(e.vessel) if e.has("vessel") else Data.ui_icon("vessel")
		"boss_defeated":
			line = "%s defeated! +%d gold" % [Data.zones[e.zone].boss.name, int(e.loot.gold)]
			col = Palette.GOLD
			icon = Data.ui_icon("gold")
		"wiped":
			line = "The party was overwhelmed on wave %d and is resting" % int(e.wave)
			col = Palette.DANGER
			icon = Data.ui_icon("health")
		"run_complete":
			line = "Run complete. Setting out again…"
			col = Palette.AETHER
			icon = Data.ui_icon("expeditions")
		"ate":
			line = "The party ate %s" % Data.item_name(e.item)
			icon = Data.item_icon(e.item)
		"pending":
			line = "A shiny %s is waiting: no vessel left to bind it" % Data.species[e.species].name
			col = Palette.GOLD
			icon = Data.ui_icon("shiny")
		"boss_wave":
			line = "The boss appears!"
			col = Palette.GOLD
			icon = Data.ui_icon("power")
		"pearl":
			line = "+%d Aether Pearl (%s)" % [int(e.amount), e.why]
			col = Color("f1e6ff")
			icon = Data.item_icon("aether-pearl")
	if line != "":
		var entry := {"text": line, "color": col, "time": now_sec(), "icon": icon}
		if e.type == "captured":
			entry.species = e.species
			entry.rarity = int(e.rarity)
			entry.shiny = bool(e.shiny)
		battle_log.push_front(entry)
		if battle_log.size() > 60:
			battle_log.resize(60)


## " · 41% chance" for a bind or an escape that was rolled, so the log shows the odds it had.
static func _chance_note(e: Dictionary) -> String:
	return " · %s chance" % F.pct(float(e.chance)) if e.has("chance") else ""


func _handle(events: Array) -> void:
	var structural := false
	var unlocked := events.filter(func(e): return e.type == "achievement")
	if unlocked.size() > ACHIEVEMENT_TOASTS:
		_notify("%d achievements unlocked!" % unlocked.size(), Data.ui_icon("achievements"), Palette.GOLD)
		Sfx.play("achievement")
	for e in events:
		event.emit(e)
		_log_battle(e)
		match e.type:
			"pearl":
				_notify("+%d Aether Pearl · %s" % [int(e.amount), e.why], Data.item_icon("aether-pearl"), Color("f1e6ff"))
				Sfx.play("rare")
			"skill_level":
				_notify("%s reached level %d" % [Data.skills[e.skill].name, e.level], Data.ui_icon(e.skill), Palette.GOLD)
				Sfx.play("level")
			"slot_unlocked":
				_notify("A new %s work slot opened" % Data.skills[e.skill].name, Data.ui_icon(e.skill), Palette.AETHER)
				structural = true
			"action_unlocked":
				var a: Dictionary = Data.actions[e.skill][e.action]
				_notify("Unlocked: %s" % a.name, Data.item_icon(a.outputs.keys()[0]), Palette.AETHER)
			"evolved":
				_notify("%s evolved into %s!" % [Data.form_name(e.species, e.from), Data.form_name(e.species, e.form)], Data.ui_icon("shiny"), Palette.GOLD)
				reveal_requested.emit("evolve", e)
				structural = true
			"discovered":
				var sp: Dictionary = Data.species[e.species]
				_notify("New in the Aether-Log: %s  (+%d Aether)" % [sp.name, int(e.reward.aether)], Data.ui_icon("aetherlog"), Palette.AETHER)
			"rarity_logged":
				_notify("New in the Aether-Log: %s %s  (+%d Aether)" % [Data.rarity(e.rarity).name, Data.species[e.species].name, int(e.aether)],
					Data.ui_icon("aetherlog"), Data.rarity_color(e.rarity))
			"captured":
				_notify("Bound %s %s%s" % [Data.rarity(e.rarity).name, Data.species[e.species].name, "  (shiny!)" if e.shiny else ""],
					Data.ui_icon("vessel"), Data.rarity_color(e.rarity))
				Sfx.play("capture")
				structural = true
			"rare_drop":
				_notify("Rare find: %d× %s" % [e.qty, Data.item_name(e.item)], Data.item_icon(e.item), Palette.GOLD)
				Sfx.play("rare")
			"boss_defeated":
				_notify("%s defeated!" % Data.zones[e.zone].boss.name, Data.ui_icon("expeditions"), Palette.GOLD)
				Sfx.play("level")
			"zone_unlocked":
				_notify("New island unlocked: %s" % Data.zones[e.zone].name, Data.ui_icon("expeditions"), Palette.AETHER)
			"shiny_spotted":
				_notify("A shiny %s appeared!" % Data.species[e.species].name, Data.ui_icon("shiny"), Palette.GOLD)
				Sfx.play("rare")
			"pending":
				_notify("A shiny %s is waiting to be bound (Expeditions)" % Data.species[e.species].name, Data.ui_icon("shiny"), Palette.GOLD)
			"wiped":
				structural = true
			"achievement":
				if unlocked.size() <= ACHIEVEMENT_TOASTS:
					var a: Dictionary = Data.achievements[e.id]
					_notify("Achievement: %s" % a.name, Data.achievement_icon(a), Palette.GOLD)
					Sfx.play("achievement")
				structural = true
	if structural:
		changed.emit()


func _notify(text: String, icon: Texture2D, color: Color) -> void:
	notifications.push_front({"text": text, "icon": icon, "time": now_sec()})
	if notifications.size() > 60:
		notifications.resize(60)
	unread += 1
	toast.emit(text, icon, color)
	notifications_changed.emit()


# ---------------------------------------------------------------- secrets

## A secret interaction (see Achievements.poke). On the title screen, with no save loaded, it waits in Options
## until a slot starts. Returns true when it unlocked something.
func note_secret(secret_id: String, n := 1) -> bool:
	if not running or state.is_empty():
		var pending: Dictionary = Options.get_value("secrets_pending").duplicate()
		pending[secret_id] = int(pending.get(secret_id, 0)) + n
		Options.set_value("secrets_pending", pending)
		return false
	Achievements.poke(state, secret_id, n)
	var events := Achievements.check(state)
	_handle(events)
	return not events.is_empty()


func _claim_pending_secrets() -> void:
	var pending: Dictionary = Options.get_value("secrets_pending")
	if pending.is_empty():
		return
	for id in pending:
		Achievements.poke(state, id, int(pending[id]))
	Options.set_value("secrets_pending", {})
	_handle(Achievements.check(state))


## Marks every unlocked achievement as looked at (the Achievements page calls this when it closes).
func mark_achievements_seen() -> void:
	for id in state.achievements.unlocked:
		state.achievements.seen[id] = true
	changed.emit()


func info(text: String, icon: Texture2D = null) -> void:
	toast.emit(text, icon, Palette.TEXT_DIM)


func warn(text: String) -> void:
	toast.emit(text, Data.ui_icon("lock"), Palette.DANGER)
	Sfx.play("error")


# ---------------------------------------------------------------- saving

func save_game() -> void:
	if state.is_empty():
		return
	_store_rng()
	state.lastSeen = now_sec()
	var t0 := Perf.begin()
	var text := JSON.stringify(state)
	Perf.end("save.stringify", t0)
	if slot <= 0:
		return
	var t1 := Perf.begin()
	_write_slot(slot, text)
	Perf.end("save.write", t1)


## Writes a save without ever leaving a half-written main file: the text goes to .tmp first, the old main
## file becomes the backup only if it is a readable save, then .tmp is renamed into place.
func _write_slot(n: int, text: String) -> bool:
	var main := ProjectSettings.globalize_path(slot_path(n))
	var tmp := ProjectSettings.globalize_path(tmp_path(n))
	var f := FileAccess.open(tmp_path(n), FileAccess.WRITE)
	if f == null:
		push_error("Could not write %s (%s)" % [tmp_path(n), error_string(FileAccess.get_open_error())])
		return false
	f.store_string(text)
	f.close()
	if FileAccess.file_exists(slot_path(n)) and (_main_ok.get(n, -1) == _file_size(slot_path(n)) or _readable(slot_path(n))):
		DirAccess.copy_absolute(main, ProjectSettings.globalize_path(backup_path(n)))
	if FileAccess.file_exists(slot_path(n)):
		DirAccess.remove_absolute(main)   # Windows can't rename over an existing file
	var done := DirAccess.rename_absolute(tmp, main) == OK
	# we just wrote it, so the next save can trust it without parsing it again, as long as its size is unchanged
	_main_ok[n] = text.to_utf8_buffer().size() if done else -1
	return done


func _file_size(path: String) -> int:
	var f := FileAccess.open(path, FileAccess.READ)
	return f.get_length() if f else -2


## The byte size of each slot's main file as this session last wrote it, so it is known to be a readable save.
var _main_ok := {}


func _readable(path: String) -> bool:
	var parsed: Variant = _parse_file(path)
	return parsed is Dictionary and parsed.has("version")


## The parsed contents of a save file, or null when it is missing or not valid JSON.
func _parse_file(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		return null
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(path)) != OK:
		return null
	return json.data


func load_game() -> bool:
	loaded_from = ""
	for path in _slot_paths(slot):
		var t0 := Perf.begin()
		var parsed: Variant = _parse_file(path)
		Perf.end("save.load_parse", t0)
		if parsed is Dictionary and parsed.has("version"):
			_adopt(parsed)
			loaded_from = path
			return true
	return false


## Which file the last load_game read (a slot's main file unless it fell back to a copy).
var loaded_from := ""


func _adopt(parsed: Dictionary) -> void:
	state = GameState.migrate(_fix_numbers(parsed))
	rng.seed = str(state.rng.seed).to_int()
	rng.state = str(state.rng.state).to_int()


## JSON has no integers: whole numbers come back as floats. Ids and counts are fine as floats in
## arithmetic, but a few places index arrays, so round every whole float back to int.
func _fix_numbers(v: Variant) -> Variant:
	if v is Dictionary:
		for k in v:
			v[k] = _fix_numbers(v[k])
	elif v is Array:
		for i in v.size():
			v[i] = _fix_numbers(v[i])
	elif v is float and is_equal_approx(v, roundf(v)) and absf(v) < 9.0e15:
		return int(v)
	return v


## 64-bit generator values would lose precision as JSON numbers, so they are saved as strings.
func _store_rng() -> void:
	state.rng.seed = str(rng.seed)
	state.rng.state = str(rng.state)


## Saves and stops the clock (back to the title screen).
func leave() -> void:
	if running:
		save_game()
	running = false
	set_process(false)
	state = {}
	slot = 0


## A short description of a slot for the title screen, or {} when it is empty.
func slot_info(n: int) -> Dictionary:
	for path in _slot_paths(n):
		var parsed: Variant = _parse_file(path)
		if not (parsed is Dictionary) or not parsed.has("creatures"):
			continue
		var best := ""
		var best_level := 0
		for id in parsed.get("skills", {}):
			var lv := int(parsed.skills[id].get("level", 1))
			if lv > best_level:
				best_level = lv
				best = id
		var zones_cleared := 0
		for z in parsed.get("expedition", {}).get("zones", {}).values():
			if z.get("cleared", false):
				zones_cleared += 1
		return {"lastSeen": float(parsed.get("lastSeen", 0)), "playSeconds": float(parsed.get("playSeconds", 0)),
			"creatures": parsed.creatures.size(), "species": parsed.get("collection", {}).get("species", {}).size(),
			"aether": float(parsed.get("aether", 0)), "bestSkill": best, "bestLevel": best_level, "zones": zones_cleared,
			"title": parsed.get("settings", {}).get("title", ""), "name": str(parsed.get("saveName", ""))}
	return {}


## Gives a save slot a name of the player's choosing ("" clears it). Works on a slot that is not loaded.
func rename_slot(n: int, save_name: String) -> void:
	save_name = save_name.strip_edges().left(24)
	if n == slot and not state.is_empty():
		state.saveName = save_name
		save_game()
		return
	var parsed: Variant = null
	for path in _slot_paths(n):
		parsed = _parse_file(path)
		if parsed is Dictionary and parsed.has("version"):
			break
	if not (parsed is Dictionary and parsed.has("version")):
		return
	parsed.saveName = save_name
	_write_slot(n, JSON.stringify(parsed))


func delete_slot(n: int) -> void:
	_main_ok.erase(n)
	for path in _slot_paths(n) + [pre_import_path(n)]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func export_text() -> String:
	_store_rng()
	return Marshalls.utf8_to_base64(JSON.stringify(state))


func import_text(text: String) -> String:
	var raw := text.strip_edges()
	var json := raw
	if not raw.begins_with("{"):
		json = Marshalls.base64_to_utf8(raw)
	var parsed: Variant = JSON.parse_string(json)
	if not (parsed is Dictionary) or not parsed.has("version") or not parsed.has("creatures"):
		return "That does not look like an Aetherbound save."
	# migrate itself stops with an error on some bad shapes (creatures as a list), so check those first
	for key in ["creatures", "items", "skills", "expedition", "collection", "rng"]:
		if parsed.has(key) and not (parsed[key] is Dictionary):
			return "That save is damaged (%s), so it was not loaded." % key
	for c: Variant in parsed.creatures.values():
		if not (c is Dictionary):
			return "That save is damaged (creatures), so it was not loaded."
	# migrate a copy first, and only adopt it when the result has the shape a game needs
	var trial: Dictionary = GameState.migrate(_fix_numbers(parsed.duplicate(true)))
	for key in ["creatures", "items", "skills", "expedition", "collection"]:
		if not (trial.get(key) is Dictionary):
			return "That save is damaged (%s), so it was not loaded." % key
	if not (trial.get("rng") is Dictionary):
		return "That save is damaged (rng), so it was not loaded."
	if slot > 0 and not state.is_empty():
		_store_rng()
		var keep := FileAccess.open(pre_import_path(slot), FileAccess.WRITE)
		if keep:
			keep.store_string(JSON.stringify(state))
			keep.close()
	_adopt(parsed)
	_last_tick = now_sec()
	save_game()
	changed.emit()
	return ""


func reset_game() -> void:
	new_game()
	_last_tick = now_sec()
	changed.emit()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if running:
			save_game()


# ---------------------------------------------------------------- actions: work

func creature(id: String) -> Dictionary:
	return GameState.creature(state, id)


func assign(cid: String, skill_id: String) -> bool:
	var c := creature(cid)
	if c.is_empty():
		return false
	if c.job.get("kind", "") == "party":
		if Expedition.party_locked(state):
			warn(Expedition.PARTY_LOCKED)
			return false
		Expedition.remove_from_party(state, c)
	var err := Skills.assign(state, c, skill_id)
	if err != "":
		warn(err)
		return false
	Sfx.play("click")
	changed.emit()
	return true


## "Fill empty slots" on a skill page: the best resting Aetherlings go to work there.
func fill_slots(skill_id: String) -> int:
	var n := Skills.fill_slots(state, skill_id)
	if n > 0:
		Sfx.play("click")
		info("%d Aetherling%s went to work in %s" % [n, "" if n == 1 else "s", Data.skills[skill_id].name], Data.ui_icon(skill_id))
	changed.emit()
	return n


func bench(cid: String) -> void:
	var c := creature(cid)
	if c.is_empty():
		return
	if c.job.get("kind", "") == "party":
		if Expedition.party_locked(state):
			warn(Expedition.PARTY_LOCKED)
			return
		Expedition.remove_from_party(state, c)
	else:
		Skills.unassign(state, c)
	changed.emit()


func set_action(skill_id: String, action_id: String) -> void:
	if not Skills.action_unlocked(state, skill_id, action_id):
		warn("Reach %s level %d first." % [Data.skills[skill_id].name, int(Data.actions[skill_id][action_id].level)])
		return
	state.skills[skill_id].action = action_id
	for c in GameState.workers(state, skill_id):
		c.progress = 0.0
		c.overclock = 0
		c.erase("stalled")
	Sfx.play("click")
	changed.emit()


# ---------------------------------------------------------------- actions: expeditions

func set_party(party_slot: int, cid: String) -> void:
	var c := creature(cid) if cid != "" else {}
	var err := Expedition.set_party_member(state, party_slot, c)
	if err != "":
		warn(err)
		return
	changed.emit()


func start_expedition(zone_id: String) -> void:
	var err := Expedition.start(state, zone_id, rng)
	if err != "":
		warn(err)
	else:
		Sfx.play("start")
	changed.emit()


func stop_expedition() -> void:
	Expedition.stop(state)
	changed.emit()


func retry_pending(index: int, vessel: String) -> void:
	_handle(Expedition.retry_pending(state, index, vessel, rng))
	save_game()
	changed.emit()


# ---------------------------------------------------------------- actions: breeding

func breed(a_id: String, b_id: String, tier: int) -> bool:
	var res := Breeding.breed(state, creature(a_id), creature(b_id), tier, rng, now_sec())
	if res.has("error"):
		warn(res.error)
		return false
	save_game()  # the rolls are committed: never let a reload re-roll them
	Sfx.play("egg")
	changed.emit()
	return true


func hatch(pod: int) -> void:
	var res := Breeding.hatch(state, pod, now_sec())
	if res.is_empty():
		return
	save_game()
	reveal_requested.emit("hatch", res)
	_handle(res.events)
	changed.emit()


func speed_up(pod: int) -> void:
	var err := Breeding.speed_up(state, pod, now_sec())
	if err != "":
		warn(err)
	changed.emit()


func ready_eggs() -> Array:
	var out := []
	var now := now_sec()
	for i in state.pods.size():
		if Breeding.is_ready(state.pods[i], now):
			out.append(i)
	return out


# ---------------------------------------------------------------- actions: economy and creatures

func sell(item_id: String, qty: int) -> void:
	var g := Economy.sell(state, item_id, qty)
	if g > 0:
		Sfx.play("coin")
		info("Sold for %s gold" % F.format_num(g), Data.ui_icon("gold"))
	changed.emit()


func shatter(item_id: String, qty: int) -> void:
	var a := Economy.shatter(state, item_id, qty)
	if a > 0:
		info("+%s Aether" % F.format_num(a), Data.ui_icon("aether"))
	changed.emit()


func buy_upgrade(id: String) -> void:
	var err := Economy.buy_upgrade(state, id)
	if err != "":
		warn(err)
	else:
		Sfx.play("level")
		_notify("%s upgraded" % Data.upgrades[id].name, Data.ui_icon("upgrade"), Palette.AETHER)
	changed.emit()


# ---------------------------------------------------------------- the Market

func _market_result(err: String, ok_text: String, icon: Texture2D) -> bool:
	if err != "":
		warn(err)
		changed.emit()
		return false
	Sfx.play("coin")
	if ok_text != "":
		info(ok_text, icon)
	changed.emit()
	return true


func market_buy(item_id: String, qty: int) -> bool:
	return _market_result(Market.buy(state, item_id, qty), "Bought %s× %s" % [F.format_num(qty), Data.item_name(item_id)], Data.item_icon(item_id))


func buy_slot(skill_id: String) -> bool:
	var ok := _market_result(Market.buy_slot(state, skill_id), "", null)
	if ok:
		_notify("A new %s work slot opens" % Data.skills[skill_id].name, Data.ui_icon(skill_id), Palette.AETHER)
	return ok


func bulk_sell(cands: Dictionary) -> void:
	var g := Market.bulk_sell(state, cands)
	if g > 0:
		Sfx.play("coin")
		info("Sold for %s gold" % F.format_num(g), Data.ui_icon("gold"))
	changed.emit()


func toggle_item_lock(item_id: String) -> void:
	Market.toggle_item_lock(state, item_id)
	changed.emit()


## `expect_window` is the stock window the screen showed (see Market.buy_offer).
func buy_offer(index: int, expect_window := -1) -> bool:
	var o: Dictionary = Market.stock(state, now_sec()).offers[index] if index < Market.stock(state, now_sec()).offers.size() else {}
	var ok := _market_result(Market.buy_offer(state, index, now_sec(), rng, expect_window), "", null)
	if ok and o.get("limited", false):
		Sfx.play("shiny_appear")
		_notify("Snapped up: %s" % o.name, Data.ui_icon("market"), Palette.GOLD)
	return ok


func buy_boost(id: String) -> bool:
	return _market_result(Market.buy_boost(state, id), "%s is working" % Market.boost_def(id).name, Data.ui_icon(Market.boost_def(id).icon))


func buy_egg(type_id: String, grade: int) -> bool:
	return _market_result(Market.buy_egg(state, type_id, grade, rng, now_sec()), "The egg is in a Genesis Pod", Data.ui_icon("pods"))


func buy_featured_egg(expect_window := -1) -> bool:
	return _market_result(Market.buy_featured(state, now_sec(), rng, expect_window), "The featured egg is in a Genesis Pod", Data.ui_icon("pods"))


func release(cid: String) -> void:
	var c := creature(cid)
	if c.is_empty():
		return
	if c.job.get("kind", "") == "party" and Expedition.party_locked(state):
		warn(Expedition.PARTY_LOCKED)
		return
	var pearls0 := GameState.count(state, "aether-pearl")
	var v := Economy.release(state, c)
	if v < 0:
		warn("Locked Aetherlings (and your last one) cannot be released.")
		return
	var pearls := int(GameState.count(state, "aether-pearl") - pearls0)
	info("Released. +%d Aether%s" % [v, " and %d Aether Pearl%s" % [pearls, "" if pearls == 1 else "s"] if pearls > 0 else ""], Data.ui_icon("aether"))
	changed.emit()


## `opts`: see Economy.BULK_DEFAULTS (or the older form: the highest rarity, and a level to stay under).
func bulk_release(opts: Variant, under_level := 0) -> void:
	var res := Economy.bulk_release(state, opts, under_level)
	if res.count > 0:
		info("Released %d Aetherlings. +%s Aether%s" % [res.count, F.format_num(res.aether),
			"  +%d Aether Pearl%s" % [res.pearls, "" if res.pearls == 1 else "s"] if res.pearls > 0 else ""], Data.ui_icon("aether"))
	else:
		warn("Nobody matched, so nobody was released.")
	save_game()
	changed.emit()


func toggle_lock(cid: String) -> void:
	var c := creature(cid)
	if not c.is_empty():
		c.locked = not c.get("locked", false)
		changed.emit()


func rename(cid: String, nick: String) -> void:
	var c := creature(cid)
	if not c.is_empty():
		c.nick = nick.strip_edges().left(20)
		changed.emit()


func attune(cid: String, locked: Array) -> bool:
	var c := creature(cid)
	var err := Traits.attune(state, c, locked, rng)
	if err != "":
		warn(err)
		return false
	save_game()
	Sfx.play("rare")
	changed.emit()
	return true


func claim_goal() -> void:
	var g := Goals.claim(state)
	if g.is_empty():
		return
	Sfx.play("level")
	info("Goal complete: %s" % g.text, Data.ui_icon("xp"))
	changed.emit()


func claim_milestone(track_id: String, index: int) -> void:
	var res := Collection.claim(state, track_id, index, rng)
	if res.is_empty():
		return
	Sfx.play("level")
	for r in res.revealed:
		_notify("A recipe hint is clearer now: %s" % Data.species[r].name, Data.ui_icon("aetherlog"), Palette.AETHER)
	info("Milestone reward claimed", Data.ui_icon("xp"))
	changed.emit()


# ---------------------------------------------------------------- dev tools (Settings > Developer)

func dev_grant(species_id: String, rarity: int, level: int, shiny: bool, form := 0) -> void:
	var c := Creatures.make(state, species_id, rarity, level, shiny, Traits.roll_fresh(rng, Data.species[species_id].types), "dev", form)
	state.creatures[c.id] = c
	_handle(Collection.on_owned(state, c))
	changed.emit()


## For sprite and effect tests: every form x every rarity x plain and shiny, of one species or (empty id) of
## every species. Each is logged in the Aether-Log like a normal catch, without a toast per creature.
## Returns how many were granted.
func dev_grant_all(species_id := "") -> int:
	var ids: Array = [species_id] if species_id != "" else Data.species_list.map(func(sp): return sp.id)
	var form_levels: Array = Data.tuning.creature.formLevels
	var n := 0
	for id in ids:
		for form in form_levels.size():
			for rarity in range(1, Data.max_rarity() + 1):
				for shiny in [false, true]:
					var c := Creatures.make(state, id, rarity, int(form_levels[form]), shiny, [], "dev", form + 1)
					state.creatures[c.id] = c
					Collection.on_owned(state, c)
					n += 1
	changed.emit()
	return n


func dev_next_wave(kind: String) -> void:
	var err := Expedition.dev_next_wave(state, kind)
	if err != "":
		warn(err)
		return
	info("Next wave: %s" % kind, Data.ui_icon("shiny"))
	changed.emit()


func dev_add(id: String, qty: float) -> void:
	GameState.add_item(state, id, qty)
	changed.emit()


func dev_fast_forward(hours: float) -> void:
	_apply_offline(hours * 3600.0)


func dev_skill_level(skill_id: String, level: int) -> void:
	var st: Dictionary = state.skills[skill_id]
	st.xp = F.xp_for_level(F.skill_curve(), level, Data.tuning.skills.maxLevel)
	st.level = level
	changed.emit()
