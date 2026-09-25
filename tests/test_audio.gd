extends RefCounted
## Music and sound effects. Nothing plays headless, so these check what gets rendered and what gets asked for.

var t


func test_boss_track_is_faster_and_brighter_than_expedition() -> void:
	var boss: Dictionary = Music.TRACKS.boss
	var calm: Dictionary = Music.TRACKS.expedition
	t.ok(float(boss.bpm) > float(calm.bpm), "faster")
	t.ok(float(boss.bright) > float(calm.bright), "brighter")
	t.ok(int(boss.beats_per_chord) < int(calm.beats_per_chord), "chords change more often")
	t.ok(boss.has("lead") and boss.has("kick") and boss.has("hat"), "a lead and drums")


func test_music_bus_has_echo_and_reverb() -> void:
	var bus := AudioServer.get_bus_index("Music")
	t.ok(bus >= 0, "Music bus exists")
	var kinds := []
	for i in AudioServer.get_bus_effect_count(bus):
		kinds.append(AudioServer.get_bus_effect(bus, i).get_class())
	t.ok("AudioEffectReverb" in kinds, "reverb on the Music bus: %s" % [kinds])
	t.ok("AudioEffectDelay" in kinds, "echo on the Music bus")


## A tiny made-up track renders quickly and exercises every voice: pad, bell, saw, square lead, pulse bass,
## kick and hat.
func _tiny(kind: String) -> Dictionary:
	return {"bpm": 240, "beats_per_chord": 1, "chords": [[48, 55, 60, 64, 67], [45, 52, 57, 60, 64]],
		"arp": [0, -1, 4, 2], "arp_oct": 12, "arp_div": 2, "arp_kind": kind, "bright": 1.0, "bass": "pulse",
		"lead": {"kind": "square", "gain": 0.05, "tone": 4, "oct": 0}, "kick": "x...", "hat": "..x."}


func test_a_loop_plays_the_chords_once_per_section_and_the_sections_differ() -> void:
	for kind in ["bell", "saw"]:
		var w: AudioStreamWAV = Music._render(_tiny(kind))
		var pass_n := int(0.5 * Music.RATE)   # two chords of one beat at 240 bpm
		var n := w.data.size() >> 1
		t.eq(n, pass_n * Music.FORM.size(), "%s: one pass per section" % kind)
		t.eq(w.loop_mode, AudioStreamWAV.LOOP_FORWARD)
		t.eq(w.loop_end, n)
		var b := Music.FORM.find("B")
		var diff := 0.0
		for i in range(0, pass_n, 7):
			diff += absf(w.data.decode_s16(i * 2) - w.data.decode_s16((b * pass_n + i) * 2))
		t.ok(diff > 1000.0, "%s: the B section is not a copy of A" % kind)


func test_evolve_sound_exists_and_outlasts_hatch() -> void:
	t.ok(Sfx._streams.has("evolve"))
	t.ok(Sfx._streams.evolve.data.size() > Sfx._streams.hatch.data.size())


## Switching screens quickly (sanctum → expeditions → sanctum inside one crossfade) must leave a track
## playing: the first fade's stop call used to silence the player the second switch had just reused.
func test_quick_switch_back_keeps_music_playing() -> void:
	var saved := [Music._streams, Music._current, Music._wanted, Music._active]
	var tone := func(hz: float) -> AudioStreamWAV:
		var w := AudioStreamWAV.new()
		w.format = AudioStreamWAV.FORMAT_16_BITS
		w.mix_rate = 22050
		var data := PackedByteArray()
		data.resize(22050 * 2)
		for i in 22050:
			data.encode_s16(i * 2, int(sin(TAU * hz * i / 22050.0) * 8000.0))
		w.data = data
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = 22050
		return w
	Music._streams = {"sanctum": tone.call(220.0), "expedition": tone.call(330.0)}
	Music._current = ""
	Music.play("sanctum")
	Music.play("expedition")
	Music.play("sanctum")   # back before the first fade has finished
	for tw in Music.get_tree().get_processed_tweens():
		tw.custom_step(30.0)
	var active: AudioStreamPlayer = Music._players[Music._active]
	var other: AudioStreamPlayer = Music._players[1 - Music._active]
	t.eq(active.stream, Music._streams.sanctum, "the Sanctum track is on the active player")
	t.ok(active.playing, "and it is still playing after every fade has run")
	t.near(active.volume_db, 0.0, 0.01, "at full volume")
	t.ok(not other.playing, "the track faded out has stopped")
	for p in Music._players:
		p.stop()
		p.volume_db = -80.0
	Music._streams = saved[0]
	Music._current = saved[1]
	Music._wanted = saved[2]
	Music._active = saved[3]


## Every type has its own hit and cast sound, and they sit at similar loudness (none drowns the others).
func test_each_type_has_its_own_attack_sounds() -> void:
	var rms := {}
	for ty in Data.types:
		for kind in ["hit_", "cast_"]:
			var id: String = kind + ty
			t.ok(Sfx._streams.has(id), "%s exists" % id)
			if not Sfx._streams.has(id):
				continue
			var w: AudioStreamWAV = Sfx._streams[id]
			var sum := 0.0
			var peak := 0.0
			var n := w.data.size() >> 1
			for i in n:
				var v := float(w.data.decode_s16(i * 2)) / 32000.0
				sum += v * v
				peak = maxf(peak, absf(v))
			rms[id] = sqrt(sum / maxf(1.0, n))
			t.ok(peak < 0.99, "%s does not clip (peak %.2f)" % [id, peak])
			t.ok(float(n) / Sfx.RATE < 0.6, "%s is short" % id)
	var hits: Array = Data.types.keys().map(func(ty): return float(rms.get("hit_" + ty, 0.0)))
	t.ok(hits.max() < hits.min() * 3.0, "hit sounds within 3x loudness of each other: %s" % [hits])
	var datas := {}
	for id in rms:
		datas[Sfx._streams[id].data] = true
	t.eq(datas.size(), rms.size(), "every attack sound is different")


func test_a_switched_off_kind_of_sound_stays_quiet() -> void:
	var was: Dictionary = Options.values.duplicate()
	for g: Array in Sfx.GROUPS:
		t.ok(Options.values.has(g[0]), "%s has an option" % g[0])
		t.eq(Sfx.group_of(g[2]), g[0], "%s previews its own kind" % g[2])
	t.eq(Sfx.group_of("hit_void"), "sfx_battle")
	t.eq(Sfx.group_of("cast_pyric"), "sfx_battle")
	t.eq(Sfx.group_of("shiny_appear"), "sfx_rare")
	t.eq(Sfx.group_of("coin"), "sfx_ui", "anything unlisted is an interface sound")
	Options.values.sfx_rare = false
	Sfx.play("click")
	Sfx.play("rare")
	t.eq(Sfx.last_played, "click", "a rare-find sound was not played")
	Options.values.sfx_rare = true
	Sfx.play("rare")
	t.eq(Sfx.last_played, "rare", "and plays again once switched back on")
	Options.values = was
