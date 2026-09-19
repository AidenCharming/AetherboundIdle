# Aetherbound Idle: Implementation Plan

Approved plan for folder structure, data schemas, and sim architecture. Written at step 1.1.
Later sessions should read this instead of re-deriving it. Change it only with the designer's OK,
and record the change in `docs/PROGRESS.md` under "Decisions and deviations".

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
      events.ts             SimEvent union (action-complete, level-up, hatch, ...)
    state/
      store.ts              zustand store: holds GameState, exposes actions
      actions.ts            thin wrappers that call sim functions and commit results
      selectors.ts          memoized reads for UI
      persistence.ts        localStorage read/write, lastSeen, autosave timer
    ui/
      screens/              Roster.tsx, Skills.tsx, Nexus.tsx, ...
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
  "cooldownTerm": 0.0,
  "benchEmissionPerMin": 1,
  "frame": { "tint": "#8a8a8a", "glow": 0 }
}]
```

Nine entries, Dim through Zenith. `gear-rarities.json` is `{tier, id, name}` only for now
(Common through Primordial); design section 4 ties tier N creatures and tier N gear to the same
resource tier.

### 3.4 resources.json

```json
[{
  "id": "oak-log", "name": "Oak Log", "tier": 1, "skill": "woodcutting",
  "kind": "raw",
  "elementType": "verdant",
  "requiredSkillLevel": 1,
  "baseActionMs": 3000,
  "xpPerAction": 10,
  "goldValue": 2,
  "rareDrop": { "id": "verdant-seedcache", "chance": 0.01 }
}]
```

`kind` is one of `raw | refined | crafted | rare`. `elementType` is what breeding costs and the
partner-element-drop hybrid traits read. v1 authors tiers 1-5 (design section 3); phase 1 ships
Woodcutting T1-T3 only: `oak-log`, `willow-log`, `yew-log` at required skill levels **1 / 15 / 30**
(PLACEHOLDER).

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
`damageType` is a type ID when the effect deals damage, otherwise null. `magnitude` multiplies the
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
and drives the "strongest only, never stacks" rule from design section 4. When `valueByStrength` is
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

`statLean` is `health | power | guard`. `emoji` holds the actual emoji character in the real file.
`art` carries the form description from content-data.md so later art work does not need the doc.

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
`primarySkill` is `tuning.skills.hybridOffPrimaryEfficiency` (PLACEHOLDER 0.60, design section 2).

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
  "offline": { "capHours": 12, "maxSegmentsPerSlot": 200 },
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
  "save": { "version": 1, "autosaveMs": 15000 }
}
```

Numbers marked PLACEHOLDER in the design doc are all here: form multipliers, cooldown floor, trait
strengths, mutation rates, shiny rates, attunement lock costs, breeding costs. Form bonuses (1.2 / 1.4)
sit well below the rarity ladder's multipliers, as design section 4 requires.

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
     + cappedFlatTraitBonus(stat)
```

### 4.2 Action cooldown

Two stages, so intrinsic growth and trait stacking cannot be confused, with one hard floor over both.

```
intrinsicTerm  = levelTermPerLevel * (level - 1)
               + rarityTermPerTier * (rarity.tier - 1)
               + formTerm[form]

intrinsicMult  = 1 / (1 + intrinsicTerm)            // hyperbolic, i.e. diminishing returns
traitReduction = min(cap["cooldown_reduction"], sum of every cooldown_reduction source)

raw        = baseActionMs * intrinsicMult * (1 - traitReduction)
cooldownMs = max(raw, baseActionMs * floorFraction)
```

Efficiency modifiers (hybrid off-primary, secondary aptitude on open skills) multiply `baseActionMs`
before this, so they sit under the same floor.

### 4.3 XP and levels

`xpToNext(L) = round(base * growth^(L-1))`, with the cumulative table built once at load and memoized.
Skill XP is awarded per completed action from `resources.json` -> `xpPerAction`; design section 3 is
explicit that creature quality changes how fast actions complete, never XP per action. Slot count is
the number of `slotUnlockLevels` entries less than or equal to the current level.

### 4.4 Bench Aether

```
emissionPerMin = sum over benched creatures of
                 rarity.benchEmissionPerMin * (1 + capped bench_aether_emission modifiers)
```

Creatures in a work slot or on an expedition are excluded (design sections 5 and 8).

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
changes the slot count or unlocks a resource tier. Output rolls across `n` actions use a binomial draw
from the seeded RNG rather than `n` individual rolls. The whole thing returns a summary object that
feeds the "welcome back" screen in step 1.8.

### 4.6 Randomness

`sim/rng.ts` exports `interface Rng { next(): number; int(n): number; chance(p): boolean; binomial(n, p): number }`
with a mulberry32 implementation. Every sim function that rolls takes an `Rng`. The store holds a seeded
instance whose seed is persisted, so reloading cannot reroll a pending breed or hatch. Tests inject a
fixed seed.

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
  rngSeed: number
  aether: number
  gold: number
  resources: Record<string, number>
  creatures: Creature[]     // id, speciesId, isHybrid, rarityTier, level, xp, form, shiny,
                            // poolTraits: [{ traitId, strength, locked }], assignment
  skills: Record<string, {
    level: number
    xp: number
    slots: ({ creatureId: string; resourceId: string } | null)[]
    progressMs: number
  }>
  collection: {
    speciesSeen: string[]
    rarityTiersSeen: Record<string, number[]>
    recipesFound: string[]
    shiniesFound: string[]
    formsUnlocked: Record<string, number>
  }
  settings: { autoBind: ..., offlineSummary: boolean }
}
```

- One localStorage key: `aetherbound-idle:save`, holding `{ version, state }`.
- `sim/save.ts` exports `MIGRATIONS: Record<number, (s: any) => any>`, applied in order from the file's
  version up to `tuning.save.version`.
- A save that cannot be migrated is **not** silently discarded: it is copied to
  `aetherbound-idle:save-broken-<timestamp>` and the player starts fresh with a visible notice.
- The save holds IDs and player progress only, never copies of content, so rebalancing a JSON file
  updates existing saves automatically.

---

## 6. Testing (vitest)

Phase 1 coverage: xp curve round-trip (level -> xp -> level), slot unlock thresholds at 1/20/40/65/90,
cooldown floor and the shared cap, modifier stacking plus the aura "strongest only" rule, bench emission,
offline progress (including a window that crosses a level-up, a zero window, and a negative/clock-skewed
window), save round-trip plus a v1 -> v2 migration stub, and a content test that every species, hybrid,
trait, ability and resource loads and cross-resolves.

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
| 1.8 | Nexus bench + emission display, welcome-back summary, polish |

Phase 1 ships one starter **Sproutlet**, Woodcutting with `oak-log` / `willow-log` / `yew-log`, and the
bench. `zones.json`, `vessels.json` and `collection-tracks.json` are created empty in step 1.3 so their
schemas exist and phase 3/4 sessions have somewhere to put content.

---

## 8. Decisions that need your OK

1. **Add `zod`** as a dependency, for the "loaders with type-checked schemas" in step 1.3. It validates
   the JSON at load and infers the TypeScript types from the same definition. Alternative: hand-written
   interfaces plus a small custom validator — no dependency, more code, weaker guarantees. Recommending
   zod.
2. **Signature and pool traits share `traits.json`** instead of living in two files, so one effect engine
   resolves both. Signature traits carry `kind: "signature"` and a `species` back-reference.
3. **Max level 99** for both skills and creatures. The design fixes slot unlocks at 90 and Form 3 at 60
   but never states a cap.
4. **Woodcutting tier unlocks at skill level 1 / 15 / 30**, 3s base action, 10 xp — pure placeholders to
   make phase 1 playable.
5. **Offline cap 12 hours** as the starting value. Design section 3 says capped and tunable but gives no
   number.
6. **Seeded, persisted RNG** so a reload cannot reroll a pending breed or hatch. Costs nothing now and
   makes the phase 2 rolls testable.

Open questions that are not blocking step 1.2 stay in `docs/PROGRESS.md`.
