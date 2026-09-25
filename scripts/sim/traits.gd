class_name Traits
extends RefCounted
## Trait effects and trait rolls. A creature has one signature trait (from its species, fixed strength)
## and up to three pool traits, each stored as {"id": trait id, "s": "minor" | "moderate" | "major"}.

const STRENGTHS := ["minor", "moderate", "major"]


static func effect_value(effect: Dictionary, strength: String) -> float:
	if effect.has("valueByStrength"):
		return float(effect.valueByStrength.get(strength, 0.0))
	return float(Data.tuning.traitStrength[strength])


## [{trait: Dictionary, s: strength}] for the signature trait and every pool trait.
static func all_of(c: Dictionary) -> Array:
	var out := []
	var sp: Dictionary = Data.species[c.species]
	var sig: Dictionary = Data.traits.get(sp.signatureTrait, {})
	if not sig.is_empty():
		out.append({"trait": sig, "s": sig.strength})
	for t in c.get("traits", []):
		if Data.traits.has(t.id):
			out.append({"trait": Data.traits[t.id], "s": t.s})
	return out


static func cap(key: String) -> float:
	return float(Data.tuning.caps.get(key, 1.0))


## Sum of a creature's own `key` effects that apply while working `skill` ("" = not tied to a skill).
## Uncapped: callers add auras and party effects, then cap.
static func self_mod(c: Dictionary, key: String, skill := "") -> float:
	var total := 0.0
	for e in all_of(c):
		for eff in e.trait.effects:
			if eff.key != key:
				continue
			var scope: Dictionary = eff.scope
			if scope.target != "self":
				continue
			if scope.has("skills") and not (skill in scope.skills):
				continue
			total += effect_value(eff, e.s)
	return total


static func capped_self(c: Dictionary, key: String, skill := "") -> float:
	return minf(cap(key), self_mod(c, key, skill))


## Effects with target "party" from every party member, summed (bind rate, free binds).
static func party_mod(members: Array, key: String) -> float:
	var total := 0.0
	for c in members:
		for e in all_of(c):
			for eff in e.trait.effects:
				if eff.key == key and eff.scope.target == "party":
					total += effect_value(eff, e.s)
	return total


## The strongest aura of each group this creature gives to others, as {group: {value, scope}}.
static func auras_of(c: Dictionary) -> Array:
	var out := []
	for e in all_of(c):
		for eff in e.trait.effects:
			if eff.has("aura"):
				out.append({"group": eff.aura.group, "key": eff.key, "scope": eff.scope, "value": effect_value(eff, e.s)})
	return out


## Partner-element drops a creature gets while working `skill`: [{type, chance}].
static func partner_drops(c: Dictionary, skill: String) -> Array:
	var out := []
	for e in all_of(c):
		for eff in e.trait.effects:
			if eff.key == "partner_element_drop_chance" and skill in eff.scope.get("skills", [skill]):
				out.append({"type": eff.elementType, "chance": minf(cap(eff.key), effect_value(eff, e.s))})
	return out


static func strength_label(s: String) -> String:
	return s.capitalize()


## Human text for one trait at one strength, e.g. "Chance for extra output (+10%)".
static func describe(trait_id: String, strength: String) -> String:
	var t: Dictionary = Data.traits[trait_id]
	var parts := []
	for eff in t.effects:
		var v := effect_value(eff, strength)
		if eff.key == "free_bind_attempts":
			parts.append("+%d" % int(v))
		else:
			parts.append("+" + F.pct(v))
	return "%s (%s)" % [t.text.trim_suffix("."), ", ".join(parts)]


# ---------------------------------------------------------------- rolling pool traits

static func eligible_pool(types: Array) -> Array:
	return Data.pool_traits.filter(func(t): return t.get("category") != "void-only" or "void" in types)


static func roll_weight(t: Dictionary, types: Array) -> float:
	var w := float(t.rollWeight)
	if t.has("typeAffinity") and t.typeAffinity in types:
		w *= Data.tuning.poolTraits.typeAffinityMult
	return w


static func roll_strength(rng: RandomNumberGenerator, t: Dictionary) -> String:
	var weights: Dictionary = Data.tuning.poolTraits.strengthWeights.duplicate()
	var min_s: String = t.get("minStrength", "minor")
	for s in STRENGTHS:
		if STRENGTHS.find(s) < STRENGTHS.find(min_s):
			weights.erase(s)
	# valueByStrength traits may not define every strength (Void Grasp has no Minor).
	for eff in t.effects:
		if eff.has("valueByStrength"):
			for s in weights.keys():
				if not eff.valueByStrength.has(s):
					weights.erase(s)
	var picked: Variant = Rng.weighted_key(rng, weights)
	return picked if picked != "" else min_s


## Adds up to `count` new pool traits to `existing` (not repeating an id). Returns the new list.
static func roll_into(rng: RandomNumberGenerator, types: Array, existing: Array, count: int) -> Array:
	var out := existing.duplicate(true)
	var max_traits: int = Data.tuning.creature.maxPoolTraits
	for i in count:
		if out.size() >= max_traits:
			break
		var have := out.map(func(e): return e.id)
		var weights := {}
		for t in eligible_pool(types):
			if not (t.id in have):
				weights[t.id] = roll_weight(t, types)
		var id: Variant = Rng.weighted_key(rng, weights)
		if id == "":
			break
		out.append({"id": id, "s": roll_strength(rng, Data.traits[id])})
	return out


## A fresh creature's pool traits (wild or bred with nothing inherited).
static func roll_fresh(rng: RandomNumberGenerator, types: Array) -> Array:
	var count := Rng.weighted_index(rng, Data.tuning.poolTraits.countWeights)
	return roll_into(rng, types, [], count)


## Clamps a strength to a trait's minimum and to the strengths it defines.
static func clamp_strength(trait_id: String, s: String) -> String:
	var t: Dictionary = Data.traits[trait_id]
	var idx := clampi(STRENGTHS.find(s), STRENGTHS.find(t.get("minStrength", "minor")), 2)
	return STRENGTHS[idx]


# ---------------------------------------------------------------- attunement (rerolling pool traits)

static func attune_cost(c: Dictionary, locks: int, s: Dictionary = {}) -> int:
	var at: Dictionary = Data.tuning.attunement
	var base: float = float(at.baseCost) * pow(float(at.rarityGrowth), int(c.rarity) - 1)
	var red := capped_self(c, "attunement_cost_reduction")
	var pearl := 1.0 - float(Data.tuning.pearls.attuneCostPerLevel) * GameState.pearl(s, "pearl-crucible")
	return int(ceil(base * float(at.lockMult[clampi(locks, 0, 2)]) * (1.0 - red) * pearl))


## Rerolls every pool trait not in `locked` (at most two locks). Returns "" or an error.
static func attune(s: Dictionary, c: Dictionary, locked: Array, rng: RandomNumberGenerator) -> String:
	var at: Dictionary = Data.tuning.attunement
	if locked.size() > int(at.maxLocks):
		return "You can lock at most %d traits." % int(at.maxLocks)
	var cost := attune_cost(c, locked.size(), s)
	if not GameState.pay(s, {"aether": cost}):
		return "Not enough Aether."
	var keep: Array = c.traits.filter(func(t): return t.id in locked)
	var target := maxi(keep.size(), Rng.weighted_index(rng, at.get("countWeights", Data.tuning.poolTraits.attunementCountWeights)))
	c.traits = roll_into(rng, Data.species[c.species].types, keep, target - keep.size())
	GameState.roster_changed()   # its Aether rate, so the perch order
	return ""
