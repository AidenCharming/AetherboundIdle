"""bugtest_benchmark: plays Aetherbound Idle like a normal player for a while and reports what broke.

    python tools/bridge.py run bugtest_benchmark [--minutes 10] [--seed 1] [--compress 8] [--continue]

It follows Overseer Vance's goal chain (one handler per check kind in scripts/sim/goals.gd KINDS), keeps
Aetherlings working, keeps an expedition running, breeds and hatches, sells and buys, sweeps every screen
every few minutes, and once per run does a save / title / load round trip and a jump of a few hours away.
Everything goes through real clicks on visible buttons; `ctx.gap` records any bridge shortcut.
"""
import itertools

from _player import GameDied, NAV

KINDS = ["working", "item", "expedition", "captures", "creatures", "species", "upgrades", "slots", "form",
         "hybrids", "specials", "counter", "skill_level", "zone", "own_type", "rarity", "creature_level",
         "total_level", "skills_at"]

MARKET_TABS = ["Today's stock", "Vessels", "Materials", "Boosts", "Work slots"]
AETHERLOG_TABS = ["Creaturedex", "Recipes", "Milestones"]
EXPEDITION_TABS = ["Party", "Auto-bind", "Supplies"]
OPTION_TABS = ["Audio", "Display", "Gameplay"]
KEEP_ITEM_CATS = ("vessel", "meal", "rare", "part", "component", "thread", "bar")


class Benchmark:
    def __init__(self, ctx):
        self.ctx = ctx
        self.p = {}
        self.lap = 0
        self.last_goal_index = -1
        self.goal_since = 0.0
        self.last_party_change = -999.0
        self.zone_attempt = {}        # zone id -> real second we first sent the party there
        self.given_up_zones = set()
        self.next_sweep = 45.0
        self.sweeps = 0
        self.round_trip = None
        self.offline = None
        self.did_round_trip = False
        self.did_offline = False
        self.chores = [self.assign_idle, self.best_actions, self.keep_expedition, self.eggs, self.economy,
                       self.milestones, self.keep_vessels]
        self.chore_i = 0
        self.breed_fail = {}          # reason -> count, for the report
        self.last_breed_try = -999.0
        self.last_shop = -999.0
        self.parked = False
        # compression: the time-away jump takes up to 3 h of the budget, the rest is spread over the run
        self.jump_hours = min(3.0, ctx.compress * 0.4) if ctx.compress > 0 else 0.0
        rest = max(0.0, ctx.compress - self.jump_hours)
        self.skips_n = max(1, int(round(ctx.minutes))) if rest > 0 else 0
        self.skip_hours = rest / self.skips_n if self.skips_n else 0.0
        self.skips_done = 0

    # ------------------------------------------------------------ reading

    def refresh(self):
        self.p = self.ctx.player()
        self.ctx._player_cache = self.p
        return self.p

    def creature(self, cid):
        for c in self.p.get("creatures", []):
            if c["id"] == cid:
                return c
        return {}

    def skill(self, sid):
        return self.p["skills"][sid]

    def can_work(self, c, sid):
        t = self.skill(sid)["type"]
        return t is None or t in c["types"]

    def party_locked(self):
        return self.p["expedition"]["running"]

    def producers(self, item):
        """[(skill id, action)] that make this item."""
        out = []
        for sid, sk in self.p["skills"].items():
            for a in sk["actions"]:
                if a["output"] == item:
                    out.append((sid, a))
        return out

    def game_hours(self):
        return self.p.get("game_seconds", 0.0) / 3600.0

    # ------------------------------------------------------------ the run

    def play(self):
        ctx = self.ctx
        if not ctx.options.get("continue"):
            ctx.log("new game in slot 2")
            ctx.send("new", slot=2, timeout=60)
        else:
            ctx.log("continuing slot 2")
            ctx.send("load", slot=2, timeout=60)
        ctx.send("focus")
        ctx.wait(1.0)
        self.intro()
        while not ctx.out_of_time():
            self.lap += 1
            st = ctx.state()
            if st.get("scene") != "main":
                ctx.stuck("the game left the game screen (scene %s): loading slot 2 again" % st.get("scene"))
                ctx.gap("got back into the game with the bridge's load")
                ctx.send("load", slot=2, timeout=60)
                ctx.wait(1.0)
                continue
            ctx.clear_overlays()
            self.refresh()
            self.timed_events()
            if ctx.out_of_time():
                break
            self.claim_goal()
            self.work_goal()
            ctx.check("goal work")
            chore = self.chores[self.chore_i % len(self.chores)]
            self.chore_i += 1
            self.refresh()
            chore()
            ctx.check(chore.__name__)
            if ctx.elapsed() >= self.next_sweep:
                self.sweep()
                self.next_sweep = ctx.elapsed() + 180.0
            ctx.wait(0.5)
        ctx.log("time's up after %d laps" % self.lap)
        self.refresh()
        self.claim_goal()
        ctx.clear_overlays()
        ctx.go("sanctum")
        ctx.shot("end")
        ctx.check("the end")

    def intro(self):
        ctx = self.ctx
        m = ctx.modals().get("modals", [])
        if m and m[-1]["title"] == "A new Sanctum":
            ctx.screens["welcome"] = ctx.shot("welcome")
            if ctx.click("Let's start: open Woodcutting"):
                st = ctx.state()
                if st.get("screen") != "skill" or st.get("screen_arg") != "woodcutting":
                    ctx.breach("\"Let's start\" should open Woodcutting, the game shows %s %s" % (st.get("screen"), st.get("screen_arg")))
        elif not ctx.options.get("continue"):
            ctx.breach("a new game didn't open Overseer Vance's welcome")

    def timed_events(self):
        """Compression skips, the save/load round trip and the time-away jump, spread over the run."""
        ctx = self.ctx
        total = ctx.minutes * 60.0
        frac = ctx.elapsed() / total
        if self.skips_n and self.skips_done < self.skips_n and frac >= (self.skips_done + 1) / (self.skips_n + 1.0):
            self.skips_done += 1
            summary = ctx.skip(self.skip_hours, "compress %d/%d" % (self.skips_done, self.skips_n))
            self.after_away(summary, shot=self.skips_done == 1)
        if not self.did_round_trip and frac >= 0.45:
            self.did_round_trip = True
            self.save_load()
        if not self.did_offline and frac >= 0.65:
            self.did_offline = True
            if self.jump_hours > 0:
                self.offline_jump()
            else:
                ctx.note("the time-away jump was skipped: --compress 0 means real time only")

    # ------------------------------------------------------------ goals

    def claim_goal(self):
        ctx = self.ctx
        g = self.p.get("goal", {})
        if g.get("index", -1) != self.last_goal_index:
            self.last_goal_index = g.get("index", -1)
            self.goal_since = ctx.elapsed()
            ctx.log("goal %s: %s (%s)" % (g.get("index"), g.get("id"), g.get("text", "")))
        if not g.get("done"):
            return
        ctx.go("sanctum")
        if not ctx.has_button("Claim", exact=True):
            ctx.wait(1.2)
            if not ctx.has_button("Claim", exact=True):
                ctx.breach("goal %s is done but the Sanctum shows no Claim button" % g.get("id"))
                # a player would click around: another page and back rebuilds the Sanctum
                ctx.go("nexus")
                ctx.go("sanctum")
        with ctx.clip_once("goal-claim"):
            claimed = ctx.click("Claim", exact=True)
            if claimed and ctx.options.get("movie"):
                ctx.wait(1.5)   # the toast slides in
        if claimed:
            before = g["index"]
            self.refresh()
            after = self.p["goal"].get("index", before)
            if after == before + 1:
                ctx.goals.append({"index": before, "id": g["id"], "text": g.get("text", ""),
                                  "real_s": round(ctx.elapsed(), 1), "game_h": round(self.game_hours(), 2)})
                ctx.log("CLAIMED goal %d %s" % (before, g["id"]))
                if len(ctx.goals) in (1, 5, 10, 20):
                    ctx.shot("goal-%d" % len(ctx.goals))
            else:
                ctx.breach("clicking Claim on goal %s moved goals.index from %d to %d" % (g["id"], before, after))
        else:
            ctx.stuck("couldn't claim goal %s" % g.get("id"))

    def work_goal(self):
        g = self.p.get("goal", {})
        if not g.get("id") or g.get("done"):
            return
        c = g["check"]
        if not self.parked and c["kind"] in ("item", "counter") and g.get("need", 0) - g.get("have", 0) <= max(3, g.get("need", 0) // 3):
            self.watch_goal_on_sanctum(g)
            return
        kind = c["kind"]
        handler = getattr(self, "goal_" + kind, None)
        if handler is None:
            self.ctx.stuck("no handler for goal kind %r (goal %s)" % (kind, g["id"]))
            return
        handler(c)

    def watch_goal_on_sanctum(self, g):
        """Once per run, like a player waiting for the last few logs: stay on the Sanctum while a goal
        finishes and check its card offers Claim without leaving the page."""
        ctx = self.ctx
        self.parked = True
        if not ctx.go("sanctum"):
            return
        ctx.log("watching goal %s finish on the Sanctum (%s/%s)" % (g["id"], g.get("have"), g.get("need")))
        end = ctx.elapsed() + 75
        while ctx.elapsed() < end and not ctx.out_of_time():
            ctx.wait(2.0)
            now = ctx.goal()
            if now.get("index") != g["index"]:
                return
            if now.get("done"):
                ctx.wait(1.5)
                if ctx.state().get("screen") == "sanctum" and not ctx.has_button("Claim", exact=True):
                    ctx.breach("goal %s finished while the Sanctum was open, but its card shows no Claim" % g["id"])
                else:
                    ctx.log("Claim showed up on the open Sanctum")
                return
        ctx.log("goal %s didn't finish while watching" % g["id"])

    def goal_working(self, c):
        self.ensure_worker(c["skill"], goal=True)

    def goal_item(self, c):
        item = c["item"]
        prods = [(sid, a) for sid, a in self.producers(item) if self.skill(sid)["usable"]]
        if not prods:
            self.ctx.stuck("nobody can make %s yet" % item)
            return
        sid, a = prods[0]
        self.ensure_worker(sid, goal=True)
        if not a["unlocked"]:
            return  # levelling the skill is all there is to do
        for inp in a["inputs"]:
            if inp == "aether":
                continue
            if self.p["items"].get(inp, 0) < 3 * float(a["inputs"][inp]):
                self.feed(inp)
        self.set_action(sid, a["id"])

    def feed(self, item):
        """Makes sure something produces an input that is running low."""
        for sid, a in self.producers(item):
            sk = self.skill(sid)
            if sk["usable"] and a["unlocked"]:
                self.ensure_worker(sid)
                self.set_action(sid, a["id"])
                return

    def goal_expedition(self, c):
        self.keep_expedition(force=True)

    def goal_captures(self, c):
        self.keep_vessels()
        self.keep_expedition(force=True)
        self.throw_pending()

    def goal_creatures(self, c):
        self.goal_captures(c)
        if len(self.p["creatures"]) >= 2:
            self.breed()

    def goal_species(self, c):
        self.keep_expedition(force=True)
        self.breed(want="new")

    def goal_hybrids(self, c):
        self.breed(want="hybrid")
        self.eggs()

    def goal_specials(self, c):
        self.breed(want="special")
        self.eggs()

    def goal_counter(self, c):
        name = c["counter"]
        if name == "bred":
            self.breed()
        elif name == "hatches":
            self.eggs(hurry=True)
            self.breed()
        else:  # kills, bossKills
            self.keep_expedition(force=True)

    def goal_skill_level(self, c):
        self.ensure_worker(c["skill"], goal=True)
        self.feed_skill(c["skill"])

    def feed_skill(self, sid):
        sk = self.skill(sid)
        a = self.best_action(sid)
        if a:
            for inp in a["inputs"]:
                if inp != "aether" and self.p["items"].get(inp, 0) < 5 * float(a["inputs"][inp]):
                    self.feed(inp)

    def goal_zone(self, c):
        self.keep_expedition(force=True, zone=c["zone"], strong=True)

    def goal_own_type(self, c):
        zones = [z for z in self.p["expedition"]["zones"] if z["type"] == c["type"] and z["unlocked"]]
        if not zones:
            # the island of that type opens after the one before it: clear the way
            self.keep_expedition(force=True, strong=True)
            return
        self.keep_expedition(force=True, zone=zones[0]["id"], strong=True)

    def goal_slots(self, c):
        # the next slot opens with skill level: push the skill closest to it
        best = max(self.p["skills"].items(), key=lambda kv: (kv[1]["usable"], kv[1]["level"]))
        self.ensure_worker(best[0], goal=True)
        for sid, sk in self.p["skills"].items():
            if sk["slot_price"] >= 0 and not sk["slot_error"] and self.p["gold"] >= sk["slot_price"]:
                self.buy_slot(sid)
                return

    def goal_upgrades(self, c):
        if not self.build_upgrade():
            self.sell_surplus()

    def goal_form(self, c):
        self.keep_expedition(force=True)

    def goal_rarity(self, c):
        self.breed(want="rare")
        self.eggs()
        self.keep_expedition()

    def goal_creature_level(self, c):
        self.keep_expedition(force=True, strong=True)

    def goal_total_level(self, c):
        self.assign_idle()
        self.best_actions()

    def goal_skills_at(self, c):
        self.assign_idle()
        self.best_actions()

    # ------------------------------------------------------------ work

    def ensure_worker(self, sid, goal=False):
        """Someone works in this skill: an idle Aetherling first, else one moved from elsewhere."""
        sk = self.skill(sid)
        if sk["workers"]:
            return True
        if not sk["usable"]:
            if goal:
                self.ctx.log("%s needs a %s Aetherling first" % (sid, sk["type"]))
            return False
        cands = [c for c in self.p["creatures"] if self.can_work(c, sid)]
        if self.party_locked():
            cands = [c for c in cands if c["job"] != "party"]
        counts = {k: len(v["workers"]) for k, v in self.p["skills"].items()}
        goal_skill = self.p["goal"].get("check", {}).get("skill")

        def rank(c):
            if c["job"] in ("", "rest"):
                return (0, -c["level"])
            if c["job"] == "skill" and counts.get(c["skill"], 0) > 1:
                return (1, -c["level"])
            if c["job"] == "skill" and c["skill"] != goal_skill:
                return (2, -c["level"])
            if c["job"] == "party" and len(self.p["expedition"]["party"]) > 1:
                return (3, c["power"])
            return (4, c["power"])

        cands.sort(key=rank)
        if not cands:
            self.ctx.log("nobody can work %s" % sid)
            return False
        if not goal and rank(cands[0])[0] >= 2:
            return False  # housekeeping never pulls someone off another job
        return self.assign(cands[0]["id"], sid)

    def assign(self, cid, sid):
        ctx = self.ctx
        if not ctx.go("skill", sid):
            return False
        if not ctx.click("Assign an Aetherling"):
            ctx.stuck("no \"Assign an Aetherling\" on %s" % sid)
            return False
        ok = ctx.click(cid=cid)
        if not ok:
            ctx.stuck("the worker picker for %s didn't list %s" % (sid, cid))
            ctx.clear_overlays()
            return False
        ctx.clear_overlays()
        self.refresh()
        c = self.creature(cid)
        if c.get("skill") != sid:
            ctx.breach("picked %s for %s but it's now %s %s" % (cid, sid, c.get("job"), c.get("skill")))
            return False
        return True

    def best_action(self, sid):
        sk = self.skill(sid)
        unlocked = [a for a in sk["actions"] if a["unlocked"]]
        if not unlocked:
            return None
        makeable = [a for a in unlocked if not a["inputs"] or a["can_make"]]
        return (makeable or unlocked)[-1]

    def set_action(self, sid, action_id):
        ctx = self.ctx
        sk = self.skill(sid)
        if sk["action"] == action_id:
            return True
        a = next((a for a in sk["actions"] if a["id"] == action_id), None)
        if not a or not a["unlocked"]:
            return False
        if not ctx.go("skill", sid):
            return False
        if not ctx.click(a["name"]):
            ctx.stuck("no task card %r on %s" % (a["name"], sid))
            return False
        self.refresh()
        if self.skill(sid)["action"] != action_id:
            ctx.breach("clicked the %r card but %s still does %s" % (a["name"], sid, self.skill(sid)["action"]))
            return False
        return True

    def assign_idle(self):
        """Idle Aetherlings go to work where there's a free slot (their own type's skills first)."""
        moved = 0
        for c in sorted(self.p["creatures"], key=lambda c: -c["level"]):
            if c["job"] not in ("", "rest") or moved >= 2:
                continue
            free = [(sid, sk) for sid, sk in self.p["skills"].items()
                    if sk["usable"] and len(sk["workers"]) < sk["slots"] and self.can_work(c, sid)]
            if not free:
                continue
            free.sort(key=lambda kv: (kv[1]["type"] is None, len(kv[1]["workers"]), kv[1]["level"]))
            if self.assign(c["id"], free[0][0]):
                moved += 1
                self.refresh()

    def best_actions(self):
        """Each skill with workers does its best unlocked task (a goal's item task comes first)."""
        g = self.p["goal"].get("check", {})
        changes = 0
        for sid, sk in self.p["skills"].items():
            if not sk["workers"] or changes >= 2:
                continue
            if g.get("kind") == "item" and any(s == sid for s, _ in self.producers(g.get("item", ""))):
                continue
            a = self.best_action(sid)
            if a and a["id"] != sk["action"] and a["can_make"]:
                if self.set_action(sid, a["id"]):
                    changes += 1

    # ------------------------------------------------------------ expeditions

    def pick_zone(self, want=None):
        zones = self.p["expedition"]["zones"]
        if want:
            z = next((z for z in zones if z["id"] == want), None)
            if z and z["unlocked"]:
                return z
        open_ = [z for z in zones if z["unlocked"]]
        frontier = [z for z in open_ if not z["cleared"] and z["id"] not in self.given_up_zones]
        if frontier:
            return frontier[0]
        cleared = [z for z in open_ if z["cleared"]]
        return (cleared or open_)[-1]

    def party_target(self):
        n = len(self.p["creatures"])
        kind = self.p["goal"].get("check", {}).get("kind", "")
        if n == 1:
            return 0 if kind in ("working", "item", "skill_level") else 1
        return min(self.p["expedition"]["party_size"], n - 1 if n <= 4 else 3)

    def keep_expedition(self, force=False, zone=None, strong=False):
        ctx = self.ctx
        ex = self.p["expedition"]
        target = self.party_target()
        if target == 0 and not force:
            return
        target = max(target, 1)
        z = self.pick_zone(zone)
        # a frontier island that hasn't fallen in 4 real minutes: farm the one before it for a while
        if not zone and z["id"] not in self.zone_attempt:
            self.zone_attempt[z["id"]] = ctx.elapsed()
        elif not zone and not z["cleared"] and ctx.elapsed() - self.zone_attempt[z["id"]] > 240:
            self.given_up_zones.add(z["id"])
            ctx.note("the party couldn't clear %s in 4 minutes; farming the island before it" % z["name"])
            z = self.pick_zone()
        party = ex["party"]
        need_party = len(party) < target
        want_ids = self.strongest(target) if strong else []
        need_swap = strong and set(want_ids) - set(party) and ctx.elapsed() - self.last_party_change > 90
        running_right = ex["running"] and ex["zone"] == z["id"]
        if running_right and not need_party and not need_swap:
            self.throw_pending()
            return
        if not ctx.go("expeditions"):
            return
        if not ctx.has_button("Party", exact=True):
            ctx.click("Show the island list", quiet=True)
        ctx.click("Party", quiet=True)
        if (need_party or need_swap) and ex["running"]:
            if not self.select_zone(ex["zone"]) or not ctx.click("Stop"):
                ctx.stuck("couldn't stop the expedition to change the party")
                return
            self.refresh()
            ex = self.p["expedition"]
        if need_party or need_swap:
            self.set_party(target, want_ids)
            self.last_party_change = ctx.elapsed()
        self.refresh()
        if not self.p["expedition"]["party"]:
            ctx.stuck("no party to send out")
            return
        if not self.select_zone(z["id"]):
            return
        if self.p["expedition"]["running"] and self.p["expedition"]["zone"] == z["id"]:
            return
        label = "Move here" if self.p["expedition"]["running"] else "Explore"
        if not ctx.click(label):
            ctx.stuck("no %r for %s" % (label, z["name"]))
            return
        self.refresh()
        ex = self.p["expedition"]
        if not ex["running"] or ex["zone"] != z["id"]:
            ctx.breach("clicked %r for %s but the expedition is %s at %s" % (label, z["id"], ex["running"], ex["zone"]))
        else:
            ctx.log("expedition running at %s with %s" % (z["id"], ex["party"]))

    def select_zone(self, zone_id):
        ctx = self.ctx
        z = next((z for z in self.p["expedition"]["zones"] if z["id"] == zone_id), None)
        if not z:
            return False
        # exact: with the island list folded, a loose match on the name hits the Explore button's tooltip
        # ("Explore Whisperleaf Hollow") and starts the run instead of selecting the island
        if ctx.click(z["name"], quiet=True, exact=True):
            return True
        ctx.click("Show the island list", quiet=True)
        if ctx.click(z["name"], exact=True):
            return True
        ctx.stuck("no island card for %s" % z["name"])
        return False

    def strongest(self, n):
        mons = sorted(self.p["creatures"], key=lambda c: -c["power"])
        goal_skill = self.p["goal"].get("check", {}).get("skill")
        keep = [c for c in mons if not (c["job"] == "skill" and c["skill"] == goal_skill
                                        and len(self.skill(goal_skill)["workers"]) == 1)]
        return [c["id"] for c in keep[:n]]

    def set_party(self, target, want_ids):
        """Fills the party up to `target` and swaps in the strongest (wanted) ones, through the pickers."""
        ctx = self.ctx
        self.refresh()
        party = list(self.p["expedition"]["party"])
        want = want_ids or self.strongest(target)
        # swap: the weakest member out for a wanted one that's missing
        missing = [cid for cid in want if cid not in party]
        extra = [cid for cid in party if cid not in want]
        for i, cid in enumerate(extra):
            if not missing:
                break
            slot = party.index(cid)
            if ctx.click("Swap", slot) and ctx.click(cid=missing[0]):
                ctx.log("party: swapped %s for %s" % (cid, missing[0]))
                party[slot] = missing.pop(0)
            else:
                ctx.clear_overlays()
        while len(party) < target and missing:
            if not ctx.click("Add an Aetherling"):
                ctx.stuck("no \"Add an Aetherling\" in the party")
                return
            cid = missing.pop(0)
            if not ctx.click(cid=cid):
                ctx.stuck("the party picker didn't list %s" % cid)
                ctx.clear_overlays()
                return
            party.append(cid)
            ctx.clear_overlays()
            self.refresh()
            party = list(self.p["expedition"]["party"])

    def throw_pending(self):
        ex = self.p["expedition"]
        if ex["pending"] and ex["pending_throwable"]:
            if self.ctx.go("expeditions") and self.ctx.click("Throw at all"):
                self.refresh()
                if self.p["expedition"]["pending"] >= ex["pending"]:
                    self.ctx.log("Throw at all bound nobody this time (%d still waiting)" % self.p["expedition"]["pending"])

    def keep_vessels(self):
        """Vessels running low: Fabrication makes Tinker's Vessels; the Market sells them."""
        if self.p["vessels"] >= 5:
            return
        fab = self.skill("fabrication")
        if fab["workers"] and fab["action"] != "tinkerers-vessel":
            self.set_action("fabrication", "tinkerers-vessel")
        if self.p["gold"] > 60 and self.ctx.go("market"):
            self.ctx.click("Vessels", quiet=True)
            for amount in ("Buy 10", "Buy 1"):
                b = self.ctx.button(amount)
                if b and not b["disabled"]:
                    self.ctx.click(amount)
                    break
        self.throw_pending()

    # ------------------------------------------------------------ breeding

    def breed(self, want="any"):
        ctx = self.ctx
        if not any(pod["empty"] for pod in self.p["pods"]):
            return False
        if ctx.elapsed() - self.last_breed_try < 20:
            return False
        self.last_breed_try = ctx.elapsed()
        mons = self.p["creatures"]
        pairs = [[a["id"], b["id"]] for a, b in itertools.combinations(mons, 2)]
        ctx.rng.shuffle(pairs)
        res = ctx.send("breed_check", pairs=pairs[:80], tier=1).get("results", [])
        ok = [r for r in res if not r.get("error")]
        if not ok:
            reasons = {}
            for r in res:
                reasons[r.get("error")] = reasons.get(r.get("error"), 0) + 1
            why = max(reasons, key=reasons.get) if reasons else "fewer than two Aetherlings"
            self.breed_fail[why] = self.breed_fail.get(why, 0) + 1
            ctx.log("can't breed yet: %s" % why)
            return False

        def score(r):
            offs = r["offspring"]
            a, b = self.creature(r["a"]), self.creature(r["b"])
            s = (a.get("rarity", 1) + b.get("rarity", 1)) * 0.1
            if want in ("new", "any") and any(o["new"] for o in offs):
                s += 5
            if want == "hybrid" and any(o["hybrid"] and o["new"] for o in offs):
                s += 10
            if want == "hybrid" and any(o["hybrid"] for o in offs):
                s += 3
            if want == "special" and any(o["special"] for o in offs):
                s += 20
            return s

        ok.sort(key=score, reverse=True)
        best = ok[0]
        tier = 1
        for t in range(4, 1, -1):
            r = ctx.send("breed_check", pairs=[[best["a"], best["b"]]], tier=t).get("results", [])
            if r and not r[0].get("error"):
                tier = t
                break
        return self.lay_egg(best["a"], best["b"], tier)

    def lay_egg(self, a, b, tier):
        ctx = self.ctx
        if not ctx.go("pods"):
            return False
        bred = int(self.p["counters"].get("bred", 0))
        if not self.pick_parent("A", a):
            ctx.clear_overlays()
            # the picker leaves out the other parent: choose B first, then A
            if not (self.pick_parent("B", b) and self.pick_parent("A", a)):
                ctx.stuck("couldn't choose the parents %s and %s" % (a, b))
                ctx.clear_overlays()
                return False
        elif not self.pick_parent("B", b):
            ctx.stuck("couldn't choose parent B %s" % b)
            ctx.clear_overlays()
            return False
        ctx.click("Tier %d ·" % tier, quiet=True)
        lay = ctx.button("Lay an egg")
        if not lay or lay["disabled"]:
            ctx.stuck("\"Lay an egg\" is %s for %s + %s at tier %d although breed_check said yes" %
                      ("missing" if not lay else "disabled (%s)" % lay.get("tip", ""), a, b, tier))
            return False
        ctx.click("Lay an egg")
        self.refresh()
        if int(self.p["counters"].get("bred", 0)) != bred + 1:
            ctx.breach("clicked \"Lay an egg\" but the bred counter went %d -> %d" % (bred, self.p["counters"].get("bred", 0)))
            return False
        ctx.log("laid an egg: %s + %s, tier %d" % (a, b, tier))
        if "pods-egg" not in ctx.screens:
            ctx.screens["pods-egg"] = ctx.shot("pods-egg")
        return True

    def pick_parent(self, which, cid):
        ctx = self.ctx
        if not ctx.click("Choose parent %s" % which, quiet=True):
            return False
        if not ctx.click(cid=cid, quiet=True):
            ctx.clear_overlays()
            return False
        ctx.clear_overlays()
        return True

    def eggs(self, hurry=False):
        """Hatches ready eggs (and plays through the reveals); speeds one up when asked and affordable."""
        ctx = self.ctx
        pods = self.p["pods"]
        ready = [x for x in pods if not x["empty"] and x["ready"]]
        hatches = int(self.p["counters"].get("hatches", 0))
        if ready:
            if not ctx.go("pods"):
                return
            label = "Hatch all %d" % len(ready) if len(ready) >= 2 else "Hatch"
            with ctx.clip_once("hatch-reveal"):
                if not ctx.click(label):
                    ctx.stuck("%d eggs are ready but there's no %r" % (len(ready), label))
                    return
                ctx.wait(0.3)
                rv = ctx.modals().get("reveal", {})
                if rv.get("active") and "hatch-reveal" not in ctx.screens:
                    ctx.wait(1.5)
                    ctx.screens["hatch-reveal"] = ctx.shot("hatch-reveal")
                ctx.wait_for(lambda st: st.get("reveal", {}).get("can_continue"), 8)
                ctx.clear_overlays()
                if ctx.options.get("movie"):
                    ctx.wait(1.0)
            self.refresh()
            got = int(self.p["counters"].get("hatches", 0)) - hatches
            if got != len(ready):
                ctx.breach("hatched %d of %d ready eggs" % (got, len(ready)))
        elif hurry:
            waiting = [x for x in pods if not x["empty"]]
            if waiting:
                egg = min(waiting, key=lambda x: x["speed_up"])
                if self.p["aether"] >= egg["speed_up"] * 1.5 and ctx.go("pods"):
                    if ctx.click("Speed up"):
                        self.refresh()
        if any(x["empty"] for x in self.p["pods"]) and len(self.p["creatures"]) >= 2:
            self.breed()

    # ------------------------------------------------------------ the economy

    def economy(self):
        """Now and then: sell surplus, build an upgrade, buy something in the Market or the Egg Market."""
        self.sell_surplus()
        self.refresh()
        self.build_upgrade()
        if self.ctx.elapsed() - self.last_shop > 150:
            self.last_shop = self.ctx.elapsed()
            self.shop()

    def needed_items(self):
        need = set()
        for sk in self.p["skills"].values():
            for a in sk["actions"]:
                if a["level"] <= sk["level"] + 20:
                    need.update(a["inputs"].keys())
        for u in self.p["upgrades"]:
            need.update(u.get("cost", {}).keys())
        return need

    def sell_surplus(self):
        ctx = self.ctx
        need = self.needed_items()
        meta = self.p.get("item_meta", {})
        cands = []
        for iid, n in self.p["items"].items():
            name, cat, element, price = (meta.get(iid) or ["", "", "", 0])
            if not name or iid in need or cat in KEEP_ITEM_CATS or element or n < 30 or price <= 0:
                continue
            cands.append((n * price, iid, name))
        if not cands:
            return
        cands.sort(reverse=True)
        _, iid, name = cands[0]
        if not ctx.go("inventory"):
            return
        if not ctx.click(name):
            ctx.click("Everything", quiet=True)
            if not ctx.click(name):
                ctx.stuck("no item tile for %s in the Inventory" % name)
                return
        gold = self.p["gold"]
        if ctx.click("Sell all but 10"):
            self.refresh()
            if self.p["gold"] <= gold:
                ctx.breach("sold %s but gold went %.0f -> %.0f" % (iid, gold, self.p["gold"]))
            else:
                ctx.log("sold %s: +%.0f gold" % (iid, self.p["gold"] - gold))

    def build_upgrade(self):
        ctx = self.ctx
        affordable = [u for u in self.p["upgrades"] if u["affordable"]]
        if not affordable:
            return False
        if not ctx.go("works"):
            return False
        built = sum(u["level"] for u in self.p["upgrades"])
        for attempt in range(8):
            for i, b in enumerate([b for b in ctx.buttons() if b["text"] == "Build"]):
                if not b["disabled"]:
                    ctx.click("Build", i)
                    self.refresh()
                    now = sum(u["level"] for u in self.p["upgrades"])
                    if now != built + 1:
                        ctx.breach("clicked Build but upgrade levels went %d -> %d" % (built, now))
                    else:
                        ctx.log("built an upgrade (%d levels now)" % now)
                    return True
            ctx.send("scroll", x=900, y=550, steps=3)
        ctx.stuck("Sanctum Works: %s is affordable but no Build button is enabled" % affordable[0]["name"])
        return False

    def buy_slot(self, sid):
        ctx = self.ctx
        if not ctx.go("market"):
            return
        ctx.click("Work slots")
        if ctx.click("Buy a slot") and ctx.click("Buy the slot"):
            ctx.log("bought a %s slot" % sid)

    def shop(self):
        ctx = self.ctx
        gold = self.p["gold"]
        if gold > 500 and ctx.go("market"):
            ctx.click("Today's stock", quiet=True)
            b = next((b for b in ctx.buttons() if b["text"] in ("Buy", "Buy now") and not b["disabled"]), None)
            if b:
                ctx.click_at(b["x"], b["y"], "(a Market offer)")
                self.refresh()
                if self.p["gold"] >= gold:
                    ctx.log("the Market offer click didn't spend gold (%.0f -> %.0f)" % (gold, self.p["gold"]))
        if any(x["empty"] for x in self.p["pods"]) and ctx.go("eggmarket"):
            b = next((b for b in ctx.buttons() if b["text"] == "Buy egg" and not b["disabled"]), None)
            if b:
                pods_full = sum(1 for x in self.p["pods"] if not x["empty"])
                ctx.click_at(b["x"], b["y"], "(Buy egg)")
                self.refresh()
                if sum(1 for x in self.p["pods"] if not x["empty"]) != pods_full + 1:
                    ctx.breach("bought an egg but the pods didn't fill")
                else:
                    ctx.log("bought a market egg")

    def milestones(self):
        ctx = self.ctx
        if not self.p.get("milestones_to_claim"):
            return
        if not ctx.go("aetherlog"):
            return
        ctx.click("Milestones")
        for _ in range(6):
            if not ctx.click("Claim", quiet=True, exact=True):
                break
            ctx.clear_overlays()
        self.refresh()
        if self.p.get("milestones_to_claim"):
            ctx.stuck("%d milestone rewards still claimable after clicking Claim" % self.p["milestones_to_claim"])

    # ------------------------------------------------------------ coverage, save/load, time away

    def sweep(self):
        """Every page, every tab, the menus: once per run each gets a screenshot."""
        ctx = self.ctx
        self.sweeps += 1
        ctx.log("coverage sweep %d" % self.sweeps)
        self.refresh()

        def visit(label, screen, arg=""):
            if ctx.go(screen, arg):
                ctx.wait(0.4)
                if label not in ctx.screens:
                    ctx.screens[label] = ctx.shot(label)
                ctx.check("visit " + label)

        visit("sanctum", "sanctum")
        for sid, sk in self.p["skills"].items():
            visit("skill-" + sid, "skill", sid)
        visit("nexus", "nexus")
        cards = [b for b in ctx.buttons() if b.get("cid")]
        if cards:
            ctx.click(cid=ctx.rng.choice(cards)["cid"])
            if "nexus-detail" not in ctx.screens:
                ctx.screens["nexus-detail"] = ctx.shot("nexus-detail")
        visit("pods", "pods")
        visit("expeditions", "expeditions")
        if self.p["expedition"]["running"]:
            with ctx.clip_once("battle", settle=False):
                if ctx.options.get("movie"):
                    ctx.wait(4.0)   # damage numbers, attacks, health bars
        for tab in EXPEDITION_TABS:
            if ctx.click(tab, quiet=True) and "expeditions-" + tab not in ctx.screens:
                ctx.screens["expeditions-" + tab] = ctx.shot("expeditions-" + tab)
        ctx.click("Party", quiet=True)
        visit("aetherlog", "aetherlog")
        for tab in AETHERLOG_TABS:
            if ctx.click(tab) and "aetherlog-" + tab not in ctx.screens:
                ctx.screens["aetherlog-" + tab] = ctx.shot("aetherlog-" + tab)
        visit("inventory", "inventory")
        if ctx.click("Sell in bulk…"):
            if "inventory-bulk-sell" not in ctx.screens:
                ctx.screens["inventory-bulk-sell"] = ctx.shot("inventory-bulk-sell")
            ctx.clear_overlays()
        visit("market", "market")
        for tab in MARKET_TABS:
            if ctx.click(tab) and "market-" + tab not in ctx.screens:
                ctx.screens["market-" + tab] = ctx.shot("market-" + tab)
            ctx.check("market tab " + tab)
        ctx.click("Today's stock", quiet=True)
        visit("eggmarket", "eggmarket")
        visit("works", "works")
        # the menu, Options (every tab) and the notifications
        if ctx.click("Menu"):
            if "menu" not in ctx.screens:
                ctx.screens["menu"] = ctx.shot("menu")
            if ctx.click("Options"):
                for tab in OPTION_TABS:
                    if ctx.click(tab) and "options-" + tab not in ctx.screens:
                        ctx.screens["options-" + tab] = ctx.shot("options-" + tab)
                    ctx.check("options " + tab)
            ctx.clear_overlays()
        else:
            ctx.stuck("no Menu button")
        if ctx.click("Notifications"):
            if "notifications" not in ctx.screens:
                ctx.screens["notifications"] = ctx.shot("notifications")
            ctx.clear_overlays()
        ctx.check("sweep")
        missing = [k for k in NAV if k not in ctx.screens]
        if missing:
            ctx.log("screens not covered yet: %s" % missing)

    def key_numbers(self):
        p = self.refresh()
        return {"gold": p["gold"], "aether": p["aether"], "creatures": len(p["creatures"]),
                "goal": p["goal"].get("index"), "levels": {k: v["level"] for k, v in p["skills"].items()},
                "bred": p["counters"].get("bred", 0), "captures": p["counters"].get("captures", 0),
                "species": p.get("species_logged", 0)}

    def save_load(self):
        """Menu > Save now > Save and return to title > Load Game > slot 2, then compare the numbers."""
        ctx = self.ctx
        ctx.log("save/load round trip")
        ctx.clear_overlays()
        before = self.key_numbers()
        verdict = []
        if not ctx.click("Menu"):
            ctx.stuck("no Menu button for the save/load round trip")
            return
        ctx.click("Save now")
        if not ctx.click("Save and return to title", allow_danger=True):
            ctx.stuck("no \"Save and return to title\" in the menu")
            ctx.clear_overlays()
            return
        st = ctx.wait_for(lambda st: st.get("scene") == "title", 15)
        if st.get("scene") != "title":
            ctx.breach("\"Save and return to title\" left the game on scene %r" % st.get("scene"))
        if "title" not in ctx.screens:
            ctx.screens["title"] = ctx.shot("title")
        ctx.check("title screen")
        if not ctx.click("Load Game"):
            ctx.stuck("no Load Game on the title screen")
            ctx.gap("loaded slot 2 with the bridge")
            ctx.send("load", slot=2, timeout=60)
        else:
            loads = [b for b in ctx.buttons() if b["text"] == "Load" and not b["disabled"]]
            if not loads:
                ctx.stuck("the Load a game dialog has no Load button")
                ctx.clear_overlays()
                ctx.gap("loaded slot 2 with the bridge")
                ctx.send("load", slot=2, timeout=60)
            else:
                if "title-load" not in ctx.screens:
                    ctx.screens["title-load"] = ctx.shot("title-load")
                # the three slot cards sit side by side: slot 2 is the middle one
                b = min(loads, key=lambda b: abs(b["x"] - 800))
                ctx.click_at(b["x"], b["y"], "(Load, slot 2)")
        st = ctx.wait_for(lambda st: st.get("scene") == "main" and st.get("slot") == 2, 15)
        ctx.wait(0.5)
        if st.get("scene") != "main" or st.get("slot") != 2:
            ctx.breach("after loading, scene %r slot %r (wanted main, slot 2)" % (st.get("scene"), st.get("slot")))
            if st.get("scene") != "main":
                ctx.send("load", slot=2, timeout=60)
                ctx.gap("got back into slot 2 with the bridge")
        ctx.send("focus")
        ctx.clear_overlays()
        after = self.key_numbers()
        rows = []
        bad = []
        for k in ("gold", "aether"):
            b, a = before[k], after[k]
            rows.append([k, "%.1f" % b, "%.1f" % a])
            # a few seconds passed: income may add a little, nothing should vanish
            if a < b - max(1.0, 0.02 * b):
                bad.append("%s went %.1f -> %.1f" % (k, b, a))
        for k in ("creatures", "goal", "bred", "captures", "species"):
            rows.append([k, before[k], after[k]])
            if after[k] != before[k] and not (k in ("captures", "species", "creatures") and after[k] > before[k]):
                bad.append("%s went %s -> %s" % (k, before[k], after[k]))
        for sid, lv in before["levels"].items():
            if after["levels"].get(sid, 0) < lv:
                bad.append("%s level went %d -> %d" % (sid, lv, after["levels"].get(sid, 0)))
        rows.append(["skill levels", sum(before["levels"].values()), sum(after["levels"].values())])
        for b in bad:
            ctx.breach("save/load: " + b)
        verdict = "Everything came back." if not bad else "Changed across the round trip: " + "; ".join(bad)
        self.round_trip = {"verdict": verdict, "rows": rows}
        ctx.log("round trip: " + verdict)
        ctx.check("after load")

    def offline_jump(self):
        ctx = self.ctx
        ctx.clear_overlays()
        summary = ctx.skip(self.jump_hours, "time-away jump")
        self.after_away(summary, shot=True, label="welcome-back-jump")
        self.offline = summary

    def after_away(self, summary, shot=False, label="welcome-back"):
        ctx = self.ctx
        for k in ("aether", "gold", "elapsed", "usedSeconds"):
            v = summary.get(k)
            if isinstance(v, float) and (v != v or v in (float("inf"), float("-inf"))):
                ctx.breach("the time-away summary's %s is %s" % (k, v))
        if summary.get("usedSeconds", 0) >= 60:
            m = ctx.modals().get("modals", [])
            if not any(x["title"] == "Welcome back" for x in m):
                ctx.breach("%.1f h away but no Welcome back summary" % (summary.get("elapsed", 0) / 3600.0))
            elif shot and label not in ctx.screens:
                ctx.screens[label] = ctx.shot(label)
        ctx.check("after time away")
        ctx.clear_overlays()


def run(ctx):
    b = Benchmark(ctx)
    try:
        b.play()
    finally:
        extra = {"round_trip": b.round_trip, "offline": b.offline, "laps": b.lap, "sweeps": b.sweeps,
                 "breed_blocked": b.breed_fail}
        try:
            extra["goal_reached"] = ctx.goal()
            extra["final"] = {k: v for k, v in ctx.state().items() if k in ("gold", "aether", "creatures", "skills", "expedition")}
        except GameDied:
            extra["goal_reached"] = None
    return extra
