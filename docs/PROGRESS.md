# Progress

Read this at the start of every session. Update it after every checkpoint (see Session protocol in CLAUDE.md).

## Next up
**Step 1.6, checkpoint B: the Skills screen** (checkpoint A, the state layer, is done, see below). Build, in `src/ui/`
and reading only through `src/state/selectors.ts` / `useGameStore` / `useActions` (never `src/sim`):
1. Woodcutting slot(s) driven by the skill's real slot count, each with the creature, a progress bar
   (`selectSlotProgress`, smoothed by `uiTickMs`, no backwards sweep at the cycle boundary) and the oak/willow/yew
   picker (locked tiers greyed with their level).
2. Assign and unassign, showing the sim's rejection reason.
3. Skill level, XP toward next level and slot count; the top bar (gold, floored Aether, resources held).
4. The quarantine banner with a dismiss control. Do not build the welcome-back screen (1.8).

## Phase 1: Economy core
- [x] 1.1 Plan: folder structure and JSON schemas written to `docs/plan.md`. **Wait for designer's OK.** *(approved 2026-09-19 with six amendments)*
- [x] 1.2 Scaffold Vite + React + TS + Zustand + Vitest. Build and test commands work. Commands filled in CLAUDE.md. First git commit. *(2026-09-19)*
- [x] 1.3 Convert `docs/content-data.md` into JSON in `src/data/` (types, skills, species, hybrids, traits, tuning knobs) plus loaders with type-checked schemas. Test that every species and hybrid loads. *(2026-09-19)*
- [x] 1.4 Sim core in `src/sim/` (pure functions): creature stats, action cooldown with floor, skill XP and levels, slot unlocks, Aether emission. Unit tests. *(2026-09-19)*
- [x] 1.5 Offline progress calculation (time elapsed ÷ cooldown, bulk, capped window) plus save/load with versioning. Unit tests. *(2026-09-19)*
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
| `resources.json` willow/yew | ~~3000 ms, 10 xp, same as oak~~ | **Superseded** by the designer's tier values (see "two data changes" below). |
| `resources.json` gold | ~~oak 2 (plan), willow 4, yew 8~~ | **Superseded**: 2 / 6 / 15. |
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

### 2026-09-19, before step 1.4 — two data changes (designer's instruction)

1. **Woodcutting placeholder tiers now scale.** oak-log 3000 ms / 10 xp / 2 gold, willow-log 4000 ms / 25 xp /
   6 gold, yew-log 5000 ms / 50 xp / 15 gold. Unlock levels unchanged (1 / 15 / 30). xp per second rises with
   each tier (3.33 → 6.25 → 10), so levelling into a tier has a point. This **supersedes** the 1.3 placeholder
   rows for willow/yew time, xp and gold, and closes the "tiers differ only in unlock level" open question.
   Still placeholders.
2. **Champion is now a small upgrade over Brawn, not strictly better.** It keeps its low roll weight (2) and
   both effects (bonus Power and bonus Guard) now carry an explicit `valueByStrength` of 0.03 / 0.06 / 0.12,
   about 60% of Brawn's default 5 / 10 / 20% on each stat. This replaces answer 3's "Champion keeps normal
   strengths" note from 1.3; the low roll weight stays.

`test/content.test.ts` pins both (73 tests).

### 2026-09-19, step 1.4 — sim core

`src/sim/`: `rng`, `formulas`, `modifiers`, `creature`, `skills`, `aether`, `events`, plus `state` (new game) and
`src/types/state.ts`. All pure: nothing imports React, zustand or `Date.now`/`Math.random`, and `src/sim` imports
only `src/data` and `src/types`. 135 new tests; 208 pass and `npm run build` is clean.

**Formulas follow plan 4.1-4.4 as amended.** Efficiency divides the base time; the floor is
`adjustedBase * floorFraction`; Aether is `emissionPerMin * dt / 60000` accrued as a float from whatever `dt` the step
carries (`benchEmissionTickMs` is not read anywhere in the sim, and a test proves changing it changes nothing); the
RNG state lives in `GameState.rngState` and is written back by every function that consumes it. Every function takes
its content as a trailing `c: Content = content` argument, so tests build variants of the real data instead of mocks.

**Dynamic effects (Overclocked) are NOT modelled, by instruction.** `modifiers.ts` has one marked hook,
`dynamicEffectValue`, which returns 0, so a `dynamic` effect contributes nothing. **The design question is still
open** (see "Needs an answer before Phase 3" below): what "resets on task completion" means for an endless idle loop.
Whatever the answer is lands in that hook and will probably need a stack counter in creature state. Tested: Coilchirp
gets no cooldown reduction from Overclocked and its other sources are unaffected.

**Deviations from plan.md shape** (plan.md updated to match):
1. **`progressMs` moved from the skill onto each slot.** Plan 5 had one per skill, but every slot has its own creature
   and cooldown, so two slots cannot share one progress counter.
2. **`nextCreatureSeq` added to `GameState`**: creature ids are `creature-<n>`, so ids need no `Math.random`.
3. **`settings.autoBind` left out.** Plan 5 wrote it as `...`; it is phase 3 and will be added with its migration.
4. **Plan 4.5's per-level segmentation is not needed yet.** Nothing about a running slot depends on the skill's level
   (cooldown uses creature level, rarity and form) and no skill consumes resources, so a window crossing a level-up gives
   an identical result summed in one pass: XP added once, level derived once, a `skill-level-up` per level crossed and a
   `slot-unlocked` at each threshold. `advanceSkills` says where segmentation goes if a later phase adds a level-dependent
   input. `offline.maxSegmentsPerSlot` is therefore unused for now. Tested: one call and 14,400 small calls agree exactly.
5. **New files beyond the plan's list:** `sim/state.ts` (`createInitialState(seed, now)`); `tick.ts` moves to step 1.5.
6. **`action-complete` is aggregated**: one event per slot per call carrying `count`, `outputs` and `skillXp`, so a
   12-hour window is one event per slot rather than tens of thousands.

**Interpretations to confirm** (the plan defines cooldown, stats and bench Aether only; these read the design's trait list):
- `extra_output_chance`: chance of +1 extra of the gathered resource per action, additive, capped (offline adds
  `offline_extra_output_chance`). `bonus_xp`: multiplies XP per action. **`rare_drop_chance` scales the drop's own
  chance** (+10% on 1% is 1.1%), not percentage points, since adding 10 points to a 1% drop would be 11x. Output rolls
  are binomial draws, exact for small expected counts and a normal approximation above 30.
- Not consumed yet, with a marked hook: `partner_element_drop_chance` (no hybrids before phase 2), `save_material_chance`
  (no consuming skills before phase 3), `treasure_drop_chance` (Fishing).
- `active-creatures` auras (Sea Breeze) include their own source; `other-active-in-skill` (Resonant Frequency) does not.
  Both reach only creatures that are in a work slot. Two of the same aura take the strongest; different auras add.
- **A hybrid on an open skill takes no off-primary penalty.** "Covered skills" are the locked skills of its two types
  (plan 3.7), so Fabrication and Scavenging are nobody's off-primary. The secondary-aptitude bonus still applies.
- **Working awards no creature XP**: design section 8 says only combat levels a creature. `grantCreatureXp` exists,
  is tested (level-ups, automatic Form 2 at 30 and Form 3 at 60) and is called by nothing until phase 3.

**A finding for the designer.** With the shipped placeholders the 20% cooldown floor is **unreachable**: the best case
(level 99, Zenith, Form 3, and the 50% trait cap) is `1/2.032 * 0.5` = **24.6%** of the adjusted base. The floor is a
safety net today, and the "an off-primary hybrid can never reach specialist speed" property still holds without it
(1.667x slower at every point). Tests raise `floorFraction` to 0.6 to prove the floor maths where it binds. If you want
the floor to matter, raise `floorFraction`, lower the cap, or steepen `levelTermPerLevel`.

### 2026-09-19, step 1.5 — offline progress and save/load

New: `sim/tick.ts`, `sim/offline.ts`, `sim/save.ts`, `state/persistence.ts`. 97 new tests; 305 pass and `npm run build`
is clean. `src/sim` is still pure (no clock, no `Math.random`, no storage, imports only `data` and `types`).

**Offline is `step` with `dt = elapsed`, and nothing else.** `tick.ts` exports the one step function
(`advanceSkills` then `accrueAether`); the online tick will call it per frame and `applyOffline` calls it once with the
window, with `offline: true` so Night Owl's `offline_extra_output_chance` applies. `offline.ts` owns only the window:
`min(now - lastSeen, capHours)`, where the cap comes from `tuning.offline.capHours`. It returns
`{ state, events, summary }` and the summary (window, cap hit, clock skew, Aether gained, per-skill actions, XP, levels
and slots unlocked, resources gained) is what 1.8's welcome-back screen shows.

**The three windows you asked for, all tested at both `applyOffline` and `loadGame` level:**
- **Crosses a level-up:** 1 hour of oak is 1,200 actions and 12,000 XP, which is level 27 and crosses the level-20 slot
  unlock. Lands on the right XP, level, slot count and resources, emits a `skill-level-up` per level and the
  `slot-unlocked`, and equals stepping the same hour online in 14,400 small steps exactly.
- **Zero:** changes nothing but `lastSeen`, consumes no randomness, empty events and summary.
- **Clock-skewed (negative):** grants nothing, sets `clockSkewed`, consumes no randomness, and **re-anchors
  `lastSeen` to `now`**. Leaving it in the future would freeze progress until the real clock caught up. Tested from a
  few minutes to a decade back, plus NaN and infinite clocks (treated as a zero window). Also tested: a window over the
  cap (100 h grants exactly 12 h and still moves `lastSeen`), and that offline Aether equals online Aether over the same
  time, including a ragged frame pattern with a dropped-tab frame.

**Save format (`sim/save.ts`).** `{ version, state }` under `aetherbound-idle:save`. `parseSave` returns a result and never
throws: `corrupt` (not JSON / no version), `invalid` (strict zod schema, then integrity checks: every ID resolves, and
a creature's `assignment` and its slot agree), `too-new`, or `migration-failed`. `MIGRATIONS[n]` upgrades n to n+1 and is
empty today; the chain is tested with a v1 -> v2 stub, a multi-step chain, a missing step and a throwing step. On load,
`reconcile` re-derives each skill's cached level from its XP (so a retuned XP curve applies to existing saves and never
removes XP or slots) and adds skills introduced since the save. A slot pointing at a removed resource loads fine and
the sim idles it.

**RNG (plan 4.6, and the reason for this checklist).** The save holds `GameState.rngState`, the *live* state, and every
step writes it back. Tests: the saved state is not the seed; a round trip reproduces the next 50 values; and
save -> reload -> roll continues the stream, including an end-to-end run that reloads between every roll and matches an
uninterrupted run. `commitRoll(storage, state, roll, now)` runs a roll and flushes the result *and* the advanced RNG in one
write, with a test that a reload straight after cannot re-roll the committed outcome.

**Persistence (`state/persistence.ts`).** Storage and the clock come in as arguments (`StorageLike`, `now`), so it is tested
in node. `flushSave` stamps `lastSeen = now` and reports a failed write instead of throwing. `loadGame(storage, now, seed)`
loads, applies offline progress, writes back so a second load does not double-count, and returns a `LoadOutcome`. A save
that cannot be loaded is copied byte-for-byte to `aetherbound-idle:save-broken-<now>`, a fresh game starts, and the
outcome carries a `quarantined` notice with the reason. This includes a save from a newer build, whose raw text is kept.

**Deviations from plan.md** (plan.md updated where it describes the shape):
1. `commitRoll` lives in `state/persistence.ts`, not `state/actions.ts`. It needs no store, so it is testable now;
   `actions.ts` will wrap it when the store exists (1.6).
2. `tick.ts` and `sim/state.ts` (`createInitialState`) exist as of 1.4/1.5; plan.md's build table put the tick with 1.6,
   but offline needs it, and the 1.6 driver only *calls* it.
3. `flushSave` stamps `lastSeen = now` on every write, so it assumes the sim has been stepped up to `now`. That holds while
   the tick driver runs; a driver that pauses without flushing would forfeit the paused time on the next load.

**Not built yet, deliberately:** the autosave timer and unload flush (they need the store and a driver; 1.6), and
any cleanup policy for old `save-broken-*` copies (each is one save's worth of localStorage; only matters if a save
is corrupted repeatedly).

**How these tests were checked.** Beyond a green run, I broke the code on purpose 18 ways and confirmed each is caught: RNG
not written back (in step, in offline, on load, on write), floor from the unadjusted base, efficiency multiplying
instead of dividing, Aether in whole-minute lumps, Aether reading `benchEmissionTickMs`, negative window let through, cap
ignored, `lastSeen` not re-anchored, `commitRoll` not flushing, auras stacking, cap not applied, the hybrid penalty on
open skills, Overclocked modelled, the migration chain skipped, and an assignment/slot mismatch not detected.

### 2026-09-19, step 1.6 checkpoint A: state layer and tick driver

New in `src/state/`: `store.ts`, `driver.ts`, `actions.ts`, `selectors.ts`, `runtime.ts`. 81 new tests (305 before this step); 386 pass and
`npm run build` is clean. `main.tsx` calls `bootGame()` once, outside React, before the first render.

**Shape.** `store.ts` is a vanilla zustand store `{ game, loadReport, noticeDismissed }` with no timers, storage or clock.
`driver.ts` is `createTickDriver(store, env)`; `actions.ts` is `createActions(store, driver, storage)`; `selectors.ts` is
what the UI reads. `runtime.ts` is the only file in `src/state` that touches `window`, `localStorage`, `crypto` or
`Date.now` (a test enforces it). It builds the real `Env`, boots the game, and exports the two hooks the UI uses,
`useGameStore(selector)` and `useActions()`. Everything else takes the clock, storage, timers and window/document as
arguments, so it is tested in node with a `FakeEnv` (`test/helpers.ts`).

**Driver rules, each with a test that fails if the rule is broken** (I broke `flush` and the re-anchor on purpose to check):
- dt is real elapsed time from the injected clock. Negative dt becomes 0 and the anchor moves to the new now, so progress
  resumes instead of freezing until the clock catches up (same reasoning as `applyOffline`). A NaN clock is ignored.
- A large dt goes to `step` in one call, never a loop. Tested with a ten-hour gap: one `step` call, result identical to
  calling the sim directly.
- **Every flush steps to now first**: the autosave (`tuning.save.autosaveMs`), `pagehide`, `beforeunload`, and
  `actions.commitRoll`. Tested by advancing the clock an hour with no tick, flushing, and checking the saved file holds
  the hour of work and that an immediate reload has a zero window (nothing forfeited, nothing double-counted).
- `visibilitychange` to visible steps to now. `start()` is idempotent and `stop()` removes every timer and listener.
- Tick period is `tuning.ui.tickMs` (new, 100, in schema, JSON, content test and plan 3.10). It is a presentation cadence
  only, like `benchEmissionTickMs`: the sim takes any dt.
- **Every action also steps to now before it acts**, so the sliver of time since the last tick is credited to the slot as it
  was, not as it becomes. Tested (30 s pending, unassign, credited 10 actions, not double-counted on the next tick).

**Boot.** `bootGame(env)` draws the seed once (`crypto.getRandomValues`, via `Env.randomSeed`), calls `loadGame`, builds the
store and starts the driver. A second call returns the running game and starts nothing. If `window.localStorage` itself
throws (some privacy modes) it plays on with a storage that reads empty and refuses writes, rather than a white screen.

**Selectors** are the only read path, and a test scans `src/ui`, `App.tsx` and `main.tsx` for any import of `src/sim`. They
return primitives, content lookups that never change, creature views cached per creature object, or lists passed through
`stable()`, which returns the previous array when the ids are equal, because zustand v5 loops on a fresh object or array
per call. A test calls every selector twice on the same state and requires the same identity. Derived values the UI needs
(slot cooldown and progress, tier lock, slot count and next slot level, XP in level, creature name/emoji/type color,
assignable creatures, floored Aether) all live there.

**Deviations and decisions (all reversible, none change the design):**
1. **`runningSlot` extracted in `sim/skills.ts`.** The progress bar needs "is this slot really working, and what is its
   cooldown", which `advanceSkills` already decided inline. Copying those idle checks into the selectors would let the bar
   and the tick drift apart, so the check became one exported function that both call. Behaviour-preserving: all 306
   existing tests passed unchanged.
2. **The autosave timer lives in `driver.ts`**, not `persistence.ts` as plan 1 listed it, so `persistence.ts` stays free of
   timers and remains just the injected-argument read/write it was in 1.5.
3. **`store.loadReport` is the `LoadOutcome` minus its `state`.** That field is the state as loaded; the live one is `game`,
   and keeping both leaves a stale copy to be read by mistake. `summary`, `events`, `isNewGame`, `migratedFrom` and
   `notice` are all kept for 1.8. Dismissing the banner sets `noticeDismissed`; the notice itself stays.
4. **No `visibilitychange`-to-hidden flush**, since the brief listed pagehide/beforeunload/visible only. Nothing is lost
   without it: whatever happened since the last save is recomputed as offline progress on the next load.
5. `test/architecture.test.ts` reads the source through `import.meta.glob` rather than `node:fs`, so no `@types/node` was
   needed. It allows `zod` in the sim (`save.ts` has used it since 1.5) and forbids React and zustand there.
6. **Sim events are not stored.** The tick's `SimEvent`s are dropped; nothing consumes them until toasts or 1.8 exist.

**Not verified in a browser yet:** all of the above is node-tested; the app has not been run. Checkpoint B and the final
check do that.

## Open questions for the designer

### Found in 1.6, not blocking
- **Should the online tick honour the offline cap?** A closed tab is capped at `offline.capHours` (12 h) on load. But a tab
  left open across a long suspend (laptop asleep for 20 h, then woken) hands its whole gap to `step` as one dt with no cap,
  because the brief says to pass a large dt straight to `step`. So the same 20 h earns 12 h if the tab was closed and 20 h
  if it was left open. I followed the brief and changed nothing. If the cap should apply, the driver can clamp the dt (or
  route a gap over some threshold through `applyOffline`, which would also give 1.8's welcome-back summary for free).
- **Resources have no emoji in the data**, only creatures do. 1.6 shows a type-colored dot plus the name. If you want an
  emoji per resource it is one optional `emoji` field on `resources.json` (schema, five values, a content test).

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

### Carried from design.md section 15, not blocking
- Full resource lists, prices and gold values per skill (placeholders in JSON for now).
- Full gear list, zone wild-species assignments, the Voltaic zone, the tutorial script.
- Special-recipe content (`recipes.json` ships with an empty `special` list).
- Exact reward tables for collection milestones.
- Same-type "sibling" species (design section 6 marks this TBD; the roll exists and resolves to nothing).
