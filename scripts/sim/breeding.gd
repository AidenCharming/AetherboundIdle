class_name Breeding
extends RefCounted
## Genesis Pods. Two parents plus Aether and element materials make an egg. Every roll (species, rarity,
## shiny, traits) happens when the egg is laid and is saved at once, so reloading can never re-roll a
## hatch; the reveal is presentation only.
## A pod is {} (empty) or an egg: {species, rarity, shiny, traits, tier, laidAt, readyAt, parents, shell}.


## Which species two parents can make, with weights.
static func offspring(a: Dictionary, b: Dictionary) -> Array:
	var sa: Dictionary = Data.species[a.species]
	var sb: Dictionary = Data.species[b.species]
	if a.species == b.species:
		return [{"species": a.species, "weight": 1.0}]
	if sa.kind != "base" or sb.kind != "base":
		return [{"species": a.species, "weight": 1.0}, {"species": b.species, "weight": 1.0}]
	var special: Dictionary = Data.special_recipes.get(Data.pair_key(a.species, b.species), {})
	if not special.is_empty():
		return [{"species": special.result, "weight": 1.0}]
	var ta: String = sa.types[0]
	var tb: String = sb.types[0]
	if ta == tb:
		return [{"species": a.species, "weight": 1.0}, {"species": b.species, "weight": 1.0}]
	return [{"species": Data.default_hybrids[Data.pair_key(ta, tb)], "weight": 1.0}]


## The element material a type needs at a tier (logs, ores, bars, fish, components, threads).
static func material(type_id: String, tier: int) -> String:
	for it in Data.item_list:
		if it.get("element", "") == type_id and int(it.tier) == tier and it.category != "rare":
			return it.id
	return ""


static func cost(a: Dictionary, b: Dictionary, tier: int) -> Dictionary:
	var br: Dictionary = Data.tuning.breeding
	var c := {"aether": float(br.aetherCost[tier - 1])}
	for parent in [a, b]:
		var id := material(Data.species[parent.species].types[0], tier)
		c[id] = int(c.get(id, 0)) + int(br.materialQty)
	return c


## How many material tiers eggs can be laid at (one per material tier).
static func tier_count() -> int:
	return Data.tuning.breeding.ceilingByTier.size()


static func ceiling(tier: int) -> int:
	return int(Data.tuning.breeding.ceilingByTier[tier - 1])


static func mutation_bonus(a: Dictionary, b: Dictionary) -> float:
	return minf(Traits.cap("mutation_odds"), Traits.self_mod(a, "mutation_odds") + Traits.self_mod(b, "mutation_odds"))


## Probability of each rarity tier (index 0 = Dim). Resource tier sets the ceiling; the odds centre on the
## parents' average rarity, falling off by `stepWeight` per tier away from it (so a Dim + Faint pair sits
## halfway between two Dims and two Faints), and never go below the weaker parent. Better materials lift
## the centre by `centreLiftPerTier` per tier above the first, so a tier that shares its ceiling with the
## one below still has better odds. Then two separate mutation rolls can push past the ceiling.
static func rarity_odds(a: Dictionary, b: Dictionary, tier: int, s: Dictionary = {}) -> Array:
	var br: Dictionary = Data.tuning.breeding
	var top := Data.max_rarity()
	var ceil_r := ceiling(tier)
	var lowest := mini(mini(int(a.rarity), int(b.rarity)), ceil_r)
	var lift := float(br.get("centreLiftPerTier", 0.0)) * (tier - 1)
	var centre := minf((float(a.rarity) + float(b.rarity)) / 2.0 + lift, float(ceil_r))
	var base := []
	var total := 0.0
	for k in range(lowest, ceil_r + 1):
		var w := pow(float(br.stepWeight), absf(k - centre))
		base.append([k, w])
		total += w
	var bonus := mutation_bonus(a, b)
	var out := []
	out.resize(top)
	out.fill(0.0)
	for pair in base:
		var k: int = pair[0]
		var p: float = pair[1] / total
		var pm := 1.0 + float(Data.tuning.pearls.mutationPerLevel) * GameState.pearl(s, "pearl-resonator")
		var p2: float = float(br.mutationPlusTwo) * pm * (float(br.topTierMutationMult) if k + 2 >= top - 1 else 1.0)
		var p1: float = (float(br.mutationPlusOne) + bonus) * pm * (float(br.topTierMutationMult) if k + 1 >= top - 1 else 1.0)
		if k + 2 > top:
			p2 = 0.0
		if k + 1 > top:
			p1 = 0.0
		out[k - 1] += p * (1.0 - p1 - p2)
		if p1 > 0.0:
			out[k] += p * p1
		if p2 > 0.0:
			out[k + 1] += p * p2
	return out


## Shiny chance for the next egg. Each shiny parent adds `shiny.shinyParentBonus` of the chance (0.5: one
## shiny parent makes 0.5% into 0.75%, two make it 1%), on top of the pity that builds after many hatches.
static func hatch_chance_shiny(s: Dictionary, a: Dictionary = {}, b: Dictionary = {}) -> float:
	var sh: Dictionary = Data.tuning.shiny
	var since := int(s.counters.hatchesSinceShiny)
	var p := float(sh.hatchRate)
	if since > int(sh.hatchPityStart):
		var t := clampf(float(since - int(sh.hatchPityStart)) / float(int(sh.hatchPityFull) - int(sh.hatchPityStart)), 0.0, 1.0)
		p = lerpf(float(sh.hatchRate), 0.2, t)
	var shiny_parents := int(bool(a.get("shiny", false))) + int(bool(b.get("shiny", false)))
	p *= 1.0 + float(sh.get("shinyParentBonus", 0.0)) * shiny_parents
	# the Pearl Lens adds a flat share per level
	p += float(Data.tuning.pearls.lensHatchPerLevel) * GameState.pearl(s, "pearl-lens")
	return minf(0.25, p)


static func hatch_seconds(a: Dictionary, b: Dictionary, tier: int, s: Dictionary = {}) -> float:
	var red := minf(Traits.cap("hatch_time_reduction"), Traits.self_mod(a, "hatch_time_reduction") + Traits.self_mod(b, "hatch_time_reduction"))
	var pearl := 1.0 - float(Data.tuning.pearls.hatchTimePerLevel) * GameState.pearl(s, "pearl-incubator")
	return float(Data.tuning.breeding.hatchMinutes[tier - 1]) * 60.0 * (1.0 - red) * pearl


static func free_pod(s: Dictionary) -> int:
	for i in s.pods.size():
		if s.pods[i].is_empty():
			return i
	return -1


static func check(s: Dictionary, a: Dictionary, b: Dictionary, tier: int) -> String:
	if a.is_empty() or b.is_empty():
		return "Choose two parents."
	if a.id == b.id:
		return "Choose two different Aetherlings."
	if tier < 1 or tier > Data.tuning.breeding.aetherCost.size():
		return "No such breeding tier."
	if free_pod(s) < 0:
		return "Every Genesis Pod is busy."
	var c := cost(a, b, tier)
	for id in c:
		if id == "":
			return "No material for that tier."
	if not GameState.can_afford(s, c):
		return "Not enough Aether or materials."
	return ""


## Pays and lays an egg. Returns {"error": ...} or {"pod": index, "egg": egg}.
static func breed(s: Dictionary, a: Dictionary, b: Dictionary, tier: int, rng: RandomNumberGenerator, now: float) -> Dictionary:
	var err := check(s, a, b, tier)
	if err != "":
		return {"error": err}
	GameState.pay(s, cost(a, b, tier))
	var opts := offspring(a, b)
	var weights := {}
	for o in opts:
		weights[o.species] = o.weight
	var sp_id: String = Rng.weighted_key(rng, weights)
	var rarity := Rng.weighted_index(rng, rarity_odds(a, b, tier, s)) + 1
	var shiny := Rng.chance(rng, hatch_chance_shiny(s, a, b))
	s.counters.hatchesSinceShiny = 0 if shiny else int(s.counters.hatchesSinceShiny) + 1
	var traits := inherit(rng, a, b, Data.species[sp_id].types, s)
	var shell := rarity
	if not Rng.chance(rng, float(Data.tuning.breeding.shellTruthChance)):
		shell = clampi(rarity + (1 if rng.randf() < 0.5 else -1), 1, Data.max_rarity())
	var secs := hatch_seconds(a, b, tier, s)
	var egg := {"species": sp_id, "rarity": rarity, "shiny": shiny, "traits": traits, "tier": tier, "laidAt": now,
		"readyAt": now + secs, "parents": [a.species, b.species], "shell": shell}
	var pod := free_pod(s)
	s.pods[pod] = egg
	s.counters.bred = int(s.counters.bred) + 1
	return {"pod": pod, "egg": egg}


## Pool traits for an offspring: each parent trait may pass down (at its strength or one step stronger), then the
## empty slots roll fresh, with a small chance of a bonus mutation trait.
static func inherit(rng: RandomNumberGenerator, a: Dictionary, b: Dictionary, types: Array, s: Dictionary = {}) -> Array:
	var br: Dictionary = Data.tuning.breeding
	var out := []
	var pool := []
	for t in a.traits + b.traits:
		pool.append(t)
	Rng.shuffle(rng, pool)
	var max_traits: int = Data.tuning.creature.maxPoolTraits
	var eligible := Traits.eligible_pool(types).map(func(t): return t.id)
	for t in pool:
		if out.size() >= max_traits:
			break
		if not (t.id in eligible) or out.any(func(o): return o.id == t.id):
			continue
		if Rng.chance(rng, float(br.inheritChance)):
			# a passed-down trait keeps its strength or grows one step, never weaker (designer's rule)
			var idx := Traits.STRENGTHS.find(t.s)
			var up := float(br.traitStrengthUpChance) + float(Data.tuning.pearls.strengthUpPerLevel) * GameState.pearl(s, "pearl-crucible")
			if Rng.chance(rng, up):
				idx += 1
			out.append({"id": t.id, "s": Traits.clamp_strength(t.id, Traits.STRENGTHS[clampi(idx, 0, 2)])})
	if out.is_empty():
		out = Traits.roll_fresh(rng, types)
	if Rng.chance(rng, float(br.traitMutationChance)):
		out = Traits.roll_into(rng, types, out, 1)
	# a fresh roll can land on a trait a parent has: it never comes out weaker than the parent's
	for o in out:
		for t in a.traits + b.traits:
			if t.id == o.id and Traits.STRENGTHS.find(t.s) > Traits.STRENGTHS.find(o.s):
				o.s = t.s
	return out


static func remaining(egg: Dictionary, now: float) -> float:
	return maxf(0.0, float(egg.readyAt) - now)


static func is_ready(egg: Dictionary, now: float) -> bool:
	return not egg.is_empty() and now >= float(egg.readyAt)


static func speed_up_cost(egg: Dictionary, now: float) -> int:
	var per: float = Data.tuning.breeding.speedUpAetherPerMinute[int(egg.tier) - 1]
	return int(ceil(remaining(egg, now) / 60.0 * per))


static func speed_up(s: Dictionary, pod: int, now: float) -> String:
	var egg: Dictionary = s.pods[pod]
	if egg.is_empty() or is_ready(egg, now):
		return ""
	var c := speed_up_cost(egg, now)
	if not GameState.pay(s, {"aether": c}):
		return "Not enough Aether."
	egg.readyAt = now
	return ""


## Hatches a ready egg into a creature. Returns {creature, events} or {} when not ready.
static func hatch(s: Dictionary, pod: int, now: float) -> Dictionary:
	var egg: Dictionary = s.pods[pod]
	if not is_ready(egg, now):
		return {}
	var c := Creatures.make(s, egg.species, int(egg.rarity), 1, bool(egg.shiny), egg.traits, "bred")
	s.creatures[c.id] = c
	GameState.roster_changed()
	s.pods[pod] = {}
	s.counters.hatches = int(s.counters.hatches) + 1
	var events := Collection.on_owned(s, c)
	if c.shiny:
		events.append_array(GameState.give_pearls(s, int(Data.tuning.pearls.shinyFound), "a shiny hatched"))
	return {"creature": c, "events": events, "egg": egg}


## Chance to make each offspring species, for the preview (a special recipe that has not been
## discovered yet shows as an unknown hybrid).
static func preview(s: Dictionary, a: Dictionary, b: Dictionary) -> Array:
	var opts := offspring(a, b)
	var total := 0.0
	for o in opts:
		total += float(o.weight)
	var out := []
	for o in opts:
		var sp: Dictionary = Data.species[o.species]
		var known: bool = sp.kind == "base" or o.species in s.collection.recipes or Collection.is_owned(s, o.species)
		out.append({"species": o.species, "chance": float(o.weight) / total, "known": known, "special": sp.kind == "special"})
	return out
