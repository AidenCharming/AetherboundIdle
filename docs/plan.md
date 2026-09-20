# Aetherbound Idle: Implementation Plan

Approved plan for folder structure, data schemas, and sim architecture. Written at step 1.1 and
approved 2026-09-19 with six amendments (section 8). Later sessions should read this instead of
re-deriving it. Change it only with the designer's OK, and record the change in `docs/PROGRESS.md`
under "Decisions and deviations".

Source of truth for *content*: `docs/content-data.md`. Source of truth for *rules*: `docs/design.md`.
This file is the source of truth for *shape*.

---

## 1. Folder structure

```
Aetherbound Idle/
  docs/                     design.md, content-data.md, plan.md, PROGRESS.md
  index.html
  package.json
  vite.config.ts
  tsconfig.json
  vitest.config.ts
  src/
    main.tsx                React entry, mounts <App/>, starts the tick driver
    App.tsx                 screen router + layout shell
    data/                   ALL content and balance JSON. No code except index.ts / schema.ts.
      types.json
      skills.json
      rarities.json
      gear-rarities.json
      resources.json
      abilities.json
      traits.json           signature + pool traits, one unified list
      species.json
      hybrids.json
      recipes.json          special recipes; empty in v1
      modifiers.json        modifier registry: stacking rule + global cap per mechanic
      tuning.json           every balance knob that is not per-entity
      zones.json            phase 3
      vessels.json          phase 3
      collection-tracks.json  phase 4
      schema.ts             zod schemas, one per file above
      index.ts              loaders: parse + cross-reference validation, exports typed content
    sim/                    PURE. No React, no zustand, no Date.now(), no Math.random().
      rng.ts                seeded RNG interface + mulberry32 impl
      formulas.ts           stats, cooldown, xp curve, level <-> xp
      modifiers.ts          collect effects from a creature/roster, apply caps and auras
      creature.ts           derived creature stats, form, effective speed
      skills.ts             slot unlocks, action resolution, output rolls, xp award
      aether.ts             bench emission
      offline.ts            bulk offline catch-up
      tick.ts               online step: (state, dtMs) -> { state, events }
      save.ts               serialize, versioning, migration chain
      state.ts              createInitialState(seed, now): a brand-new game (added at 1.4)
      events.ts             SimEvent union (action-complete, level-up, hatch, ...)
    state/
      store.ts              zustand store: holds GameState, exposes actions
      actions.ts            thin wrappers that call sim functions and commit results
      selectors.ts          memoized reads for UI
      persistence.ts        localStorage read/write, lastSeen, autosave timer
    ui/
      screens/              Roster.tsx, Skills.tsx, Nexus.tsx, DevPanel.tsx, ...
      components/           CreatureCard.tsx, ProgressBar.tsx, ResourceBar.tsx, ...
      art/                  placeholder art helpers (type colors, rarity frames, hue shift)
      theme.css             CSS variables: type colors, rarity frames, spacing
    types/
      content.ts            types inferred from zod schemas (re-export)
      state.ts              GameState, Creature, SkillState, SaveFile
  test/                     vitest specs mirroring src/sim/*
```

Rules that follow from this layout:
- `src/sim/**` may import from `src/data/**` and `src/types/**` only.
- `src/ui/**` never imports `src/sim/**` directly; it goes through `src/state/selectors.ts`.
- Nothing outside `src/data/` contains a balance number.

---

## 2. Conventions

- **IDs** are kebab-case ASCII slugs: `sproutlet`, `aether-weaving`, `resonant-frequency`, `void`.
- **Names** are the exact strings from `docs/content-data.md`, never regenerated from the ID:
  `{ "id": "aether-weaving", "name": "Aether-Weaving" }`.
- Every cross-reference is by ID, and `src/data/index.ts` fails loudly at load if an ID does not resolve.
- Percentages are stored as decimals (`0.15`), durations in **milliseconds**, rates per **minute** only
  where the design doc uses per-minute (bench emission), converted at load.
- Enums live in the schema file, never as free strings.

---

## 3. Data schemas

Shown as annotated examples. `schema.ts` holds the authoritative zod version of each.

### 3.1 types.json

```json
[{
  "id": "verdant", "name": "Verdant", "element": "Nature", "color": "#4CAF50",
  "lockedSkills": ["woodcutting", "herbalism"],
  "wheel": { "beats": "telluric", "resists": "pyric" },
  "outsideWheel": false
}]
```

Wheel from design section 8: Aqueous beats Pyric beats Verdant beats Telluric beats Voltaic beats Aqueous,
each resisting the previous. Void sets `outsideWheel: true` with `wheel: null`; its flat multipliers live
in `tuning.json` under `combat`.

### 3.2 skills.json

```json
[{
  "id": "woodcutting", "name": "Woodcutting",
  "requiredType": "verdant",
  "open": false,
  "slotUnlockLevels": [1, 20, 40, 65, 90],
  "maxLevel": 99
}]
```

Open skills (Scavenging, Fabrication) have `requiredType: null`. The secondary-aptitude bonus for them is
a tuning knob, not a per-skill field.

### 3.3 rarities.json and gear-rarities.json

```json
[{
  "tier": 1, "id": "dim", "name": "Dim",
  "statMultiplier": 1.0,
  "benchEmissionPerMin": 1,
  "frame": { "tint": "#8a8a8a", "glow": 0 }
}]
```

Nine entries, Dim through Zenith. `gear-rarities.json` is `{tier, id, name}` only for now
(Common through Primordial); design section 4 ties tier N creatures and tier N gear to the same
resource tier.

Rarity has **no per-entry cooldown field**. Its entire contribution to action speed is
`tuning.cooldown.rarityTermPerTier * (tier - 1)` (section 4.2), so there is exactly one place to tune it.
A per-rarity override would have to be added deliberately, not inherited from an unused field.

### 3.4 resources.json

```json
[{
  "id": "oak-log", "name": "Oak Log", "emoji": "🪵", "tier": 1, "skill": "woodcutting",
  "kind": "raw",
  "elementType": "verdant",
  "requiredSkillLevel": 1,
  "baseActionMs": 3000,
  "xpPerAction": 10,
  "goldValue": 2,
  "rareDrop": { "id": "verdant-seedcache", "chance": 0.01 }
}]
```

`emoji` is optional (added in step 1.7): the top bar and the slot picker show it in place of the type-colored dot,
and fall back to the dot when a resource has none. Every resource that ships has its own.
`kind` is one of `raw | refined | crafted | rare`. `elementType` is what breeding costs and the
partner-element-drop hybrid traits read. v1 authors tiers 1-5 (design section 3); phase 1 ships
Woodcutting T1-T3 only: `oak-log`, `willow-log`, `yew-log` at required skill levels **1 / 15 / 30**
(PLACEHOLDER).

`requiredSkillLevel`, `baseActionMs` and `xpPerAction` are null on items that are dropped rather than
gathered (`kind: "rare"`, e.g. `verdant-seedcache`); a `raw` resource must have all three. Every
`rareDrop.id` must resolve to a resource with `kind: "rare"`.

### 3.5 abilities.json

```json
[{
  "id": "leaf-shield", "name": "Leaf Shield",
  "effect": "shield-party",
  "damageType": null,
  "tempo": "standard",
  "magnitude": 1.0
}]
```

`effect` enum, and nothing else (design section 8): `single-target-damage`, `multi-target-damage`,
`heal-instant`, `heal-over-time`, `buff-power`, `buff-guard`, `shield-self`, `shield-party`, `thorns`.
`damageType` is a type ID, and is required when the effect deals damage. Non-damage abilities may also
carry one, because content-data.md gives six hybrid heals, shields and buffs a type (Briar Wash, Facet
Ward, Warm Tides, Twilight Bough, Obsidian Shroud, Twilight Mend); the sim reads it only for damage.
Base-species non-damage abilities have none in the doc, so theirs is null. `magnitude` multiplies the
tempo's base value, so "strong self shield" (Bucket Block) is `shield-self` / `heavy` / `1.5` rather
than a new effect. Base numbers per tempo live in `tuning.json` under `combat.tempo`.

### 3.6 traits.json (signature and pool traits in one list)

One list, because both resolve through the same effect engine. `kind` separates them.

```json
[{
  "id": "overgrowth", "name": "Overgrowth", "kind": "signature",
  "species": "sproutlet",
  "defaultStrength": "moderate",
  "text": "Chance for extra output.",
  "effects": [{ "key": "extra_output_chance", "scope": { "target": "self" } }]
},
{
  "id": "green-thumb", "name": "Green Thumb", "kind": "pool",
  "category": "verdant",
  "rollWeight": 10,
  "typeAffinity": "verdant",
  "minStrength": null,
  "text": "Chance for extra output on Woodcutting or Herbalism.",
  "effects": [{ "key": "extra_output_chance",
                "scope": { "target": "self", "skills": ["woodcutting", "herbalism"] } }]
}]
```

`category` is one of `universal-econ | universal-combat | <type id> | void-only`. `rollWeight` is
relative (Geneticist, Champion and the Void-only traits get low weights, per content-data.md).
`minStrength` is `"moderate"` for Void-only traits, null elsewhere.

**Effect object**

```json
{
  "key": "cooldown_reduction",
  "scope": {
    "target": "self",
    "skills": ["mining"],
    "types": ["aqueous"]
  },
  "aura": { "group": "cooldown-aura", "stacking": "strongest-only" },
  "valueByStrength": { "minor": 0.03, "moderate": 0.06, "major": 0.12 }
}
```

`scope.target` is one of `self | party | active-creatures | other-active-in-skill`; `skills` and `types`
are optional filters. `aura` is present only on the two aura signatures (Resonant Frequency uses
`other-active-in-skill` + `skills: ["mining"]`; Sea Breeze uses `active-creatures` + `types: ["aqueous"]`)
and drives the "strongest only, never stacks" rule from design section 4. Each aura is its own `group`
(`resonant-frequency`, `sea-breeze`), since design says the strongest "of each kind" applies. An effect
with key `partner_element_drop_chance` carries `"elementType": "<type id>"` (the partner type whose element
resource it drops); no other effect may. When `valueByStrength` is
absent the loader fills it from `tuning.json` -> `traitStrength.default` (PLACEHOLDER Minor 0.05 /
Moderate 0.10 / Major 0.20, design section 4).

**`key` vocabulary** — the complete allowed list, derived from design section 4's "nothing else" clause.
The schema rejects anything not in it:

`extra_output_chance`, `offline_extra_output_chance`, `save_material_chance`, `cooldown_reduction`,
`bonus_xp`, `rare_drop_chance`, `treasure_drop_chance`, `bench_aether_emission`, `bind_rate`,
`free_bind_attempts`, `hatch_time_reduction`, `mutation_odds`, `attunement_cost_reduction`,
`bonus_health`, `bonus_power`, `bonus_guard`, `ability_cooldown_reduction`, `bonus_combat_xp`,
`partner_element_drop_chance`.

Two entries need engine support beyond a static value:

- **Overclocked** (Coilchirp): a stacking cooldown reduction that resets on task completion. Modelled as
  `"dynamic": "stacking-until-complete"` with `perStack` and `maxStacks`. The stack count is runtime
  creature state, not saved content.
- **Void Grasp**: `free_bind_attempts` is a **count** (Moderate = 1, Major = 2), not a percent. The
  modifier registry marks its unit as `count`.

### 3.7 species.json (24) and hybrids.json (15)

```json
[{
  "id": "sproutlet", "name": "Sproutlet",
  "types": ["verdant"],
  "forms": [
    { "form": 1, "name": "Sproutlet",   "emoji": "(seedling)", "art": "tiny glowing leafy biped with a sapling on its head" },
    { "form": 2, "name": "Timberhorn",  "emoji": "(deer)",     "art": "sturdy bark-armored quadruped with wooden antler buds" },
    { "form": 3, "name": "Lumbercrown", "emoji": "(tree)",     "art": "majestic forest beast with a glowing canopy of antlers" }
  ],
  "primarySkill": "woodcutting",
  "secondaryAptitude": "scavenging",
  "statLean": "guard",
  "signatureTrait": "overgrowth",
  "ability": "leaf-shield",
  "origin": "wild"
}]
```

`statLean` is `health | power | guard`. `emoji` holds the actual emoji character in the real file, and the
schema rejects anything that is not one. `art` carries the form description from content-data.md so later
art work does not need the doc; content-data.md only describes base species, so hybrid forms omit it.
Species may carry an optional `artNote` for whole-creature art direction (`"Stays cute."`).

`hybrids.json` uses the same shape plus:

```json
[{
  "id": "ashwood", "name": "Ashwood",
  "types": ["verdant", "pyric"],
  "pair": ["pyric", "verdant"],
  "isDefaultForPair": true,
  "primarySkill": "woodcutting",
  "coveredSkills": ["woodcutting", "herbalism", "cooking", "smithing"],
  "origin": "breed"
}]
```

`pair` is stored sorted and is the default-hybrid lookup key. Base species do not store covered skills —
they are derived from their type's `lockedSkills`. Efficiency on a covered skill that is not
`primarySkill` is `tuning.skills.hybridOffPrimaryEfficiency` (PLACEHOLDER 0.60, design section 2),
applied as a **divisor** on the base action time — see section 4.2.

### 3.8 recipes.json

```json
{
  "special": [
    { "parents": ["emberfang", "sproutlet"], "result": "some-hybrid-id", "hint": "..." }
  ],
  "sameTypeSiblingChance": 0.02
}
```

`special` is empty in v1 (content in progress). Lookup order, from design section 6: sort the two parent
species IDs, then exact special recipe, then the default hybrid for the sorted type pair, then the
same-type rule (one of the two parents, small sibling chance that rolls to nothing until sibling species
exist). Order-independence comes from sorting; the schema rejects duplicate pairs.

### 3.9 modifiers.json (the cap registry)

Design section 4: "Every source of the same mechanic shares a global cap."

```json
[{
  "key": "cooldown_reduction",
  "unit": "percent",
  "stacking": "additive",
  "cap": 0.50,
  "note": "Shared by signature traits, pool traits, auras and gear (design section 3)."
},
{ "key": "mutation_odds", "unit": "percent", "stacking": "additive", "cap": 0.03 }]
```

`unit` is `percent | flat | count`. `sim/modifiers.ts` reads this registry, so adding a capped mechanic
is a data change, not a code change.

### 3.10 tuning.json (every remaining knob)

```json
{
  "creature": {
    "maxLevel": 99,
    "baseStats": { "health": 50, "power": 10, "guard": 10 },
    "statLeanMultiplier": { "leaned": 1.25, "other": 0.9 },
    "statPerLevel": 0.04,
    "formUnlockLevels": { "2": 30, "3": 60 },
    "formMultiplier": { "1": 1.0, "2": 1.2, "3": 1.4 }
  },
  "cooldown": {
    "floorFraction": 0.20,
    "levelTermPerLevel": 0.004,
    "rarityTermPerTier": 0.06,
    "formTerm": { "1": 0, "2": 0.08, "3": 0.16 }
  },
  "xp": {
    "skillCurve": { "base": 100, "growth": 1.10 },
    "creatureCurve": { "base": 80, "growth": 1.12 }
  },
  "skills": { "secondaryAptitudeBonus": 0.15, "hybridOffPrimaryEfficiency": 0.60 },
  "offline": { "capHours": 12, "maxSegmentsPerSlot": 200, "awayThresholdMs": 120000 },
  "aether": { "benchEmissionTickMs": 60000 },
  "traitStrength": { "default": { "minor": 0.05, "moderate": 0.10, "major": 0.20 } },
  "breeding": {
    "mutationPlusOne": 0.15, "mutationPlusTwo": 0.025,
    "costByCeiling": [100, 400, 1600, 6400], "costGrowthPerTier": 4
  },
  "shiny": {
    "encounterRate": 0.002, "encounterPityStart": 400,
    "hatchRate": 0.005, "hatchPityStart": 150
  },
  "attunement": { "lockCostMultiplier": [1, 3, 9] },
  "combat": {
    "wheelStrong": 1.5, "wheelWeak": 0.75,
    "voidDealt": 1.25, "voidTaken": 0.75, "voidHybridFraction": 0.5,
    "tempo": { "quick": {}, "standard": {}, "heavy": {} }
  },
  "save": { "version": 1, "autosaveMs": 15000 },
  "ui": { "tickMs": 100, "shinyHueDeg": 150 }
}
```

Numbers marked PLACEHOLDER in the design doc are all here: form multipliers, cooldown floor, trait
strengths, mutation rates, shiny rates, attunement lock costs, breeding costs. Form bonuses (1.2 / 1.4)
sit well below the rarity ladder's multipliers, as design section 4 requires.

Two knobs in this file are easy to misread, so they are pinned down here:

- `skills.hybridOffPrimaryEfficiency` (0.60) and `skills.secondaryAptitudeBonus` (0.15) are **divisors**
  on the base action time, not multipliers. Higher is always better. See section 4.2.
- `aether.benchEmissionTickMs` (60000) is a **save/display cadence only**. Aether accrues continuously
  from `dt`; changing this number must not change how much a player earns. See section 4.4.
- `ui.tickMs` (100) is how often the tick driver in `main.tsx` steps the sim. Presentation cadence only, for
  the same reason: the driver measures real elapsed time and hands it to `step`, so a slower or throttled
  tick loses nothing. Added at step 1.6.
- `ui.shinyHueDeg` (150) is the CSS `hue-rotate` applied at runtime to a shiny creature's art. It is never a
  separate asset (CLAUDE.md rule 4). Must be strictly between 0 and 360, or a shiny would look like a normal
  creature. Presentation only. Added at step 1.7 (PLACEHOLDER value).
- `offline.awayThresholdMs` (120000, PLACEHOLDER) is the gap that counts as **away** while the tab is still open:
  a sleeping laptop, a tab throttled for hours. A gap at or under it is an ordinary `step`; a longer one is routed
  through `applyOffline`, so `capHours` and Night Owl's offline bonus apply to an open tab exactly as they do to a
  closed one, and the welcome-back summary is produced either way (designer, 2026-09-19; this resolves the 1.6 open
  question). It must stay below `capHours`, which the loader checks. Added at step 1.8a.

---

## 4. Sim formulas (phase 1)

All pure, all constants from `tuning.json`, all unit-tested.

### 4.1 Stats

```
lean = (stat === species.statLean) ? statLeanMultiplier.leaned : statLeanMultiplier.other

stat = baseStats[stat] * lean
     * (1 + statPerLevel * (level - 1))
     * rarity.statMultiplier
     * formMultiplier[form]
     * (1 + cappedTraitBonus(stat))
```

`cappedTraitBonus` sums the `bonus_health` / `bonus_power` / `bonus_guard` effects (Vitality, Brawn,
Stalwart, Champion) at their `traitStrength` percentages and clamps to the modifier registry cap. It is a
**percentage of the stat**, not a flat add, so the default Minor 5% / Moderate 10% / Major 20% apply to it
unchanged (designer's decision, 2026-09-19).

### 4.2 Action cooldown

Three stages: fit for the job, then intrinsic growth, then trait stacking — with one hard floor over
the last two.

```
// stage 1: efficiency. A DIVISOR, so 0.60 efficiency means the action takes 1/0.60 = 1.667x as long.
efficiency    = 1.0
if creature is a hybrid working a covered skill that is not its primarySkill:
    efficiency *= hybridOffPrimaryEfficiency              // 0.60 -> base / 0.60
if the skill is open and matches the creature's secondaryAptitude:
    efficiency *= (1 + secondaryAptitudeBonus)            // 0.15 -> base / 1.15

adjustedBase  = baseActionMs / efficiency

// stage 2: intrinsic growth from level, rarity and form
intrinsicTerm = levelTermPerLevel * (level - 1)
              + rarityTermPerTier * (rarity.tier - 1)
              + formTerm[form]
intrinsicMult = 1 / (1 + intrinsicTerm)                   // hyperbolic, i.e. diminishing returns

// stage 3: capped trait reduction
traitReduction = min(cap["cooldown_reduction"], sum of every cooldown_reduction source)

raw        = adjustedBase * intrinsicMult * (1 - traitReduction)
cooldownMs = max(raw, adjustedBase * floorFraction)
```

**The floor is relative to the efficiency-adjusted base, not the raw base.** This is the point of the
divisor form: an off-primary hybrid's floor is `(base / 0.60) * floorFraction`, which is `1.667x` a
specialist's floor, so no amount of level, rarity, form or trait stacking lets it reach specialist speed
on a skill it is not built for. If the floor were taken from the unadjusted base, both would converge on
the same number at the cap and the specialisation would vanish exactly where it matters most.

The same reasoning is why efficiency divides rather than multiplies: a multiplier of 0.60 would make the
off-primary hybrid *faster*, and a secondary-aptitude "bonus" of 1.15 would make an aptitude-matched
creature *slower*. Both knobs read as "how well suited is this creature", where higher is always better.

`efficiency` is multiplicative across its own sources but is **not** part of the
`cooldown_reduction` cap — it describes job fit, not a stacking speed bonus, and it can be below 1.

### 4.3 XP and levels

`xpToNext(L) = round(base * growth^(L-1))`, with the cumulative table built once at load and memoized.
Skill XP is awarded per completed action from `resources.json` -> `xpPerAction`; design section 3 is
explicit that creature quality changes how fast actions complete, never XP per action. Slot count is
the number of `slotUnlockLevels` entries less than or equal to the current level.

### 4.4 Bench Aether

Emission is a **continuous rate**, accrued fractionally from elapsed time. There is no once-a-minute
lump, online or offline.

```
emissionPerMin = sum over benched creatures of
                 rarity.benchEmissionPerMin * (1 + capped bench_aether_emission modifiers)

// applied every step, with whatever dt the step happens to carry
aetherGained = emissionPerMin * (dtMs / 60000)
state.aether += aetherGained                      // fractional, never rounded in storage
```

Creatures in a work slot or on an expedition are excluded (design sections 5 and 8).

Consequences, all deliberate:
- A 200ms UI frame and a 6-hour offline window use the **same function** with a different `dt`.
  Section 4.5 calls it once with the capped elapsed time rather than reimplementing it.
- Aether is stored as a float. Only the display rounds, so short sessions and small benches are not
  silently worth zero.
- `tuning.aether.benchEmissionTickMs` (60000) does **not** gate accrual. It controls only how often the
  value is re-rendered and flushed to the save. Accrual itself is continuous and dt-driven; changing
  this knob must never change how much Aether a player earns.

### 4.5 Offline progress

Design section 3: bulk, never a tick replay.

```
elapsed = min(now - lastSeen, capHours)

for each active work slot:
  loop, bounded by maxSegmentsPerSlot:
    cd            = cooldownMs(creature, resource)
    actionsToNext = actions needed to reach the next skill level
    n             = min(floor(remaining / cd), actionsToNext)
    award n actions of output and xp, advance remaining, re-derive on level-up
```

Segmenting on level-ups keeps this bulk (a handful of divisions) while staying correct when a level-up
changes something a running slot depends on. **Today nothing does** (cooldown depends on creature level, not skill
level, and no skill consumes resources), so `advanceSkills` sums XP and derives the level once; segment there if a
later phase adds a level-dependent input. Output rolls across `n` actions use a binomial draw
from the seeded RNG rather than `n` individual rolls. The whole thing returns a summary object that
feeds the "welcome back" screen in step 1.8.

Bench Aether for the same window is **not** computed here. `offline.ts` calls the section 4.4 function
once with `dt = elapsed`, so the online and offline paths cannot drift apart.

**`applyOffline` is the only catch-up path.** All three ways of being away go through it, so none of them can rot:

| Away | Who calls it | Window measured from |
|---|---|---|
| Closed tab | `state/persistence.ts` `loadGame` | the save's `lastSeen` |
| Open tab, gap > `offline.awayThresholdMs` | `state/driver.ts` `stepToNow` | the **driver's own tick anchor** |
| Dev panel fast-forward N hours | `state/driver.ts` `fastForwardHours` | `now - N hours` |

The open-tab case must measure from the driver's anchor, not from `state.lastSeen`: `lastSeen` is only stamped when
the save is flushed (every `save.autosaveMs`), while the driver has already stepped the sim past it. Measuring from
the stale `lastSeen` would grant up to one autosave period of progress twice.

### 4.6 Randomness

`sim/rng.ts` exports `interface Rng { next(): number; int(n): number; chance(p): boolean; binomial(n, p): number }`
with a mulberry32 implementation. Every sim function that rolls takes an `Rng`. Tests inject a fixed
state and assert exact sequences.

**The save persists the current RNG state, not the initial seed.** mulberry32's state is a single uint32
that advances on every `next()`; the save stores that live value, and it is written back on every
consume:

```ts
type Rng = {
  state: number           // uint32, advances on every consume
  next(): number          // mutates state, returns [0, 1)
}
// state.rngState mirrors rng.state and is what the save file holds
```

Storing the initial seed instead would make the stream a pure function of *how many rolls have happened
since the save*, so quitting and reloading would replay the same numbers — the exact reroll this is meant
to prevent.

**Outcome-committing rolls force an immediate save**, rather than waiting for the 15s autosave:
breeding a pair, hatching an egg, and a capture/bind attempt. Each of these writes the result *and* the
advanced RNG state in one commit, so a crash or a deliberate reload between the roll and the next
autosave cannot rewind either. `commitRoll(storage, state, roll, now)` in `state/persistence.ts` runs the roll and flushes the result and the
advanced RNG synchronously; `state/actions.ts` wraps it, and those three actions must go through it.
Idle progress (work actions, rare-drop rolls, bench Aether) stays on the 15s autosave — the stakes are
low and the write volume would be high.

### 4.7 Events

`sim/tick.ts` and `sim/offline.ts` both return `{ state, events }`. `SimEvent` covers `action-complete`,
`skill-level-up`, `slot-unlocked`, `creature-level-up` and `form-evolved` now, and `egg-hatched`,
`shiny-revealed` and `species-discovered` later. The UI subscribes to that queue for progress animations
and, in phase 2, the hatch reveal — so the reveal needs no sim rework.

---

## 5. State and save

```ts
type GameState = {
  version: number
  lastSeen: number          // epoch ms, written on autosave and on unload
  rngState: number          // CURRENT mulberry32 state, advanced on every consume (section 4.6)
  aether: number            // float; only the display rounds
  gold: number
  resources: Record<string, number>
  creatures: Creature[]     // id, speciesId, isHybrid, rarityTier, level, xp, form, shiny,
                            // poolTraits: [{ traitId, strength, locked }], assignment
  nextCreatureSeq: number   // creature ids are `creature-<n>`, so ids need no Math.random
  skills: Record<string, {
    level: number           // cached from xp; only addSkillXp changes either
    xp: number              // cumulative
    slots: ({ creatureId: string; resourceId: string; progressMs: number } | null)[]
                            // progressMs is per SLOT: each slot's creature has its own cooldown
  }>
  collection: {
    speciesSeen: string[]
    rarityTiersSeen: Record<string, number[]>
    recipesFound: string[]
    shiniesFound: string[]
    formsUnlocked: Record<string, number>
  }
  settings: { offlineSummary: boolean, devPanelEnabled: boolean }   // autoBind arrives in phase 3
}
```

- One localStorage key: `aetherbound-idle:save`, holding `{ version, state }`.
- Writes happen on the `autosaveMs` timer, on unload, and **immediately after any outcome-committing
  roll** (breed, hatch, capture — section 4.6).
- `settings.devPanelEnabled` is part of the save, so the dev panel's visibility survives a reload.
- `sim/save.ts` exports `MIGRATIONS: Record<number, (s: any) => any>`, applied in order from the file's
  version up to `tuning.save.version`.
- A save that cannot be migrated is **not** silently discarded: it is copied to
  `aetherbound-idle:save-broken-<timestamp>` and the player starts fresh with a visible notice.
- The save holds IDs and player progress only, never copies of content, so rebalancing a JSON file
  updates existing saves automatically.

---

## 6. Testing (vitest)

Phase 1 coverage:

- xp curve round-trip (level -> xp -> level) and slot unlock thresholds at 1/20/40/65/90.
- Cooldown: the shared `cooldown_reduction` cap, and the floor taken from the **efficiency-adjusted**
  base. One test asserts the property that matters: a maxed off-primary hybrid is still strictly slower
  than a floored specialist on the same resource.
- Efficiency as a divisor: off-primary (0.60) makes the action longer, secondary aptitude (0.15) makes it
  shorter, and the two compose.
- Modifier stacking plus the aura "strongest only" rule.
- Bench emission: continuous accrual, with the invariant that one call with `dt = 60min` equals
  `N` calls summing to 60min (within float tolerance), and that changing `benchEmissionTickMs` changes
  nothing about the total.
- Offline progress: a window crossing a level-up, a zero window, a negative/clock-skewed window, and a
  window longer than `capHours`. Plus: offline Aether for a window equals online Aether for the same
  elapsed time.
- RNG: the saved state is the *current* state, so save -> reload -> roll continues the stream instead of
  replaying it. A round-trip through `save.ts` reproduces the same next value.
- Save round-trip, a v1 -> v2 migration stub, and the broken-save quarantine path.
- Content: every species, hybrid, trait, ability and resource loads and cross-resolves.

---

## 7. Phase 1 build order (maps to PROGRESS.md)

| Step | Adds |
|---|---|
| 1.2 | Scaffold, tooling, `.gitignore`, commands filled into CLAUDE.md |
| 1.3 | All of `src/data/` plus `schema.ts` and `index.ts`, content load test |
| 1.4 | `rng`, `formulas`, `modifiers`, `creature`, `skills`, `aether`, `events` + tests |
| 1.5 | `offline`, `save`, `state/persistence` + tests |
| 1.6 | Skills screen, top bar, tick driver |
| 1.7 | Roster screen, placeholder art, filter and sort, assign to slot |
| 1.8a | Away path for a long-open tab, welcome-back summary, Settings tab, dev-panel fast-forward |
| 1.8b | Rest of the dev panel, Nexus bench + emission display, polish |

Phase 1 ships one starter **Sproutlet**, Woodcutting with `oak-log` / `willow-log` / `yew-log`, and the
bench. `zones.json`, `vessels.json` and `collection-tracks.json` are created empty in step 1.3 so their
schemas exist and phase 3/4 sessions have somewhere to put content.

### 7.1 Dev panel (step 1.8)

`src/ui/screens/DevPanel.tsx`, hidden behind a Settings toggle (`settings.devPanelEnabled`, default off,
persisted). It exists to make phase 2-4 content testable without grinding, and it starts in phase 1
because every later phase needs it.

| Control | Behaviour | Built |
|---|---|---|
| Fast-forward N hours | Rewinds `lastSeen` by N hours and re-runs the **real** offline path. | 1.8a |
| Grant creature | Pick any species or hybrid, any rarity tier, level and form; optional shiny. Rolls pool traits normally unless overridden. | 1.8b |
| Add resources | Any amount of any resource ID. | 1.8b |
| Add Aether / gold | Direct numeric grant. | 1.8b |
| Reset save | Wipes the save and reloads, behind a confirmation. | 1.8b |

Step 1.8 was split in two at the designer's instruction (2026-09-19): 1.8a is the away path, the summary, the
Settings tab and the fast-forward; 1.8b is the rest.

The fast-forward control is the important one, and it must not have its own maths. It sets
`lastSeen = now - N hours` and calls the same `sim/offline.ts` entry point the app calls on load, so it
exercises the shipped code path — including the `capHours` clamp, which means fast-forwarding 100 hours
with a 12-hour cap correctly yields 12 hours of progress rather than 100. A separate "simulate" path
would let the offline code rot untested, which is the one thing this panel exists to prevent.

Dev actions still flow through `state/actions.ts` and the normal save path; the panel gets no privileged
access to the store. It ships in the production build behind the toggle rather than being stripped by a
build flag, so the designer can use it on a deployed build.

---

## 8. Approved decisions

All six approved by the designer on 2026-09-19, with six amendments folded into the sections above.

1. **`zod`** is the dependency for the type-checked loaders in step 1.3.
2. **Signature and pool traits share `traits.json`**, resolved by one effect engine. Signature traits
   carry `kind: "signature"` and a `species` back-reference.
3. **Max level 99** for both skills and creatures.
4. **Woodcutting tier unlocks at skill level 1 / 15 / 30**, 3s base action, 10 xp — placeholders.
5. **Offline cap 12 hours** as the starting tunable value.
6. **Seeded RNG**, persisted so a reload cannot reroll a pending breed or hatch.

### Amendments made at approval

| # | Amendment | Lands in |
|---|---|---|
| 1 | Efficiency modifiers **divide** the base action time instead of multiplying it, and the cooldown floor is taken from the **efficiency-adjusted** base, so an off-primary hybrid can never reach specialist speed | 3.7, 3.10, 4.2 |
| 2 | Rarity's cooldown contribution has one home: `tuning.cooldown.rarityTermPerTier`. The `cooldownTerm` field is gone from `rarities.json` | 3.3 |
| 3 | The save persists the **current** RNG state, advanced on every consume, and outcome-committing rolls (breed, hatch, capture) flush the save immediately rather than waiting for autosave | 4.6, 5 |
| 4 | Bench Aether accrues **continuously** from `dt`, online and offline through the same function. `benchEmissionTickMs` controls save/display cadence only | 3.10, 4.4, 4.5 |
| 5 | A **dev panel** ships in phase 1, behind a Settings toggle, with fast-forward running the real offline path | 1, 5, 7, 7.1 |
| 6 | Offline slot-ordering needs a rule once skills consume resources | `docs/PROGRESS.md` open questions |

Open questions that do not block step 1.2 live in `docs/PROGRESS.md`.
