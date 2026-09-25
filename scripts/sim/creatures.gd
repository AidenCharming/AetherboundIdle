class_name Creatures
extends RefCounted
## Creature records and the rules about them. A creature is a Dictionary:
## {id, species, rarity, level, form, xp, shiny, traits: [{id, s}], nick, locked, born, origin, job: {}, progress, overclock}
## `job` is {} when benched, {"kind": "skill", "id": skill_id} when working, {"kind": "party"} on an expedition.


## `form` 0 means the form its level gives; a wild one keeps the form it was met in (never above that).
static func make(state: Dictionary, species_id: String, rarity: int, level: int, shiny: bool, traits: Array, origin: String, form := 0) -> Dictionary:
	state.nextCreatureId = int(state.nextCreatureId) + 1
	var lv := clampi(level, 1, int(Data.tuning.creature.maxLevel))
	var top := F.form_for_level(lv)
	return {
		"id": "c%d" % int(state.nextCreatureId),
		"species": species_id,
		"rarity": clampi(rarity, 1, Data.max_rarity()),
		"level": lv,
		"form": top if form <= 0 else clampi(form, 1, top),
		"xp": F.xp_for_level(F.creature_curve(), lv, Data.tuning.creature.maxLevel),
		"shiny": shiny,
		"traits": traits,
		"nick": "",
		"locked": false,
		"born": int(Time.get_unix_time_from_system()),
		"origin": origin,
		"job": {},
		"progress": 0.0,
		"overclock": 0,
	}


static func types_of(c: Dictionary) -> Array:
	return Data.species[c.species].types


## The stored form. Saves from before forms were stored have none: theirs is the form their level gives.
static func form_of(c: Dictionary) -> int:
	return int(c.form) if c.has("form") else F.form_for_level(int(c.level))


static func display_name(c: Dictionary) -> String:
	if c.get("nick", "") != "":
		return c.nick
	return Data.form_name(c.species, form_of(c))


static func is_hybrid(c: Dictionary) -> bool:
	return Data.species[c.species].kind != "base"


static func is_benched(c: Dictionary) -> bool:
	return c.get("job", {}).is_empty()


static func job_kind(c: Dictionary) -> String:
	return c.get("job", {}).get("kind", "")


## Can this creature work `skill_id` at all? Locked skills need a matching type; open skills take anyone.
static func can_work(c: Dictionary, skill_id: String) -> bool:
	var skill: Dictionary = Data.skills[skill_id]
	if skill.type == null:
		return true
	return skill.type in types_of(c)


## Job fit, as a divisor on the base action time (higher is better).
static func efficiency(c: Dictionary, skill_id: String) -> float:
	var sp: Dictionary = Data.species[c.species]
	var t: Dictionary = Data.tuning.skills
	var e := 1.0
	if sp.kind != "base" and Data.skills[skill_id].type != null and skill_id != sp.primarySkill:
		e *= t.hybridOffPrimaryEfficiency
	if skill_id == sp.primarySkill:
		e *= 1.0 + t.get("specialistBonus", 0.0)
	if skill_id == sp.secondaryAptitude:
		e *= 1.0 + t.secondaryAptitudeBonus
	return e


static func stat(c: Dictionary, stat_name: String) -> float:
	var sp: Dictionary = Data.species[c.species]
	var bonus := Traits.capped_self(c, "bonus_" + stat_name)
	return F.stat_value(stat_name, sp.statLean, int(c.level), int(c.rarity), form_of(c), bonus, bool(c.shiny))


static func stats(c: Dictionary) -> Dictionary:
	return {"health": stat(c, "health"), "power": stat(c, "power"), "guard": stat(c, "guard")}


## A single number for sorting and party suggestions.
static func power_rating(c: Dictionary) -> float:
	var s := stats(c)
	var w: Dictionary = Data.tuning.creature.powerRating
	return s.health * float(w.health) + s.power * float(w.power) + s.guard * float(w.guard)


## Adds creature XP. Returns events: level_up and evolved. A creature crossing a form's level evolves to it;
## one caught in a lower form than its level allows evolves one form on each level-up until it catches up.
static func add_xp(c: Dictionary, amount: float) -> Array:
	var events := []
	var max_lv: int = Data.tuning.creature.maxLevel
	if amount <= 0.0 or int(c.level) >= max_lv:
		return events
	var before_level := int(c.level)
	var before_form := form_of(c)
	c.xp = minf(float(c.xp) + amount, F.xp_for_level(F.creature_curve(), max_lv, max_lv))
	c.level = F.level_for_xp(F.creature_curve(), c.xp, max_lv)
	if int(c.level) > before_level:
		events.append({"type": "creature_level", "creature": c.id, "level": c.level})
		var top := F.form_for_level(int(c.level))
		var behind := before_form < F.form_for_level(before_level)
		var after_form := mini(top, before_form + 1) if behind else maxi(before_form, top)
		c.form = after_form
		if after_form > before_form:
			events.append({"type": "evolved", "creature": c.id, "species": c.species, "form": after_form, "from": before_form})
	return events


static func release_value(c: Dictionary) -> int:
	var t: Dictionary = Data.tuning.aether
	var by_level := 1.0 + (int(c.level) - 1) / float(t.releaseLevelsPerStep)
	var by_form := 1.0 + (form_of(c) - 1) * float(t.releasePerForm)
	return int(round(Data.rarity(int(c.rarity)).releaseAether * by_level * by_form))


static func bench_rate_per_min(c: Dictionary) -> float:
	var base: float = Data.rarity(int(c.rarity)).benchAetherPerMin
	return base * (1.0 + Traits.capped_self(c, "bench_aether_emission"))
