extends Node
## Tiny synthesised sound effects (no audio files). Each sound is a few notes rendered to a WAV buffer
## once at start-up; play() picks a free player from a small pool. Volume is the "SFX" bus (Options).

const RATE := 22050
const POOL := 6

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	# [frequency Hz, start s, length s, wave, gain]
	_streams.click = _render([[880, 0.0, 0.05, "tri", 0.35]])
	_streams.level = _render([[523, 0.0, 0.12, "tri", 0.4], [659, 0.08, 0.12, "tri", 0.4], [784, 0.16, 0.12, "tri", 0.4], [1047, 0.24, 0.3, "tri", 0.45]])
	_streams.capture = _render([[392, 0.0, 0.1, "sine", 0.5], [587, 0.07, 0.1, "sine", 0.5], [784, 0.14, 0.25, "sine", 0.5], [1175, 0.2, 0.35, "sine", 0.25]])
	_streams.rare = _render([[1319, 0.0, 0.25, "sine", 0.3], [1568, 0.06, 0.25, "sine", 0.3], [2093, 0.12, 0.4, "sine", 0.3]])
	_streams.coin = _render([[988, 0.0, 0.06, "square", 0.18], [1319, 0.05, 0.18, "square", 0.18]])
	_streams.egg = _render([[330, 0.0, 0.15, "sine", 0.45], [494, 0.1, 0.25, "sine", 0.4]])
	_streams.crack = _render([[180, 0.0, 0.05, "noise", 0.35], [140, 0.03, 0.06, "noise", 0.25]])
	_streams.hatch = _render([[523, 0.0, 0.2, "tri", 0.4], [784, 0.1, 0.2, "tri", 0.4], [1047, 0.2, 0.25, "tri", 0.4], [1568, 0.3, 0.6, "sine", 0.35], [2093, 0.35, 0.6, "sine", 0.2]])
	_streams.error = _render([[196, 0.0, 0.12, "square", 0.2], [165, 0.1, 0.16, "square", 0.2]])
	_streams.start = _render([[440, 0.0, 0.1, "tri", 0.35], [660, 0.08, 0.18, "tri", 0.35]])
	_streams.hit = _render([[120, 0.0, 0.07, "noise", 0.25]])
	_streams.whoosh = _render([[400, 0.0, 0.25, "noise", 0.12]])


func play(sound: String, pitch := 1.0) -> void:
	# headless runs (tests, exports) have no audio output, and sounds left playing at exit show up as leaks
	if not _streams.has(sound) or DisplayServer.get_name() == "headless":
		return
	for p in _players:
		if not p.playing:
			p.stream = _streams[sound]
			p.pitch_scale = pitch
			p.play()
			return


func _render(notes: Array) -> AudioStreamWAV:
	var length := 0.0
	for n in notes:
		length = maxf(length, n[1] + n[2])
	var count := int((length + 0.05) * RATE)
	var buf := PackedFloat32Array()
	buf.resize(count)
	buf.fill(0.0)
	var noise := RandomNumberGenerator.new()
	noise.seed = 7
	for n in notes:
		var f: float = n[0]
		var start := int(n[1] * RATE)
		var samples := int(n[2] * RATE)
		for i in samples:
			var t := float(i) / RATE
			var env := minf(1.0, t / 0.008) * pow(1.0 - float(i) / samples, 2.0)
			var ph := fmod(t * f, 1.0)
			var v := 0.0
			match n[3]:
				"sine":
					v = sin(TAU * ph)
				"tri":
					v = 4.0 * absf(ph - 0.5) - 1.0
				"square":
					v = 1.0 if ph < 0.5 else -1.0
				"noise":
					v = noise.randf_range(-1.0, 1.0) * (0.6 + 0.4 * sin(TAU * f * t))
			var idx := start + i
			if idx < count:
				buf[idx] += v * env * float(n[4])
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count:
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = bytes
	return w
