class_name Market
extends RefCounted
## The Market (data/market.json): wares at a little over their sell value, extra work slots, bulk selling
## with item locks, a stock that rotates every few hours (sometimes with a rare limited offer), short
## boosts, and market eggs. Wares and grades open up as islands are cleared.


static func cfg() -> Dictionary:
	return Data.market


static func state(s: Dictionary) -> Dictionary:
	if not s.has("market"):
		s.market = fresh_state()
	return s.market


static func fresh_state() -> Dictionary:
	return {"slots": {}, "locked": {}, "boosts": {}, "stock": {}, "seenWindow": -1}


## Islands whose boss has fallen at least once.
static func clears(s: Dictionary) -> int:
	var n := 0
	for z in Data.zone_list:
		if bool(s.expedition.zones.get(z.id, {}).get("cleared", false)):
			n += 1
	return n


## How much later prices grow with progress (boosts, crystals): priceGrowth ^ islands cleared.
static func growth(s: Dictionary) -> float:
	return pow(float(cfg().priceGrowth), clears(s))


# ---------------------------------------------------------------- wares

## The Market's price: the sell value times the markup (to the nearest gold, and always at least a gold
## more), so selling back loses a little.
static func buy_price(id: String) -> int:
	var sell := int(Data.items[id].sell)
	return maxi(sell + 1, roundi(sell * float(cfg().markup)))


static func sells(id: String) -> bool:
	var it: Dictionary = Data.items.get(id, {})
	return not it.is_empty() and it.category in cfg().buyCategories and int(it.sell) > 0


## Islands to clear before the Market stocks an item: vessels have their own list; materials open a tier
## per island (tier 1 from the start).
static func unlock_clears(id: String) -> int:
	var it: Dictionary = Data.items[id]
	if it.category == "vessel":
		return int(cfg().vesselClears.get(id, 99))
	return maxi(0, ceili(float(int(it.tier) - 1) / float(cfg().tierPerClear)))


static func for_sale(s: Dictionary, id: String) -> bool:
	return sells(id) and clears(s) >= unlock_clears(id)


## Every item the Market deals in, optionally of one category, in file order.
static func catalog(category := "") -> Array:
	return Data.item_list.filter(func(it): return sells(it.id) and (category == "" or it.category == category))


static func buy(s: Dictionary, id: String, qty: int) -> String:
	if qty <= 0:
		return "Choose how many to buy."
	if not sells(id):
		return "Not for sale."
	if not for_sale(s, id):
		return "Not in stock yet."
	if not GameState.pay(s, {"gold": float(buy_price(id))}, qty):
		return "Not enough gold."
	GameState.add_item(s, id, qty)
	return ""


# ---------------------------------------------------------------- extra work slots

static func extra_slots(s: Dictionary, skill_id: String) -> int:
	return int(state(s).slots.get(skill_id, 0))


## The price of the skill's next extra slot, or -1 when every one is bought.
static func next_slot_price(s: Dictionary, skill_id: String) -> int:
	var prices: Array = cfg().extraSlots.gold
	var n := extra_slots(s, skill_id)
	return int(prices[n]) if n < prices.size() else -1


static func slot_check(s: Dictionary, skill_id: String) -> String:
	var price := next_slot_price(s, skill_id)
	if price < 0:
		return "Every extra slot is open."
	if int(s.skills[skill_id].level) < int(cfg().extraSlots.needLevel):
		return "Reach level %d first." % int(cfg().extraSlots.needLevel)
	if float(s.gold) < price:
		return "Not enough gold."
	return ""


static func buy_slot(s: Dictionary, skill_id: String) -> String:
	var err := slot_check(s, skill_id)
	if err != "":
		return err
	GameState.add_item(s, "gold", -next_slot_price(s, skill_id))
	state(s).slots[skill_id] = extra_slots(s, skill_id) + 1
	return ""


# ---------------------------------------------------------------- bulk selling and item locks

static func is_locked(s: Dictionary, id: String) -> bool:
	return state(s).locked.has(id)


static func toggle_item_lock(s: Dictionary, id: String) -> void:
	if is_locked(s, id):
		state(s).locked.erase(id)
	else:
		state(s).locked[id] = true


## What a bulk sale would sell: {item id: qty}. Locked items and anything unsellable stay; with no category
## chosen, vessels and rare finds stay too. `max_tier` 0 means every tier; `keep` of each is kept.
static func bulk_candidates(s: Dictionary, category: String, max_tier: int, keep: int) -> Dictionary:
	var out := {}
	for it in Data.item_list:
		var n := int(GameState.count(s, it.id))
		if n <= keep or int(it.sell) <= 0 or is_locked(s, it.id):
			continue
		if category == "" and it.category in cfg().bulkSell.skipCategories:
			continue
		if category != "" and it.category != category:
			continue
		if max_tier > 0 and int(it.tier) > max_tier:
			continue
		out[it.id] = n - keep
	return out


## Treasure: every unlocked item you hold that nothing uses (Economy.uses is empty), all of it, for "Sell treasure".
static func treasure_candidates(s: Dictionary) -> Dictionary:
	var out := {}
	for it in Data.item_list:
		var n := int(GameState.count(s, it.id))
		if n > 0 and int(it.sell) > 0 and not is_locked(s, it.id) and Economy.uses(it.id).is_empty():
			out[it.id] = n
	return out


static func bulk_value(cands: Dictionary) -> int:
	var g := 0
	for id in cands:
		g += int(Data.items[id].sell) * int(cands[id])
	return g


static func bulk_sell(s: Dictionary, cands: Dictionary) -> int:
	var g := 0
	for id in cands:
		g += Economy.sell(s, id, int(cands[id]))
	return g


# ---------------------------------------------------------------- the rotating stock

static func window_seconds() -> float:
	return float(cfg().rotation.hours) * 3600.0


static func window(now: float) -> int:
	return int(floor(now / window_seconds()))


static func window_ends(now: float) -> float:
	return float(window(now) + 1) * window_seconds()


## Today's stock, rolled once per window (the same for the whole window, whatever happens meanwhile).
static func stock(s: Dictionary, now: float) -> Dictionary:
	var w := window(now)
	if int(state(s).stock.get("window", -1)) != w:
		state(s).stock = roll_stock(s, w)
	_reprice(s, state(s).stock)
	return state(s).stock


static func has_limited(s: Dictionary, now: float) -> bool:
	for o in stock(s, now).offers:
		if o.get("limited", false) and int(o.left) > 0:
			return true
	return false


static func roll_stock(s: Dictionary, w: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([int(s.get("created", 0)), w])
	var rot: Dictionary = cfg().rotation
	var offers := []
	var weights := {}
	for i in rot.pool.size():
		weights[str(i)] = float(rot.pool[i].weight)
	var guard := 0
	while offers.size() < int(rot.offers) and guard < 40:
		guard += 1
		var o := _offer(s, rot.pool[int(Rng.weighted_key(rng, weights))], rng)
		if o.is_empty() or offers.any(func(x): return x.get("item", x.get("boost", "")) == o.get("item", o.get("boost", "-"))):
			continue
		o.left = int(rot.perOffer)
		offers.append(o)
	if rng.randf() < float(rot.limitedChance):
		var lim := _limited(s, rng)
		if not lim.is_empty():
			offers.push_front(lim)
	return {"window": w, "offers": offers, "featured": _featured(s, rng)}


static func _offer(s: Dictionary, p: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	match p.kind:
		"materials", "vessels":
			var pool := catalog("vessel") if p.kind == "vessels" else catalog().filter(func(it): return it.category != "vessel")
			pool = pool.filter(func(it): return for_sale(s, it.id))
			if pool.is_empty():
				return {}
			# the best tier on sale, so the offer stays useful as the islands open up
			var top := 0
			for it in pool:
				top = maxi(top, int(it.tier))
			var best := pool.filter(func(it): return int(it.tier) >= top - 1)
			var pick: Dictionary = best[rng.randi_range(0, best.size() - 1)]
			var qty := rng.randi_range(int(p.qty[0]), int(p.qty[1]))
			# priced by the lot, not per unit: rounding each 3-gold Scrap up would undo the whole discount. Still
			# more than selling the lot back, so an offer can never be flipped for profit.
			var full: int = buy_price(pick.id) * qty
			var gold: int = maxi(int(pick.sell) * qty + 1, ceili(full * float(p.discount)))
			return {"kind": "item", "item": pick.id, "qty": qty, "gold": gold, "discount": 1.0 - float(gold) / full}
		"boost":
			var list: Array = cfg().boosts.list
			var b: Dictionary = list[rng.randi_range(0, list.size() - 1)]
			return {"kind": "boost", "boost": b.id, "gold": ceili(boost_price(s, b.id) * float(p.discount)), "discount": 1.0 - float(p.discount)}
		"crystals":
			var qty := ceili(rng.randi_range(int(p.qty[0]), int(p.qty[1])) * growth(s))
			return {"kind": "item", "item": "aether-crystal", "qty": qty, "gold": qty * int(p.goldEach)}
	return {}


## A boost offer follows the boost's current price (it grows with each island cleared), so its discount stays
## true for the whole window instead of keeping the price from when the stock was rolled.
static func _reprice(s: Dictionary, st: Dictionary) -> void:
	for o in st.get("offers", []):
		if o.get("kind", "") == "boost" and not o.get("limited", false):
			o.gold = ceili(boost_price(s, o.boost) * (1.0 - float(o.discount)))


static func _limited(s: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var c := clears(s)
	var eligible: Array = cfg().rotation.limited.filter(func(e): return c >= int(e.minClears))
	if eligible.is_empty():
		return {}
	var weights := {}
	for i in eligible.size():
		weights[str(i)] = float(eligible[i].weight)
	var l: Dictionary = eligible[int(Rng.weighted_key(rng, weights))]
	var o := {"limited": true, "left": 1, "name": l.name, "blurb": l.blurb, "id": l.id}
	if l.has("egg"):
		var types := egg_types(s)
		o.kind = "egg"
		o.type = types[rng.randi_range(0, types.size() - 1)]
		o.grade = mini(best_grade(s) + int(l.egg.gradeUp), grades().size() - 1)
		o.shiny = bool(l.egg.shiny)
		o.gold = ceili(egg_price(int(o.grade)) * float(l.priceMult))
	else:
		o.kind = "item"
		o.item = l.item
		o.qty = int(l.qty) if l.has("qty") else ceili(int(l.qtyMult) * int(cfg().offerQtyBase) * growth(s))
		o.gold = int(l.gold) if l.has("gold") else int(o.qty) * int(l.goldEach)
	return o


const STOCK_CHANGED := "The stock has just changed. Take another look."


## Buys one of an offer from today's stock. Returns "" or a reason. `expect_window` is the stock window the
## player was looking at: when the stock has changed since, nothing is bought (index i may be another offer now).
static func buy_offer(s: Dictionary, index: int, now: float, rng: RandomNumberGenerator, expect_window := -1) -> String:
	if expect_window >= 0 and expect_window != window(now):
		return STOCK_CHANGED
	var st := stock(s, now)
	if index < 0 or index >= st.offers.size():
		return "That offer is gone."
	var o: Dictionary = st.offers[index]
	if int(o.left) <= 0:
		return "Sold out."
	if o.kind == "egg" and Breeding.free_pod(s) < 0:
		return "Every Genesis Pod is busy."
	if o.kind == "boost" and boost_full(s, o.boost):
		return "Already stocked up for %d hours." % int(cfg().boosts.maxHours)
	if not GameState.pay(s, {"gold": float(o.gold)}):
		return "Not enough gold."
	match o.kind:
		"item":
			GameState.add_item(s, o.item, int(o.qty))
		"boost":
			add_boost(s, o.boost)
		"egg":
			_lay(s, make_egg(s, o.type, int(o.grade), bool(o.shiny), rng, now))
	o.left = int(o.left) - 1
	return ""


# ---------------------------------------------------------------- boosts

static func boost_def(id: String) -> Dictionary:
	for b in cfg().boosts.list:
		if b.id == id:
			return b
	return {}


static func boost_price(s: Dictionary, id: String) -> int:
	return ceili(float(boost_def(id).gold) * growth(s))


static func boost_left(s: Dictionary, id: String) -> float:
	return float(state(s).boosts.get(id, 0.0))


static func boost_full(s: Dictionary, id: String) -> bool:
	return boost_left(s, id) + float(boost_def(id).minutes) * 60.0 > float(cfg().boosts.maxHours) * 3600.0 + 1.0


static func add_boost(s: Dictionary, id: String) -> void:
	var cap := float(cfg().boosts.maxHours) * 3600.0
	state(s).boosts[id] = minf(cap, boost_left(s, id) + float(boost_def(id).minutes) * 60.0)


static func buy_boost(s: Dictionary, id: String) -> String:
	if boost_def(id).is_empty():
		return "Not for sale."
	if boost_full(s, id):
		return "Already stocked up for %d hours." % int(cfg().boosts.maxHours)
	if not GameState.pay(s, {"gold": float(boost_price(s, id))}):
		return "Not enough gold."
	add_boost(s, id)
	return ""


## The summed bonus of the running boosts with this effect (0 when none). Offline, a boost that ran out
## partway counts for the share of the time it lasted.
static func bonus(s: Dictionary, effect: String) -> float:
	if not s.has("market"):
		return 0.0
	var out := 0.0
	var frac: Dictionary = s.market.get("_frac", {})
	for id in s.market.boosts:
		if float(s.market.boosts[id]) <= 0.0:
			continue
		var b := boost_def(id)
		if not b.is_empty() and b.effect == effect:
			out += float(b.value) * float(frac.get(id, 1.0))
	return out


static func tick(s: Dictionary, dt_sec: float) -> void:
	if not s.has("market"):
		return
	for id in s.market.boosts.keys():
		var left := float(s.market.boosts[id]) - dt_sec
		if left <= 0.0:
			s.market.boosts.erase(id)
		else:
			s.market.boosts[id] = left


static func offline_begin(s: Dictionary, used: float) -> void:
	var frac := {}
	for id in state(s).boosts:
		frac[id] = clampf(float(s.market.boosts[id]) / maxf(1.0, used), 0.0, 1.0)
	s.market._frac = frac


static func offline_end(s: Dictionary, used: float) -> void:
	state(s).erase("_frac")
	tick(s, used)


# ---------------------------------------------------------------- market eggs

static func grades() -> Array:
	return cfg().eggs.grades


## The best egg grade on sale (by islands cleared).
static func best_grade(s: Dictionary) -> int:
	var c := clears(s)
	var best := 0
	for i in grades().size():
		if c >= int(grades()[i].minClears):
			best = i
	return best


static func egg_price(grade: int) -> int:
	return int(grades()[grade].gold)


## Types the Egg Market has eggs of: those you own an Aetherling of.
static func egg_types(s: Dictionary) -> Array:
	return Data.type_list.map(func(t): return t.id).filter(func(t): return Collection.owned_type(s, t))


static func base_species(type_id: String) -> Array:
	return Data.species_list.filter(func(sp): return sp.kind == "base" and sp.types == [type_id]).map(func(sp): return sp.id)


## Rarity weights (index = tier - 1) for a grade: its floor, then one and two above.
static func egg_odds(grade: int) -> Array:
	var odds := []
	odds.resize(Data.max_rarity())
	odds.fill(0.0)
	var w: Array = cfg().eggs.rarityOdds
	var fl := int(grades()[grade].floor)
	for i in w.size():
		var r := mini(fl + i, Data.max_rarity())
		odds[r - 1] = float(odds[r - 1]) + float(w[i])
	return odds


static func make_egg(s: Dictionary, type_id: String, grade: int, force_shiny: bool, rng: RandomNumberGenerator, now: float,
		species_id := "") -> Dictionary:
	var pool := base_species(type_id)
	var sp_id := species_id if species_id != "" else String(pool[rng.randi_range(0, pool.size() - 1)])
	var rarity := Rng.weighted_index(rng, egg_odds(grade)) + 1
	# a market egg never counts toward the hatch pity, so gold can't buy a shiny that way
	var sh: Dictionary = Data.tuning.shiny
	var shiny := force_shiny or Rng.chance(rng, float(sh.hatchRate) + float(Data.tuning.pearls.lensHatchPerLevel) * GameState.pearl(s, "pearl-lens"))
	var shell := rarity
	if not Rng.chance(rng, float(Data.tuning.breeding.shellTruthChance)):
		shell = clampi(rarity + (1 if rng.randf() < 0.5 else -1), 1, Data.max_rarity())
	var g: Dictionary = grades()[grade]
	return {"species": sp_id, "rarity": rarity, "shiny": shiny, "traits": Traits.roll_fresh(rng, Data.species[sp_id].types),
		"tier": clampi(grade * 2 + 1, 1, Breeding.tier_count()), "laidAt": now, "readyAt": now + float(g.minutes) * 60.0,
		"parents": [], "shell": shell, "market": g.name}


static func _lay(s: Dictionary, egg: Dictionary) -> int:
	var pod := Breeding.free_pod(s)
	s.pods[pod] = egg
	return pod


static func egg_check(s: Dictionary, type_id: String, grade: int) -> String:
	if grade < 0 or grade >= grades().size() or not Data.types.has(type_id):
		return "No such egg."
	if grade > best_grade(s):
		return "Not on sale yet."
	if not (type_id in egg_types(s)):
		return "Own a %s Aetherling first." % Data.types[type_id].name
	if Breeding.free_pod(s) < 0:
		return "Every Genesis Pod is busy."
	if float(s.gold) < egg_price(grade):
		return "Not enough gold."
	return ""


static func buy_egg(s: Dictionary, type_id: String, grade: int, rng: RandomNumberGenerator, now: float) -> String:
	var err := egg_check(s, type_id, grade)
	if err != "":
		return err
	GameState.add_item(s, "gold", -egg_price(grade))
	_lay(s, make_egg(s, type_id, grade, false, rng, now))
	return ""


## The window's featured egg: one named base Aetherling of a type you own, a grade above the best on sale.
static func _featured(s: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var types := egg_types(s)
	if types.is_empty():
		return {}
	var f: Dictionary = cfg().eggs.featured
	var t: String = types[rng.randi_range(0, types.size() - 1)]
	var pool := base_species(t)
	var grade := mini(best_grade(s) + int(f.gradeUp), grades().size() - 1)
	return {"type": t, "species": pool[rng.randi_range(0, pool.size() - 1)], "grade": grade,
		"gold": ceili(egg_price(grade) * float(f.priceMult)), "left": 1}


static func buy_featured(s: Dictionary, now: float, rng: RandomNumberGenerator, expect_window := -1) -> String:
	if expect_window >= 0 and expect_window != window(now):
		return STOCK_CHANGED
	var f: Dictionary = stock(s, now).featured
	if f.is_empty() or int(f.left) <= 0:
		return "Sold out."
	if Breeding.free_pod(s) < 0:
		return "Every Genesis Pod is busy."
	if not GameState.pay(s, {"gold": float(f.gold)}):
		return "Not enough gold."
	_lay(s, make_egg(s, f.type, int(f.grade), false, rng, now, f.species))
	f.left = 0
	return ""
