class_name Combat
extends RefCounted
## Automatic real-time combat between the party and a wave of wild Aetherlings. Fighters are plain
## Dictionaries so a battle in progress saves and loads with everything else. step() returns events the
## arena view animates (hits, abilities, heals, deaths); the numbers never depend on the view.

const SUBSTEP_MS := 100.0


static func tempo(t: String) -> Dictionary:
	return Data.tuning.combat.tempo[t]


static func attack_interval(level: int, rarity: int, form: int) -> float:
	var cb: Dictionary = Data.tuning.combat
	return maxf(float(cb.minAttackMs), float(cb.baseAttackMs) / (1.0 + F.intrinsic_term(level, rarity, form)))


## A party member as a fighter.
static func ally(c: Dictionary) -> Dictionary:
	var st := Creatures.stats(c)
	var sp: Dictionary = Data.species[c.species]
	var ab: Dictionary = Data.abilities[sp.ability]
	var form := Creatures.form_of(c)
	return _fighter({
		"cid": c.id, "species": c.species, "name": Creatures.display_name(c), "types": sp.types, "level": int(c.level),
		"rarity": int(c.rarity), "shiny": bool(c.shiny), "form": form, "maxHp": st.health, "power": st.power, "guard": st.guard,
		"ability": ab.id, "abCdMs": float(tempo(ab.tempo).cooldownMs) * (1.0 - Traits.capped_self(c, "ability_cooldown_reduction")),
		"atkMs": attack_interval(int(c.level), int(c.rarity), form),
	})


## A wild creature (or boss) as a fighter. `mult` scales its stats.
static func wild(species_id: String, level: int, rarity: int, shiny: bool, mult: Dictionary, name_override := "", ability_override := "", form_override := 0) -> Dictionary:
	var sp: Dictionary = Data.species[species_id]
	var form := form_override if form_override > 0 else F.form_for_level(level)
	var st := {}
	for k in ["health", "power", "guard"]:
		st[k] = F.stat_value(k, sp.statLean, level, rarity, form, 0.0, shiny) * float(mult.get(k, 1.0))
	var ab: Dictionary = Data.abilities[ability_override if ability_override != "" else sp.ability]
	return _fighter({
		"species": species_id, "name": name_override if name_override != "" else Data.form_name(species_id, form),
		"types": sp.types, "level": level, "rarity": rarity, "shiny": shiny, "form": form,
		"maxHp": st.health, "power": st.power, "guard": st.guard, "ability": ab.id,
		"abCdMs": float(tempo(ab.tempo).cooldownMs), "atkMs": attack_interval(level, rarity, form),
		"boss": name_override != "",
	})


static func _fighter(d: Dictionary) -> Dictionary:
	d.hp = d.maxHp
	d.alive = true
	d.shield = 0.0
	d.atkT = 0.0
	d.abT = 0.0
	d.buffPower = 0.0
	d.buffPowerT = 0.0
	d.buffGuard = 0.0
	d.buffGuardT = 0.0
	d.hotPerMs = 0.0
	d.hotT = 0.0
	d.thornsT = 0.0
	return d


# ---------------------------------------------------------------- type wheel

static func _beats(a: String, b: String) -> bool:
	return Data.types.has(a) and Data.types[a].beats == b


static func type_mult(atk_type: String, def_types: Array) -> float:
	var cb: Dictionary = Data.tuning.combat
	var m := 1.0
	if atk_type == "void":
		m *= cb.voidDealt
	else:
		for dt in def_types:
			if dt == "void":
				continue
			if _beats(atk_type, dt):
				m *= cb.wheelStrong
			elif _beats(dt, atk_type):
				m *= cb.wheelWeak
	if "void" in def_types:
		var taken: float = cb.voidTaken
		if def_types.size() > 1:
			taken = 1.0 - (1.0 - taken) * float(cb.voidHybridFraction)
		m *= taken
	return m


# ---------------------------------------------------------------- stepping

## Advances the fight. Returns events. Stops early when one side is wiped.
static func step(allies: Array, enemies: Array, dt_ms: float, rng: RandomNumberGenerator) -> Array:
	var events := []
	var left := dt_ms
	while left > 0.0:
		var d := minf(SUBSTEP_MS, left)
		left -= d
		_substep(allies, enemies, d, rng, events)
		if not any_alive(allies) or not any_alive(enemies):
			break
	return events


static func any_alive(side: Array) -> bool:
	for f in side:
		if f.alive:
			return true
	return false


static func _substep(allies: Array, enemies: Array, d: float, rng: RandomNumberGenerator, events: Array) -> void:
	for side in [0, 1]:
		var own: Array = allies if side == 0 else enemies
		var foe: Array = enemies if side == 0 else allies
		for i in own.size():
			var f: Dictionary = own[i]
			if not f.alive:
				continue
			_tick_status(f, d)
			if not any_alive(foe):
				return
			f.abT += d
			if f.abT >= f.abCdMs:
				if _use_ability(own, foe, side, i, rng, events):
					f.abT = 0.0
				else:
					f.abT = f.abCdMs
			f.atkT += d
			if f.atkT >= f.atkMs:
				f.atkT -= f.atkMs
				var t := _target(foe, side, rng)
				if t >= 0:
					_hit(f, foe[t], side, i, t, 1.0, f.types[0], "", rng, events)


static func _tick_status(f: Dictionary, d: float) -> void:
	for k in ["buffPower", "buffGuard"]:
		if f[k + "T"] > 0.0:
			f[k + "T"] = maxf(0.0, f[k + "T"] - d)
			if f[k + "T"] <= 0.0:
				f[k] = 0.0
	if f.hotT > 0.0:
		var h := minf(d, f.hotT)
		f.hp = minf(f.maxHp, f.hp + f.hotPerMs * h)
		f.hotT -= h
	if f.thornsT > 0.0:
		f.thornsT = maxf(0.0, f.thornsT - d)


## Allies focus the first standing enemy (easy to read); enemies pick a random standing ally.
static func _target(foe: Array, side: int, rng: RandomNumberGenerator) -> int:
	var alive := []
	for i in foe.size():
		if foe[i].alive:
			alive.append(i)
	if alive.is_empty():
		return -1
	return alive[0] if side == 0 else Rng.pick(rng, alive)


static func damage(att: Dictionary, def: Dictionary, mult: float, dmg_type: String, rng: RandomNumberGenerator) -> float:
	var cb: Dictionary = Data.tuning.combat
	var p: float = att.power * (1.0 + att.buffPower)
	var g: float = def.guard * (1.0 + def.buffGuard)
	var v := rng.randf_range(1.0 - cb.variance, 1.0 + cb.variance)
	return maxf(1.0, p * p / (p + g) * mult * type_mult(dmg_type, def.types) * v)


static func _hit(att: Dictionary, def: Dictionary, side: int, ai: int, di: int, mult: float, dmg_type: String, ability: String,
		rng: RandomNumberGenerator, events: Array) -> void:
	var dmg := damage(att, def, mult, dmg_type, rng)
	var absorbed := minf(def.shield, dmg)
	def.shield -= absorbed
	var through := dmg - absorbed
	def.hp -= through
	events.append({"type": "hit", "side": side, "from": ai, "to": di, "dmg": dmg, "absorbed": absorbed, "ability": ability,
		"eff": type_mult(dmg_type, def.types), "dtype": dmg_type})
	if def.thornsT > 0.0 and att.alive:
		var back: float = dmg * float(Data.tuning.combat.thornsReflect)
		att.hp -= back
		events.append({"type": "thorns", "side": 1 - side, "from": di, "to": ai, "dmg": back})
		if att.hp <= 0.0:
			att.hp = 0.0
			att.alive = false
			events.append({"type": "down", "side": side, "index": ai})
	if def.hp <= 0.0:
		def.hp = 0.0
		def.alive = false
		events.append({"type": "down", "side": 1 - side, "index": di})


## Returns false to hold the ability (a heal with nobody hurt).
static func _use_ability(own: Array, foe: Array, side: int, i: int, rng: RandomNumberGenerator, events: Array) -> bool:
	var f: Dictionary = own[i]
	var ab: Dictionary = Data.abilities[f.ability]
	var tp := tempo(ab.tempo)
	var pw: float = tp.power
	var cb: Dictionary = Data.tuning.combat
	match ab.effect:
		"single-target-damage":
			var t := _target(foe, side, rng)
			if t < 0:
				return false
			events.append({"type": "ability", "side": side, "index": i, "ability": ab.id})
			_hit(f, foe[t], side, i, t, pw, ab.damageType, ab.id, rng, events)
		"multi-target-damage":
			events.append({"type": "ability", "side": side, "index": i, "ability": ab.id})
			for t in foe.size():
				if foe[t].alive:
					_hit(f, foe[t], side, i, t, pw * cb.multiTargetFraction, ab.damageType, ab.id, rng, events)
		"heal-instant", "heal-over-time":
			var hurt := false
			for a in own:
				if a.alive and a.hp < a.maxHp * 0.85:
					hurt = true
			if not hurt:
				return false
			events.append({"type": "ability", "side": side, "index": i, "ability": ab.id})
			var amount: float = f.maxHp * cb.healFraction * pw
			for j in own.size():
				var a: Dictionary = own[j]
				if not a.alive:
					continue
				if ab.effect == "heal-instant":
					a.hp = minf(a.maxHp, a.hp + amount)
					events.append({"type": "heal", "side": side, "index": j, "amount": amount})
				else:
					var ms: float = float(cb.hotSeconds) * 1000.0
					a.hotPerMs = amount / ms
					a.hotT = ms
					events.append({"type": "heal", "side": side, "index": j, "amount": amount, "hot": true})
		"buff-power", "buff-guard":
			events.append({"type": "ability", "side": side, "index": i, "ability": ab.id})
			var key := "buffPower" if ab.effect == "buff-power" else "buffGuard"
			for j in own.size():
				if own[j].alive:
					own[j][key] = maxf(own[j][key], cb.buffFraction * pw)
					own[j][key + "T"] = float(cb.buffMs)
					events.append({"type": "buff", "side": side, "index": j, "stat": key})
		"shield-party":
			events.append({"type": "ability", "side": side, "index": i, "ability": ab.id})
			for j in own.size():
				if own[j].alive:
					own[j].shield = maxf(own[j].shield, f.maxHp * cb.shieldFraction * pw)
					events.append({"type": "shield", "side": side, "index": j})
		"shield-self", "thorns":
			events.append({"type": "ability", "side": side, "index": i, "ability": ab.id})
			var mult: float = cb.selfShieldMult if ab.effect == "shield-self" else 1.0
			f.shield = maxf(f.shield, f.maxHp * cb.shieldFraction * pw * mult)
			events.append({"type": "shield", "side": side, "index": i})
			if ab.effect == "thorns":
				f.thornsT = float(cb.thornsMs)
		_:
			return false
	return true
