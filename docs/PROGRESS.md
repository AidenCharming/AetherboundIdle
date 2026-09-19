# Progress

Read this at the start of every session. Update it after every checkpoint (see Session protocol in CLAUDE.md).

## Next up
**Step 1.4: sim core.** Build to `docs/plan.md` sections 4.1-4.4, 4.6 and 4.7, and the phase 1 test list in
section 6. Create `src/sim/` as pure functions (no React, no zustand, no `Date.now()`, no `Math.random()`):
`rng.ts`, `formulas.ts` (stats, cooldown with the efficiency divisor and floor, xp curve, level <-> xp),
`modifiers.ts` (collect effects, apply the registry caps and the strongest-only aura rule), `creature.ts`,
`skills.ts` (slot unlocks, action resolution, output rolls, xp), `aether.ts` (continuous bench emission)
and `events.ts`, each with unit tests in `test/`.

Read game content through `import { content } from '../data'` (validated, with trait strengths filled in).
Two things changed at 1.3 that affect this step: the bonus Health/Power/Guard traits are a **percentage of
the stat** (plan 4.1 was amended), and the Overclocked `dynamic` effect has an open question (below), so
skip modelling `dynamic` effects until that is answered. Then 1.5 (offline + save) is the step after.

## Phase 1: Economy core
- [x] 1.1 Plan: folder structure and JSON schemas written to `docs/plan.md`. **Wait for designer's OK.** *(approved 2026-09-19 with six amendments)*
- [x] 1.2 Scaffold Vite + React + TS + Zustand + Vitest. Build and test commands work. Commands filled in CLAUDE.md. First git commit. *(2026-09-19)*
- [x] 1.3 Convert `docs/content-data.md` into JSON in `src/data/` (types, skills, species, hybrids, traits, tuning knobs) plus loaders with type-checked schemas. Test that every species and hybrid loads. *(2026-09-19)*
- [ ] 1.4 Sim core in `src/sim/` (pure functions): creature stats, action cooldown with floor, skill XP and levels, slot unlocks, Aether emission. Unit tests.
- [ ] 1.5 Offline progress calculation (time elapsed ÷ cooldown, bulk, capped window) plus save/load with versioning. Unit tests.
- [ ] 1.6 UI: skills screen with a Woodcutting slot and progress bars, top bar with resources.
- [ ] 1.7 UI: roster screen with placeholder art cards (type colors, emoji, rarity frame), filter and sort, assign to slot.
- [ ] 1.8 Bench and Aether emission display, "welcome back" offline summary, dev panel (see plan.md 7.1), polish pass. Phase 1 playable.

## Phase 2: Breeding and hatching
Not started. Break into steps at the start of the phase.

## Phase 3: Expeditions and capture
Not started.

## Phase 4: Depth
Not started.

## Decisions and deviations from the design

### 2026-09-19, step 1.1 — plan written and approved
The repo had no git history; `git init` was run as part of this checkpoint so the protocol's
per-checkpoint commits start at 1.1 rather than 1.2.

All six proposals in `docs/plan.md` section 8 were approved: zod for the loaders, one `traits.json` for
signature and pool traits, max level 99, Woodcutting tiers at level 1/15/30, a 12-hour offline cap, and a
seeded persisted RNG.

Approved with six amendments, all folded into plan.md:

1. **Efficiency modifiers divide the base action time, they do not multiply it.** Hybrid off-primary
   efficiency 0.60 means `baseActionMs / 0.60`; secondary aptitude 0.15 means `baseActionMs / 1.15`.
   Higher is always better for both knobs. **The cooldown floor is taken from the efficiency-adjusted
   base**, not the unadjusted one, so an off-primary hybrid's floor is 1.667x a specialist's and it can
   never reach specialist speed on a skill it is not built for. (plan.md 3.7, 3.10, 4.2)
2. **Rarity's cooldown contribution has exactly one home:** `tuning.cooldown.rarityTermPerTier`. The
   duplicate `cooldownTerm` field has been removed from `rarities.json`. (plan.md 3.3)
3. **The save persists the current RNG state, not the initial seed**, advanced on every consume.
   Outcome-committing rolls — breed, hatch, capture — flush the save immediately instead of waiting for
   the 15s autosave, via a `commitRoll` helper in `state/actions.ts`. Persisting the seed alone would let
   a reload replay the same numbers, which is the exact reroll this prevents. (plan.md 4.6, 5)
4. **Bench Aether accrues continuously and fractionally from `dt`**, never in once-a-minute lumps. The
   offline path calls the same function with `dt = elapsed`, so online and offline cannot drift apart.
   `tuning.aether.benchEmissionTickMs` now controls save/display cadence only and must never change how
   much a player earns. Aether is stored as a float; only the display rounds. (plan.md 3.10, 4.4, 4.5)
5. **A dev panel ships in phase 1**, behind a Settings toggle (`settings.devPanelEnabled`, default off,
   persisted): grant any species at any rarity/level/form, add resources and Aether, fast-forward N hours,
   reset the save. Fast-forward rewinds `lastSeen` and re-runs the **real** offline path rather than a
   parallel simulation, so the shipped code stays exercised. Added to step 1.8. Phase 1 still starts the
   player with one Sproutlet and nothing else. (plan.md 1, 5, 7, 7.1)
6. Offline slot-ordering question recorded below.

### 2026-09-19, step 1.2 — scaffold
Scaffolded by hand rather than `npm create vite`, because that command prompts when the target directory
is not empty. Layout follows plan.md section 1: `tsconfig.json`, `vite.config.ts`, `vitest.config.ts`,
`index.html`, `src/main.tsx`, `src/App.tsx`, and empty `src/{data,sim,state,ui/*,types}` and `test/`
folders (each holds a `.gitkeep` so git tracks it).

- Versions are whatever npm resolved today: React 19.3, Vite 8.3, Vitest 5.0, **TypeScript 7.0**, zod 4.6,
  Zustand 5.0. Note TS 7 is the native compiler; `tsc --noEmit` type-checks the build.
- `vitest.config.ts` only includes `test/**/*.test.ts`, matching plan.md's `test/` folder.
- `test/smoke.test.ts` is a one-assertion toolchain check so `npm test` has something to run. It goes away
  in 1.3 when the real content test lands.
- Verified: `npm run build` exits 0, `npm test` passes, and `npm run dev` serves the page and the
  transformed `App.tsx` on :5173.
- The commit also carries the earlier uncommitted formatting pass on `CLAUDE.md` (bullets, blank lines,
  the new session-naming rule 7), plus the rule 7 fix: literal `\*\*` restored to bold, and the trailing
  "Then commit that change" sentence removed.

### 2026-09-19, step 1.3 — content data

`src/data/` now holds all 15 files from plan.md section 1, plus `schema.ts` (strict zod schema per file,
unknown fields rejected) and `index.ts` (`loadContent` parses, fills trait-strength defaults, cross-checks
every ID, and throws one `ContentError` listing every problem; `content` is the validated singleton).
24 species, 15 hybrids, 39 abilities, 69 traits (39 signature + 30 pool), 6 types, 11 skills, 9 + 9
rarities. `test/content.test.ts` (71 tests) proves everything loads and cross-resolves, re-checks every
name and text field against `docs/content-data.md`, and includes negative tests that the loader rejects bad
data. `test/smoke.test.ts` is deleted.

Names were not typed by hand: the JSON was generated by parsing the content-data.md tables, so every name
is copied verbatim (IDs are slugs of the names, never the reverse). The content test then re-parses the doc
and compares. I confirmed it fails on a one-letter typo and on a placeholder emoji.

**Contradictions found, and the designer's answers (2026-09-19):**

1. **Hybrid non-damage abilities carry a type in content-data.md; plan 3.5 said `damageType` is null unless
   damaging.** Kept the doc's type on those six (Briar Wash, Facet Ward, Warm Tides, Twilight Bough,
   Obsidian Shroud, Twilight Mend). Plan 3.5 amended. Base-species non-damage abilities stay null (the doc
   gives them no type).
2. **design.md said forms give +20%/+40% to stats and speed; plan `cooldown.formTerm` is 0.08/0.16.**
   Kept the plan's 0.08/0.16 speed and the +20%/+40% stats. **design.md section 4 was edited** to say forms
   give a smaller, tunable speed bonus. Reason: +20%/+40% speed would nearly equal the whole rarity
   ladder's speed contribution (8 tiers x 0.06 = 0.48).
3. **Bonus Health/Power/Guard traits: plan 4.1 added them flat, design gives every strength as a percent.**
   They are a **percentage of the stat** using the default 5/10/20%. **Plan 4.1 amended**
   (`cappedTraitBonus`). Champion keeps normal strengths and gets a low roll weight instead of smaller
   per-stat values (the doc says "or").
4. **Geneticist: default strengths (5/10/20%) exceed its 3% cap.** Explicit values 0.5% / 1% / 2%, all under
   the 3% cap, added to the +1 mutation chance (so 15% can reach at most 18%).

**Placeholders I supplied (content-data.md had no value; plan.md had none either unless noted).** All are
in JSON, so changing them needs no code:

| Where | Value | Basis |
|---|---|---|
| `types.json` colors | Telluric `#8D6E63`, Pyric `#FB8C00`, Aqueous `#2196F3`, Voltaic `#FDD835`, Void `#7E57C2` | Verdant `#4CAF50` is plan.md's; the rest match the color names in CLAUDE.md rule 4. `element` labels are design section 2. |
| `rarities.json` `statMultiplier` | 1.0 / 1.8 / 2.8 / 4.2 / 6.0 / 8.5 / 12 / 17 / 24 | Dim = 1.0 is plan.md's; the rest are mine, chosen so even Faint clears Form 3's 1.4 comfortably. |
| `rarities.json` `frame` | tints and glow 0 to 1 for tiers 2-9 | Dim (`#8a8a8a`, 0) is plan.md's. |
| `resources.json` willow/yew | 3000 ms, 10 xp, same as oak | Plan decision 4 says "3s base action, 10 xp" without per-tier values. **T2/T3 are therefore no faster or richer than T1**; see open questions. |
| `resources.json` gold | oak 2 (plan), willow 4, yew 8 | Mine, doubling per tier. |
| `resources.json` rare drop | all three logs drop `verdant-seedcache` at 1% | Plan only shows it on oak. The item itself (`Verdant Seedcache`, tier 1, gold 20) is mine; plan only named the id. |
| `resources.json` names | Willow Log, Yew Log | From the ids in plan 3.4 and the design's oak/willow/yew example. |
| `traits.json` Overclocked | `perStack` 0.02, `maxStacks` 5 (10% at cap, matching Moderate) | plan 3.6 names the fields but gives no numbers. |
| `traits.json` `rollWeight` | 10 for everything, 2 for Geneticist, Champion and the four Void-only traits | Doc says only "rare" vs "common or uncommon"; I did not use an uncommon tier. |
| `modifiers.json` caps | 0.50 for every percent mechanic, except `bench_aether_emission` 1.00 and `free_bind_attempts` 3 (count) | `cooldown_reduction` 0.50 is plan.md's and `mutation_odds` 0.03 is design's. The other 17 are mine. `bonus_health/power/guard` caps are a percent of the stat. |
| `tuning.json` `combat.tempo` | `{}` for quick / standard / heavy | Left empty exactly as plan 3.10 shows; phase 3 authors the combat numbers. |
| `tuning.json` everything else | plan 3.10 unchanged | Includes `formTerm` 0.08/0.16 (see answer 2). |

**Interpretations, not contradictions:**
- **Emoji were chosen by me** (content-data.md gives none), 117 real characters, distinct within a creature.
  The schema rejects anything that is not an emoji, so no placeholder can slip in.
- **Hybrid forms have no `art`**: content-data.md only describes base species. Cinderpup and Voltfluff's
  "(Stays cute.)" is kept as a species-level `artNote`.
- **Signature-trait effect keys** map straight from the doc's wording. Judgement calls: Pure Filter
  ("rare-catch") is `rare_drop_chance`; Slow Cooker ("ingredients") is `save_material_chance`; Void
  Resonance (Aether materials), Spatial Pocket (vessel output) and Starlight Infusion (vessels it crafts)
  are scoped to `aether-weaving` / `vessel-crafting`; Captivating, Starlight Magnet and Void Grasp target
  the `party`; the two auras are separate groups (`resonant-frequency`, `sea-breeze`).
- **Hybrid signature traits** are `partner_element_drop_chance` scoped to the hybrid's primary skill, with
  the partner element named in the trait. Gridrift is the one exception (bench Aether emission, Major),
  as content-data.md's notes say. The loader checks the element is the partner type, not the primary
  skill's type.
- **Ability effects**: "instant party heal" becomes `heal-instant` (the plan's enum has no target), and
  Thorn Roll's `damageType` is null (the doc gives it none). Bucket Block is `shield-self` / heavy / 1.5.
- IDs are kebab-case slugs of the names. Hybrid `pair` is sorted alphabetically (`void` sorts before
  `voltaic`).

**Schema additions beyond plan.md** (plan.md updated where it describes the shape): `effect.elementType`;
`species.artNote`; optional `art` on forms; nullable `requiredSkillLevel` / `baseActionMs` / `xpPerAction` on
`kind: "rare"` resources; and minimal schemas for `zones.json`, `vessels.json` and
`collection-tracks.json` (plan.md promised the schemas but gave no shape). Those three files ship as `[]`.
Field choices come from design sections 8-9 and are provisional until phase 3/4.

The content test imports `docs/content-data.md` as raw text, so it will fail if that doc's table layout
changes. That is intentional: it is what keeps the names honest.

## Open questions for the designer

### Needs an answer before Phase 3
- **What does Overclocked's "resets on task completion" mean for an endless idle loop?** Coilchirp's trait
  is "small stacking cooldown reduction that resets on task completion". If every completed action resets
  it, stacks can never build. It may mean stacks accrue during a long task, or per consecutive action with
  a reset on something else. The data models it as `dynamic: stacking-until-complete` with placeholder
  numbers, but the sim needs a rule. Coilchirp is wild-only, so nothing before Phase 3 exercises it.
- **Offline catch-up needs a slot-ordering rule once skills consume resources.** Today every skill only
  produces, so slots can be resolved in any order and the result is identical. As soon as one slot's
  input is another slot's output (Smithing eating ore, Cooking eating fish), the order in which offline
  resolves slots changes the totals, and a wrong order can starve a downstream slot that would have run
  fine in real time. Options: fixed skill priority, player-set ordering, or interleaved time-sliced
  segments. Needs deciding before Phase 3 introduces consuming skills — Phase 1 and 2 are unaffected.

### Not blocking
- **Woodcutting tiers currently differ only in the level that unlocks them.** Oak, willow and yew all take
  3 s and give 10 xp, which is what plan decision 4 literally says, but it means levelling into a higher
  tier gains nothing yet. Say whether tiers should scale time, xp and gold, and by how much; it is a
  three-line JSON change and can wait until 1.6 makes it visible.

### Carried from design.md section 15, not blocking
- Full resource lists, prices and gold values per skill (placeholders in JSON for now).
- Full gear list, zone wild-species assignments, the Voltaic zone, the tutorial script.
- Special-recipe content (`recipes.json` ships with an empty `special` list).
- Exact reward tables for collection milestones.
- Same-type "sibling" species (design section 6 marks this TBD; the roll exists and resolves to nothing).
