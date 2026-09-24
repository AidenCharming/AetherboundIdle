extends Node
## Tiny synthesised sound effects (no audio files). Each sound is a few notes rendered to a WAV buffer
## once at start-up; play() picks a free player from a small pool. Volume is the "SFX" bus (Options).

const RATE := 22050
const POOL := 10

var _streams: Dictionary = {}
var last_played := ""   # the most recent sound asked for, even headless (tests read it)
var _players: Array[AudioStreamPlayer] = []


func _ready() -> void:
	for i in POOL:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_players.append(p)
	# [frequency Hz, start s, length s, wave, gain, (glide-to Hz), ("drop": the glide decays like a pluck)]
	_streams.click = _render([[880, 0.0, 0.05, "tri", 0.35]])
	_streams.level = _render([[523, 0.0, 0.12, "tri", 0.4], [659, 0.08, 0.12, "tri", 0.4], [784, 0.16, 0.12, "tri", 0.4], [1047, 0.24, 0.3, "tri", 0.45]])
	_streams.capture = _render([[392, 0.0, 0.1, "sine", 0.5], [587, 0.07, 0.1, "sine", 0.5], [784, 0.14, 0.25, "sine", 0.5], [1175, 0.2, 0.35, "sine", 0.25]])
	_streams.rare = _render([[1319, 0.0, 0.25, "sine", 0.3], [1568, 0.06, 0.25, "sine", 0.3], [2093, 0.12, 0.4, "sine", 0.3]])
	_streams.coin = _render([[988, 0.0, 0.06, "square", 0.18], [1319, 0.05, 0.18, "square", 0.18]])
	_streams.egg = _render([[330, 0.0, 0.15, "sine", 0.45], [494, 0.1, 0.25, "sine", 0.4]])
	_streams.crack = _render([[180, 0.0, 0.05, "noise", 0.35], [140, 0.03, 0.06, "noise", 0.25]])
	_streams.hatch = _render([[523, 0.0, 0.2, "tri", 0.4], [784, 0.1, 0.2, "tri", 0.4], [1047, 0.2, 0.25, "tri", 0.4], [1568, 0.3, 0.6, "sine", 0.35], [2093, 0.35, 0.6, "sine", 0.2]])
	# evolution: two voices sweep up two octaves and land on a full C major chord over a low root, with a
	# sparkle run on top; longer and wider than hatch's single run of notes
	_streams.evolve = _render([[262, 0.0, 0.7, "tri", 0.2, 1047], [392, 0.05, 0.65, "sine", 0.14, 1568],
		[131, 0.62, 0.9, "sine", 0.3], [523, 0.62, 1.1, "tri", 0.17], [659, 0.62, 1.1, "tri", 0.15], [784, 0.62, 1.1, "tri", 0.15],
		[1047, 0.64, 1.2, "sine", 0.17], [1319, 0.75, 0.5, "sine", 0.13], [1568, 0.85, 0.5, "sine", 0.13],
		[2093, 0.95, 0.9, "sine", 0.15], [2637, 1.05, 0.8, "sine", 0.1]])
	_streams.error = _render([[196, 0.0, 0.12, "square", 0.2], [165, 0.1, 0.16, "square", 0.2]])
	_streams.start = _render([[440, 0.0, 0.1, "tri", 0.35], [660, 0.08, 0.18, "tri", 0.35]])
	_streams.hit = _render([[120, 0.0, 0.07, "noise", 0.25]])
	# attacks sound like their type. A 7th element "drop" makes a glide pluck (falls in pitch, decays)
	# instead of swelling. hit_<type> is a basic attack, cast_<type> an ability going off.
	_streams.hit_verdant = _render([[2400, 0.0, 0.05, "noise", 0.16], [520, 0.0, 0.09, "tri", 0.34, 260, "drop"], [780, 0.02, 0.05, "tri", 0.14]], 1.25)
	_streams.hit_telluric = _render([[140, 0.0, 0.16, "sine", 0.6, 55, "drop"], [90, 0.0, 0.08, "noise", 0.34], [70, 0.05, 0.05, "noise", 0.18]], 0.8)
	_streams.hit_pyric = _render([[1400, 0.0, 0.14, "noise", 0.2], [600, 0.02, 0.06, "noise", 0.16], [330, 0.0, 0.12, "tri", 0.26, 150, "drop"]], 1.35)
	_streams.hit_aqueous = _render([[280, 0.0, 0.1, "sine", 0.42, 820, "drop"], [3000, 0.02, 0.05, "noise", 0.1], [560, 0.05, 0.08, "sine", 0.18, 1300, "drop"]])
	_streams.hit_voltaic = _render([[1500, 0.0, 0.08, "square", 0.14, 380, "drop"], [2200, 0.01, 0.04, "square", 0.08], [60, 0.0, 0.05, "noise", 0.2]], 1.4)
	_streams.hit_void = _render([[240, 0.0, 0.2, "sine", 0.34, 90, "drop"], [247, 0.0, 0.2, "sine", 0.26, 93, "drop"], [120, 0.03, 0.16, "tri", 0.18]], 0.85)
	_streams.cast_verdant = _render([[392, 0.0, 0.1, "tri", 0.26], [523, 0.06, 0.1, "tri", 0.26], [784, 0.12, 0.22, "tri", 0.26], [2400, 0.0, 0.2, "noise", 0.06]])
	_streams.cast_telluric = _render([[98, 0.0, 0.3, "sine", 0.55, 65, "drop"], [196, 0.05, 0.18, "tri", 0.2], [80, 0.1, 0.12, "noise", 0.3]])
	_streams.cast_pyric = _render([[200, 0.0, 0.3, "noise", 0.2], [262, 0.0, 0.25, "tri", 0.24, 520], [900, 0.1, 0.2, "noise", 0.12]])
	_streams.cast_aqueous = _render([[330, 0.0, 0.1, "sine", 0.3, 880, "drop"], [440, 0.07, 0.1, "sine", 0.28, 1100, "drop"], [660, 0.14, 0.14, "sine", 0.26, 1500, "drop"]])
	_streams.cast_voltaic = _render([[880, 0.0, 0.05, "square", 0.12], [1320, 0.05, 0.05, "square", 0.12], [1760, 0.1, 0.05, "square", 0.12], [2640, 0.15, 0.1, "square", 0.1], [60, 0.0, 0.08, "noise", 0.18]])
	_streams.cast_void = _render([[196, 0.0, 0.35, "sine", 0.26, 392], [203, 0.0, 0.35, "sine", 0.2, 380], [98, 0.1, 0.3, "tri", 0.2]])
	# a shiny enters: a quick glittering run up two octaves with a shimmer on top
	_streams.shiny_appear = _render([[1047, 0.0, 0.12, "sine", 0.24], [1319, 0.05, 0.12, "sine", 0.24], [1568, 0.1, 0.12, "sine", 0.24],
		[2093, 0.15, 0.3, "sine", 0.26], [2637, 0.2, 0.4, "sine", 0.16], [3136, 0.26, 0.45, "sine", 0.12], [1568, 0.15, 0.5, "tri", 0.1, 3136]])
	# a rare one enters: a two-note bell chime
	_streams.rare_appear = _render([[784, 0.0, 0.4, "sine", 0.3], [1568, 0.0, 0.3, "sine", 0.08], [1175, 0.12, 0.5, "sine", 0.28], [2350, 0.12, 0.35, "sine", 0.07]])
	# a super-effective hit adds a bright ping on top
	_streams.strong = _render([[1568, 0.0, 0.12, "sine", 0.22], [2349, 0.03, 0.14, "sine", 0.16]])
	_streams.whoosh = _render([[400, 0.0, 0.25, "noise", 0.12]])


func play(sound: String, pitch := 1.0) -> void:
	last_played = sound
	# headless runs (tests, exports) have no audio output, and sounds left playing at exit show up as leaks
	if not _streams.has(sound) or DisplayServer.get_name() == "headless":
		return
	for p in _players:
		if not p.playing:
			p.stream = _streams[sound]
			p.pitch_scale = pitch
			p.play()
			return


func _render(notes: Array, gain := 1.0) -> AudioStreamWAV:
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
		# a glide note sweeps exponentially to its end pitch and swells instead of decaying
		var glide: float = n[5] if n.size() > 5 else 0.0
		var pluck: bool = n.size() > 6 and n[6] == "drop"
		var gph := 0.0
		for i in samples:
			var t := float(i) / RATE
			var env := minf(1.0, t / 0.008) * pow(1.0 - float(i) / samples, 2.0)
			var ph := fmod(t * f, 1.0)
			if glide > 0.0:
				var x := float(i) / samples
				if not pluck:
					env = pow(x, 1.2) * minf(1.0, (1.0 - x) / 0.08)
				gph = fmod(gph + f * pow(glide / f, x) / RATE, 1.0)
				ph = gph
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
				buf[idx] += v * env * float(n[4]) * gain
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
