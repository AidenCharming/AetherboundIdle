extends Node
## Development probe (not a test): a dedicated player's first weeks, run through the real sim, to check the
## one-month pacing target (every skill near 99, Zenith Spire cleared, a party in the 90s).
##   godot --headless --path godot res://tests/month_probe.tscn [-- --days=35]
##
## The player it models:
## - keeps every open work slot filled with a specialist of that skill (a base species whose primary skill it
##   is), and gathers what the crafting skills need: a skill makes whichever of its unlocked items is short
##   for a skill further down the chain, otherwise its best tier;
## - breeds workers up to one rarity below what their material tier allows (the party gets the full cap), a
##   day behind the materials;
## - spends half of its Aether income on breeding (the other half is there for Aether-Weaving), and buys
##   perches and the Resonance Extractor over the month;
## - fights the hardest island its party can clear; the party's XP comes from short real battles (cached),
##   so the combat side is measured, not guessed.

const STEP_MIN := 10.0
## A specialist per skill; scavenging and fabrication take any type.
const WORKER := {"woodcutting": "sproutlet", "herbalism": "mossgear", "mining": "tuskcub", "fishing": "dewdrop",
	"scavenging": "pebblescoot", "smithing": "emberfang", "cooking": "roastbelly", "circuitry": "voltfluff",
	"aether-weaving": "eclipsa", "vessel-crafting": "riftsneak", "fabrication": "geodecore"}
## Skills whose output feeds another skill (they switch tiers to cover demand).
const FEEDERS := ["woodcutting", "herbalism", "mining", "fishing", "scavenging", "smithing", "aether-weaving"]
const TRACE_SKILL := "herbalism"
const PARTY := ["tuskcub", "emberfang", "dewdrop"]

var days := 35
var _combat_cache := {}


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--days="):
			days = int(a.substr(7))
	var t0 := Time.get_ticks_msec()
	if "--split" in OS.get_cmdline_user_args():
		split()
		get_tree().quit()
		return
	if "--calibrate" in OS.get_cmdline_user_args():
		calibrate()
		get_tree().quit()
		return
	var timeline := run_skills()
	if "--rates" in OS.get_cmdline_user_args():
		party_rates(timeline)
	elif not "--skills" in OS.get_cmdline_user_args():
		run_party(timeline)
	print("\n(probe took %.1f s)" % ((Time.get_ticks_msec() - t0) / 1000.0))
	get_tree().quit()


## Egg tier whose materials the player can make: most tiered skills must have opened it.
static func material_tier(s: Dictionary) -> int:
	var levels := []
	for id in ["woodcutting", "mining", "fishing", "smithing", "circuitry", "aether-weaving"]:
		levels.append(int(s.skills[id].level))
	levels.sort()
	var lv: int = levels[2]   # the fourth-best of six: most element materials are available
	var tier := 1
	for a in Data.skills.woodcutting.actions:
		if int(a.level) <= lv:
			tier = int(Data.items[a.id].tier)
	return mini(tier, Breeding.tier_count())


func run_skills() -> Array:
	var s := GameState.new_game()
	s.creatures.clear()
	s.items.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var workers := {}   # skill -> [creature]
	for id in WORKER:
		workers[id] = []
	var timeline := []   # per day: {day, levels, cap, worker_rarity, aether_min, duty}
	var cap_history := [2]
	var steps_per_day := int(24.0 * 60.0 / STEP_MIN)
	var busy := {}
	var reached := {}
	var trace := [0.0]   # TRACE_SKILL: day each level was reached
	for id in WORKER:
		reached[id] = {}
	for day in days:
		var cap_today: int = cap_history[maxi(0, cap_history.size() - 2)]   # a day behind the materials
		var worker_r := maxi(1, cap_today - 1)
		# Sanctum upgrades bought over the month
		var perches := mini(16, 4 + floori(day / 2.0))
		var extractor: float = [0, 5, 15, 35, 75, 150, 300, 600][mini(7, floori(day / 3.0))]
		var aether_min := perches * float(Data.rarity(worker_r).benchAetherPerMin) + extractor
		for id in WORKER:
			busy[id] = 0.0
		for step in steps_per_day:
			# fill open slots, and breed replacements up to the current rarity
			for id in WORKER:
				var list: Array = workers[id]
				while list.size() < GameState.slot_count(s, id):
					var c := Creatures.make(s, WORKER[id], worker_r, 1, false, [], "probe")
					s.creatures[c.id] = c
					Skills.assign(s, c, id)
					list.append(c)
				for c in list:
					if int(c.rarity) < worker_r:
						c.rarity = worker_r
			s.aether = float(s.aether) + aether_min * 0.5 * STEP_MIN
			_choose_actions(s)
			var before := {}
			for id in WORKER:
				before[id] = float(s.skills[id].xp)
			Skills.step(s, STEP_MIN * 60000.0, rng)
			for id in WORKER:
				if float(s.skills[id].xp) > before[id]:
					busy[id] += 1.0
				var lv := int(s.skills[id].level)
				if id == TRACE_SKILL and lv > int(trace.size()):
					while trace.size() < lv:
						trace.append(day + float(step + 1) / steps_per_day)
				for mark in [10, 30, 50, 70, 90, 99]:
					if lv >= mark and not reached[id].has(mark):
						reached[id][mark] = day + float(step) / steps_per_day
		cap_history.append(Breeding.ceiling(material_tier(s)))
		var levels := {}
		var duty := {}
		for id in WORKER:
			levels[id] = int(s.skills[id].level)
			duty[id] = busy[id] / steps_per_day
		timeline.append({"day": day + 1, "levels": levels, "cap": cap_today, "worker_r": worker_r, "aether_min": aether_min,
			"duty": duty, "tier": material_tier(s)})
	# report
	print("Skills (day each level was reached; duty = share of the last day spent working):")
	print("%-16s %6s %6s %6s %6s %6s %6s   %s" % ["skill", "10", "30", "50", "70", "90", "99", "duty"])
	for id in WORKER:
		var row := "%-16s" % id
		for mark in [10, 30, 50, 70, 90, 99]:
			row += " %6s" % ("%.1f" % reached[id][mark] if reached[id].has(mark) else "-")
		row += "   %.0f%%" % (timeline.back().duty[id] * 100.0)
		print(row)
	print("\nday  tier cap  worker-rarity  aether/min  levels (wc he mi fi sc sm co ci we ve fa)")
	for d in timeline:
		if d.day % 3 == 0 or d.day == 1:
			var lv := []
			for id in WORKER:
				lv.append("%2d" % d.levels[id])
			print("%3d  %4d %3s  %-12s  %9.0f  %s" % [d.day, d.tier, Data.rarity(d.cap).name.left(3), Data.rarity(d.worker_r).name, d.aether_min, " ".join(lv)])
	if "--trace" in OS.get_cmdline_user_args():
		print("TRACE " + ",".join(trace.map(func(x): return "%.4f" % x)))
	return timeline


## Picks each skill's action for the next step, as a player keeping the chains fed would: demand starts from
## every skill's best tier and flows back up the chain (a feeder making something for another skill adds that
## recipe's inputs to the demand), a few passes deep.
func _choose_actions(s: Dictionary) -> void:
	var chosen := {}
	for id in WORKER:
		chosen[id] = _best_unlocked(s, id)
	for pass_i in 3:
		var demand := {}
		for id in WORKER:
			var a: Dictionary = chosen[id]
			var per_h := 0.0
			for c in GameState.workers(s, id):
				per_h += 3600000.0 / Skills.worker_cooldown(c, id, a, [])
			for inp in a.get("inputs", {}):
				demand[inp] = float(demand.get(inp, 0.0)) + per_h * float(a.inputs[inp])
		for id in FEEDERS:
			var worst := 1.0
			var pick: Dictionary = {}
			for a in Data.skills[id].actions:
				if int(a.level) > int(s.skills[id].level):
					continue
				var out: String = a.outputs.keys()[0]
				var need: float = demand.get(out, 0.0)
				if need <= 0.0:
					continue
				var ratio := GameState.count(s, out) / need
				if ratio < worst:
					worst = ratio
					pick = a
			chosen[id] = pick if not pick.is_empty() else _best_unlocked(s, id)
	for id in WORKER:
		var a: Dictionary = chosen[id]
		if Skills.affordable(s, a) <= 0:
			# fall back to the best tier it can afford
			var acts: Array = Data.skills[id].actions.duplicate()
			acts.reverse()
			a = {}
			for b in acts:
				if int(b.level) <= int(s.skills[id].level) and Skills.affordable(s, b) > 0:
					a = b
					break
		if not a.is_empty():
			s.skills[id].action = a.id


static func _best_unlocked(s: Dictionary, id: String) -> Dictionary:
	var best: Dictionary = Data.skills[id].actions[0]
	for a in Data.skills[id].actions:
		if int(a.level) <= int(s.skills[id].level):
			best = a
	return best


# ---------------------------------------------------------------- the party

## Walks a party through the islands hour by hour: it fights the hardest island it can clear (2 of 2 real
## runs won) at the rarity cap of that day, and gains the XP those runs measured.
func run_party(timeline: Array) -> void:
	var level := 1.0
	var unlocked := 1
	var cleared := {}
	var curve := F.creature_curve()
	var max_lv: int = Data.tuning.creature.maxLevel
	var xp := 0.0
	var ptrace := [0.0]   # day each party level was reached
	print("\nParty (%s), fighting the hardest island it can clear:" % ", ".join(PARTY))
	print("day  rarity       level  island")
	for d in timeline:
		var zone_i := 0
		for hour in 24:
			var lv := int(level)
			zone_i = 0
			var rate := 0.0
			for zi in unlocked:
				var r := _combat(Data.zone_list[zi].id, d.cap, lv)
				if r.wins >= 2:
					zone_i = zi
					rate = r.xp_per_sec
			if not cleared.has(zone_i) and _combat(Data.zone_list[zone_i].id, d.cap, lv).wins >= 2:
				cleared[zone_i] = d.day
				unlocked = mini(Data.zone_list.size(), maxi(unlocked, zone_i + 2))
			if rate <= 0.0:
				rate = _combat(Data.zone_list[0].id, d.cap, lv).xp_per_sec * 0.5
			xp += rate * 3600.0
			level = F.level_for_xp(curve, xp, max_lv)
			while ptrace.size() < int(level):
				ptrace.append(d.day - 1 + (hour + 1) / 24.0)
		if d.day % 3 == 0 or d.day == 1:
			print("%3d  %-11s  %5d  %s" % [d.day, Data.rarity(d.cap).name, int(level), Data.zone_list[zone_i].name])
	if "--trace" in OS.get_cmdline_user_args():
		print("PTRACE " + ",".join(ptrace.map(func(x): return "%.4f" % x)))
	print("\nIslands first cleared (day):")
	for zi in Data.zone_list.size():
		print("  %-20s %s" % [Data.zone_list[zi].name, str(cleared.get(zi, "-"))])


## For curve fitting: at each party level, the XP per second (per member) at the hardest island a party of
## that level clears, at the rarity cap of the day that level is due (the target below, same as the skills').
func party_rates(timeline: Array) -> void:
	var pts := [[1, 0.0], [10, 0.04], [20, 0.17], [30, 0.5], [40, 1.5], [50, 3.5], [60, 6.5], [70, 10.5], [80, 16.0], [90, 22.5], [100, 30.0]]
	var out := []
	for lv in range(1, 101, 3):
		var day := 0.0
		for i in pts.size() - 1:
			if lv >= pts[i][0] and lv <= pts[i + 1][0]:
				var f := float(lv - pts[i][0]) / float(pts[i + 1][0] - pts[i][0])
				day = lerpf(pts[i][1], pts[i + 1][1], f)
		var cap: int = timeline[mini(timeline.size() - 1, int(day))].cap
		var best := {"zone": "-", "rate": 0.0}
		for z in Data.zone_list:
			var r := _combat(z.id, cap, lv)
			if r.wins >= 2:
				best = {"zone": z.id, "rate": r.xp_per_sec}
		if best.rate <= 0.0:
			best.rate = _combat(Data.zone_list[0].id, cap, lv).xp_per_sec * 0.5
		out.append("%d:%.4f" % [lv, best.rate * 86400.0])
		print("level %3d  day %5.2f  %-11s  %-20s  %.0f xp/day" % [lv, day, Data.rarity(cap).name, best.zone, best.rate * 86400.0])
	print("RATES " + ",".join(out))


## For tuning island difficulty: for each island, the strength factor (on its wild enemies' enemyMult and
## its boss's mult) at which the target party only just stops winning, and a suggestion at 80% of that, with
## a check that a party one rarity weaker loses there.
const CAL_TARGETS := {"whisperleaf-hollow": [1, 4], "fractured-quarry": [1, 12], "smoldering-caldera": [2, 23],
	"whispering-tides": [3, 35], "thunderhum-steppe": [4, 45], "null-horizon": [5, 56], "verdigris-canopy": [5, 65],
	"magmaglass-rift": [6, 74], "stormsea-expanse": [7, 83], "zenith-spire": [9, 92]}


func calibrate() -> void:
	for zid in CAL_TARGETS:
		var z: Dictionary = Data.zones[zid]
		var em0: float = z.enemyMult
		var bm0: Dictionary = z.boss.mult.duplicate()
		var tgt: Array = CAL_TARGETS[zid]
		var lo := 0.2
		var hi := 30.0
		for i in 12:
			var mid := sqrt(lo * hi)
			_scale_zone(z, em0, bm0, mid)
			_combat_cache.clear()
			if _combat(zid, tgt[0], tgt[1], 3).wins >= 3:
				lo = mid
			else:
				hi = mid
		var pick := lo * 0.8
		_scale_zone(z, em0, bm0, pick)
		_combat_cache.clear()
		var weaker: int = _combat(zid, maxi(1, tgt[0] - 1), tgt[1], 3).wins
		var lower: int = _combat(zid, tgt[0], maxi(1, tgt[1] - 8), 3).wins
		print("%-20s target %-11s lv %2d  breaks at x%.2f  suggest x%.2f (enemyMult %.2f)  one rarity weaker wins %d/3, 8 levels lower wins %d/3" % [
			zid, Data.rarity(tgt[0]).name, tgt[1], lo, pick, em0 * pick, weaker, lower])
		_scale_zone(z, em0, bm0, 1.0)


## Waves against boss, per island: for the calibration party, how much stronger the waves alone (boss made
## trivial) and the boss alone (waves made trivial) can get before that party stops winning. A boss that
## breaks far above its waves is a pushover once the waves are cleared; an island whose waves break well
## below its neighbours' is a wall.
func split() -> void:
	print("island               target         waves break at  boss breaks at  boss/waves")
	for zid in CAL_TARGETS:
		var z: Dictionary = Data.zones[zid]
		var em0: float = z.enemyMult
		var bm0: Dictionary = z.boss.mult.duplicate()
		var tgt: Array = CAL_TARGETS[zid]
		var out := []
		for part in ["waves", "boss"]:
			var lo := 0.05
			var hi := 40.0
			for i in 12:
				var mid := sqrt(lo * hi)
				z.enemyMult = em0 * (mid if part == "waves" else 0.01)
				for k in bm0:
					z.boss.mult[k] = float(bm0[k]) * (0.01 if part == "waves" else mid)
				_combat_cache.clear()
				if _combat(zid, tgt[0], tgt[1], 3).wins >= 2:
					lo = mid
				else:
					hi = mid
			out.append(lo)
		_scale_zone(z, em0, bm0, 1.0)
		print("%-20s %-10s lv %2d  x%-14.2f x%-14.2f %.2f" % [zid, Data.rarity(tgt[0]).name, tgt[1], out[0], out[1], out[1] / out[0]])


func _scale_zone(z: Dictionary, em0: float, bm0: Dictionary, f: float) -> void:
	z.enemyMult = em0 * f
	for k in bm0:
		z.boss.mult[k] = float(bm0[k]) * f


## Two real runs of an island for this party (cached on a grid of levels): wins, XP per second per member.
func _combat(zone: String, rarity: int, level: int, runs := 2) -> Dictionary:
	var lv := maxi(1, floori(level / 3.0) * 3)
	var key := "%s|%d|%d|%d" % [zone, rarity, lv, runs]
	if _combat_cache.has(key):
		return _combat_cache[key]
	var wins := 0
	var xp := 0.0
	var secs := 0.0
	for r in runs:
		var s := GameState.new_game()
		s.creatures.clear()
		s.items.clear()
		var rng := RandomNumberGenerator.new()
		rng.seed = r * 31 + 7
		var i := 0
		for sp in PARTY:
			var c := Creatures.make(s, sp, rarity, lv, false, [], "probe")
			s.creatures[c.id] = c
			Expedition.set_party_member(s, i, c)
			i += 1
		# the party carries meals of its tier, as a player would cook
		var zi := Data.zone_list.find(Data.zones[zone])
		var meal_id: String = Data.skills.cooking.actions[mini(zi, Data.skills.cooking.actions.size() - 1)].id
		GameState.add_item(s, meal_id, 50)
		s.expedition.autoRepeat = false
		for z in Data.zone_list:
			s.expedition.zones[z.id] = {"cleared": true, "runs": 0, "bestWave": 0, "kills": 0}
		var lead: Dictionary = s.creatures[s.expedition.party[0]]
		lead.xp = F.xp_for_level(F.creature_curve(), lv, Data.tuning.creature.maxLevel)
		var xp0 := float(lead.xp)
		Expedition.start(s, zone, rng)
		var t := 0.0
		var won := false
		while Expedition.is_running(s) and t < 1200000.0:
			var ev := Expedition.step(s, 250.0, rng)
			t += 250.0
			for e in ev:
				if e.type == "run_complete":
					won = true
				if e.type in ["run_complete", "wiped"]:
					Expedition.stop(s)
		# a wipe waits out exhaustion before the next try
		secs += t / 1000.0 + (0.0 if won else float(Data.tuning.combat.exhaustMs) / 1000.0)
		xp += float(lead.xp) - xp0
		wins += 1 if won else 0
	var res := {"wins": wins, "xp_per_sec": xp / maxf(1.0, secs)}
	_combat_cache[key] = res
	return res
