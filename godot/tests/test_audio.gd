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
