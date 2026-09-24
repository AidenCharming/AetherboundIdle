class_name Sim
extends RefCounted
## One step of the whole game. Pure: takes the state and a time slice, returns events. The Game autoload
## calls this every frame; Offline calls the same systems with large slices.


static func step(s: Dictionary, dt_sec: float, rng: RandomNumberGenerator) -> Array:
	if dt_sec <= 0.0:
		return []
	var events := Skills.step(s, dt_sec * 1000.0, rng, false)
	Economy.step(s, dt_sec)
	events.append_array(Expedition.step(s, dt_sec * 1000.0, rng))
	Market.tick(s, dt_sec)
	s.playSeconds = float(s.playSeconds) + dt_sec
	return events
