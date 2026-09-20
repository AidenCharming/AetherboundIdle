# Progress

Read this at the start of every session. Update it after every checkpoint (see Session protocol in CLAUDE.md).

## Next up
**Step 1.8b, in three checkpoints. A (the dev panel) and B (bench, Aether per minute, the Nexus tab) are DONE and
committed; C (polish pass and the Phase 1 acceptance run) is next.** 1.8a and the 1.8t tuning pass are done. Starting points:
- ~~**Dev panel**~~ **Done in checkpoint A** (see "1.8b checkpoint A" below): grant creature (picked by hand, nothing rolled),
  add resources / Aether / gold, set skill level, reset save. To test with a varied roster, grant creatures from the Dev tab.
- ~~**Bench and Aether per minute**~~ **Done in checkpoint B** (see "1.8b checkpoint B" below): the top bar shows Aether per
  minute (always, `0/min` when empty) and the Nexus tab lists the benched creatures with their emission and the totals.
- **Polish pass**: whatever 1.6/1.7/1.8a left rough. The known list is in the "Not verified" notes of each checkpoint.
- Same UI rules throughout: read through `selectors.ts` and the two hooks, no hex colors or balance numbers in `ui/`,
  selectors keep identity (`test/architecture.test.ts` and the selector tests enforce these).
- **After 1.8t, skills run to level 250 on a 250 / 1.04 curve and the work slots open at 1 / 50 / 100 / 165 / 225.**
  The Dev tab's **reset save** is the cheap way to get a fresh save, and **set skill level** (designer-approved) reaches
  the upper levels that fast-forward's 12 h cap cannot.

## Phase 1: Economy core
- [x] 1.1 Plan: folder structure and JSON schemas written to `docs/plan.md`. **Wait for designer's OK.** *(approved 2026-09-19 with six amendments)*
- [x] 1.2 Scaffold Vite + React + TS + Zustand + Vitest. Build and test commands work. Commands filled in CLAUDE.md. First git commit. *(2026-09-19)*
- [x] 1.3 Convert `docs/content-data.md` into JSON in `src/data/` (types, skills, species, hybrids, traits, tuning knobs) plus loaders with type-checked schemas. Test that every species and hybrid loads. *(2026-09-19)*
- [x] 1.4 Sim core in `src/sim/` (pure functions): creature stats, action cooldown with floor, skill XP and levels, slot unlocks, Aether emission. Unit tests. *(2026-09-19)*
- [x] 1.5 Offline progress calculation (time elapsed ÷ cooldown, bulk, capped window) plus save/load with versioning. Unit tests. *(2026-09-19)*
- [x] 1.6 UI: skills screen with a Woodcutting slot and progress bars, top bar with resources. *(2026-09-19; state layer in checkpoint A, screen in checkpoint B)*
- [x] 1.7 UI: roster screen with placeholder art cards (type colors, emoji, rarity frame), filter and sort, assign to slot. *(2026-09-19; data, selectors and pure logic in checkpoint A, screen in checkpoint B)*
- [x] 1.8a Offline path for a long-open tab, "welcome back" summary, Settings tab, dev-panel fast-forward. *(2026-09-19; step 1.8 was split at the designer's instruction. State layer in checkpoint A, screens in checkpoint B)*
- [x] 1.8t Tuning pass (designer's decision): skill max level 99 -> 250, skill XP curve 250 / 1.04, work-slot unlock levels 1/50/100/165/225. Data only; no new systems. *(2026-09-19)*
- [ ] 1.8b Rest of the dev panel (grant creature, add resources / Aether / gold, reset save), bench and Aether-per-minute display, polish pass. Phase 1 playable.
- [ ] 1.9 Desktop wrapper: package the game as a Windows `.exe` (see "Desktop packaging" below). Do this right after 1.8b so the designer can double-click the game from the first playable version on.

### Desktop packaging (planned step 1.9, designer's request)
The designer wants the game to run as an `.exe`, not as a browser link. `npm run dev` is only the development server; the game is
already a plain static Vite build, so a desktop wrapper opens that same build in its own window and needs **no change to the game
code**. Not built yet. Do not add wrapper code before step 1.9, and until then keep the app a plain static build with no server
dependency.
- **Recommended wrapper: Electron** (bundles Chromium, installs as plain npm packages, works well with Steam, about 100 MB or more).
  Alternative: Tauri (about 10 MB, but needs Rust and the Windows C++ build tools installed first). **Designer confirmed
  Electron (2026-09-19).**
- **Scope of 1.9:** an Electron main process (`electron/`), an `npm run` script that launches the built game in a window, an
  installer/portable `.exe` build script, an app name and icon (placeholder icon is fine), and the commands added to CLAUDE.md.
  Keep the wrapper code out of `src/`.
- **Vite `base`:** set `base: './'` so the built files load from `file://` (the default `/` breaks in a packaged app). Check that the
  browser build still works after the change.
- **Saves:** localStorage keeps working in the wrapper, and offline progress keeps working because it only needs `lastSeen`. But the
  wrapper's storage folder can be wiped or moved, so add **file-based save export and import** (a Settings button) so players can
  back up. Whether to make the file the primary save is a separate decision for the designer.
- **Single instance:** use Electron's single-instance lock so the game cannot be opened twice on one save. Two windows fight over
  the same save (seen in 1.8a testing on two browser tabs). A browser build has no such guard; see "Deferred".
- **Background throttling:** a minimized window may slow its timers. The tick driver already handles any gap (`step` for short
  gaps, `applyOffline` above `awayThresholdMs`), so nothing is lost; verify it once in the packaged build.
- **Verify in the packaged app:** launch, play a minute, close, reopen after a few minutes and confirm the welcome-back summary and
  that progress and the save survived.

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

**Browser check:** this checkpoint was node-tested only; the driver, autosave and unload flush were then run in a real
browser as part of checkpoint B (see below), which is where the progress-bar bug turned up.

### 2026-09-19, step 1.6 checkpoint B: Skills screen

`src/ui/`: `theme.css`, `format.ts`, `components/{ProgressBar,TopBar,NoticeBanner,SlotCard}.tsx`, `screens/Skills.tsx`;
`App.tsx` is the layout shell (no router until 1.7 adds a second screen). The UI imports only `state/selectors`,
`state/runtime` (the two hooks) and `state/actions` (types); a test scans for anything else. 386 tests pass and
`npm run build` is clean.

**What it shows.** One panel per skill that has something to gather (data-driven: Mining etc. appear when they get
resources). The panel has the skill level, an XP bar with `xp in level / xp to next`, and `Slots n / total, next at level X`.
It renders one `SlotCard` per **actual** unlocked slot (`selectSlotCount`, not a hardcoded 1). Each card has the creature
(emoji, form name, level), a progress bar with percent and cooldown per action, the tier picker, Unassign, and an Assign /
Replace list of the creatures that can work the skill. The top bar has gold, floored Aether, and a chip per resource held.
A quarantine banner shows the sim's own message, the `save-broken-<timestamp>` key the old save was kept under, and Dismiss.

**Decisions (all reversible):**
1. **Locked tiers are natively `disabled`** and show `Needs level N`. So the sim's rejection reason is wired end to end
   (`actions` return it, `SlotCard` renders it under the card) but the UI cannot produce one today: the only moves it
   offers are ones the sim accepts. The reason text is covered by `test/store.test.ts`; the rendering path was **not**
   exercised in a browser. Say so if you would rather have locked tiers clickable so they can show the sim's message.
2. **An empty slot keeps the player's tier choice as local component state** until they assign someone, defaulting to the
   lowest unlocked resource (`selectDefaultResourceId`). An occupied slot's picker calls `setSlotResource`. Unassigning
   resets the choice to the default.
3. **Resources show a type-colored dot and the name, not an emoji**, because `resources.json` has no emoji field (creatures
   do). Gold and Aether are plain labels. Nothing in `ui/` writes a type color: skill accents, creature rings and resource
   dots all come from `types.json` through the selectors, and `theme.css` holds neutral chrome only.
4. **Aether is floored for display in a selector** (`selectAetherDisplay`); the stored float is never touched, and a
   component re-renders once per whole Aether instead of once per tick.
5. **Only the progress bar re-renders every tick.** Each component selects narrow primitives; `SlotProgress` is the sole
   10 Hz subscriber.

**A bug found only by running it, and fixed.** The bar smooths each 100 ms step with a CSS transition, so the fill must not
transition when it falls back at the cycle boundary. The first version used a `snap` class, and in the browser 1 in 8 wraps
still swept backwards: the 15 s autosave lands on the same tick (15000 is a multiple of the tick and of the 3000 ms cycle),
and its second store update re-rendered the bar 1 ms after the wrap, removing the class before the browser painted. The fix
(`ProgressBar.tsx`) disables the transition and forces a style flush on the element in a layout effect, so no later render
can undo it. Re-measured over 12 wraps, three of them autosave-aligned: no backwards sweep (the only transitions left were
about 0.1% forward nudges). This is verified in the browser only: there is no DOM test environment, and adding jsdom would
be a new dependency.

**Verified in a real browser (Vite dev server, Chromium pane):**
- The bar fills and wraps every 3.0 s (oak), 4.0 s (willow) and 5.0 s (yew). Logs and XP climb in the top bar and skill
  panel; the level went 1 to 9 in a few minutes.
- The picker locks and unlocks by level, editing the saved XP: level 14 has Willow and Yew locked; level 15 unlocks Willow
  (Yew still locked); level 30 unlocks Yew and gives two slots. Clicking Willow and Yew switches the slot and its cooldown.
- Assign, unassign and move: choosing a tier on an empty slot, then Assign, moves the Sproutlet out of its old slot.
- A plain reload keeps everything (only the seconds the reload took were credited: no loss, no double count).
- **Offline catch-up**: `lastSeen` rewound one hour with the Sproutlet on yew gave exactly +36,000 XP (720 actions x 50),
  +774 yew (720 plus Overgrowth extras, a low draw at -2.2 sd; I checked 400 seeds in node: mean 73.1, sd 7.9 against
  72 / 8.05), +8 seedcache, level 30 to 42, and a third slot at level 40.
- **The unload flush**: with the saved `lastSeen` 11.4 s stale, both `beforeunload` and `pagehide` had rewritten it to
  0 ms by the time a later listener ran.
- The quarantine banner: a corrupt save gives the banner with the sim's message and the backup key, the raw text is kept
  byte for byte under that key, and Dismiss removes the banner.
- Phone width (375 px): no horizontal overflow, every button at least 44 px tall.

**Not verified:** the rejection-reason rendering (decision 1); the `visibilitychange` catch-up in a real backgrounded tab (only
the node test covers it); a real phone, Safari or Firefox (Chromium only); and the ProgressBar has no automated test.

**Two notes for whoever tests by hand.**
- **"Set `lastSeen` back in localStorage and reload" does not work as written while the tab is open.** The tab's own
  `pagehide`/`beforeunload` flush rewrites `lastSeen = now` before the reload, silently undoing the edit. I emulated a closed
  tab by registering a later `pagehide` listener that re-wrote the edited save. Step 1.8's dev-panel fast-forward is the
  proper answer and is exactly what plan 7.1 describes.
- On the very first `vite` start of this step the console logged "Invalid hook call" once and the page recovered on Vite's
  own reload. A second, fully cold start (`node_modules/.vite` deleted) did not reproduce it, so I treated it as dependency
  pre-bundling on the first run and changed nothing.

**Tooling.** The preview launcher would not run `npm` from a folder with a space in its path, so
`C:\ClaudeProjects\.claude\launch.json` (workspace root, outside the repo, not committed) starts Vite through `node`
directly. `npm run dev` is unchanged.

### 2026-09-19, step 1.7 checkpoint A: data, selectors, pure roster logic

New: `src/state/roster.ts`, `ui/components/ResourceIcon.tsx`, `test/roster.test.ts`, `rosterGame()` in `test/helpers.ts`. 466 tests pass
(386 before this checkpoint) and `npm run build` is clean. No new dependency.

**Resource emoji.** `resources.json` has an optional `emoji` (schema: same `Emoji` check as creatures; a non-emoji string is rejected).
The four resources that exist got one each, all distinct: oak 🪵, willow 🧺, yew 🏹, Verdant Seedcache 🌰. **The brief said "all five
resources"; there are four** (oak, willow, yew, seedcache). Gold and Aether are currencies, not entries in `resources.json`, so they
stay plain labels. The content test requires every resource that ships to have a distinct emoji, so a fifth resource cannot be added
without one; the field stays optional in the schema so a missing one falls back to the type-colored dot. `TopBar` chips and the
`SlotCard` tier picker use the new `ResourceIcon` (emoji, else dot). plan.md 3.4 updated.

**Shiny hue.** `tuning.ui.shinyHueDeg` = 150 (placeholder), schema `> 0 and < 360` (0 or 360 would make a shiny look normal), content
test, plan.md 3.10. `selectors.shinyHueDeg` exposes it; checkpoint B applies it as a CSS `hue-rotate` on the art only.

**Creature view (extended, not duplicated).** `selectCreatureView` is still the single view, still cached per creature object, and now
carries: `seq`, `name` (form name, unchanged) and `speciesName`, `isHybrid`, `emoji`, `color` (first type, unchanged) and `types`
(one or two `TypeChip`s with the color and its position in types.json), `rarity` (`tier, id, name, tint, glow` from `rarities.json`),
`form` (number), `level`, `shiny`, `statLean`, `primarySkill` and `secondaryAptitude` (display names), `signatureTrait` and
`poolTraits` (`id, name, text, strength`; a signature's strength is its `defaultStrength`), `workableSkillIds` (every skill the sim's
`canWork` accepts), `assignableSkillIds` (those with something to gather), `working` and `workingAt`. An unknown rarity tier still
renders (plain frame, no glow).
- `selectCreatureViews` returns every view as one list. It is cached on the `game.creatures` array itself (the tick never replaces it),
  so a tick costs one WeakMap lookup at any roster size, and a new array whose views are all unchanged returns the previous list.
- Lookup lists for the filter bar are content constants: `typeOptions`, `rarityOptions`, `skillOptions` (all skills, in data order),
  `formNumbers`. `selectSlotAssignResourceId` gives the resource a roster assignment gathers (the slot's own, else the lowest unlocked
  tier) so the rule is not written in a component.

**Filter and sort (`state/roster.ts`, pure, no React).** They work on anything shaped like a view (`RosterItem`), so `roster.ts` imports
nothing. `selectors.ts` re-exports it, so the UI still reaches the state layer through `selectors.ts` alone and the architecture
test's allowlist is unchanged.
- Filter (`RosterFilter`, `null` = off, all set fields AND together): `type` (a hybrid matches either of its two types), `rarity`
  (tier), `form`, `shiny` (true = only shinies, false = only the rest), `work` (`working` | `benched`), `canWork` (a skill id).
- **"Can work skill X" is the sim's own `canWork`**, evaluated once per creature when its view is built and stored in
  `workableSkillIds`; the filter only reads it. Nothing in `roster.ts` re-implements the rule, and a test checks the filter against
  `canWork` directly for every skill and every creature in the roster.
- Sort (`RosterSort` = key + direction): rarity, level, name, type, form. Name sorts by the **name shown** (the form name), case
  insensitively. Type sorts by the type's position in `types.json`, then the second type, so a pure type comes before its hybrids.
  Every sort ends with the creature sequence number **ascending regardless of direction** (then the id text), so it is a total order:
  tested by shuffling the input four ways for all ten key/direction pairs. `defaultDirection`: rarity, level, form open best first;
  name and type open A to Z.
- Tested against `rosterGame(120)`: 121 creatures from the real data covering all 6 types, all 15 hybrids (45 hybrid creatures), 9 rarities, 3 forms, shinies,
  0-3 pool traits at all strengths, and 5 in work slots. The expected results in the filter tests are computed from the game state
  and the data, not from the views. I broke the code six ways (first-type-only filter, no tiebreak, tiebreak that flips with the
  direction, everyone-can-work-everything, a shiny filter that ignores `false`, an off-by-one rarity) and each is caught.

**Deviations and decisions:**
1. `roster.ts` is re-exported from `selectors.ts` rather than added to the architecture test's allowlist (the brief: the UI reads
   through `selectors.ts` and the two hooks).
2. The filter offers **every** skill under "can work", not just gatherable ones (everyone can work the open skills, so those two
   filters are simply "all"); only the *assign* menu is limited to skills with something to gather.
3. The signature trait's `strength` in the view is its `defaultStrength` (signature traits have no roll).

### 2026-09-19, step 1.7 checkpoint B: roster screen and navigation

New: `ui/screens/Roster.tsx`, `ui/components/{RosterCard,RosterFilters,TabBar}.tsx`; `App.tsx` gets the screen switch. 470 tests pass
and `npm run build` is clean. No new dependency.

**Navigation.** A plain `useState` screen switch (Skills / Roster), no router. `TabBar` is a tablist. At phone width it is pinned to the
bottom edge (thumb reach, 57 px tall, and `.app` leaves room so nothing hides behind it); from 768 px it sits under the top bar. The tick
driver runs whichever screen shows. **Filter and sort live in `App` state**, not `Roster`, so a trip to Skills and back keeps them (I first
had them in `Roster`, saw them reset in the browser, and lifted them). Which card is open is `Roster`-local and closes when you leave. None
of it is in `GameState` or the save.

**Cards.** A grid (`auto-fill, minmax(150px, 1fr)`, so 2 columns at 375 px). The art panel is filled by the type color(s) from `types.json`:
a diagonal split for a dual-type hybrid, solid for a single type. Rarity is the frame color (`frame.tint`), a tint wash on the card body and
a glow sized by `frame.glow`; all reach CSS as custom properties (`--rarity`, `--glow`) set from the data. A shiny's emoji gets
`hue-rotate(var(--shiny-hue))` with `--shiny-hue` = `tuning.ui.shinyHueDeg`, plus a "Shiny" text tag so it is not colour-only. Working
shows a filled badge with `Woodcutting, slot 3`; benched an outlined one. Tapping a card opens it in place (full grid width): species,
type(s), rarity, form number and name, stat lean, primary skill, aptitude, signature trait and each pool trait with its strength and effect
text, then work status. Placeholder art only (emoji plus CSS). `test/architecture.test.ts` now also fails on any hex color in `ui/` code, or
in a CSS file outside the `:root` token block. That needed `css: { include: [/\.css/] }` in `vitest.config.ts`: vitest otherwise blanks
every `.css` import, `?raw` included, so the test would have passed on empty strings (I caught this by planting a hex and seeing it pass).

**Assign / unassign from the roster.** A creature offers "Assign to..." for each skill it can work **that has something to gather**
(`assignableSkillIds`; only Woodcutting today), listing every unlocked slot: `empty`, `replaces <occupant>` (the sim benches them, as the
Skills screen's "Replace with" already does), or `working here now` (disabled). The resource is `selectSlotAssignResourceId` (the slot's own,
else `selectDefaultResourceId`). A working creature also gets Unassign. The sim's rejection reason is shown as written under the card
(`role="alert"`). A creature that can work nothing gatherable says so instead.

**Performance.** `Roster` selects `selectCreatureViews` once and passes each `memo`'d card its view; there is no per-card subscription.
`test/roster.test.ts` runs the real store, driver and actions around a 121-creature roster: 60 ticks (and a 3-hour step) change resources,
XP and slot progress but leave `game.creatures`, the view list, every view and the slot selectors identical, and an assign changes only the
two creatures it touches. Mutation-checked both ways (uncached views, uncached list).

**Verified in the real browser (Vite dev server, Chromium pane), on a hand-injected 40-creature save** (all 24 species and 15 hybrids, all 9
rarities, 3 forms, 5 shinies, 4 assigned):
- Every filter (type incl. hybrids on either side, rarity, form, shiny, working, benched, can work Woodcutting/Mining/Scavenging) compared
  against an expectation computed in the page from the game data and the save: all equal. "N of M" and the empty state ("0 of 40", "No
  creatures match these filters", Clear filters at 44 px) work; the clear button restores 40 of 40.
- All 5 sort keys in both directions equal an independently written oracle, including the sequence-number tiebreak (ascending in both
  directions).
- Assign to an empty slot, replace an occupant, Unassign from the Roster, and Unassign from the Skills screen: each shows the same on the
  other screen (the Petalsprocket had its real 1.7 s cooldown on Skills).
- Shiny: computed `filter: hue-rotate(150deg)` from the tuned value, and visibly a different-hued sprite beside the normal one. Rarity: Dim
  is a grey frame with no glow (`#8a8a8a`), Zenith `#fff4c2` with a glow, straight from `rarities.json`. Dual-type hybrids show the diagonal
  two-color panel.
- **No re-render on the tick**: with temporary render counters in `Roster` and `RosterCard` (removed afterwards), 3.5 s of ticks with 40 cards
  and one open gave 0 roster renders, 0 card renders and 0 DOM writes inside the roster while the top bar's resources changed; one assignment
  re-rendered one card.
- **The sim's rejection reason renders**: a save with Woodcutting at level 1 and slot 1 on Yew Log makes the roster's assign onto slot 1 refuse
  with "Yew Log needs woodcutting level 30", in the alert colour, and nothing moved. This closes the 1.6 "not verified" item for the same path
  on the Skills screen (the same corner exists there).
- 375 px: no horizontal overflow on Skills, Roster (filters folded or open) or an opened card; every button, select, summary and tab is at
  least 44 px tall; 2 card columns; the tab bar sits at the bottom of the viewport with 15 to 28 px of clearance under the last content.

**Not verified:** a real phone, Safari or Firefox (Chromium only; `color-mix` and `env(safe-area-inset-bottom)` were only exercised there);
the "filters open by default on a wide screen" branch reads `matchMedia` once at mount (checked at 800 px open and 375 px folded, not on
resize); keyboard-only use of the tablist (arrow keys are not wired, tabs are plain buttons) and screen-reader behaviour; and there is no
automated DOM test (no jsdom), so the components are covered by the browser run above and not by the suite.

**Decisions and deviations (all reversible):**
1. Filters are `<select>`s inside a `<details>` (folded on a phone, open from 768 px), not chips: eight controls fit two-up at 375 px.
2. Opening a card is in-place expansion (one open at a time), not a modal.
3. A creature that stops matching the filter (say "Benched", then you assign it) drops out of the list, and its open card with it.
4. The filter offers all 11 skills under "Can work" (the two open skills match everyone); only the assign menu is limited to gatherable skills.
5. The brief said five resources need emoji; there are four (see checkpoint A).

**Observation for the designer (not changed):** the roster (and the Skills screen's "Replace with") assigns onto an occupied slot using **that
slot's own resource**. If a slot sits on a tier its skill's level no longer unlocks (only reachable through a retuned or hand-edited save; the
sim idles such a slot), the assign is refused until the tier is changed on the Skills screen. If you want it smoother, fall back to the default
resource when the slot's is locked. Normal play never hits it.

**How to test the roster by hand.** Until the 1.8 dev panel exists: build a save with the real code (a throwaway vitest file using
`rosterGame(39)` from `test/helpers.ts` plus `flushSave`), write it to `localStorage['aetherbound-idle:save']` with `lastSeen = Date.now()`,
and register `pagehide`/`beforeunload` listeners that write the same text back, then reload (the tab's own unload flush would otherwise
overwrite it; see the 1.6 note). The Browser pane must be fronted for screenshots, and a screenshot in an emulated viewport can time out once;
a retry works.

### 2026-09-19, step 1.8a checkpoint A: the away path in the driver

New: `src/state/welcomeBack.ts`. Changed: `tuning.json` + `schema.ts` + `index.ts` (one new knob), `state/driver.ts`,
`state/store.ts`, `state/actions.ts`. 489 tests pass (470 before this checkpoint) and `npm run build` is clean. No new
dependency, no UI yet.

**The designer's decision (2026-09-19), which closes the 1.6 open question.** The 12-hour offline cap applies to a tab
left open across a long gap (a sleeping laptop, a throttled tab) exactly as it does to a closed tab. A gap over a
threshold is routed through `applyOffline` rather than handed to `step` as one big dt.

**The knob.** `tuning.offline.awayThresholdMs` = 120000 (PLACEHOLDER), `PosInt` in the schema, with a loader
cross-check that it stays below `offline.capHours` (a threshold at or above the cap would silently become the cap).
The content test covers all of that. plan.md 3.10 updated.

**One catch-up path, three callers** (plan.md 4.5 now carries the table):

| Away | Caller | Window measured from |
|---|---|---|
| Closed tab | `loadGame` | the save's `lastSeen` |
| Open tab, gap > `awayThresholdMs` | `driver.stepToNow` | the driver's own tick anchor |
| Dev fast-forward N hours | `driver.fastForwardHours` | `now - N hours` |

`driver.catchUp(since, now)` is the single private function both driver routes use; `stepToNow` and
`fastForwardHours` differ only in the `since` they pass.

**The trap, and the test that catches it.** `state.lastSeen` is only stamped at a flush (every 15 s), but the driver's
`lastTick` has advanced since, and that time has **already been stepped**. So the away path passes
`{ ...game, lastSeen: since }` where `since` is the driver's anchor, never the state's own `lastSeen`. Measuring from
the stale one would re-grant up to one autosave period. The test ticks 90 s with no flush (so the save still reads the
old `lastSeen`), then opens a gap of `threshold + 7 min`, and asserts the result equals `applyOffline` called directly
on the anchored state, plus an exact oak count of `(90 s + gap) / 3 s` rather than `(180 s + gap) / 3 s`.

**Also tested:** a 20 h gap on an open tab grants exactly 12 h and reports `capped` (deep-equal to `applyOffline`
called directly, so resources, XP, levels, Aether and the RNG state all match); a gap exactly at the threshold takes
the plain `step` path and produces no summary; a backwards clock grants nothing, produces no summary and re-anchors so
ordinary time resumes at once; after a routed catch-up `lastSeen` and the anchor are both `now`, a second
`stepToNow` at the same clock grants nothing more, and a flush straight afterwards reloads with a zero window; the
RNG state advances exactly as the sim's does on real content; and the autosave timer and `visibilitychange`-to-visible
route the same way as the tick.

**`store.welcomeBack`** is the pending `OfflineSummary | null`. `state/welcomeBack.ts` decides what goes in it:
- Set at boot from `loadReport.summary`, and by every routed catch-up.
- Only when the window is over `awayThresholdMs`, it is not a new game, and `settings.offlineSummary` is true.
  **The catch-up itself always happens**; the setting only controls the report. A test loads an 8 h absence with the
  setting off and asserts no summary but the full 8 h of logs.
- If one is still unread when another arrives they are **combined**, not dropped: time, Aether, resources, actions
  and XP add up; a skill's span runs from the earliest `levelBefore` to the latest `levelAfter`; unlocked slots are
  the union, sorted and de-duplicated. A clock-skewed window's negative `requestedMs` is clamped to 0 before adding,
  so it cannot subtract time away.
- `actions.dismissWelcomeBack()` clears it.

**`driver.fastForwardHours(hours)`** (plan 7.1) ships in this checkpoint, tested, with no UI yet: it steps to now, then
runs `catchUp(now - hours, now)`. 100 h under the 12 h cap grants exactly 12 h; 1 h grants exactly 1 h and deep-equals
the sim; un-ticked time since the last tick is credited once, not twice; and it grants time without moving the clock,
so a flush plus a reload re-grants nothing.

**Decisions (all reversible):**
1. **A backwards clock is not an away window.** It is still clamped to 0 and re-anchored as in 1.6, and produces no
   summary. Only a gap *forward* past the threshold is "away".
2. **`applyOffline` is injectable into `createTickDriver`** as a fifth argument, the way `step` already was, so a test
   can assert *which* path ran rather than only what it produced.
3. **`welcomeBack.ts` is a separate file, not part of `store.ts`**, because the driver queues into it too. It is
   internal to the state layer; the UI reads it through `selectors.ts` in checkpoint B.
4. **Turning `offlineSummary` off does not clear a summary that is already pending.** The modal takes focus, so the
   Settings toggle is not reachable while one is open; the rule would be dead code.

**How these tests were checked.** Beyond a green run, I broke the code on purpose seven ways and confirmed each is
caught: the `lastSeen` re-anchor skipped (4 tests fail), the cap dropped from `applyOffline` (8), the threshold
replaced by a hardcoded 24 h (7), a second summary replacing the pending one instead of combining (1), the threshold
gate removed from `queueWelcomeBack` (3), the loader's below-the-cap cross-check removed (1), and `awayThresholdMs`
loosened from `PosInt` in the schema (1).

### 2026-09-19, step 1.8a checkpoint B: welcome-back dialog, Settings tab, fast-forward

New: `src/ui/components/WelcomeBack.tsx`, `src/ui/screens/{Settings,DevPanel}.tsx`, `test/format.test.ts`. Changed:
`state/selectors.ts`, `state/actions.ts`, `ui/format.ts`, `ui/theme.css`, `App.tsx`. 516 tests pass (489 after
checkpoint A) and `npm run build` is clean. No new dependency.

**Four tabs.** Skills, Roster, Settings, and Dev while `settings.devPanelEnabled` is on. Which tab is chosen is still
UI-local state; turning the Dev panel off while standing on the Dev tab falls back to Settings rather than leaving an
empty panel (`App.tsx` derives the shown screen from the tabs that exist).

**Settings.** Two checkboxes, both already in `GameState.settings` and the save schema, so **no migration was
needed**. `actions.setSetting(key, value)` commits and flushes at once, so the choice survives however the tab ends.
The whole row is the label, so tapping the text toggles the box (the box itself is 22 px, the row is 80 to 119 px).

**The welcome-back dialog.** A native `<dialog>` opened with `showModal()`: focus moves inside and is trapped, the
rest of the page goes inert, and the backdrop is the browser's. `role="dialog"` and `aria-modal="true"` are written
out although they are implicit. It shows time away; "capped at 12 h, the rest earned nothing" when the cap bit (with
both durations read from the summary, never written in the UI); Aether gained, floored for display only; each
resource with its emoji; and per skill the actions, XP, `level before -> after` and any new slot numbers. Every number
comes from `selectWelcomeBack`, a view cached per summary object so the dialog is not rebuilt on the tick;
`ui/format.ts` gained `formatDuration` ("12 h 30 m", "4 d 4 h", always rounding down) and `formatGain`.

**Two browser-only findings, both fixed** (neither is reachable from a node test: there is no DOM test environment):
1. **React's `onClose` on a `<dialog>` never fires.** The first version cleared the summary from it, so Close left a
   closed-but-mounted, invisible dialog over a summary the player had not read.
2. **The dialog's own `close` event does not fire either** in the browser this was tested in — proven directly:
   `d.addEventListener('close', ...); d.showModal(); d.close()` left the listener uncalled. So the rewrite listens
   for neither. Escape is handled by an explicit `onKeyDown` (with `preventDefault`, so the browser's own close
   watcher cannot act as well), and Escape and the Close button both call `dismissWelcomeBack`; React unmounting the
   dialog is what takes it out of the top layer. An effect keyed on the summary restores focus to whatever opened it,
   which the browser would otherwise have done itself.

**The Dev tab, this step only: fast-forward.** An hours field plus 1 h / 12 h / 100 h presets. It has **no maths of
its own**: `actions.fastForwardHours(n)` calls `driver.fastForwardHours(n)`, which steps to now and then runs the
same `catchUp` a long open-tab gap runs, then flushes. The panel notes why it exists (the tab's own unload flush
overwrites a hand-edited `lastSeen`).

**Verified in a real browser** (Vite dev server on :5174, Chromium pane), each number checked against the maths:
- **Fast-forward 1 h, Sproutlet on oak**: exactly **1,200 actions** (3600 s / 3.0 s) and **+12,000 XP** (1,200 x 10),
  level 1 -> 27 crossing the level-20 slot unlock, which matches the 1.5 offline test exactly. Oak +1,332 and
  seedcache +20 are the random Overgrowth extras and rare drops on top.
- **Fast-forward 100 h**: "You were away for 4 d 4 h", the capped line, and exactly **14,400 actions / +144,000 XP**,
  which is 12 h and not 100 h. Repeated from a fresh save: same 14,400.
- **A long gap on an open tab**, by overriding `Date.now` in the page to jump 20 h forward and letting the 100 ms tick
  land on it: the dialog says 20 h away, capped, **14,400 actions** again, `lastSeen` moved the full 20 h + the real
  seconds that passed, and the XP gained was the 144,000 of the window plus exactly the ordinary ticks around it -
  nothing double-counted.
- **Boot path**: `lastSeen` rewound 3 h in localStorage and re-written from a late `pagehide` listener (the 1.6
  trick), then reloaded: the dialog opens on load with 3,604 actions, which is 3 h plus the 12 s the edit took.
- **Under the threshold**: fast-forwarding 0.01 h (36 s) grants 120 XP (12 actions) and shows **no** dialog.
- **The setting**: with "Show welcome-back summary" off, a 1 h fast-forward grants the full 12,000 XP and shows no
  dialog. Both toggles survive a reload, and the Dev tab appears and disappears with its toggle.
- **Accessibility**: focus is inside the dialog while it is open and returns to the button that opened it; Escape
  closes it and clears the summary; the Close button is exactly 44 px; the page behind is inert.
- **375 px**: no horizontal overflow on Settings or Dev; the dialog is 337 px wide with no overflow and does not
  scroll; the gains list is one column on a phone and two from about 420 px (`minmax(160px, 1fr)`, so "Verdant
  Seedcache" no longer breaks mid-word); every control is at least 44 px except the two checkbox boxes, whose whole
  row is the target. Console clean on a fresh load.

**Not verified:** a real phone, Safari or Firefox (Chromium only) - and the two `<dialog>` findings above are exactly
the kind of thing that differs per engine, so the dialog is worth re-checking there; keyboard-only tabbing inside the
dialog and screen-reader output; and there is still no automated DOM test (no jsdom), so all three new components are
covered by the browser run above and by the selector and action tests underneath them, not by the suite.

**A trap for whoever tests by hand.** **Two tabs open on the same save fight over it.** Both drivers autosave to
`aetherbound-idle:save` every 15 s from their own copy of the state, so readings jump around and progress is lost.
This is not new in 1.8a and is not a bug this step introduced, but it wasted time here: close every other tab before
measuring anything. (A real multi-tab rule - a lock, or a "this game is open elsewhere" notice - is not in the design;
raise it with the designer if it matters.)

**Decisions (all reversible):**
1. **`selectWelcomeBack` returns a display view, not the raw summary**, so the dialog does no lookups of its own: it
   carries resource names, emoji and colors, skill names and colors, 1-based slot numbers and floored Aether.
2. **Slot numbers are shown 1-based** (`New slot: 2`), matching the Skills screen's "slot 1", while the summary keeps
   the sim's 0-based index.
3. **`formatDuration` shows two units and rounds down.** It must never claim more time than passed.
4. **`SettingKey` is exported from `selectors.ts`** so the UI names a setting without importing `src/types/state`.
5. **A skill with nothing to report is dropped from the dialog**, and an away window with nothing at all says so
   rather than showing empty lists.
6. **The fast-forward field is disabled rather than clamped** when it is empty or not a positive number.

### 2026-09-19, step 1.8t — skill levels, XP curve and slot unlocks retuned (designer's decision)

A **tuning pass only**: no new systems, no new code paths. **Every number below is a PLACEHOLDER and lives in JSON
only** (`src/data/tuning.json`, `src/data/skills.json`). Nothing in `src/` or `test/` hardcodes any of them.

**What changed**
| Knob | Was | Now | Where |
|---|---|---|---|
| Skill max level | 99 | **250** | `skills.json` `maxLevel`, all 11 skills |
| Skill XP curve | base 100, growth 1.1 | **base 250, growth 1.04** | `tuning.xp.skillCurve` |
| Work-slot unlock levels | 1 / 20 / 40 / 65 / 90 | **1 / 50 / 100 / 165 / 225** | `skills.json` `slotUnlockLevels`, all 11 skills |

Growth 1.1 over 250 levels would need about 20 trillion XP for the last level, which is why the curve flattened as
the cap rose. Total XP to level 250 on the new curve is **108,932,283**.

**Not changed, on the designer's instruction:** `tuning.xp.creatureCurve`, `creature.maxLevel` (99), the Form 2 / 3
thresholds (30 / 60), and the Woodcutting resource tier unlock levels (1 / 15 / 30).

**Pacing targets (one unupgraded Sproutlet, level 1, tier 1, Form 1, no traits, on the shipped Woodcutting tiers:
oak 3000 ms / 10 XP, willow at 15 = 4000 ms / 25 XP, yew at 30 = 5000 ms / 50 XP).** These are the target feel; a
retune that silently breaks them fails `test/pacing.test.ts`.

| Milestone | Time | Cumulative XP |
|---|---|---|
| First level-up (1 -> 2) | **75 s** | 250 |
| Level 15 (willow) | 22.9 min | 4,571 |
| Level 30 (yew) | **46 min** | 13,239 |
| Level 50 (slot 2) | 1.41 h | 36,456 |
| Level 100 (slot 3) | **8.66 h** | 297,267 |
| Level 165 (slot 4) | 4.5 d | 3,878,365 |
| Level 225 (slot 5) | 47.3 d | 40,858,428 |
| Level 250 (cap) | **126 d, about 4.1 months** | 108,932,283 |

**What happens to an existing save, checked rather than assumed.** A save holds XP, not levels, so `reconcile`
re-derives each skill's level from its XP on load. Measured against the real old and new tuning:

| Old level (slots it had) | XP | New level (slots it earns) |
|---|---|---|
| 5 (1) | 464 | 2 (1) |
| 15 (1) | 2,796 | 10 (1) |
| 20 (2) | 5,114 | 16 (1) |
| 28 (2) | 12,108 | 28 (1) |
| 40 (3) | 40,141 | 52 (2) |
| 65 (4) | 444,788 | 110 (3) |
| 90 (5) | 4,829,015 | 170 (4) |
| 99 (5) | 11,387,930 | 192 (4) |

- **Levels do not simply drop.** The two curves cross at old level 28: below it a save loses levels (old 20 becomes
  16), at or above it a save *gains* them (old 90 becomes 170). A long-played save is not demoted.
- **Slots always go down relative to what the save had**, because the unlock levels rose 2.5x while the XP re-levels
  by less than that. Every save above old level 20 keeps at least one slot its new level would not earn.
- **Nothing crashes, nothing is lost.** `reconcile` grows the slot array and never shrinks it, `integrityProblems`
  does not check slots against the level, and `advanceSkills` walks the slots the state has. So the load is clean,
  XP is byte-identical, no creature is dropped and no creature is benched.

**Decision: grandfather the extra slots instead of benching.** The designer's fallback was to bench a creature in a
slot beyond the new count. The existing rule is better and was kept: the player keeps the slot and keeps working, and
loses nothing for a balance change they did not make. It cannot create a slot the player did not already have, and it
only affects saves written before this step. Two consequences, both handled:
- `selectNextSlotLevel` now counts from the slots that exist rather than from the level, so a grandfathered save is
  never offered a slot it already holds (it would have said "next at level 50" next to two open slots).
- A slot on a resource tier the new level no longer unlocks **idles**, as already documented for `runningSlot`: the
  creature and the slot stay, nothing is gathered. Only saves that fall below a tier's level hit this (old level 15 on
  willow becomes level 10); old level 20 on willow lands at 16 and keeps cutting.

Seven new tests in `test/save.test.ts` (`a save written before the 1.8t retune`) pin all of it, against an old-tuning
content variant pinned inside the test: a clean load with three occupied slots, no creature lost or benched, XP
unchanged at six different levels, a second load that changes nothing, the grandfathered slot still producing, and the
idled tier. One more in `test/selectors.test.ts` covers the next-slot label.

**`test/pacing.test.ts` guards the feel.** It reads the real `tuning.json` and `skills.json` (no fixture, no
variant), builds the Woodcutting tier ladder from `resources.json`, puts one unupgraded starter Sproutlet on it and
runs every action time through the real `creatureCooldown`, then asserts the four milestone times **within 15%**. The
tolerance only has to absorb the designer's rounding (level 100 is "about 8 h" against a real 8.7 h, the widest gap at
8%); it is far too tight to survive a retune. Checked by moving `growth` from 1.04 to 1.05, a change small enough to
slip through review: three of the four milestones fail. It also pins that all 11 skills share the cap and the unlock
levels, and that the second work slot is more than an hour out.

**Open items this step deliberately did not decide:**
- **Resource tier unlock levels are unchanged (Woodcutting 1 / 15 / 30), on the designer's instruction.** Against a
  250-level skill this now means every tier the game has is open by level 30, in the first 46 minutes, and the
  remaining 220 levels add no new resource. **Tiers 4 and 5 (and their unlock levels, times, XP and gold) still need
  authoring** before the new cap means anything to a player.
- **Per-tier XP for tiers 4 and 5** has to be authored with them: the pacing table above is built from the three
  tiers that exist, so adding faster tiers will shorten every milestone past their unlock level and this test will
  say so.
- **Creature max level stays 99** with `creatureCurve` untouched, and the Form 2 / 3 thresholds stay at 30 / 60.
  Whether creatures follow skills to a higher cap is a **Phase 3 decision** and is not open in Phase 1.

**Docs updated.** `design.md` section 3 now states the max skill level, the slot unlock levels, the XP curve and the
pacing targets, all marked PLACEHOLDER with the JSON key they live under, and section 4 says creature level is a
separate knob that did not move. `plan.md` section 3.2, section 3.10, section 4.3 and section 6 carry the new numbers,
and approved decision 3 now reads "skills 250, creatures 99" with a note that the designer amended it here.

**Verified in the browser (Chromium, `npm run dev`), not only in tests:**
- **First level-up at 74.98 s** of wall-clock play on a fresh save, one starter Sproutlet on oak. Target 75 s.
- **Fresh save reads `0 / 250 XP to level 2` and `Slots 1 / 5 · next at level 50`.** Willow still says "Needs level
  15" and yew "Needs level 30", so the tier gates did not move.
- **Fast-forward 1 h: `1,200 actions · +12,000 XP`, `Level 1 -> 28`.** Exactly the brief.
- **Fast-forward 12 h: `14,400 actions · +144,000 XP`, `Level 28 -> 84`, `New slot: 2`.** 43,200 s / 3,000 ms =
  14,400 actions at 10 XP, and 156,000 cumulative XP is level 84 on the new table. The level-50 slot is reported.
- **Fast-forward 100 h: capped, and says so** ("away for 4 d 4 h", "Offline progress is capped at 12 h"). It granted
  the same 14,400 actions and 144,000 XP, `Level 84 -> 100`, `New slot: 3`, and 300,000 cumulative XP is level 100.
- **A reload keeps everything**: level 100, three slots, the creature still working, no console errors.
- **375 px**: level 100 (`2,913 / 12,141 XP to level 101`, `next at level 165`), level 249 with the widest caption
  the game can produce (`1,234,627 / 4,189,943 XP to level 250`) and level 250 (`Max level`, `Slots 5 / 5`, no "next
  at" line) all render on one line each, with no horizontal scroll at any of them.
- **A real pre-retune save** was on this machine and was used as the migration test: Woodcutting, 187,980 XP, **five
  occupied slots**, 40 creatures. It loads with no console error, re-levels to 88 (it was stored as 88 with XP worth
  old level 55, so the cached level was stale either way), keeps all 40 creatures and all five occupied slots while
  its level now earns two, shows `Slots 5 / 5` with no misleading "next at" line, and every creature keeps working.
  XP only ever grew. It was backed up before the session and restored afterwards; the local save is untouched.

**Could not verify:** nothing in the brief. Two things are out of reach by their nature and are covered by the
pacing test instead: the level 100 (8.7 h) and level 250 (about 4 months) milestones cannot be played in real time,
and fast-forward is capped at 12 h per press, so reaching them in the UI would take hundreds of presses. The level
249 and 250 screens above were reached by writing the XP into the save directly, which exercises the same render
path but not the play that would earn it.

### 2026-09-20, step 1.8b checkpoint A: the rest of the dev panel

New: `src/sim/dev.ts` (pure grants), `raiseSkillToLevel` in `sim/skills.ts`, `ui/components/{DevGrantCreature,DevGrants,DevSkillLevel,DevReset,DevMessage}.tsx`,
`test/dev.test.ts` (62 tests). Changed: `state/{actions,driver,persistence,runtime,selectors}.ts`, `data/{tuning.json,schema.ts}`, `ui/screens/DevPanel.tsx`,
`ui/theme.css`, `test/{helpers,content}.test.ts`, `docs/plan.md` (3.10 and 7.1). 596 tests pass and `npm run build` is clean. No new dependency.

**What the Dev tab has now.** Fast-forward (1.8a), then grant creature, add resources / Aether / gold, set skill level and reset save. Every control is an
action in `state/actions.ts` that steps to now, changes the state, commits and flushes the save; none touches the RNG.

**The designer's answer on pool traits (2026-09-20), which changed the brief.** No pool-trait roll exists in any document (how many traits, how rare Major is,
how much `typeAffinity` weighs), so "roll normally" had nothing to call. Decision: **no roll**. The grant has up to three trait dropdowns, each with a strength
dropdown limited to what that trait allows (`minStrength` respected: the Void-only traits start at Moderate), no duplicates, default none; shiny is a plain
checkbox. Because nothing is rolled the grant **consumes no RNG and does not use `commitRoll`** (a normal action plus a flush); the tests assert `rngState` is
unchanged instead of advanced. **No `tuning.poolTraits` block and no roll were added.** The designer will design the roll at the start of Phase 2 (see "Open
questions").

**Form versus level: checked, no contradiction.** `Creature.form` is stored, not derived; `integrityProblems` deliberately does not check it against the level,
and only `grantCreatureXp` (combat, Phase 3) ever raises it. So plan 7.1's "any combination allowed" is what the sim already permits: a level-1 Form 3 and a
level-99 Form 1 both load, save and reload cleanly (tested). The grant sets the creature's **XP to the cumulative XP its level takes** on the creature curve, so
level and XP agree and a later `grantCreatureXp` continues from the right place. A level above `creature.maxLevel` (99) is **refused**, not clamped.

**Set skill level (designer-approved).** No existing sim function fit, so one thin wrapper was added: `raiseSkillToLevel(state, skillId, level)` in `sim/skills.ts`,
next to `addSkillXp` and calling it, so the level cache and the slot unlocks (grow the slot array, emit `slot-unlocked`) are the sim's own. It raises the skill's XP
to `xpForLevel(level)` **exactly**, also from a fractional XP total. (I first added a `Math.ceil` against float dust, then searched 20 million random pairs and
found none: `xp + (target - xp)` rounds back to `target`, so the ceil only overshot the level's XP by up to 1 and was removed; the test pins exactness on
fractional totals.) It **only raises**: a skill already at or past the level is refused with "Woodcutting is already level 120; this only raises". The 1 to
`maxLevel` bound is read from the skill's data. `dev.ts`'s `setSkillLevel` adds the text parsing and the message. Tested at levels 49/50, 99/100, 164/165 and
224/225 (1, 2, 3, 4, 5 slots), for all 11 skills to their max, keeping an occupant and its progress, and never lowering.

**Input validation.** Amount fields take **text** through to the sim (an `unknown` in the action), because `Number('')` is 0 and would pass an empty box for a real
entry. Refused, with a visible reason and no throw: empty or blank, not a number (`abc`, `1,000`, `12 logs`), NaN, Infinity, `1e999`, negative, zero, a fraction
where a whole number is needed (resources and gold; **Aether may be fractional**, it is stored as a float), and anything above **1,000,000,000,000 per grant**
(`DEV_MAX_AMOUNT`, an input guard for the tool and not a balance number) or that would push a total past `Number.MAX_SAFE_INTEGER`. A refusal leaves the store and
the saved text byte-identical (tested: no write happens).

**Reset save, and the trap.** `resetSave()` calls `driver.retire()` first: `stop()` (timers and the pagehide / beforeunload / visibilitychange listeners) and then
`flush` is a no-op for good, so a click on a flushing action while the page goes away cannot rewrite the save either. Only then does it `removeItem` the main key
(`aetherbound-idle:save`; `save-broken-*` and everything else stays) and ask the page to reload. The UI is two steps ("Reset save..." asks; "Yes, wipe my save"
acts), focus lands on Cancel, Escape cancels. `commitRoll` wrote straight to storage rather than through the driver, so its storage is guarded by `driver.retired`
too. New plumbing: `StorageLike.removeItem`, `Env.reload` (`window.location.reload()` lives in `runtime.ts` like every other browser global) and a fourth argument
to `createActions`. **Mutation-checked:** dropping `retire()` fails 4 tests, dropping the flush guard 1, dropping the `commitRoll` guard 1; dropping the
`minStrength` check, allowing empty text and letting set-level lower fail 1, 1 and 5.

**Verified in a real browser (Vite dev server, Chromium pane):**
- Grant: a Zenith Sproutlet, level 40, Form 3, Void Grasp (Moderate) and Night Owl (Minor). The Void Grasp strength list offered only Moderate and Major, and
  picked traits were disabled in the other slots. The saved file held the creature the moment the button was pressed (`creature-41`, XP 54,719, `nextCreatureSeq`
  42). With the shiny box really clicked, `creature-42` was saved as shiny. Both new creatures showed up in the Skills screen's assign lists.
- Invalid amounts on the gold row: empty ("Enter an amount."), `-5` ("Amount cannot be negative."), `1e999`, `abc`, and `1e30` ("Amount must be at most
  1,000,000,000,000.") each showed a red alert and changed nothing. `1000` gold, `12.5` Aether and `250` Oak Log showed a status line and were in `localStorage` at once.
- **Reset**: the first click only asks (save untouched, focus on Cancel); Cancel leaves the save; confirming wipes. A write log installed before the confirm shows
  the last autosave (42 creatures) **before** the confirm, then the `remove`, then **no write of any kind** as the old page unloaded. The reloaded page held a new game
  (1 creature, 0 gold, Woodcutting 1, Dev panel off), the backup key survived, and a **second reload still showed the new game**. Console clean.
- 375 px: no horizontal overflow on the Dev tab and every button, select and text input at least 44 px. (The species select now takes its own row so
  "Brambletrundle (Verdant)" is not cut.)

**Not verified:** a real phone, Safari or Firefox; Escape on the reset question; keyboard-only use of the panel; the reset in a browser that blocks localStorage
(node covers the throw); and there is still no DOM test environment, so the five new components are covered by the browser run and the action tests under them.

**Decisions and deviations (all reversible):**
1. **One new tuning knob: `tuning.creature.maxPoolTraits` = 3** (design.md section 3: "up to 3 pool traits"). The picker needs the number, and rule 1 says no hardcoded
   balance numbers. It sits in the existing `creature` block, not a `poolTraits` block, and drives nothing but the picker and the sim's own check. Say if you would
   rather it moved into whatever Phase 2 designs.
2. **A grant does not touch `collection`** (`speciesSeen`, `rarityTiersSeen`, `shiniesFound`, `formsUnlocked`). Nothing reads it in Phase 1 and no rule says when it is
   updated, so a granted creature is not "seen". Whoever builds the collection tracks (Phase 4) decides whether a grant should count.
3. **`sim/dev.ts` is a new sim file** for the pure, validated grants, so the actions stay thin. It ships in the production build behind the Settings toggle, as plan 7.1
   says.
4. **Reset turns the Dev panel off**, because `devPanelEnabled` lives in the save and a reset is a real wipe. Re-check the box in Settings to keep testing.
5. `setSkillLevel` also works on the skills that have nothing to gather yet (Mining and so on); it only raises their level and opens their slots.

**For whoever tests by hand.** The browser tool's `form_input` sets a checkbox's DOM state without React seeing it, so a controlled checkbox snaps back: use a real
click on the label. And a Vite hot reload after any edit sends the app back to the Skills tab and invalidates the tool's element refs: re-`find` them.

### 2026-09-20, step 1.8b checkpoint B: the bench, Aether per minute, and the Nexus tab

New: `ui/screens/Nexus.tsx`, `ui/components/{NexusCard,cardStyle}.tsx`, `test/bench.test.ts` (14 tests). Changed: `state/selectors.ts`, `ui/format.ts` (`formatRate`), `ui/components/{TopBar,RosterCard}.tsx`,
`App.tsx`, `ui/theme.css`. 610 tests pass and `npm run build` is clean. No new dependency, no new tuning number.

**Selectors (the sim's own numbers, no maths in components).** `selectBenchEntries` is every benched creature as `{ view, perMin }`, where `perMin` is the sim's `creatureEmissionPerMin` (the
rarity's `benchEmissionPerMin` scaled by the creature's capped `bench_aether_emission` traits: Glimmer, Aether-Drenched, Singularity Glow). `selectAetherPerMinute` is the sim's own
`emissionPerMin(state)` and `selectAetherPerHour` is that times 60. The total is **the function `accrueAether` uses**, not a re-sum, and a test asserts it is `toBe` equal to it and equal (to 9
places) to the sum of the entries. The list is sorted biggest emitter first, then the older creature (by `creature-<n>`), which a test pins with the game's creature array reversed. Both are cached
on `game.creatures`, which only an assignment or a grant replaces, so the 10 Hz tick costs a lookup, and the entry is cached per creature object like the roster view. (Identity is also held by
reusing the previous list when every entry is the same object, so that cache is a cost optimisation and a mutation-check that removes it does not fail a test.)

**Top bar.** Aether has its rate beside it: `Aether 15,643  257/min`, muted and smaller, with an `aria-label` of "257 Aether per minute". **My call on the empty bench: it always shows, as `0/min`, and is never
hidden.** Hiding it would make a bench that is empty because everyone is working look the same as a broken counter, and the number would jump into the bar the first time someone is benched. At the start
of a new game the Sproutlet is benched, so the bar opens on `1/min`. `formatRate` keeps up to two decimals below 10, one below 1,000, none above, drops trailing zeros ("0.5", "12.5", "256", "1,024",
"15,360") and says "<0.01" for a tiny nonzero rate rather than "0".

**Nexus tab** (the name plan.md 7 and design.md section 11 use), between Roster and Settings. A panel with the placeholder line, **per minute, per hour and benched count**, then the benched creatures in the
roster's card language: type-colored art, rarity frame and glow, shiny hue, name, level and form, rarity, and `N Aether/min`. It is read-only. **No habitat, capacity or bench-upgrade system** (design.md
section 11 lists them as future); an empty bench says so and points at Unassign. `cardStyle.ts` is the custom-property block both cards use, lifted out of `RosterCard` so a creature looks the same in both
(behaviour unchanged, the roster tests still pass). Five tabs fit at 375 px (73 to 83 px each, 56 px tall).

**Verified in a real browser (Vite dev server, Chromium pane, 375 px):**
- New game: top bar `Aether 8  1/min`; the Nexus shows the starter with `1 Aether/min`, totals 1 per minute, 60 per hour, 1 benched.
- Granted a Zenith Sproutlet from the Dev tab: the bar reads `257/min` at once. **Online**: over 30.02 s of wall clock Aether went 8 to 137, +129 against 257 x 30.02 / 60 = 128.6 (the display floors, so
  within 1). **Fast-forward 1 h**: the welcome-back dialog says `Aether +15,420`, which is exactly 257 x 60, and the bar moved by 15,428 (the 15,420 plus 1.7 s of live accrual, about 8). So the online
  rate and the offline gain are the same number. The Nexus then listed the Zenith first (glowing frame, `256 Aether/min`) and the Dim starter (`1 Aether/min`), totals 257 / 15,420 / 2.
- No horizontal overflow at 375 px; console clean.

**Not verified:** the Nexus and the top-bar rate on a wide desktop layout (done in the acceptance run below), a real phone, Safari or Firefox, screen-reader output of the rate, and the tick-time render
cost with a very large bench (the roster's 121-creature test covers the same caching pattern; there is no render-count test for the Nexus).

**Decisions and deviations (all reversible):**
1. **The empty-bench rate shows as `0/min`** (see above).
2. **No emission on the roster card.** The old Next up said a roster card "could" show it; the brief for this checkpoint asked for the Nexus tab and the top bar only, so the roster card is unchanged (its
   Details panel already says whether a creature is benched). Say if you want it there too.
3. **Per hour is per minute x 60 in the selector**, a unit conversion and not a balance number.

**For whoever tests by hand.** After several quick file swaps (my mutation checks) the Vite dev server kept serving a stale transform of `App.tsx` under its HMR-stamped URL while a fresh query string returned the
new code, so the pane showed the old app. `preview_stop` and `preview_start` fixed it; a page reload did not.

## Deferred (design.md section 10, needs decisions before it is built)
Listed so they are not forgotten. Not in step 1.7 and not started:
- **Bulk release** of creatures. Needs the Aether refund formula (what a release returns) and a rule about what may not be released
  (assigned, locked).
- **Favorite / lock** flag on a creature. Needs a field in the save (`Creature.locked`) plus a **save migration** (`MIGRATIONS[1]`), and
  a decision on what a lock protects against (release, breeding, both).
- **Auto-assign-best** (fill empty slots with the best creature). Needs the definition of "best" per skill and resource.
- **Two tabs or windows on the same save** (found in 1.8a). Each copy autosaves from its own state and they overwrite each other,
  so progress is lost. Not in the design. The `.exe` build (step 1.9) gets a single-instance lock; the browser build would need a
  cross-tab lock or an "open elsewhere" notice. Designer to decide whether the browser build needs one.
- **Native `<dialog>` cancel path** (found in the 1.8a review): the welcome-back dialog handles Escape itself, but a browser-level
  cancel (for example the Android back button) fires a `cancel` event that nothing handles, which would close the dialog and leave the
  summary pending. Handle `cancel` (preventDefault, then dismiss) in the 1.8b polish pass, and re-check the dialog in Firefox and Safari.

## Open questions for the designer

### Found in 1.6, not blocking
- ~~**Should the online tick honour the offline cap?**~~ **Resolved by the designer, 2026-09-19, and built in 1.8a
  checkpoint A.** Yes: the cap applies to a tab left open across a long gap exactly as it does to a closed tab. A gap
  over `tuning.offline.awayThresholdMs` (120 s) is routed through `applyOffline` rather than handed to `step`, so the
  cap, Night Owl's offline bonus and the welcome-back summary all apply either way.
- ~~**Resources have no emoji in the data**~~ **Resolved in 1.7 checkpoint A**: optional `emoji` on `resources.json`.

### Needed at the start of Phase 2 (designer will design it, decided 2026-09-20)
- **The pool-trait roll.** How many pool traits a new creature rolls (design says "up to 3"), how rare Major is ("Major is rare" has no number), and how much a
  trait's `typeAffinity` should tilt its `rollWeight`. The dev panel's grant deliberately does not roll (see 1.8b checkpoint A); reroll and inheritance need the same
  answer. `traits.json` already carries `rollWeight`, `typeAffinity` and `minStrength`; there is no `tuning.poolTraits` block yet.
- Whether a dev grant should count toward the collection (`Collection` is written by nothing in Phase 1).

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
