extends Node
## Background music, synthesised in code (no audio files ship with the project). Each track is a seamless
## loop built on four chords: a soft chord pad, a sub bass and an arpeggio, played four times in an
## A / A2 / B / A form so a long idle session doesn't hear the same bars verbatim. Echo and reverb come from
## effects on the "Music" bus, not from the samples. Tracks render on a worker thread at start-up; play()
## crossfades between them.

const RATE := 22050
const FADE_SEC := 2.0
## Bump whenever _render's output changes, so renders cached in user://music are redone.
const RENDER_VERSION := 2
## One loop plays the chords once per pass: A as written, A2 with ghost notes and a run into B, B with the
## arpeggio turned upside down an octave higher (or, on a track with a lead, the lead taking the tune).
const FORM := ["A", "A2", "B", "A"]
## Target RMS level of a rendered loop, so switching tracks doesn't jump in volume.
const LOUDNESS := 0.17

## name -> {bpm, beats_per_chord, chords: [[midi notes, bass first]], arp: [chord-tone index per step, -1 =
## rest], arp_oct, bright}. Optional: arp_div (arp steps per beat, 2), arp_kind ("bell", or "saw"/"square"),
## arp_gain, bass ("pulse": a plucked saw on every eighth), lead ({kind, gain, tone, oct}: in B, holds that
## chord tone through each chord), kick / hat (one character per arp step, "x" hit, "o" soft, "." rest; the
## arpeggio is accented where the kick lands), echo ([tap 1 dB, tap 2 dB] for the bus delay).
const TRACKS := {
	"title": {"bpm": 64, "beats_per_chord": 8, "chords": [[50, 57, 62, 66, 69], [47, 54, 59, 62, 66], [43, 50, 55, 59, 64], [45, 52, 57, 61, 64]],
		"arp": [4, -1, 2, -1, 3, -1, 1, -1, 4, -1, 3, 2, -1, -1, 1, -1], "arp_oct": 12, "bright": 0.6},
	"sanctum": {"bpm": 84, "beats_per_chord": 8, "chords": [[48, 55, 60, 64, 67], [45, 52, 57, 60, 64], [41, 48, 53, 57, 60], [43, 50, 55, 59, 62]],
		"arp": [0, 2, 4, 2, 3, 1, 4, -1, 0, 2, 4, 3, 1, 2, -1, 4], "arp_oct": 12, "bright": 0.9},
	"expedition": {"bpm": 104, "beats_per_chord": 8, "chords": [[45, 52, 57, 60, 64], [41, 48, 53, 57, 60], [43, 50, 55, 59, 62], [40, 47, 52, 55, 59]],
		"arp": [0, 4, 2, 4, 1, 4, 3, 4, 0, 4, 2, 4, 3, 2, 1, 4], "arp_oct": 12, "bright": 1.0},
	# D minor, i-VI-VII-V twice with a iv turn, a chord every bar: plucked saw sixteenths over a pulsing
	# bass and drums; in B a square lead sings the top line (A F G E A F D E)
	"boss": {"bpm": 138, "beats_per_chord": 4, "chords": [[50, 57, 62, 65, 69], [46, 53, 58, 62, 65], [48, 55, 60, 64, 67], [45, 52, 57, 61, 64],
			[50, 57, 62, 65, 69], [46, 53, 58, 62, 65], [43, 50, 55, 58, 62], [45, 52, 57, 61, 64]],
		"arp": [0, 2, 4, 2, 3, 4, 2, 4, 0, 2, 4, 2, 3, 4, 3, 1], "arp_oct": 12, "arp_div": 4, "arp_kind": "saw", "arp_gain": 0.05,
		"bright": 1.4, "bass": "pulse", "lead": {"kind": "square", "gain": 0.05, "tone": 4, "oct": 0},
		"kick": "x.....x.x.......", "hat": "..x...x...x.o.x.", "echo": [-17.0, -24.0]},
}

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _wanted := ""
var _current := ""
var _thread: Thread
var _mutex := Mutex.new()
var _delay: AudioEffectDelay


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.bus = "Music"
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	_setup_bus()
	if DisplayServer.get_name() == "headless":
		return
	_thread = Thread.new()
	_thread.start(_render_all)


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()


## The Music bus (made by Options) gets a tempo-synced echo, a room reverb and a limiter so the wet tails
## never clip.
func _setup_bus() -> void:
	var bus := AudioServer.get_bus_index("Music")
	if bus < 0 or AudioServer.get_bus_effect_count(bus) > 0:
		return
	_delay = AudioEffectDelay.new()
	_delay.dry = 1.0
	_delay.feedback_active = false
	_delay.tap1_active = true
	_delay.tap2_active = true
	_set_echo(TRACKS.title)
	var reverb := AudioEffectReverb.new()
	reverb.room_size = 0.72
	reverb.damping = 0.45
	reverb.spread = 0.8
	reverb.hipass = 0.15
	reverb.predelay_msec = 30.0
	reverb.dry = 1.0
	reverb.wet = 0.22
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = -1.0
	AudioServer.add_bus_effect(bus, _delay)
	AudioServer.add_bus_effect(bus, reverb)
	AudioServer.add_bus_effect(bus, limiter)


## Echo taps at three quarters of a beat and a beat and a half, as the old baked-in echo had.
func _set_echo(t: Dictionary) -> void:
	if _delay == null:
		return
	var beat_ms := 60000.0 / float(t.bpm)
	var levels: Array = t.get("echo", [-10.0, -15.0])
	_delay.tap1_delay_ms = beat_ms * 0.75
	_delay.tap1_level_db = levels[0]
	_delay.tap2_delay_ms = minf(beat_ms * 1.5, 1500.0)
	_delay.tap2_level_db = levels[1]


static func _cache_path(track: String) -> String:
	return "user://music/%s-%d.pcm" % [track, hash(str(TRACKS[track]) + str(FORM) + str(RATE) + str(RENDER_VERSION))]


## Renders each track once and caches the samples in user://music/ (keyed by the track's settings and the
## render version), so only the very first launch spends time synthesising. Stale renders are deleted.
func _render_all() -> void:
	DirAccess.make_dir_recursive_absolute("user://music")
	var keep := {}
	for track in TRACKS:
		keep[_cache_path(track).get_file()] = true
	for f in DirAccess.get_files_at("user://music"):
		if not keep.has(f):
			DirAccess.remove_absolute("user://music/" + f)
	for track in TRACKS:
		var path := _cache_path(track)
		var stream: AudioStreamWAV
		if FileAccess.file_exists(path):
			stream = _wav(FileAccess.get_file_as_bytes(path))
		else:
			stream = _render(TRACKS[track])
			var f := FileAccess.open(path, FileAccess.WRITE)
			if f:
				f.store_buffer(stream.data)
				f.close()
		_mutex.lock()
		_streams[track] = stream
		_mutex.unlock()
		call_deferred("_on_rendered", track)


func _on_rendered(track: String) -> void:
	if track == _wanted and _current != track:
		play(track)


## Crossfades to a track. Safe to call before it has rendered: it starts as soon as it is ready.
func play(track: String) -> void:
	_wanted = track
	_mutex.lock()
	var stream: AudioStreamWAV = _streams.get(track)
	_mutex.unlock()
	if stream == null or _current == track:
		return
	_current = track
	_set_echo(TRACKS[track])
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


## The track a screen last asked for (it may still be rendering).
func wanted() -> String:
	return _wanted


static func _midi_hz(n: float) -> float:
	return 440.0 * pow(2.0, (n - 69.0) / 12.0)


func _render(t: Dictionary) -> AudioStreamWAV:
	var beat := 60.0 / float(t.bpm)
	var chord_len := beat * float(t.beats_per_chord)
	var chords: Array = t.chords
	var pass_len: float = chord_len * chords.size()
	var pass_n := int(pass_len * RATE)
	var bright: float = t.bright
	# pad and sub bass are the same every pass: render one pass (wrapping, so it joins itself) and tile it
	var pad := PackedFloat32Array()
	pad.resize(pass_n)
	pad.fill(0.0)
	for ci in chords.size():
		var chord: Array = chords[ci]
		var start: float = ci * chord_len
		var length := chord_len * 1.35
		for k in range(1, chord.size()):
			var f := _midi_hz(chord[k])
			_add_voice(pad, start, length, f, 0.045, 1.2, length * 0.5, "pad", bright)
			_add_voice(pad, start, length, f * 1.004, 0.03, 1.2, length * 0.5, "pad", bright)
		_add_voice(pad, start, chord_len * 1.05, _midi_hz(chord[0] - 12), 0.09, 0.3, chord_len * 0.4, "sine", bright)
		if t.get("bass", "") == "pulse":
			for e in int(t.beats_per_chord) * 2:
				_add_synth(pad, start + e * beat / 2.0, beat * 0.45, _midi_hz(chord[0] - 12), 0.05 if e % 2 == 0 else 0.035, "saw", 0.005, beat * 0.2, 160.0, 5.0, 0.0)
	var form: Array = FORM
	var buf := PackedFloat32Array()
	buf.resize(pass_n * form.size())
	for p in form.size():
		for i in pass_n:
			buf[p * pass_n + i] = pad[i]
	# arpeggio (and lead and drums), varied per pass
	var div := int(t.get("arp_div", 2))
	var step := beat / float(div)
	var per_chord := int(t.beats_per_chord) * div
	var steps := per_chord * chords.size()
	var pattern: Array = t.arp
	var kind: String = t.get("arp_kind", "bell")
	var arp_gain: float = t.get("arp_gain", 0.07)
	var kick: String = t.get("kick", "")
	var hat: String = t.get("hat", "")
	var lead: Dictionary = t.get("lead", {})
	var noise := RandomNumberGenerator.new()
	noise.seed = 11
	for p in form.size():
		var sec: String = form[p]
		var base: float = p * pass_len
		for i in steps:
			var at: float = base + i * step
			var chord: Array = chords[floori(float(i) / per_chord) % chords.size()]
			var kick_hit := kick != "" and kick[i % kick.length()] == "x"
			var accented := kick_hit if kick != "" else i % (2 * div) == 0
			if kick_hit:
				_add_perc(buf, at, "kick", 0.3, noise)
			if hat != "":
				var hc := hat[i % hat.length()]
				if hc != ".":
					_add_perc(buf, at, "hat", 0.12 if hc == "x" else 0.06, noise)
			var idx: int = pattern[i % pattern.size()]
			var gain := arp_gain * (1.0 if accented else 0.7)
			var oct := int(t.arp_oct)
			match sec:
				"A2":
					if idx < 0:   # a soft ghost of the next written note fills each rest
						idx = pattern[(i + 1) % pattern.size()]
						gain *= 0.45
					if i >= steps - 4:   # a rising run leads into B
						idx = 1 + i - (steps - 4)
						gain = arp_gain * 0.85
				"B":
					if not lead.is_empty():
						gain *= 0.6
					elif i % 2 == 1 or idx < 0:
						continue
					else:
						idx = chord.size() - 1 - idx
						oct += 12
						gain *= 0.8
			if idx < 0:
				continue
			var note: float = chord[clampi(idx, 0, chord.size() - 1)] + oct
			if kind == "bell":
				_add_voice(buf, at, 1.6, _midi_hz(note), gain, 0.004, 0.0, "bell", bright)
			else:
				_add_synth(buf, at, step * 1.6, _midi_hz(note), gain, kind, 0.003, step * 0.5, 700.0 * bright, 4.0, 0.0)
		if sec == "B" and not lead.is_empty():
			for ci in chords.size():
				var tone: float = chords[ci][int(lead.get("tone", 4))] + int(lead.get("oct", 0))
				_add_synth(buf, base + ci * chord_len, chord_len * 0.98, _midi_hz(tone), float(lead.gain), String(lead.kind), 0.04, chord_len * 0.8, 1800.0, 1.0, 0.004)
	# every track lands at the same loudness (RMS), unless that would push its peaks past 0.95
	var peak := 0.0001
	var sq := 0.0
	for v in buf:
		peak = maxf(peak, absf(v))
		sq += v * v
	var n := buf.size()
	var level := minf(LOUDNESS / sqrt(sq / n + 1e-12), 0.95 / peak)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i in n:
		bytes.encode_s16(i * 2, int(clampf(buf[i] * level, -1.0, 1.0) * 32000.0))
	return _wav(bytes)


func _wav(bytes: PackedByteArray) -> AudioStreamWAV:
	var n := bytes.size() >> 1
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


## A saw or square note (band-limited with PolyBLEP) through a two-pole low-pass whose cutoff opens by
## `sweep` times at the attack and closes again, for a plucked edge. `vibrato` is its depth (a fraction of
## the pitch) at 5.5 Hz, fading in. Wraps like _add_voice.
func _add_synth(buf: PackedFloat32Array, start_sec: float, len_sec: float, f: float, gain: float, kind: String, attack: float, release_at: float, cutoff: float, sweep: float, vibrato: float) -> void:
	var n := buf.size()
	var start := int(start_sec * RATE)
	var count := int(len_sec * RATE)
	var ph := 0.0
	var lp1 := 0.0
	var lp2 := 0.0
	for i in count:
		var tt := float(i) / RATE
		var inc := f * (1.0 + vibrato * minf(1.0, tt / 0.4) * sin(TAU * 5.5 * tt)) / RATE
		var v := 0.0
		if kind == "square":
			v = (1.0 if ph < 0.5 else -1.0) + _blep(ph, inc) - _blep(fmod(ph + 0.5, 1.0), inc)
		else:
			v = 2.0 * ph - 1.0 - _blep(ph, inc)
		var fc := minf(cutoff * (1.0 + sweep * exp(-tt * 14.0)), RATE * 0.45)
		var a := 1.0 - exp(-TAU * fc / RATE)
		lp1 += a * (v - lp1)
		lp2 += a * (lp1 - lp2)
		var env := minf(1.0, tt / attack)
		if tt >= release_at:
			env *= maxf(0.0, 1.0 - (tt - release_at) / maxf(0.001, len_sec - release_at))
		buf[(start + i) % n] += lp2 * env * gain
		ph += inc
		if ph >= 1.0:
			ph -= 1.0


## PolyBLEP correction around a waveform's jump at phase 0, which keeps saw and square from aliasing.
static func _blep(ph: float, inc: float) -> float:
	if ph < inc:
		var x := ph / inc
		return x + x - x * x - 1.0
	if ph > 1.0 - inc:
		var x := (ph - 1.0) / inc
		return x * x + x + x + 1.0
	return 0.0


## Drum hits from filtered noise. "kick": a sine that drops from 150 Hz to about 45 Hz under a low-passed
## noise thump. "hat": high-passed noise with a very short decay.
func _add_perc(buf: PackedFloat32Array, start_sec: float, kind: String, gain: float, noise: RandomNumberGenerator) -> void:
	var n := buf.size()
	var start := int(start_sec * RATE)
	var kick := kind == "kick"
	var count := int((0.32 if kick else 0.07) * RATE)
	var ph := 0.0
	var lp := 0.0
	for i in count:
		var tt := float(i) / RATE
		var x := noise.randf_range(-1.0, 1.0)
		var v := 0.0
		if kick:
			lp += 0.08 * (x - lp)
			v = sin(TAU * ph) * exp(-tt * 9.0) + lp * 2.5 * exp(-tt * 60.0)
			ph = fmod(ph + (45.0 + 105.0 * exp(-tt * 28.0)) / RATE, 1.0)
		else:
			lp += 0.35 * (x - lp)
			v = (x - lp) * exp(-tt * 55.0)
		buf[(start + i) % n] += v * gain
