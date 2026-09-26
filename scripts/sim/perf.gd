class_name Perf
extends RefCounted
## Timing metrics: how long each part of the game takes, measured while it runs.
##   var t0 := Perf.begin()
##   ... work ...
##   Perf.end("sim.skills", t0)
## Each name keeps a count, total, max and the last RING samples (for the median and the 95th percentile).
## Reports: Developer tools > Timings, the test bridge's `perf` command, and the probes.
## Pure bookkeeping on the clock: no nodes, no game state, so the sim can use it. About a microsecond a call.

const RING := 240

static var enabled := true
static var _stats := {}      # name -> {n, total, max, last, ring: PackedFloat32Array, at}
static var _since_usec := Time.get_ticks_usec()


static func begin() -> int:
	return Time.get_ticks_usec() if enabled else 0


## Records the time since `t0` (from begin()) under `metric`, in milliseconds. Returns it.
static func end(metric: String, t0: int) -> float:
	if not enabled:
		return 0.0
	var ms := (Time.get_ticks_usec() - t0) / 1000.0
	sample(metric, ms)
	return ms


## Records one value (milliseconds) under `metric`: for times measured elsewhere, like a frame's length.
static func sample(metric: String, ms: float) -> void:
	if not enabled:
		return
	var st: Dictionary = _stats.get(metric, {})
	if st.is_empty():
		var ring := PackedFloat32Array()
		ring.resize(RING)
		st = {"n": 0, "total": 0.0, "max": 0.0, "last": 0.0, "ring": ring, "at": 0}
		_stats[metric] = st
	st.n += 1
	st.total += ms
	st.last = ms
	if ms > st.max:
		st.max = ms
	var r: PackedFloat32Array = st.ring
	r[st.at] = ms
	st.at = (int(st.at) + 1) % RING


static func reset() -> void:
	_stats.clear()
	_since_usec = Time.get_ticks_usec()


static func has(metric: String) -> bool:
	return _stats.has(metric)


## One row per metric, the most total time first: {name, n, total, avg, median, p95, max, last} (ms), and
## `share`, the part of the wall-clock time since the last reset it took.
static func report(prefix := "") -> Array:
	var wall := maxf(0.001, (Time.get_ticks_usec() - _since_usec) / 1000.0)
	var rows := []
	for metric in _stats:
		if prefix != "" and not String(metric).begins_with(prefix):
			continue
		var st: Dictionary = _stats[metric]
		var kept := mini(int(st.n), RING)
		var recent: Array = Array(st.ring).slice(0, kept)
		recent.sort()
		rows.append({"name": metric, "n": int(st.n), "total": float(st.total), "avg": float(st.total) / maxf(1.0, st.n),
			"median": _pct(recent, 0.5), "p95": _pct(recent, 0.95), "max": float(st.max), "last": float(st.last),
			"share": float(st.total) / wall})
	rows.sort_custom(func(a, b): return a.total > b.total)
	return rows


## The report as fixed-width text (the bridge, the probes and the log print this).
static func table(prefix := "") -> String:
	var lines := ["%-36s %8s %10s %8s %8s %8s %8s %7s" % ["metric", "calls", "total ms", "avg", "median", "p95", "max", "share"]]
	for r in report(prefix):
		lines.append("%-36s %8d %10.1f %8.3f %8.3f %8.3f %8.2f %6.2f%%" % [r.name, r.n, r.total, r.avg, r.median, r.p95, r.max, r.share * 100.0])
	return "\n".join(lines)


static func _pct(sorted: Array, q: float) -> float:
	if sorted.is_empty():
		return 0.0
	return float(sorted[mini(sorted.size() - 1, int(floor(q * sorted.size())))])
