class_name Sim
extends RefCounted
## One step of the whole game. Pure: takes the state and a time slice, returns events. The Game autoload
## calls this every frame; Offline calls the same systems with large slices.


static func step(s: Dictionary, dt_sec: float, rng: RandomNumberGenerator) -> Array:
	if dt_sec <= 0.0:
		return []
	var t0 := Perf.begin()
	var events := Skills.step(s, dt_sec * 1000.0, rng, false)
	var t1 := Perf.begin()
	Perf.end("sim.skills", t0)
	Economy.step(s, dt_sec)
	var t2 := Perf.begin()
	Perf.end("sim.economy", t1)
	events.append_array(Expedition.step(s, dt_sec * 1000.0, rng))
	var t3 := Perf.begin()
	Perf.end("sim.expedition", t2)
	Market.tick(s, dt_sec)
	s.playSeconds = float(s.playSeconds) + dt_sec
	var t4 := Perf.begin()
	Perf.end("sim.market", t3)
	events.append_array(Achievements.tick(s, dt_sec))
	Perf.end("sim.achievements", t4)
	Perf.end("sim.step", t0)
	return events
