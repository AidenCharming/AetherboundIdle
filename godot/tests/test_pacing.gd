extends RefCounted
## Pacing guard: a lone Dim starter on Woodcutting, always on the best tier it has unlocked, run through the
## real sim. If a retune moves these landmarks far, this fails on purpose; update the numbers here and the
## pacing notes in docs/DECISIONS.md together.

var t


func _time_to(levels: Array) -> Dictionary:
	var s := GameState.new_game()
	var c: Dictionary = s.creatures.values()[0]
	Skills.assign(s, c, "woodcutting")
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var out := {}
	var elapsed := 0.0
	var step := 10.0
	while elapsed < 60.0 * 3600.0 and out.size() < levels.size():
		var best: Dictionary = {}
		for a in Data.skills.woodcutting.actions:
			if int(a.level) <= int(s.skills.woodcutting.level):
				best = a
		s.skills.woodcutting.action = best.id
		Skills.step(s, step * 1000.0, rng)
		elapsed += step
		for lv in levels:
			if not out.has(lv) and int(s.skills.woodcutting.level) >= lv:
				out[lv] = elapsed
	return out


func test_lone_starter_landmarks() -> void:
	var m := _time_to([2, 10, 30])
	t.ok(m.get(2, 1e9) <= 30.0, "first level-up in %ss" % m.get(2))
	t.ok(m.get(10, 1e9) >= 10 * 60.0 and m.get(10, 1e9) <= 40 * 60.0, "level 10 at %s" % F.format_seconds(m.get(10, 0)))
	t.ok(m.get(30, 1e9) >= 10 * 3600.0 and m.get(30, 1e9) <= 26 * 3600.0, "level 30 at %s" % F.format_seconds(m.get(30, 0)))
