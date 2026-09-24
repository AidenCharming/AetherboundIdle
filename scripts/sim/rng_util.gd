class_name Rng
extends RefCounted
## Random helpers on a RandomNumberGenerator. The game keeps one generator and saves its state, so a
## reload never re-rolls an outcome.


static func chance(rng: RandomNumberGenerator, p: float) -> bool:
	return p > 0.0 and rng.randf() < p


## Picks a key from {key: weight}. Returns "" when every weight is zero.
static func weighted_key(rng: RandomNumberGenerator, weights: Dictionary) -> Variant:
	var total := 0.0
	for k in weights:
		total += maxf(0.0, float(weights[k]))
	if total <= 0.0:
		return ""
	var roll := rng.randf() * total
	for k in weights:
		roll -= maxf(0.0, float(weights[k]))
		if roll < 0.0:
			return k
	return weights.keys().back()


## Picks an index from an array of weights.
static func weighted_index(rng: RandomNumberGenerator, weights: Array) -> int:
	var total := 0.0
	for w in weights:
		total += maxf(0.0, float(w))
	if total <= 0.0:
		return 0
	var roll := rng.randf() * total
	for i in weights.size():
		roll -= maxf(0.0, float(weights[i]))
		if roll < 0.0:
			return i
	return weights.size() - 1


## Number of successes in n trials of probability p. Exact for small n, Poisson or normal approximation
## for large n so a 12-hour offline window stays cheap.
static func binomial(rng: RandomNumberGenerator, n: int, p: float) -> int:
	if n <= 0 or p <= 0.0:
		return 0
	if p >= 1.0:
		return n
	if n <= 40:
		var k := 0
		for i in n:
			if rng.randf() < p:
				k += 1
		return k
	var mean := n * p
	if mean < 12.0:
		return mini(n, poisson(rng, mean))
	var sd := sqrt(mean * (1.0 - p))
	return clampi(roundi(rng.randfn(mean, sd)), 0, n)


static func poisson(rng: RandomNumberGenerator, mean: float) -> int:
	if mean <= 0.0:
		return 0
	var limit := exp(-mean)
	var k := 0
	var prod := rng.randf()
	while prod > limit:
		k += 1
		prod *= rng.randf()
	return k


static func pick(rng: RandomNumberGenerator, list: Array) -> Variant:
	if list.is_empty():
		return null
	return list[rng.randi_range(0, list.size() - 1)]
