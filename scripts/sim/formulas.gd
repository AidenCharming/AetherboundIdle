class_name F
extends RefCounted
## Pure formulas over tuning numbers: XP curves, stats, cooldowns. Every constant comes from data/tuning.json.

static var _tables: Dictionary = {}


# ---------------------------------------------------------------- XP curves

## XP to go from `level` to `level + 1`: base × level^power × growth^(level-1). The polynomial part keeps
## the early game quick and the exponential part stretches the late game; power defaults to 0.
static func xp_to_next(curve: Dictionary, level: int) -> float:
	return roundf(curve.base * pow(level, float(curve.get("power", 0.0))) * pow(curve.growth, level - 1))


static func _table(curve: Dictionary, max_level: int) -> PackedFloat64Array:
	var key := "%s|%s|%s|%d" % [curve.base, curve.growth, curve.get("power", 0.0), max_level]
	if _tables.has(key):
		return _tables[key]
	var t := PackedFloat64Array()
	t.resize(max_level + 1)
	t[0] = 0.0
	t[1] = 0.0
	for lv in range(2, max_level + 1):
		t[lv] = t[lv - 1] + xp_to_next(curve, lv - 1)
	_tables[key] = t
	return t


## Cumulative XP at which `level` is reached.
static func xp_for_level(curve: Dictionary, level: int, max_level: int) -> float:
	return _table(curve, max_level)[clampi(level, 1, max_level)]


static func level_for_xp(curve: Dictionary, xp: float, max_level: int) -> int:
	var t := _table(curve, max_level)
	if xp <= 0.0:
		return 1
	var lo := 1
	var hi := max_level
	while lo < hi:
		var mid := (lo + hi + 1) >> 1
		if t[mid] <= xp:
			lo = mid
		else:
			hi = mid - 1
	return lo


## 0..1 progress through the current level.
static func level_progress(curve: Dictionary, xp: float, max_level: int) -> float:
	var lv := level_for_xp(curve, xp, max_level)
	if lv >= max_level:
		return 1.0
	var a := xp_for_level(curve, lv, max_level)
	var b := xp_for_level(curve, lv + 1, max_level)
	return clampf((xp - a) / maxf(1.0, b - a), 0.0, 1.0)


static func skill_curve() -> Dictionary:
	return Data.tuning.skills.xpCurve


static func creature_curve() -> Dictionary:
	return Data.tuning.creature.xpCurve


# ---------------------------------------------------------------- forms and stats

static func form_for_level(level: int) -> int:
	var levels: Array = Data.tuning.creature.formLevels
	var form := 1
	for i in levels.size():
		if level >= int(levels[i]):
			form = i + 1
	return form


## One stat for a creature. `trait_bonus` is the capped bonus_<stat> total.
static func stat_value(stat: String, lean: String, level: int, rarity_tier: int, form: int, trait_bonus: float, shiny: bool) -> float:
	var c: Dictionary = Data.tuning.creature
	var lean_mult: float = c.leaned if stat == lean else c.other
	var v: float = c.baseStats[stat] * lean_mult * (1.0 + c.statPerLevel * (level - 1))
	v *= Data.rarity(rarity_tier).statMultiplier * c.formStatMult[form - 1] * (1.0 + trait_bonus)
	if shiny:
		v *= 1.0 + Data.tuning.shiny.statBonus
	return v


## Level, rarity and form speed-up as a divisor term (hyperbolic, so diminishing returns).
static func intrinsic_term(level: int, rarity_tier: int, form: int) -> float:
	var cd: Dictionary = Data.tuning.cooldown
	return cd.levelTerm * (level - 1) + cd.rarityTerm * (rarity_tier - 1) + cd.formTerm[form - 1]


## Action time in ms. `efficiency` divides the base (higher is better). `reduction` is the capped
## cooldown_reduction total. The floor comes from the efficiency-adjusted base, so a creature working
## outside its specialty can never reach a specialist's speed.
static func cooldown_ms(base_ms: float, efficiency: float, level: int, rarity_tier: int, form: int, reduction: float) -> float:
	var adjusted := base_ms / maxf(0.01, efficiency)
	var raw := adjusted / (1.0 + intrinsic_term(level, rarity_tier, form)) * (1.0 - reduction)
	return maxf(raw, adjusted * Data.tuning.cooldown.floorFraction)


static func format_ms(ms: float) -> String:
	return format_seconds(ms / 1000.0, true)


static func format_seconds(sec: float, fractional := false) -> String:
	if sec < 0:
		sec = 0
	if sec < 60:
		return ("%.1fs" % sec) if fractional and sec < 10 else "%ds" % int(ceil(sec))
	var s := int(sec)
	if s < 3600:
		return "%dm %02ds" % [floori(s / 60.0), s % 60]
	if s < 86400:
		return "%dh %02dm" % [floori(s / 3600.0), floori((s % 3600) / 60.0)]
	return "%dd %02dh" % [floori(s / 86400.0), floori((s % 86400) / 3600.0)]


static func format_num(v: float) -> String:
	var a := absf(v)
	if a < 1000:
		return str(int(floor(v))) if a >= 10 or is_equal_approx(v, floorf(v)) else "%.1f" % v
	var units := ["K", "M", "B", "T"]
	var i := -1
	while a >= 1000 and i < units.size() - 1:
		a /= 1000.0
		i += 1
	var minus := "-" if v < 0 else ""
	return minus + ("%.2f" % a if a < 10 else "%.1f" % a if a < 100 else "%d" % int(a)) + units[i]


static func pct(v: float) -> String:
	var p := v * 100.0
	if p >= 10 or is_equal_approx(p, roundf(p)):
		return "%d%%" % roundi(p)
	return "%.1f%%" % p
