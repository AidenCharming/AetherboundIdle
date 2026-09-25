extends RefCounted
## The Market: wares and their unlocks, extra work slots, bulk selling, the rotating stock, boosts and
## market eggs.

var t


func _game(gold := 0.0) -> Dictionary:
	var s := GameState.new_game()
	s.gold = gold
	return s


func _clear(s: Dictionary, n: int) -> void:
	for i in n:
		Expedition.zone_state(s, Data.zone_list[i].id).cleared = true


func _rng(seed_value := 3) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value
	return r


func test_wares_open_with_the_islands() -> void:
	var s := _game(10000)
	t.ok(Market.for_sale(s, "oak-log"), "tier-1 materials from the start")
	t.ok(not Market.for_sale(s, "maple-log"), "tier 3 needs two islands")
	t.ok(Market.for_sale(s, "tinkerers-vessel") and not Market.for_sale(s, "sturdy-vessel"), "vessels have their own list")
	t.eq(Market.buy(s, "maple-log", 1), "Not in stock yet.")
	_clear(s, 2)
	t.ok(Market.for_sale(s, "maple-log"), "open after two clears")
	var price := Market.buy_price("maple-log")
	t.eq(Market.buy(s, "maple-log", 10), "")
	t.eq(int(GameState.count(s, "maple-log")), 10)
	t.near(float(s.gold), 10000.0 - price * 10, 0.01, "paid the price")
	s.gold = 0.0
	t.eq(Market.buy(s, "oak-log", 1), "Not enough gold.")
	t.eq(Market.buy(s, "aether-pearl", 1), "Not for sale.", "rare things only come through the stock")


func test_extra_work_slots() -> void:
	var s := _game(1e9)
	var base := GameState.slot_count(s, "mining")
	t.ok(Market.slot_check(s, "mining").begins_with("Reach level"), "needs the five slots open first")
	s.skills.mining.level = int(Market.cfg().extraSlots.needLevel)
	var five := GameState.slot_count(s, "mining")
	t.ok(five > base)
	var first := Market.next_slot_price(s, "mining")
	t.eq(Market.buy_slot(s, "mining"), "")
	t.eq(GameState.slot_count(s, "mining"), five + 1, "one more slot")
	t.ok(Market.next_slot_price(s, "mining") > first, "the next costs more")
	t.eq(GameState.slot_count(s, "woodcutting"), 1, "only that skill")
	for i in 5:
		Market.buy_slot(s, "mining")
	t.eq(GameState.slot_count(s, "mining"), 10, "capped at ten")
	t.eq(Market.next_slot_price(s, "mining"), -1)
	t.eq(Market.slot_check(s, "mining"), "Every extra slot is open.")


func test_bulk_sell_keeps_locked_and_some_of_each() -> void:
	var s := _game()
	GameState.add_item(s, "oak-log", 50)
	GameState.add_item(s, "copper-ore", 50)
	GameState.add_item(s, "iron-bar", 50)
	GameState.add_item(s, "sturdy-vessel", 5)
	Market.toggle_item_lock(s, "copper-ore")
	var c := Market.bulk_candidates(s, "", 0, 10)
	t.eq(int(c.get("oak-log", 0)), 40, "keeps 10")
	t.ok(not c.has("copper-ore"), "a locked item stays")
	t.ok(not c.has("sturdy-vessel") and not c.has("tinkerers-vessel"), "vessels stay unless chosen")
	t.ok(not Market.bulk_candidates(s, "", 1, 0).has("iron-bar"), "a tier cap")
	t.ok(Market.bulk_candidates(s, "vessel", 0, 0).has("sturdy-vessel"), "choosing vessels sells them")
	var gold := Market.bulk_sell(s, c)
	t.eq(gold, Market.bulk_value(c))
	t.eq(int(GameState.count(s, "oak-log")), 10)
	t.eq(int(GameState.count(s, "copper-ore")), 50)


func test_stock_rotates_and_holds_still_within_a_window() -> void:
	var s := _game(1e9)
	var hours := Market.window_seconds()
	var now := hours * 1000.0 + 5.0
	var a: Dictionary = Market.stock(s, now).duplicate(true)
	t.eq(Market.stock(s, now + 60.0).offers, a.offers, "the same stock all window")
	t.ok(a.offers.size() >= int(Market.cfg().rotation.offers), "a full stock")
	var b: Dictionary = Market.stock(s, now + hours)
	t.eq(int(b.window), int(a.window) + 1, "a new window rolls a new stock")
	# buying uses up an offer
	var st := Market.stock(s, now + hours)
	var idx := -1
	for i in st.offers.size():
		if st.offers[i].kind == "item":
			idx = i
	t.ok(idx >= 0)
	var left := int(st.offers[idx].left)
	t.eq(Market.buy_offer(s, idx, now + hours, _rng()), "")
	t.eq(int(st.offers[idx].left), left - 1)
	# limited offers turn up now and then, and only ones the islands allow
	_clear(s, 0)
	var seen := {}
	for w in 300:
		var roll := Market.roll_stock(s, w)
		for o in roll.offers:
			if o.get("limited", false):
				seen[o.id] = true
	t.ok(seen.size() > 0, "limited offers happen")
	t.ok(not seen.has("pearl") and not seen.has("shiny-egg"), "a Pearl or shiny egg needs cleared islands")
	_clear(s, 10)
	seen.clear()
	for w in 300:
		for o in Market.roll_stock(s, w).offers:
			if o.get("limited", false):
				seen[o.id] = true
	t.ok(seen.has("pearl") and seen.has("shiny-egg"), "all of them late on")


func test_limited_offer_sells_once() -> void:
	var s := _game(1e9)
	_clear(s, 10)
	var now := 0.0
	var w := 0
	while w < 500 and not Market.has_limited(s, now):
		w += 1
		now = w * Market.window_seconds() + 1.0
	t.ok(Market.has_limited(s, now), "found a limited offer")
	var idx := -1
	var st := Market.stock(s, now)
	for i in st.offers.size():
		if st.offers[i].get("limited", false):
			idx = i
	t.eq(Market.buy_offer(s, idx, now, _rng()), "")
	t.eq(Market.buy_offer(s, idx, now, _rng()), "Sold out.")
	t.ok(not Market.has_limited(s, now), "gone once bought")


func test_boosts() -> void:
	var s := _game(1e9)
	var c := Creatures.make(s, "sproutlet", 3, 10, false, [], "test")
	s.creatures[c.id] = c
	var base := Economy.aether_per_min(s)
	t.ok(base > 0.0, "a perched Aetherling makes Aether")
	t.eq(Market.buy_boost(s, "aether-incense"), "")
	t.near(Economy.aether_per_min(s), base * 1.5, 0.001, "+50% Aether")
	t.near(Market.boost_left(s, "aether-incense"), 3600.0, 0.01)
	Market.tick(s, 3599.0)
	t.ok(Market.boost_left(s, "aether-incense") > 0.0)
	Market.tick(s, 2.0)
	t.near(Economy.aether_per_min(s), base, 0.001, "runs out")
	# buying again adds time, up to the cap
	for i in 20:
		Market.buy_boost(s, "aether-incense")
	t.near(Market.boost_left(s, "aether-incense"), float(Market.cfg().boosts.maxHours) * 3600.0, 0.01, "capped")
	t.ok(Market.buy_boost(s, "aether-incense").begins_with("Already"), "no buying past the cap")
	# offline, a boost that ends partway counts for its share of the time
	s.market.boosts.clear()
	Market.add_boost(s, "aether-incense")   # 60 minutes
	var before := float(s.aether)
	Offline.apply(s, 7200.0, _rng())
	t.near(float(s.aether) - before, base * 120.0 * 1.25, base * 0.5, "half the time boosted")
	t.ok(not s.market.has("_frac"), "the offline share is cleared")
	t.eq(Market.boost_left(s, "aether-incense"), 0.0)
	# faster work
	var w := Creatures.make(s, "sproutlet", 1, 1, false, [], "test")
	s.creatures[w.id] = w
	var a := Skills.current_action(s, "woodcutting")
	var cd := Skills.worker_cooldown(w, "woodcutting", a, [], Skills.speed(s))
	Market.add_boost(s, "tinkers-brew")
	t.near(Skills.worker_cooldown(w, "woodcutting", a, [], Skills.speed(s)), cd / 1.2, 0.01, "20% faster")


func test_glimmer_lure_brings_rarer_wilds() -> void:
	var s := _game()
	var z: Dictionary = Data.zones["fractured-quarry"]
	var count := func() -> int:
		var r := _rng(9)
		var n := 0
		for i in 3000:
			if int(Expedition.roll_wild(s, z, r).rarity) > 1:
				n += 1
		return n
	var plain: int = count.call()
	Market.add_boost(s, "glimmer-lure")
	var lured: int = count.call()
	t.ok(lured > plain * 1.25, "more non-Dim wilds (%d vs %d)" % [lured, plain])


func test_market_eggs() -> void:
	var s := _game(1e9)
	var rng := _rng()
	t.eq(Market.egg_types(s), ["verdant"], "the starter's type only")
	t.ok(Market.egg_check(s, "pyric", 0).begins_with("Own a"), "a type you own")
	t.ok(Market.egg_check(s, "verdant", 1) != "", "Fine eggs need cleared islands")
	var free := Breeding.free_pod(s)
	t.eq(Market.buy_egg(s, "verdant", 0, rng, 100.0), "")
	var egg: Dictionary = s.pods[free]
	t.ok(egg.species in Market.base_species("verdant"), "a base Verdant Aetherling")
	t.ok(int(egg.rarity) >= 1 and int(egg.rarity) <= 3, "Common: Dim to Steady")
	t.eq(int(s.counters.hatchesSinceShiny), 0, "never counts toward the shiny pity")
	var h := Breeding.hatch(s, free, float(egg.readyAt))
	t.ok(not h.is_empty(), "hatches like any egg")
	# grades and the pods
	_clear(s, 8)
	t.eq(Market.grades()[Market.best_grade(s)].id, "royal")
	for i in s.pods.size():
		Market.buy_egg(s, "verdant", 4, rng, 0.0)
	t.eq(Market.egg_check(s, "verdant", 0), "Every Genesis Pod is busy.")
	for p in s.pods:
		t.ok(int(p.rarity) >= 5, "Royal eggs are Luminous or rarer")
	# a shiny-egg offer always hatches shiny
	var e := Market.make_egg(s, "verdant", 0, true, rng, 0.0)
	t.ok(bool(e.shiny))


## A buy made from a page showing an old stock window buys nothing once the stock has changed, so index i can
## never buy a different offer at a different price.
func test_buying_from_a_changed_stock_buys_nothing() -> void:
	var s := _game(1e9)
	var rng := _rng()
	var now := 10.0 * Market.window_seconds() + 5.0
	var w := Market.window(now)
	var later := now + Market.window_seconds()
	var o: Dictionary = Market.stock(s, now).offers[0]
	var left := int(o.left)
	t.eq(Market.buy_offer(s, 0, later, rng, w), Market.STOCK_CHANGED, "an offer")
	t.eq(float(s.gold), 1e9, "no gold taken")
	t.eq(int(o.left), left, "the old offer is untouched")
	var pods: Array = s.pods.duplicate(true)
	var f: Dictionary = Market.stock(s, now).featured
	t.eq(Market.buy_featured(s, later, rng, w), Market.STOCK_CHANGED, "the featured egg")
	t.eq(float(s.gold), 1e9, "no gold taken for the egg")
	t.eq(s.pods, pods, "no egg laid")
	t.ok(f.is_empty() or int(f.left) == 1, "the old featured egg is still for sale")
	t.eq(Market.buy_offer(s, 0, now, rng, w), "", "the same window still buys")


## Buying none (or a negative number) is refused, not reported as a purchase.
func test_buying_nothing_is_refused() -> void:
	var s := _game(1e6)
	var id: String = Market.catalog("vessel")[0].id
	var before := GameState.count(s, id)
	for qty in [0, -5]:
		t.ok(Market.buy(s, id, qty) != "", "qty %d is refused" % qty)
	t.eq(float(s.gold), 1e6, "no gold taken")
	t.eq(GameState.count(s, id), before, "no items added")


## Every discounted offer really costs less than the Boosts and wares tabs (cheap items used to round the discount
## away per unit), never less than selling it back, and a boost offer follows the boost's price as islands clear.
func test_stock_discounts_are_real() -> void:
	var s := _game(1e9)
	var items := 0
	for w in 200:
		for o in Market.roll_stock(s, w).offers:
			if o.get("limited", false) or not o.has("discount"):
				continue
			if o.kind == "item":
				items += 1
				var full: int = Market.buy_price(o.item) * int(o.qty)
				t.ok(int(o.gold) < full, "%d× %s costs %d, less than %d" % [int(o.qty), o.item, int(o.gold), full])
				t.ok(int(o.gold) > int(Data.items[o.item].sell) * int(o.qty), "and more than it sells back for")
				t.near(float(o.discount), 1.0 - float(o.gold) / full, 0.0001, "the chip shows the true discount")
	t.ok(items > 0, "item offers were rolled")
	var boost := {}
	var now := 0.0
	for w in 200:
		now = w * Market.window_seconds() + 1.0
		for o in Market.stock(s, now).offers:
			if o.kind == "boost":
				boost = o
		if not boost.is_empty():
			break
	t.ok(not boost.is_empty(), "a boost offer turned up")
	if boost.is_empty():
		return
	var before := int(boost.gold)
	_clear(s, 2)
	Market.stock(s, now)
	t.eq(int(boost.gold), ceili(Market.boost_price(s, boost.boost) * (1.0 - float(boost.discount))), "priced from today's boost price")
	t.ok(int(boost.gold) > before, "which went up with the clears")


## "Sell treasure" takes every unlocked item nothing uses, and nothing a recipe, build or pod needs.
func test_treasure_is_what_nothing_uses() -> void:
	var s := _game()
	GameState.add_item(s, "sunken-trinket", 3)
	GameState.add_item(s, "seedcache", 2)
	GameState.add_item(s, "oak-log", 50)
	Market.toggle_item_lock(s, "seedcache")
	var c := Market.treasure_candidates(s)
	t.eq(int(c.get("sunken-trinket", 0)), 3, "treasure sells")
	t.ok(not c.has("seedcache"), "a locked one stays")
	t.ok(not c.has("oak-log"), "logs are used in recipes")
	for id in c:
		t.eq(Economy.uses(id), [], "%s has no use" % id)
	t.ok(Economy.uses("oak-log").any(func(u): return u.kind == "recipe"), "oak logs list their recipes")
