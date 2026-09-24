extends Node
## Background music, synthesised in code (no audio files ship with the project). Each track is a short
## seamless loop: a soft chord pad, a sub bass and a bell arpeggio, run through a simple echo. Tracks
## render on a worker thread at start-up; play() crossfades between them on the "Music" bus.

const RATE := 22050
const FADE_SEC := 2.0

## name -> {bpm, chords: [[midi notes]], arp: [chord-tone index per step, -1 = rest], octave, bright}
const TRACKS := {
	"title": {"bpm": 64, "beats_per_chord": 8, "chords": [[50, 57, 62, 66, 69], [47, 54, 59, 62, 66], [43, 50, 55, 59, 64], [45, 52, 57, 61, 64]],
		"arp": [4, -1, 2, -1, 3, -1, 1, -1, 4, -1, 3, 2, -1, -1, 1, -1], "arp_oct": 12, "bright": 0.6},
	"sanctum": {"bpm": 84, "beats_per_chord": 8, "chords": [[48, 55, 60, 64, 67], [45, 52, 57, 60, 64], [41, 48, 53, 57, 60], [43, 50, 55, 59, 62]],
		"arp": [0, 2, 4, 2, 3, 1, 4, -1, 0, 2, 4, 3, 1, 2, -1, 4], "arp_oct": 12, "bright": 0.9},
	"expedition": {"bpm": 104, "beats_per_chord": 8, "chords": [[45, 52, 57, 60, 64], [41, 48, 53, 57, 60], [43, 50, 55, 59, 62], [40, 47, 52, 55, 59]],
		"arp": [0, 4, 2, 4, 1, 4, 3, 4, 0, 4, 2, 4, 3, 2, 1, 4], "arp_oct": 12, "bright": 1.0},
}

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _wanted := ""
var _current := ""
var _thread: Thread
var _mutex := Mutex.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	if DisplayServer.get_name() == "headless":
		return
	_thread = Thread.new()
	_thread.start(_render_all)


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


func _render_all() -> void:
	for name in ["title", "sanctum", "expedition"]:
		var stream := _render(TRACKS[name])
		_mutex.lock()
		_streams[name] = stream
		_mutex.unlock()
		call_deferred("_on_rendered", name)


func _on_rendered(name: String) -> void:
	if name == _wanted and _current != name:
		play(name)


## Crossfades to a track. Safe to call before it has rendered: it starts as soon as it is ready.
func play(name: String) -> void:
	_wanted = name
	_mutex.lock()
	var stream: AudioStreamWAV = _streams.get(name)
	_mutex.unlock()
	if stream == null or _current == name:
		return
	_current = name
	var old := _players[_active]
	_active = 1 - _active
	var nu := _players[_active]
	nu.stream = stream
	nu.volume_db = -40.0
	nu.play()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(nu, "volume_db", 0.0, FADE_SEC).set_trans(Tween.TRANS_SINE)
	if old.playing:
		tw.tween_property(old, "volume_db", -60.0, FADE_SEC).set_trans(Tween.TRANS_SINE)
		tw.chain().tween_callback(old.stop)


static func _midi_hz(n: float) -> float:
	return 440.0 * pow(2.0, (n - 69.0) / 12.0)


func _render(t: Dictionary) -> AudioStreamWAV:
	var beat := 60.0 / float(t.bpm)
	var chord_len := beat * float(t.beats_per_chord)
	var total: float = chord_len * t.chords.size()
	var n := int(total * RATE)
	var buf := PackedFloat32Array()
	buf.resize(n)
	buf.fill(0.0)
	var bright: float = t.bright
	# pad: each chord note, two slightly detuned voices, slow swell, crossfading into the next chord
	for ci in t.chords.size():
		var chord: Array = t.chords[ci]
		var start: float = ci * chord_len
		var length := chord_len * 1.35
		for k in range(1, chord.size()):
			var f := _midi_hz(chord[k])
			_add_voice(buf, start, length, f, 0.045, 1.2, length * 0.5, "pad", bright)
			_add_voice(buf, start, length, f * 1.004, 0.03, 1.2, length * 0.5, "pad", bright)
		_add_voice(buf, start, chord_len * 1.05, _midi_hz(chord[0] - 12), 0.09, 0.3, chord_len * 0.4, "sine", bright)
	# arpeggio: eighth notes on a pattern of chord tones
	var step := beat / 2.0
	var steps := int(round(total / step))
	var pattern: Array = t.arp
	for i in steps:
		var idx: int = pattern[i % pattern.size()]
		if idx < 0:
			continue
		var chord: Array = t.chords[int(i * step / chord_len) % t.chords.size()]
		var note: float = chord[clampi(idx, 0, chord.size() - 1)] + int(t.arp_oct)
		var accent := 1.0 if i % 4 == 0 else 0.7
		_add_voice(buf, i * step, 1.6, _midi_hz(note), 0.07 * accent, 0.004, 0.0, "bell", bright)
	# echo, wrapped around the loop point so the loop is seamless
	for tap in [[0.375, 0.32], [0.75, 0.18]]:
		var d := int(tap[0] * beat * 2.0 * RATE)
		var src := buf.duplicate()
		for i in n:
			buf[(i + d) % n] += src[i] * float(tap[1])
	var peak := 0.0001
	for v in buf:
		peak = maxf(peak, absf(v))
	var gain := 0.8 / peak
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(buf[i] * gain, -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	w.loop_mode = AudioStreamWAV.LOOP_FORWARD
	w.loop_begin = 0
	w.loop_end = n
	return w


## Adds one note to the buffer, wrapping past the end so every loop joins seamlessly.
func _add_voice(buf: PackedFloat32Array, start_sec: float, len_sec: float, f: float, gain: float, attack: float, release_at: float, kind: String, bright: float) -> void:
	var n := buf.size()
	var start := int(start_sec * RATE)
	var count := int(len_sec * RATE)
	var inc := f / RATE
	var ph := 0.0
	for i in count:
		var tt := float(i) / RATE
		var env := 0.0
		match kind:
			"bell":
				env = minf(1.0, tt / 0.004) * exp(-tt * 3.2)
			_:
				var a := minf(1.0, tt / attack)
				var r := 1.0 if release_at <= 0.0 or tt < release_at else maxf(0.0, 1.0 - (tt - release_at) / (len_sec - release_at))
				env = a * r
		var v := sin(TAU * ph)
		if kind == "pad":
			v += 0.25 * bright * sin(TAU * ph * 2.0) + 0.1 * bright * sin(TAU * ph * 3.0)
		elif kind == "bell":
			v += 0.3 * sin(TAU * ph * 2.76) * exp(-tt * 6.0)
		buf[(start + i) % n] += v * env * gain
		ph += inc
		if ph >= 1.0:
			ph -= 1.0
