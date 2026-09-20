# Aetherbound Idle: Design Document

Status: pre-production. Everything here is decided unless marked **PLACEHOLDER** (pick a sensible value, put it in JSON) or **TBD** (ask the designer).

## 1. Vision
A creature-collecting incremental game like Melvor Idle. The player collects **Aetherlings**, assigns them as workers to skills, breeds them into rarer and hybrid forms, and sends parties on simple idle-combat expeditions to capture new species. **Aether** is the central resource that binds everything. The player is a collector and completionist, so collection tracks, hidden recipes, shinies, and Creaturedex completion are core, not extras.

Tone: science-fantasy, creature-collector first, machinery as an accent. Cute stays cute.
No prestige system. Long-term progression comes from zones, breeding, and collection.
No real-money purchases. Everything is earned through play.

## 2. Types
| Type | Element | Color | Locked skills |
|---|---|---|---|
| Verdant | Nature | Green | Woodcutting, Herbalism |
| Telluric | Stone | Brown | Mining |
| Pyric | Flame | Orange | Cooking, Smithing |
| Aqueous | Water | Blue | Fishing |
| Voltaic | Electric | Yellow | Circuitry |
| Void | Aether | Purple | Aether-Weaving (enchanting), Vessel Crafting |
| (open to all) | | | Scavenging, Fabrication |

- **Locked skills** require an Aetherling of the matching type in the work slot.
- **Open skills** (Scavenging, Fabrication) accept any creature. A creature whose *secondary aptitude* matches the skill gets a bonus (tunable).
- **Hybrids** (dual-type, bred only) fill either parent type's slots. A hybrid has full efficiency in its **primary skill** and reduced efficiency (tunable, PLACEHOLDER 60%) in its other covered skills.

## 3. Skills, slots, cooldowns
- **Skill level** unlocks resource tiers and work slots. **Creature level, rarity, and form** improve speed.
- **Max skill level: 250** (PLACEHOLDER, `skills.json` `maxLevel`, the same for every skill). Creature max level is separate and is **99**; see section 4.
- **Work slots per skill:** 1 at skill level 1, then 2/3/4/5 at levels **50/100/165/225** (PLACEHOLDER, `skills.json` `slotUnlockLevels`). Extra slots beyond 5 are a shop item at a huge gold cost (endgame gold sink).
- **Skill XP curve (PLACEHOLDER, `tuning.xp.skillCurve`): base 250, growth 1.04.** A level costs `round(250 * 1.04^(L-1))` XP; level 250 is 108.9 M XP in total. Growth is low *because* the cap is high: 1.1 over 250 levels would need about 20 trillion XP.
- **Pacing targets for the curve** (one unupgraded starter creature, alone, on the shipped Woodcutting tiers): first level-up about **75 s**, level 30 about **46 min**, level 100 about **8 h**, level 250 about **4 months**. These are the feel the curve is tuned to, not a promise about a developed account; `test/pacing.test.ts` fails if a retune moves any of them by more than 15%.
- **No hunger, rest, or upkeep.** Each creature has an **action cooldown** that shortens with level, rarity, and form, with a hard floor (PLACEHOLDER 20% of base) and diminishing returns.
- Skill XP is per completed action. Creature quality changes how fast actions complete, not XP per action.
- **Global cap:** all cooldown reduction from every source (signature, pool traits, auras) shares one cap.
- **Benched creatures** (not in a slot, not on an expedition) passively emit Aether, scaled by rarity.
- **Skills never fail and have no hazards.** Idle game: no bonuses for active clicking.
- Resource tiers per skill map to the tier ladder (section 5). PLACEHOLDER example for Woodcutting: oak (T1, level 1), willow (T2, level 15), yew (T3, level 30), then higher tiers. Author content for tiers 1 to 5 only in v1, but build systems for 9. **Tier unlock levels were deliberately left alone when the cap rose to 250**, so all three tiers that exist today are open within the first hour; tiers 4 and 5 and their unlock levels still need authoring before the upper levels have anything to reach for.

## 4. Creatures
- Base species are captured. Hybrids are bred only.
- Each creature has: species, type(s), rarity (9 tiers), level, form (1 to 3), stat lean (Health/Power/Guard), primary skill, secondary aptitude, one combat ability with a tempo tag, **one signature trait** (innate, not rerollable, not inherited), and **up to 3 pool traits**.
- **Creature level caps at 99** (PLACEHOLDER, `tuning.creature.maxLevel`) on its own XP curve (`tuning.xp.creatureCurve`), which is **not** the skill curve and did not move when skills went to 250. Whether creatures follow skills to a higher cap is a Phase 3 decision.
- **Forms:** Form 2 at creature level 30, Form 3 at level 60 (tunable). Same creature growing stronger, never a different species. Bonus per form: PLACEHOLDER +20% at Form 2, +40% at Form 3 to stats, and a smaller speed bonus (PLACEHOLDER about +8% / +16%, tunable in `tuning.json` under `cooldown.formTerm`). A full +20% / +40% speed bonus would nearly match the whole rarity ladder's speed contribution. Form bonuses must stay well below rarity bonuses. Evolution is automatic on reaching the level (v1). Offspring always hatch at Form 1, level 1.
- **Rarity is a tier on the same species** (frame, tint, stat multiplier), not separate art.
- **Creature rarity ladder (light intensity):** Dim, Faint, Steady, Gleaming, Luminous, Radiant, Brilliant, Resplendent, Zenith.
- **Gear rarity ladder:** Common, Uncommon, Rare, Epic, Legendary, Mythic, Celestial, Ascendant, Primordial. Tier N creatures and tier N gear share the same resource and processed-goods tier (one spreadsheet internally).

### Traits
- **Signature trait:** one per species, defines its role. Hybrids get their own new one.
- **Pool traits:** rerollable and inheritable. Strength (Minor / Moderate / Major) is **rolled per creature**, not baked into the trait. Major is rare. Universal pool traits are small. A few rare ones are the chase targets.
- Void-only pool traits roll at Moderate minimum. Type-flavored pool traits are weighted toward creatures of that type.
- **Trait mechanics allowed (nothing else):** chance for extra output, chance to save materials, cooldown reduction, bonus XP, rare-drop chance within the current tier, chance at treasure drops (fishing), Aether emission while benched, bind/capture rate, egg hatch time, small capped mutation odds, attunement cost, bonus Health/Power/Guard, ability cooldown reduction, bonus combat XP, bonus drop of the partner type's element resource (hybrids).
- Every source of the same mechanic shares a global cap. Auras (Resonant Frequency, Sea Breeze) don't stack: only the strongest of each kind applies.
- Strength values live in JSON (PLACEHOLDER: Minor +5%, Moderate +10%, Major +20%).
- Geneticist (mutation bonus) is capped in total across all sources (PLACEHOLDER +3% max).

### Attunement (trait rerolling)
Spend Aether to reroll a creature's pool traits. The player may **lock up to 2 traits**. Cost multiplies per lock: 0 locks = 1x, 1 lock = 3x, 2 locks = 9x. Rerolls draw from the creature's type pool more often. Only pool traits reroll, never the signature trait.

## 5. Aether and the economy
Aether is the primary currency for breeding, vessels, attunement, upgrades.

**Sources:** benched creature emission (scales ~2x per rarity tier), Aether-infrastructure buildings (Resonance Extractors / Aether Pipelines, crafted from high-tier goods), and releasing a creature (returns Aether, plus extra for high level/form).

**Sinks:** breeding, vessel charging, attunement, habitat/bench upgrades, more incubators, catalysts (nudge mutation odds for one breed), awakening/stars, region unlocks, offline-cap extension, egg hatch speed-ups.

**Scaling (PLACEHOLDER table, all in JSON):**
| Rarity ceiling | Breeding Aether cost | Emission per benched creature |
|---|---|---|
| 1 | 100 | 1/min |
| 2 | 400 | 2/min |
| 3 | 1,600 | 4/min |
| 4 | 6,400 | 8/min |
| 5+ | x4 per tier | x2 per tier |
Costs scale by the target rarity ceiling, not the parents. The gap between cost and emission is closed by bench capacity upgrades and Aether buildings. Tune so each tier takes a satisfying amount of time.

**Resource tier ladder:** tiers 1-2 raw resources, 3-4 refined (planks, bars, cooked food), 5-6 crafted items (tools, charms, tinctures), 7-9 rare drops, boss materials, or multi-skill items.

## 6. Breeding and eggs
- Cost: Aether + element resources. Higher target rarity needs higher-tier (and more processed) resources. Hybrids need resources from **both** parent types. Void offspring need parents of two different types, heavy Aether, and a late-tier enchanted item.
- **Resource tier sets the rarity ceiling; parent rarity sets the odds within it.**
- **Rarity mutation (separate rolls):** 15% chance of +1 above the ceiling, 2.5% chance of +2. Otherwise the ceiling. Capped at the highest rarity, with lower rates for the top two tiers. **No pity system on rarity.**
- **Inheritance:** blend of parents' aptitudes and pool traits, small chance of mutation. Pool traits inherit and may mutate. Signature traits do not inherit.
- **Recipes:** hybrid species are decided by parent *species*, not just type. Any two species from a type pair with no special recipe produce that pair's **default hybrid**. Specific species pairs can have **special recipes** producing a unique hybrid. Recipes are order-independent and **hidden until discovered**. Discovered recipes are recorded in the Aether-Log. Same-type breeding produces one of the two parent species, with a small chance of a rare "sibling" species (TBD content).
- The recipe decides the species. Rarity, traits, and shiny status still roll normally.
- **Eggs:** breeding produces an egg with a hatch timer (minutes at tier 1, hours at high tiers, scaling with rarity ceiling). Incubators run eggs in parallel (more via upgrades). Shell glow hints at rarity, sometimes misleadingly. **Hatch reveal is a core feature:** slow build-up, escalating flash/sound/screen effect by rarity, batch hatching with sequential reveals, offline eggs queue up and play a reveal sequence on return. Aether can speed up hatching.

## 7. Shinies / variants
- Cosmetic first (recolor, particle, sparkle in the Aether-Log). Any stat bonus is tiny.
- **Encounters:** ~1 in 500 with a soft pity counter (counts encounters). **Hatches:** separate, gentler roll, ~1 in 200, with pity ramping after ~150 hatches. Both PLACEHOLDER and in JSON.
- A shiny **never flees** and is never skipped by auto-bind filters. If the player is offline it waits in a "pending bind" queue.
- Show all odds in-game.

## 8. Adventures and capture
- Wild Aetherlings (base species) are obtained **only by adventuring**. Each zone has native species and a tier ceiling for wild rarity. Each zone has a boss.
- **Aether Vessels** are crafted, tiered, and consumed on use. Higher tiers bind higher-rarity creatures more reliably. The tutorial gives **5 basic vessels**. Open Crafting (Fabrication) can craft the lowest tier (the Tinkerer's Vessel) so early players aren't stuck. Better vessels need Void Vessel Crafting.
- Vessel tiers: Tinkerer's, Flimsy, Sturdy, Polished, Resonant, Luminescent, Aetheric Matrix (PLACEHOLDER order, tune as needed).
- **First capture of each type is guaranteed** and doesn't consume a roll. After that it's chance-based, with no pity on rarity.
- **Auto-bind settings** (for offline): choose which vessel to use and a minimum rarity worth spending on (e.g. "only Steady+ or species I don't own").
- Capture is a **passive roll on defeated wild creatures**, with vessel use governed by the auto-bind settings.
- **Void acquisition:** guaranteed first capture from the final zone's boss, then rare wild encounters, then breeding.

### Zones (v1)
| Zone | Type | Boss |
|---|---|---|
| Starter area | Verdant | (none / tutorial) |
| Fractured Quarry | Telluric | Granitusk, the Stone-Cracker |
| Smoldering Caldera | Pyric | Ignis Prime |
| Whispering Tides | Aqueous | Leviathan Core |
| Voltaic zone | Voltaic | TBD |
| Null Horizon | Void | The Aetherial Apex |
Each zone has 2 to 3 signature wild species. Gear requirements for zones use the *previous* type's skills (avoids chicken-and-egg): Verdant Woodcutting → wooden gear → Quarry → Mining → stone gear → Caldera → Cooking/Smithing → gear → Tides → Fishing.

### Combat (simple, automatic)
- Stats: Health, Power, Guard. Speed comes from the creature's action cooldown.
- Party of 1 to 3, fully automatic, ending in a zone boss. No permadeath: a wiped party retreats and is briefly "exhausted."
- **Type wheel:** Aqueous → Pyric → Verdant → Telluric → Voltaic → Aqueous. Each beats the next (1.5x damage) and resists the previous (0.75x).
- **Void** is outside the wheel. It always deals 1.25x and takes 0.75x. Void hybrids get half that bonus (12.5%) and keep their partner's place on the wheel. All multipliers in JSON.
- One combat ability per creature on a cooldown. **Allowed effects only:** single-target damage, multi-target damage, heal (instant or over time), party buff (Power or Guard), shield, thorns (Verdant only: a shield that reflects a small portion of damage). Ability damage uses the creature's own type. **Tempo tag:** Quick (small effect, short cooldown), Standard, or Heavy (big effect, long cooldown).
- Gear slots: weapon, armor, charm. Flat stats and a few set bonuses.
- Combat XP levels the creature itself.
- A creature on an adventure isn't working or emitting Aether. That opportunity cost is intentional. Early expeditions should be short.

## 9. Collection tracks (the completionist layer)
Milestone thresholds and rewards are JSON. Discovery rewards are one-time (releasing and recatching can't farm them).
| Track | Counts | Total (v1) | Milestones |
|---|---|---|---|
| Species discovered | Owning a species at least once | 69+ | 5, 10, 25, 50, all |
| Forms unlocked | Reaching Form 2 or 3 on any species | 2x species | 10, 25, 50, 100, all |
| Recipes discovered | Hidden breeding recipes found | 45 | 5, 10, 25, all |
| Rarity tiers seen | Each species x each rarity | species x 9 | 25, 50, 100, 200, 400, all |
| Shinies | Shiny variants collected | species | 1, 5, 10, 25, 50, all |
- Rewards: first-time species/hybrid/rarity discovery pays small Aether + gold (hybrids pay more). Early milestones give convenience items (vessels, eggs). Mid milestones give utility (bench slot, incubator slot, small emission bonus). Late milestones give cosmetics/titles/frames or a rarity-floor egg. **No big permanent stat bonuses.**
- At recipe milestones (10/25/45) reveal one undiscovered recipe's parent species as a hint.
- The Aether-Log shows undiscovered hybrids as silhouettes. One headline completion % (rarity-tier track is the long-tail chase).

## 10. Roster management
Roster bloat is a known risk. Requirements: filter and sort by type, rarity, level, skill, traits, form, shiny; auto-assign best-for-skill; bulk release for Aether (with confirmation, and locking to protect favorites). The roster screen deserves the most UI polish.

## 11. Screens
Roster, Skills (with slots), Nexus/Menagerie (bench, habitat), Genesis Pods (breeding and incubators), Expeditions, Aether-Log (Creaturedex and collection tracks), Inventory, Shop, Settings. Working names: bench/habitat = The Nexus (or The Menagerie), incubators = Genesis Pods, Creaturedex = The Aether-Log, guide NPC = Overseer Vance, player title = The Architect (TBD).

**UI direction (designer's reference, 2026-09-20; built in step 1.9b, see PROGRESS.md; the Adventure and Collection sidebar sections appear when those screens exist).** The designer wants the finished game to look and feel like `docs/reference/ui-reference-sidebar-layout.png`, a screenshot of another idle game used **only as a look-and-feel reference** (do not copy its name, wording or art, and keep the image out of any public repo or shipped build). What to take from it:
- **Left sidebar navigation** instead of the top tab bar, grouped under small section headings (for us roughly: Skills / Creatures / Adventure / Collection / System), each entry an icon plus a label. The tab bar will not scale to the roughly ten screens listed above.
- A **pinned "current activity" panel** at the bottom of the sidebar, with a progress bar and the latest activity. For us it would summarize what the working creatures are doing.
- **Header card per skill** (icon, level, XP), then a **card per option** the player can pick (icon, name, what it needs, time, XP, "you have N" for inputs) with a clear primary button. This is also the pattern for the crafting recipe picker (Phase 3).
- **Toast notifications** for events (level-up, slot unlocked) and a **notification bell with a count**. This needs the sim's `SimEvent`s kept in the store; they are dropped today.
- A quiet dark theme with one warm accent for UI chrome, generous spacing and rounded cards. Type colors stay reserved for creatures and skill accents (CLAUDE.md rule 4).
- A small "autosaves locally" status line.
- **Not to copy:** its production *queue* (one shared, ordered queue where inputs are consumed when queued). Our design is parallel creature work slots. It is worth remembering as one candidate answer to the open offline slot-ordering question before Phase 3.
- Timing: a presentation-only "UI shell" step (sidebar, activity panel, toasts), scheduled as step 1.9b right after Phase 1, before the new Phase 2 screens (Genesis Pods, Aether-Log) are added to a tab bar that is already full.

## 12. Backlog (not in v1)
- Fishing expansion: bait, deep-sea zones, a treasure system (sunken-treasure drops exist as traits already).
- Special-recipe hybrids beyond the 15 defaults (data-driven, add later).
- Same-type "sibling" species, Voltaic zone content, optional manual evolution with Aether cost.
- Idle-combat depth, gear set bonuses, more zones, tiers 6 to 9 content.
- Real art (see section 14).

## 13. Build phases (ship a playable each phase)
**Phase 1: The economy core (first thing to see).** Scaffold, data loading, save/load, offline progress. One starter Verdant creature (Sproutlet). Woodcutting with 3 log tiers and a work slot. Roster screen with placeholder art cards. Benched creatures emit Aether. Skill XP, levels, and slot unlocks. A working tick loop with progress bars.
**Phase 2: Breeding and hatching.** Incubators, egg timers, breeding costs (Aether + element resources), recipe lookup (defaults for the 15 pairs), rarity mutation rolls, shiny rolls, and the full hatch reveal with animation. Aether-Log with silhouettes.
**Phase 3: Expeditions and capture.** Zones, auto-combat, type wheel, vessels, the tutorial's guaranteed first captures (Telluric first), unlocking Mining, the "pending bind" queue, and auto-bind settings.
**Phase 4: Depth.** Remaining skills and zones, attunement, forms, gear, collection tracks and rewards, trait pool, Void.
Each phase should end with a working build and unit tests for the sim.

## 14. Art
Placeholder art for everything at first (emoji or generated SVG on type-colored cards). Sprite counts if real art is added later: 24 base species x 3 forms = 72, plus 15 default hybrids x 3 = 45, plus specials x 3. Shinies and rarity tiers are runtime effects (hue shift, frames, glow) and need no extra sprites. Also needed eventually: ~6 to 12 egg sprites, resource and gear icons, vessel icons, zone backgrounds.

## 15. Known gaps (ask the designer before deciding)
- Skills' full resource lists, prices, and gold values (use placeholders in JSON).
- Full gear list, zone wild-species assignments beyond the guaranteed firsts, the Voltaic zone, and the full tutorial script.
- Special-recipe content (in progress).
- Exact reward tables for collection milestones.
