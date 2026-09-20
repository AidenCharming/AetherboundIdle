# Progress

Read this at the start of every session. Update it after every checkpoint (see Session protocol in CLAUDE.md).

## Next up
**Phase 2 planning (breeding and hatching). Phase 1 is finished: it is complete, playable, retuned, and ships as a Windows `.exe` (version 0.1.1).**

**Phase 2 starts with a designer decision, not with code: the pool-trait roll.** Nothing in any document says how many pool traits a new creature rolls (design says "up to 3"), how rare Major is ("Major is
rare" has no number), or how much a trait's `typeAffinity` should tilt its `rollWeight`. Breeding, hatching, reroll and trait inheritance all need that same answer, and the dev panel's grant deliberately does
not roll (see 1.8b checkpoint A). `traits.json` already carries `rollWeight`, `typeAffinity` and `minStrength`; there is no `tuning.poolTraits` block yet.

Once the designer has answered, the next session should: break Phase 2 into steps in this file, write the plan (folder structure and the JSON schemas for the new content) into `docs/plan.md`, and **wait for the
designer's OK** before building, as the protocol asks.

**Two UI sections are deliberately still missing and belong to later phases, not to Phase 2's first step:** the **Adventure** sidebar section (expeditions, Phase 3) and the **Collection** section (Phase 4). The
shell was built in 1.9b with room for both; they appear with their screens.

**Before that, one thing for the designer: run the manual checklist for 0.1.1** (see "Manual checklist for 0.1.1" under 1.9c checkpoint E below). It covers the background image, the new Play time and Skill
milestones cards, and the two things no automated test can reach: a toast over the image, and the export/import round trip through the real Save and Open dialogs.

**Also waiting on the designer** (all recorded under "Open questions"): whether the card and button **border contrast** should be raised to 3:1 (it is 1.2 to 1.7:1 in the 1.9b theme, which predates the
background image and is barely changed by it); whether `tuning.ui.pacingMilestones` should show different levels; and that the **pacing floor must be re-checked** once Woodcutting tiers 4 and 5, faster
creatures, or Phase 2 and 3 content land.

**Step 1.9c is done (2026-09-20), and it closed step 1.9.** Five checkpoints, each its own commit: A the play-time counter and save version 2 with the first real migration, B the level-reached timestamps,
C the pacing retune (skill curve growth 1.04 -> 1.045), D the background image, E verification and the exe rebuilt as 0.1.1.

Things a fresh session should know before starting:
- **Saves are version 2 now.** An older build (the 0.1.0 or 0.0.0 exe) reads a version-2 save as **too-new**: it copies it to `aetherbound-idle:save-broken-<time>` and starts a fresh game. It does not delete
  anything, but do not run an old exe against `%APPDATA%\Aetherbound Idle`.
- **The project path has a space** (`Aetherbound Idle`) and this machine is Windows. `npm` from a path with a space did not work under the preview launcher (see the 1.6 tooling note: `.claude/launch.json`
  starts Vite through `node` directly), and the dev server has twice served a stale module here (see the 1.8b checkpoint C tooling note). The Electron scripts and electron-builder work from this path.
- **Saves live in the wrapper's own localStorage**, in `%APPDATA%\Aetherbound Idle` (the dev run, the installer and the portable exe share it). `SAVE_KEY` is `aetherbound-idle:save`; a reset wipes only that key.
  Export and import (Settings) are the backup. Whether the exported file should ever become the primary save is still a separate designer decision.
- **Working-tree line endings are CRLF** (`core.autocrlf=true`). A script that patches source text must match `\r\n`, or it silently finds nothing.
- **Screenshots from the Browser pane are unreliable while the page is scrolled** (a large black band appears above the content that is not in the DOM). Scroll to the top before photographing, and check layout
  with `getBoundingClientRect` rather than by eye when in doubt. Found in 1.9c checkpoint E.
- **Open for the designer at the start of Phase 2**: the pool-trait roll, and whether a dev grant counts toward the collection (see "Open questions"). Also open, not blocking: code signing (see 1.9 checkpoint C),
  and the border-contrast question from 1.9c checkpoint D.

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
- [x] 1.8b Rest of the dev panel (grant creature, add resources / Aether / gold, set skill level, reset save), bench and Aether-per-minute display with a Nexus tab, polish pass. **Phase 1 complete and playable.** *(2026-09-20; checkpoints A, B and C, each its own commit)*
- [x] 1.9 Desktop wrapper: package the game as a Windows `.exe` (see "Desktop packaging" below). *(2026-09-20; checkpoint A the wrapper and its smoke test, B save export and import, C packaging; each its own commit)* **Step 1.9 is complete: 1.9b restyled the shell and 1.9c closed it with the play-time counter, the pacing retune, the background image and the 0.1.1 exe.**

- [x] 1.9c Play-time counter and level-reached timestamps (save version 2, the first real migration), the pacing retune (skill curve growth 1.04 -> 1.045), the background image, and the exe rebuilt as 0.1.1 (designer's requests, 2026-09-20). **It closes step 1.9, and with it Phase 1.** Five checkpoints, each its own commit: A the play-time counter, B the level-reached timestamps, C the pacing retune, D the background image, E verification and the exe rebuild. *(2026-09-20)*
- [x] 1.9b UI shell redesign, then rebuild the exe (designer's request, 2026-09-20). Presentation only, no new game systems. Sidebar navigation with section headings (drawer on a phone), pinned current-activity panel, per-option cards, toast notifications and a bell (the store keeps `SimEvent`s), a warm-accent dark theme, an optional `emoji` on each skill; then `npm run electron:pack` (version 0.1.0) and the packaged smoke tests. Reference: `docs/design.md` section 11 "UI direction" and `docs/reference/`. Three checkpoints: A shell and theme (done, see below), B activity panel and notifications (done, see below), C restyle of every screen and the exe rebuild (done, version 0.1.0; see below). *(2026-09-20; each checkpoint its own commit)*

### Desktop packaging (step 1.9, designer's request; built, see the three 1.9 checkpoints below)
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
Not started; it is next. Break into steps at the start of the phase and write the plan into `docs/plan.md`. **First the designer designs the pool-trait roll** (see "Open questions"), then the sidebar's Adventure and Collection sections follow with their own phases.

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

**Not verified:** a real phone, Safari or Firefox; keyboard-only use of the panel (Escape on the reset question was checked in checkpoint C); the reset in a browser that blocks localStorage
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

### 2026-09-20, step 1.8b checkpoint C: polish pass and the Phase 1 acceptance run (Phase 1 complete)

New: `ui/tabKeys.ts`, `test/tabkeys.test.ts` (5 tests). Changed: `ui/components/{TabBar,WelcomeBack,SlotCard}.tsx`, `ui/theme.css`. 615 tests pass and `npm run build` is clean. No new dependency, no new
tuning number, no new system. The polish is bounded to the documented rough spots plus what the acceptance run turned up.

**What changed.**
- **Tab bar keyboard support** (the ARIA tabs pattern). Only the selected tab is in the Tab order (a roving tabindex, `aria-orientation="horizontal"`); Right and Left step and wrap, Home and End jump to the ends,
  and the new tab is selected and focused. Arrow selects at once ("automatic activation"): a screen costs nothing to show and the tick driver runs whichever is open. The key logic is a pure `nextTabIndex`
  (`ui/tabKeys.ts`), tested for wrapping, both ends, one tab, keys it must leave alone and a focus that is not a tab.
- **Welcome-back dialog `cancel`.** `onCancel` calls `preventDefault` and then `dismissWelcomeBack`, so a browser-level cancel that is not Escape (the Android back button, a close request) cannot close the dialog
  and leave the summary pending. Escape and Close are unchanged. It is React's `onCancel` prop, not a native listener.
- **Reduced motion.** The progress bar's smoothing was already switched off under `prefers-reduced-motion: reduce` (`.bar-fill { transition: none }`); that block now says it is the game's only motion.
  **The rarity glows are static box-shadows with no animation or transition, so there was nothing in them to switch off**; I left them and did not invent a toned-down variant. Anything animated later belongs in that block.
- **Visible focus.** The one 2 px ring used to be on buttons only. It now covers `select`, `input` and `summary` too. A control that fills a clipping container (a roster card, the wide-screen tab bar, both
  `overflow: hidden`) would lose an outward ring, so those two draw it inside (`outline-offset: -4px`).
- **Empty state.** An empty slot when none of your creatures can work the skill said only "Slot N: empty". It now says "None of your creatures can work Woodcutting yet." Not reachable with the Phase 1 starter, but
  it will be once creatures can leave the roster.

**Phase 1 acceptance run, in the real browser (Vite dev server, Chromium pane), from a fresh save made with the new Reset:**
| Item | Result |
|---|---|
| Fresh save | After Reset (Escape on the question cancelled it first, then the two-step wipe): one benched Sproutlet, 0 gold, 0 Aether, `1/min` in the top bar, no resources; Woodcutting `0 / 250 XP to level 2`, `Slots 1 / 5 · next at level 50`. |
| First level-up about 75 s | Assigned on the Skills screen: **level 2 at 75.10 s** by the page clock (100 ms poll, and the pane was hidden, so read it as within about a second). At 64.7 s it read `210 / 250 XP`, level 1. |
| Woodcutting works and levels | 21 actions at 64.7 s (oak 23 with Overgrowth extras, 1 Verdant Seedcache), then level 2 with `10 / 260 XP to level 3`. The top bar showed `0/min` while the only creature worked. |
| Set skill level: slots | 49 gives 1 slot; **50 gives 2** (slot 1 kept working); 99 gives 2; **100 gives 3 at 297,267 XP**; 165 gives 4 at 3,878,365; 225 gives 5 at 40,858,428. Every XP figure equals the 1.8t pacing table. Asking for 60 at level 100 was refused ("Woodcutting is already level 100; this only raises.") and changed nothing. |
| Levels above 99 at 375 px | Level 249: `40 / 4,189,943 XP to level 250`, `Slots 5 / 5`, five slot cards, no horizontal overflow, nothing wider than the viewport. |
| Varied roster from the Dev panel | Nine creatures: Quakemaw (Telluric, Steady, L20), Dewdrop (Aqueous, Faint, L10), Ashwood (Verdant/Pyric hybrid, Gleaming, L60, Form 3), Eclipsa (Void, Brilliant, L35, Form 2), Mosscoil (Verdant/Voltaic hybrid, Radiant, L30), Petalsprocket (Resplendent, L50), Emberfang (Luminous, L45, shiny), Voltfluff (Zenith, L99, Form 3, shiny), plus the starter. |
| Assign and unassign from both screens | Skills: Bloomwheel (Petalsprocket) into slot 2. Roster: Hearthtrunk (Ashwood) into slot 3. Roster Unassign of Hearthtrunk, then Skills Unassign of Bloomwheel. Each change showed on the other screen at once (badge `Woodcutting, slot 2` and so on) and the bench rate moved by that creature's emission (510, 382, 374, 382, 510 per minute). |
| Bench emission | 510/min with eight benched creatures (4 + 2 + 8 + 64 + 32 + 128 + 16 + 256); see checkpoint B for online against fast-forward. |
| Fast-forward and the 12 h cap | 100 h gave "away for 4 d 4 h", "Offline progress is capped at 12 h, so only the first 12 h earned anything", **Aether +367,200 (510 x 720)**, 14,400 actions, +144,000 XP. The dialog was 337 px wide with no overflow, modal, focus on Close. A `cancel` event on it was refused and dismissed the summary, with focus back on the button that opened it. |
| Reload keeps everything | All nine creatures (species, rarity, level, form, shiny), the slot, the level and the Dev setting were identical after a reload. The gap from the flush to the boot was 20.17 s (from the saved `lastSeen` values) and Aether rose by exactly 171 = 510 x 20.17 / 60: nothing lost, nothing double-counted. |
| Reset really resets | Done at the start of this run and twice in checkpoint A (with a write log proving no write after the wipe); a second reload stayed reset. |
| 375 px, every screen | One pass over Skills, Roster (filters open, and a card opened), Nexus, Settings and Dev: no horizontal overflow, nothing wider than the viewport and no button, select, input, summary or tab under 44 px. Top bar with 13-digit Gold, Aether and Oak Log wraps to rows with no overflow. |
| Desktop width (1024 px) | No overflow; the tab bar sits in the page (static) and its focus ring is visible inside it. |
| Keyboard | Tab bar: Right moved Skills to Roster, End went to Dev, Right wrapped to Skills, Left wrapped to Dev, Home returned, Tab left the bar. Focus rings measured as a 2 px solid outline for a button, select, text input, checkbox, summary and tab (inset on the tab and the card). Escape cancels the Reset question. |

**Not verified:** a real phone, Safari or Firefox (Chromium only; the dialog and `color-mix` are the things most likely to differ); **the browser's own `cancel`** (I dispatched the event by hand, so the wiring is proved
but not that a real Android back press raises it); **reduced motion switched on** (the rule is present and parsed in the browser, and nothing else animates, but the pane cannot emulate the OS setting);
`visibilitychange` catch-up in a genuinely backgrounded tab (only the node test covers it; the pane reported itself hidden while I timed things, and the game's real-time accounting was right regardless);
screen-reader output (the top-bar rate label, the tablist, the dialog); the level 250 "Max level" line in this run (checked in 1.8t); and there is still no DOM test environment, so every component is covered by
these browser runs and the selector and action tests under them.

**Deliberately not built (documented rough spots, none of them needed to call Phase 1 done):**
1. The roster filter bar opens by default from `matchMedia` read once at mount; resizing across 768 px does not re-decide it. Listening to it would override a player's own open or close, so it stays.
2. The progress bar has no automated test (no DOM environment; adding jsdom is a new dependency and the designer's call).
3. The empty-slot line repeats on each empty slot. Fine at one to five slots; a single line per skill would be tidier once more skills work.
4. The roster card does not show bench emission (checkpoint B decision 2).
5. Reset turns the Dev panel off (checkpoint A decision 4).
6. Two tabs on one save still fight each other (already under "Deferred").

**Decisions and deviations (all reversible):** the tab bar selects on arrow; `onCancel` rather than a native listener; the rarity glows are left static; the focus ring is inset where a container clips; the empty-slot line is new copy.

**A tooling note for whoever tests by hand.** The Vite dev server on this machine (a path with a space, Windows) twice served a stale transform of a file I had just changed (once after several quick file swaps, once after a single edit): a fresh
query string returned the new code while the page's HMR-stamped URL returned the old. Reloading does not help; `preview_stop` and `preview_start` does. And the browser tool's `form_input` on a React checkbox does not
register (use a real click); its 45 s limit means a long wait has to be split into a watcher plus a later read.

### 2026-09-20, step 1.9 checkpoint A: the wrapper runs the built game

New: `electron/main.cjs`, `electron/smoke.cjs`, `electron/smoke-runner.mjs`, `test/electron.test.ts` (8 tests). Changed: `package.json` (`main`, two scripts, `electron` and
`electron-builder` pinned exactly at 44.4.3 and 26.15.3 as devDependencies), `vite.config.ts` (`base: './'`), `.gitignore` (`release/`), `CLAUDE.md` (commands). Nothing else in
`src/` changed. 623 tests pass (615 before) and `npm run build` is clean. The plain browser build still works: `npm run build` emits `./assets/...`, and the dev server (checked in the
Browser pane on :5174) loads the game with a clean console.

**The window.** One `BrowserWindow`, 1280x800 content size, resizable, minimum 375 x 560 (`useContentSize`, so the 375 px phone layout is reachable), background `#14171c` (the theme's
`--bg`; a test fails if the two drift), no menu bar (`Menu.setApplicationMenu(null)`), `loadFile('dist/index.html')`. `contextIsolation` on, `nodeIntegration` off, `sandbox` on. **No IPC and
no preload: nothing needed one.** Save export and import (checkpoint B) work inside the page (a download link and a file picker). DevTools exist only when `!app.isPackaged` (`devTools`
option, plus F12 / Ctrl+Shift+I). New windows are denied, and an `http(s)` link opens in the default browser; the page may only navigate to itself (a reload, which the dev panel's reset save
uses). Every permission request (camera, notifications and so on) is refused. **Background throttling is at its default (on)**, and a test fails if anyone turns it off.

**Why `main.cjs`, not TypeScript.** Electron runs it as written, so there is no compile step, no second tsconfig and no `dist-electron` to keep in sync; it is about 100 lines, shares
no types with `src/`, and the repo's `"type": "module"` is why the extension is `.cjs`.

**Single instance.** `requestSingleInstanceLock()` before anything else; a second launch quits at once, and the first window is restored and focused on `second-instance`.

**Save location, a decision to check.** `userData` is pinned to `%APPDATA%\Aetherbound Idle` (unless `--user-data-dir` is given), so the dev run (`npm run electron:start`), the installer and
the portable exe all play the **same** save, in the wrapper's own localStorage. The alternative (each keeps its own) would mean the exe you play never sees the save from a test run. The
smoke test never touches it: every launch gets a throw-away `--user-data-dir`.

**The smoke test** (`npm run electron:smoke`, `electron/smoke-runner.mjs` launching `main.cjs --smoke=<mode>`; the page is driven from the main process with `executeJavaScript`, so it
needs no IPC). It works from this path (the space is never given to a shell). Three launches, each hidden:
- `load`: the page loads, its text contains "Woodcutting", and there was no console error, failed load or dead renderer. 0.8 s.
- `progress`: the window is **minimized first** (a `show: false` window still reports itself visible and is not throttled: I measured 30 ticks of a 100 ms interval in 3 s; minimized it is
  4 in 3 s). Then it assigns the Sproutlet to Woodcutting through the real Assign button, waits 9 s, and requires the XP to be a whole number of actions and to match the wall clock
  (4 actions in 13.0 s at a 3.0 s cooldown), then reloads and requires the progress to survive. The worth of one action is read from the first completed action, so no balance number is
  written in the test. **This is the verification of "throttled timers lose nothing".** I mutation-checked it: making the driver credit at most one tick (100 ms) per tick fails it
  ("timed out waiting for the first action"), and restoring the driver passes.
- `single`: launches a first instance, then a second on the same profile. The second must quit by itself (exit 0) and the first must report the `second-instance` event. Both pass.
  The first instance is hidden in the test, so the focusing itself (`restore`, `show`, `focus`) is skipped there and is on the manual checklist.

**Not verified in this checkpoint:** the window on screen (only ever hidden), the focus behaviour, Chromium's deeper throttling after 5 minutes hidden (once a minute; the driver's
real-elapsed-time rule covers it and its node tests do, but it was not run for 5 minutes here), and the packaged app (checkpoint C). Electron Security Warnings (Chromium logs a
warning, not an error, about the missing Content-Security-Policy in a dev run) are not counted as failures; no CSP was added, since `index.html` is not wrapper code.

**A note for a fresh machine.** npm 11 skips dependency install scripts here, so Electron's 100 MB binary is downloaded the first time it is required (`npm run electron:*`), not by
`npm install`.

### 2026-09-20, step 1.9 checkpoint B: save export and import (Settings tab)

New: `src/ui/components/SaveFile.tsx`, `test/savefile.test.ts` (35 tests). Changed: `state/persistence.ts` (`saveReplacedKey`, `exportFileName`, `checkImport`, `replaceSave`, `MAX_IMPORT_BYTES`),
`state/actions.ts` (`exportSave`, `inspectSave`, `importSave`, and a trailing `c: Content = content` argument to `createActions` like every other function that reads content), `state/selectors.ts`
(re-exports `MAX_IMPORT_BYTES`), `ui/screens/Settings.tsx`. `loadGame`, the driver and the save format are unchanged. 658 tests pass (623 before) and `npm run build` is clean. No new dependency, no new tuning number,
no migration.

**Export.** A button on Settings. `actions.exportSave()` steps to now, flushes like every save, and returns `{ fileName, text }` where `text` is `serializeSave(game())`: the text `sim/save.ts` just wrote. The
file is `aetherbound-idle-save-YYYY-MM-DD-HHMMSS.json` in local time. The page turns it into a Blob download (in the desktop app that opens the native Save dialog; no IPC). Tested: the exported text equals the stored
save byte for byte, holds the minute of work that no tick had seen, and is a real save (strict-schema parse, RNG state kept).

**Import goes through the normal load, not a copy of it.** The Settings button picks a file and the page calls `actions.inspectSave(text)` (the real `parseSave`: JSON, version, migrations, strict schema, integrity, reconcile;
it changes nothing) so a bad file is refused at once with the reason. A good file shows a confirmation naming the file, its creature count and when it was saved; only "Yes, replace my game" acts (same two-step as Reset, focus on
Cancel, Escape cancels). `actions.importSave(text)` then: validates again, steps to now and **flushes** (so the backup is the game as it is right now, not up to 15 s old), copies the stored save **byte for byte** to
`aetherbound-idle:save-replaced-<now>`, writes the file's own text as the save, **retires the driver**, and reloads. The reload boots through `loadGame`: `parseSave`, migrations, `reconcile`, `applyOffline` (a stale file
grants its offline time under the 12 h cap) and the welcome-back summary. There is no second loader, so nothing can drift. Tested against `applyOffline` directly: the booted state equals `applyOffline(parsed file)` exactly.

**Decision: reload, not a live swap.** A live swap would have needed a new driver method to re-anchor the clock and a second place that queues the summary. Reload reuses the reset pattern (`retire()` then reload) and the
whole load path. The cost is one page reload (about a second).

**A bad file is refused, not quarantined.** Nothing was replaced and the player still has the file, so `save-broken-*` is not written. Refused with a reason and *nothing* changed (not even a flush, no key written, the state
object identical): empty, not JSON, truncated, no version, a bad version, no state, an array, a schema violation (`gold: -5`), an unknown field, an unknown species, a file newer than this build, and a file over 5 MB
(`MAX_IMPORT_BYTES`, about what localStorage holds; an input guard, not a balance number). If the backup or the write cannot be stored, the player is told and the old save is still the save (the copy is removed).

**The trap and the write order.** `importSave` writes the file and calls `retire()` in the same synchronous block, before `reload()`; nothing can run between. After it, `pagehide`, `beforeunload`, `visibilitychange`,
the autosave, the tick and every flushing action (`setSetting`, `addGold`, `fastForwardHours`, `exportSave`, `commitRoll`) leave the save as the file, byte for byte. Tested, including a `reload()` that runs its unload
handlers synchronously as a real page does. **Mutation-checked** (each restored afterwards): removing `retire()` fails 3 tests, retiring after `reload()` fails 1 (the synchronous-unload one), skipping the backup copy fails 2,
skipping the flush before the backup fails 1 (stale backup), and skipping validation fails 16. The two that matter most are the first (old game written back over the import) and the backup (nothing replaced without a copy).

**Verified in a real browser** (Vite dev server, Chromium pane): export handed over a Blob equal to the stored save with the right name; garbage, a too-new file and a schema violation each showed their reason with no
dialog and no key changed; Cancel and Escape left everything untouched; a confirmed import of a file that was 3 h stale (Sproutlet cutting, 777 gold) logged exactly three writes on the old page (flush, backup, file) and
**none** from the real pagehide/beforeunload that followed, then booted into the imported game (gold 777) with the welcome-back dialog ("away for 3 h", 3,601 actions, +36,010 XP, level 1 to 49) and the old game (gold 0,
74,367 oak) under `save-replaced-<time>`. 375 px: no horizontal overflow, every button at least 44 px, a long file name wraps.

**Not verified:** the native Save dialog and file picker inside the Electron window (only the packaged-app checklist covers them); a file that is 12 h or more stale in the browser (node covers the cap); Firefox and
Safari; keyboard-only use of the two-step confirmation beyond Escape and the initial focus; and there is still no DOM test environment, so `SaveFile.tsx` is covered by the browser run above and the action tests under it.

**Decisions and deviations (all reversible):**
1. The confirmation shows the file's creature count and save time, which the brief did not ask for, so the player can tell an old backup from a new one before replacing the game. It costs one small read of the file.
2. There is no "restore backup" button: the copy exists for a person (or a later step) to recover by hand. The confirmation says so in words.
3. `save-replaced-*` copies are never cleaned up, like `save-broken-*` (each is one save's worth of localStorage; only matters with many imports).
4. The section reuses the Dev tab's `.dev-control`, `.dev-row` and `.dev-confirm` styles rather than adding near-identical ones.
5. Vite's hot reload logged one stale "bootGame() must run" error in a tab that was open while I edited; a clean load in a new tab logs nothing.

### 2026-09-20, step 1.9 checkpoint C: packaging (Phase 1 ships as an `.exe`)

New: `electron-builder.yml`, `electron/make-icon.mjs`, `electron/assets/icon.ico` and `icon.png`. Changed: `package.json` (`description`, `author`, two scripts), `electron/main.cjs` and `electron/smoke.cjs` (a
`--smoke-out` file channel, the effective-flags checks), `electron/smoke-runner.mjs`, `test/electron.test.ts` (now 11), `CLAUDE.md`. 661 tests pass and `npm run build` is clean. Nothing in `src/` changed in this checkpoint.

**Artifacts** (`npm run electron:pack`, about 20 s, in `release/`, gitignored; version is still `0.0.0`):

| File | Size |
|---|---|
| `Aetherbound-Idle-0.0.0-setup.exe` (NSIS installer, per-user, pick the folder, no administrator prompt) | 102,944,381 bytes (98.2 MiB) |
| `Aetherbound-Idle-0.0.0-portable.exe` (single exe, unpacks itself to a temp folder on each launch) | 102,661,076 bytes (97.9 MiB) |
| `win-unpacked/` (the same app, unpacked; what the installer lays down) | 321 MB on disk |

`app.asar` holds only `dist/`, `electron/main.cjs`, `electron/smoke.cjs` and `package.json` (9 entries, no `node_modules`: Vite already bundled react, zustand and zod). Only the `en-US` Chromium locale is kept.

**Placeholder icon** (`electron/make-icon.mjs`, no dependency): a violet-to-teal rounded tile with a glowing white "aether" orb, a thin ring around it and three small motes on the ring, drawn from maths and
written as a 6-size `.ico` (16 to 256) and a 512 px `.png`. Nothing traced, borrowed or branded. Replace both files when there is real art.

**Placeholders in the config, all yours to change:** `appId: com.aetherbound.idle`, `author: "Aetherbound Idle"` (shows as the exe's Company name and the installer's publisher), version `0.0.0`, and the file names
`Aetherbound-Idle-<version>-setup.exe` / `-portable.exe`.

**Unsigned, and what SmartScreen will show.** No certificate is configured (all three exes report `NotSigned`; the "signing with signtool.exe" lines in electron-builder's log are a no-op without one). A file you built on
this machine and run from here usually starts without a warning. A file that came through a browser download, a zip, a chat or a cloud drive carries the internet "mark of the web", and Windows shows **"Windows protected
your PC: Microsoft Defender SmartScreen prevented an unrecognized app from starting", publisher "Unknown publisher"**. Click **More info**, then **Run anyway**. The installer looks the same, with "Unknown publisher" in
its install prompt. Some antivirus programs also scan or briefly hold a fresh unsigned exe, which can make the first launch slow. **Code signing is not part of this step** and is not set up (it needs a
certificate, an ongoing cost, and a decision on publisher name); a Steam release would not need one for the store itself. Say when you want it looked at.

**How the build had to be adjusted on this machine** (both in `electron-builder.yml`, neither a game change):
1. electron-builder's own Electron download-and-extract step failed twice with `EPERM ... rename 'release\win-unpacked.tmp'`, whatever is holding the freshly extracted files (antivirus or an indexer; not a process of ours).
   `electronDist: node_modules/electron/dist` makes it copy the Electron that `npm install` already fetched (the pinned 44.4.3) instead, which is also faster and guarantees the packaged Electron is the tested one.
   Side effect: an unused `resources/default_app.asar` (108 KB) rides along; Electron loads `app.asar` ahead of it.
2. The `nsis` and `7zip` helper tools were downloaded on the first run and are cached.

**Verified, on the packaged app** (`npm run electron:smoke:packaged`, and the same runner with `--exe=` on the portable exe): all three checks pass on **both `win-unpacked/Aetherbound Idle.exe` and
`Aetherbound-Idle-0.0.0-portable.exe`** (`packaged=true` in the output): the page loads and says "Woodcutting" with no console error; the window has `sandbox`, `contextIsolation` and no `nodeIntegration`; **DevTools
refuse to open** (the check asks for them and requires that they do not open; I forced `devTools: true` into an unpacked build and confirmed it fails with "DevTools OPENED", then restored it); a minimized, throttled
window (4 ticks of a 100 ms timer in 3 s) earned exactly the time that passed (4 actions of 10 XP in 13.0 s at a 3.0 s cooldown) and kept it across a reload; and a second launch on the same profile quits by itself
(exit 0) while the first is told about it. The portable launcher does propagate a failing exit code (a deliberate bad `--smoke=bogus` exits 1). The launcher does not pass the app's stdout on, so the test hook also
writes its lines to a file (`--smoke-out=`) and the runner requires both the app's PASS line and exit code 0.

**Not verified:** **the NSIS installer was built but never run**: installing writes to the machine (a per-user program folder, a Start-menu shortcut, an uninstall entry), so I left that to you; the checklist below
has the steps, and `win-unpacked` is the same app the installer lays down, which did pass. Also not seen: the window on screen, the native Save and Open dialogs for export and import, and the first window
coming to the front on a second launch (the smoke test's windows are hidden, so it proves the lock and the event, not the `focus()`); the taskbar and file icon rendering at every size; how the portable exe behaves
when run from a read-only or network location; a machine without the Visual C++ runtime; and 5+ minutes minimized (see checkpoint A).

**Manual checklist for the portable exe** (designer; about 15 minutes, mostly waiting). `release\Aetherbound-Idle-0.0.0-portable.exe`. The exe is the whole game; the save lives in
`%APPDATA%\Aetherbound Idle` (paste that into the Explorer address bar to see it). Tick each line; write down anything that differs from what it says.
1. **Launch.** Double-click it. Expect: a few seconds' pause (it unpacks itself first), maybe the SmartScreen prompt (More info, Run anyway), then one window about 1280 x 800 titled "Aetherbound Idle", dark
   background, **no menu bar**, the Skills tab, one Sproutlet, 0 gold. Nothing opens a browser. F12 and Ctrl+Shift+I do nothing.
2. **Play.** Skills, Woodcutting, under "Assign" click the Sproutlet. Expect: the progress bar fills in 3.0 s and wraps, Oak Log and XP rise in the top bar, and the Aether rate shows `0/min` while it works.
   Drag the window narrower: it can shrink to a phone width (375 px) and the layout follows.
3. **Close and reopen after a few minutes.** Note the time and close the window with the X. Wait **at least 3 minutes** (under 2 minutes no dialog opens, by design). Launch again. Expect: a **welcome-back
   dialog** ("You were away for 3 m", about 20 actions per minute, the XP and Oak Log gained) and the Sproutlet still working in slot 1. Close it with Close or Escape. Progress (level, logs) kept, nothing doubled.
4. **Minimize.** Leave it minimized for 3 minutes and restore it. Expect: the logs and XP jumped by about that much, with the welcome-back dialog if it was over 2 minutes. (This is the throttled-timer case.)
5. **Second launch.** With the game open, double-click the exe again. Expect: **no second window**; the existing window comes to the front (try it with the first one minimized and behind another program). Check
   Task Manager: one "Aetherbound Idle" group, not two.
6. **Export.** Settings, "Export save". Expect: a native **Save dialog** suggesting `aetherbound-idle-save-<date>-<time>.json`. Save it somewhere you can find it (the Desktop). Open it in Notepad: one line of JSON
   starting `{"version":1,"state":{`.
7. **Reset.** Settings, tick "Dev panel", the Dev tab, "Reset save...", "Yes, wipe my save". Expect: a new game (one benched Sproutlet, 0 gold, Woodcutting level 1).
8. **Import it back.** Settings, "Import save...". Expect: a native **Open dialog**. Pick the file from step 6. Expect a confirmation naming the file, its creature count and when it was saved. Click "Yes, replace
   my game". Expect: the page reloads into the game from step 6, with a **welcome-back dialog** if more than 2 minutes have passed since you exported (it applies offline time, capped at 12 h).
9. **A bad file.** Import any non-save file (a `.txt`). Expect: a red message with the reason, and nothing changes.
10. **Optional, the installer.** Run `Aetherbound-Idle-0.0.0-setup.exe`, pick a folder, launch from the Start menu, and check it opens with the same save as the portable exe (they share `%APPDATA%\Aetherbound Idle`).
    Uninstall from Windows Settings, Apps. Note what the icon looks like on the taskbar and in Explorer.

**Decisions and deviations (all reversible):**
1. **`electronDist`** instead of electron-builder's own download (see above).
2. **The dev run, the installer and the portable exe share one save folder** (checkpoint A). If you would rather the portable exe kept its save beside itself, that is a change to `main.cjs`; say so.
3. **Two Windows targets from one config**, x64 only. No auto-update, no code signing, no ARM build.
4. **`author` is a placeholder** (`Aetherbound Idle`): electron-builder needs one for the installer and the exe's Company name.
5. The packaged smoke test checks the **effective** window flags and the DevTools behaviour, not the source text. (The first version asserted a property Electron does not report and failed; it now asks for DevTools to
   open and requires that they do not.)

### 2026-09-20, step 1.9b checkpoint A: theme and shell

New: `state/nav.ts`, `ui/navKeys.ts` (was `tabKeys.ts`), `ui/useMediaQuery.ts`, `ui/components/{Sidebar,Header,Stats,Brand,PageTitle}.tsx`, `ui/screens/SkillPage.tsx`, `test/nav.test.ts`, `test/navkeys.test.ts`.
Gone: `TabBar`, `TopBar`, `screens/Skills.tsx`. Changed: `App.tsx`, `theme.css` (rebuilt), `skills.json` + `schema.ts` + `content.test.ts` + plan.md 3.2 (an optional `emoji` on every skill, 11 distinct), `selectors.ts` (`SkillInfo.emoji`,
`selectNav`, re-exports `nav.ts`), `electron/main.cjs` (`BACKGROUND`). 680 tests pass (661 before) and `npm run build` is clean. Nothing in `src/sim` and nothing about the save changed.

**Theme.** One `:root` block (still the only place a hex may live) with layered surfaces (`--bg` page, `--panel` sidebar and cards, `--panel-raised`, `--panel-high`), `--line` / `--line-strong`, one warm gold (`--gold`,
`--gold-strong`, `--gold-ink`) for UI chrome only (selected page, the working badge, checkbox accent, later the primary buttons and activity bars), `--focus`, `--ok`, `--danger`, rounded radii (16 / 20 px), a shadow and
`--sidebar-w`. `--accent` is unchanged in meaning: the per-skill / per-creature type color from the data, with a neutral fallback. `--bg` is now `#0d1015` and `BACKGROUND` in `electron/main.cjs` is the same value (the
electron test compares them).

**Shell.** A fixed 240 px sidebar from 768 px (brand, nav under small section headings, a pinned foot for checkpoint B), a header, and the page. Below 768 px the sidebar is a drawer.
- **The breakpoint lives in script, once** (`DESKTOP` in `App.tsx`, read with `matchMedia` through `useMediaQuery`): it sets `data-drawer` on the shell and sidebar, and the layout CSS follows that attribute rather than a media
  query, so CSS and the drawer's focus / inert logic cannot disagree about which mode the window is in.
- **Drawer**: opens from the menu button in the header. While open it is `role="dialog" aria-modal`, focus moves onto the current page's entry, Escape and a click on the backdrop close it, the whole page column is `inert`,
  the body does not scroll, and closing (also after choosing a page) puts focus back on the menu button. Closed, it is `inert` too, so nothing in it is tabbable or read out. It also has its own Close button. Widening the
  window closes it. The slide is a 0.2 s transform, switched off under `prefers-reduced-motion`.
- **Nav** (`state/nav.ts`, pure, node-tested): `buildNav({ devPanelEnabled }, content)` gives SKILLS (one page per skill with a raw resource, in skills.json order, with its emoji), CREATURES (Roster, Nexus), SYSTEM (Settings,
  and Dev only while the setting is on); an empty section is left out. `resolvePage` keeps the choice, or falls back (Dev vanishing sends you to Settings; nothing chosen opens the first entry). `selectNav` caches the two
  possible results, so it is stable by identity. Which page is open is `useState` in `App`, so it is not in the save; the roster's filter and sort stay in `App` too and survive a trip to another page (checked in the browser).
- **Keys**: the nav is one Tab stop (roving tabindex); Down, Up (wrapping), Home and End move focus through the entries across the section headings; Enter or Space opens the page (native button). `nextNavIndex` replaces
  `nextTabIndex`; Left and Right are now left to the browser. The old rule "arrows select" became "arrows move focus", because selecting on arrow would close the drawer at every step.
- **Header**: on a wide screen one line, the stats (gold, Aether with its per-minute rate, one chip per resource) and the right end kept for the bell (empty until checkpoint B). On a phone the sticky header is only the menu
  button, the name and the bell, and the stats sit under it in the page: pinning five rows of chips would have eaten a third of a phone screen (I built that first, looked at it, and changed it). From 768 to 1023 px the
  header is not sticky either, for the same reason (three lines of chips). Gold and Aether got emoji (🪙 ✨), like the resource chips.
- **Skill page**: `SkillPage` replaces the stacked Skills screen: the title, a header card (emoji tile, "Level N", XP bar with `xp / to next XP to level N+1`, slots `n / total` and where the next one comes), then the slots.
  The slot cards themselves are unchanged apart from the new tokens; the option cards are checkpoint C. Every page now starts with one `h1` (`PageTitle`).

**Deviations and decisions (all reversible):**
1. **The hard-coded glyphs.** The nav glyphs for the fixed pages (🐾 Roster, 🌀 Nexus, ⚙️ Settings, 🧪 Dev), the brand glyph 🔮 and the gold / Aether glyphs are chrome, not data, so they are written in the UI / nav model.
   A skill's own emoji is data (skills.json); a skill without one gets `◆`.
2. **The Dev page's heading levels.** Dev components still use `h3` under the page's `h1` (the old `h2` became the page title). Fixed in checkpoint C with the restyle.
3. **The `Sidebar` reads the pane through `returnFocus`**, a ref to the header's menu button, rather than owning that button, so the header stays a plain component.
4. **The 1.9b line in the checklist and design.md's timing sentence** were already edited (uncommitted) by the designer's setup before this session; they ride along in this commit.

**Verified in a real browser** (Vite dev server, Browser pane; a save with a 40-creature roster and 2 million Aether): at 1280, 1024, 768 and 375 px every page (Woodcutting, Roster, Nexus, Settings, Dev) has no horizontal
overflow and no control under 43.5 px in height or width (checked by script, with the filter panel open; checkboxes are inside 44 px labels); at 375 px the drawer opens onto the current page with focus on it, Down, Up, Home
and End move focus (roving tabindex confirmed), Escape closes and focus is on the menu button again, the page column is inert and the body scroll locked while open, and choosing Roster from it opens Roster and closes
the drawer; the roster's filter and sort survive a visit to Woodcutting and back; toggling Dev on adds the Dev entry.

**Not verified:** Enter and Space on a focused button. The Browser pane's key tool sends `keydown` and `keyup` without `keypress`, so a browser does not run the button's default action (I logged the events to confirm);
I used `click()` on the focused element, which is exactly what those keys do on a native button. The Tab order inside the open drawer with a real keyboard (everything else is inert, so it should only cycle through the drawer).
A screen reader. Firefox and Safari.

### 2026-09-20, step 1.9b checkpoint B: current activity, notifications, toasts

New: `state/notifications.ts` (pure), `ui/components/{ActivityPanel,NotificationBell,ToastHost}.tsx`, `test/notifications.test.ts`, `test/notifications-driver.test.ts`, `test/activity.test.ts`. Changed: `store.ts` (`notifications`), `driver.ts`,
`actions.ts` (`markNotificationsRead`, `clearNotifications`), `selectors.ts`, `ProgressBar.tsx` (`tone="gold"`), `App.tsx`, `theme.css`, and four numbers in `tuning.json` under `ui` (with schema, content test and plan.md 3.10): `activityPanelMax` 3,
`maxNotifications` 50, `maxToasts` 3, `toastMs` 5000 (all PLACEHOLDERS). 724 tests pass (680 before) and `npm run build` is clean. Nothing in `src/sim` changed and nothing is written to the save.

**Current activity** (pinned at the bottom of the sidebar, so also in the drawer): for each working slot the creature (emoji, name), the skill and the resource, and a thin gold bar; at most `activityPanelMax`, then "+N more"; with
nothing working, "Nothing is working. Put a creature in a skill slot and it shows up here."; then "Autosaves locally" with a green dot. `selectActivity` lists the slots the sim's own `runningSlot` says are running (an idle slot,
a resource above the skill's level, a vanished creature are not listed) and keeps its identity through ticks, so the panel re-renders only when a slot starts or stops. **Measured in the browser**: over 6 s of ticking, a
MutationObserver saw 252 DOM changes inside progress bars and none anywhere else in the sidebar (3 in the header when a resource count moved). The "Autosaves locally" line is static text: it does not know if a write failed.

**Notifications** live in the store as `notifications: { items, nextId }`, next to `game`, never inside it. Each item is `{ id, at, kind, text, read, skillId, level }` (`skillId` and `level` are two fields beyond the four you listed: the toast needs
the skill's emoji, and coalescing needs the level). Kinds are `skill-level-up` and `slot-unlocked`; the text is built from the data's names ("Woodcutting reached level 2", "Woodcutting unlocked slot 2"). Bounded by
`maxNotifications` (oldest dropped). Ids are never reused, even after Clear.
- **Source**: `driver.stepToNow` only, in its ordinary-step branch, with the injected clock's `now`. `catchUp` (a long open-tab gap, and the dev fast-forward) and the load path never touch the log; `action-complete`,
  `creature-level-up` and `form-evolved` are ignored. The dev panel's grants and set-skill-level do not notify either (they do not go through a step).
- **Coalescing**: a level-up joins the NEWEST entry when that is a level-up of the same skill recorded within `toastMs` of its last update: the entry then says the latest level, its `at` moves forward (so a steady burst stays
  one line) and it becomes unread again. A slot unlock is never merged, and one between two level-ups breaks the run. At level 50 the level-up and the slot arrive together, so that is two lines.
- **Toasts**: `ToastHost`, bottom-right on a wide screen and bottom-centred on a phone, `role="status"` with `aria-live="polite"`, at most `maxToasts`, each with a 44 px dismiss button, gone after `toastMs`. The timer is an effect in
  the toast (`setTimeout`, cleared on unmount), stopped while the pointer or focus is on it, restarted in full when they leave. Which toasts are up is derived (`visibleToasts`, pure and tested): notifications recorded after the
  host mounted, minus the dismissed ones (remembered as id -> `at`, so a level-up that coalesces into a dismissed toast shows it again with the new text), newest `maxToasts`. Hidden while the drawer is open.
- **Bell**: in the header's right end, with an unread badge (hidden at 0, "99+" at most, and the count is in the button's accessible name). It opens a non-modal dialog listing the notifications newest first (skill emoji, text, kind, local
  time, "new"), with "Mark all read" and "Clear" (both stay enabled, so focus is never lost to a disabled button). Opening moves focus into the panel; Escape closes it and returns focus to the bell; a press outside closes it.

**Tests** (node): pure log (texts from data, the two kinds only, ids, the bound and its knob, every coalescing rule and its edge, unread, mark, clear, `visibleToasts`), the driver end to end (level-up across the first level at 76 s gives
"reached level 2" and "unlocked slot 2", a quiet tick leaves the log object untouched, a fast skill is one line and a pause over the window is a second), **offline never notifies** (a load after 4 h, a long open-tab gap, the dev
fast-forward, each asserting the away window really did level the skill and produced a welcome-back, so the test is not vacuous), online ticks after an away window still notify and do not repeat the away levels, and **nothing reaches
the save** (no `notifications` key in `GameState`, the serialized save is byte-identical with and without notifications, the flushed file contains none of their words, a reload starts empty, a flush leaves the log alone), and `selectActivity`.
**I broke the code on purpose for the two that matter and each was caught:** (1) offline events leaking in: adding `notify(..., caughtUp.events, ...)` to `catchUp` failed 3 tests (the open-tab gap, the dev fast-forward, and "online ticks
after an away window"), and adding `notify(emptyLog(), outcome.events, 0)` to `createGameStore` failed the load test; (2) no coalescing: `if (false && ...)` in `notify` failed 7 tests (same step, successive steps, sixty in a minute, the window edge, the sliding
window, the read entry becoming unread, and the end-to-end fast skill). Both changes were reverted; `grep BROKEN` finds nothing.

**Verified in a real browser** (Vite dev server; Dev panel Reset save, then the Sproutlet on Woodcutting): the first level-up came at 43-76 s and produced a toast ("Level up / Woodcutting reached level 2") bottom-right at 1280 px and bottom-centred at 375 px, the bell badge went 1, 2, 3 as
levels came, and Escape / Mark all read / Clear behave as described (read entries stay listed, Clear shows the empty text). Toast timing, with a synthetic hover event and a real `focus()`: held 8 s while hovered, gone 5 s after the pointer left; held 7.5 s while its
dismiss button had focus; the dismiss click removed it at once and the bell's count was unaffected. The drawer shows the activity panel. **Not verified in a real browser: a slot-unlocked toast** (the first one is level 50; node tests cover it, as you allowed), and a real (not synthetic) pointer
hover.

**Deviations and decisions (all reversible):**
1. **Two extra fields on a notification** (`skillId`, `level`), see above.
2. **Dev-panel actions do not notify**, which follows from "the online tick only". If you would rather a dev set-level toast, that is one line in `actions.ts`.
3. **A toast for a coalesced level-up restarts its timer** and reappears if it had been dismissed.

### 2026-09-20, step 1.9b checkpoint C: every screen restyled, and the exe rebuilt (0.1.0)

Changed: `SlotCard.tsx` (option cards), `selectors.ts` (`ResourceInfo.baseActionMs` / `xpPerAction`), `theme.css`, the Dev / Settings / welcome-back components (heading levels, gold primary buttons), `ui/format.ts` (`KIND_LABEL` moved out of a component
file), `vite.config.ts`, `electron/smoke.cjs`, `package.json` (0.1.0), `CLAUDE.md`, `design.md`. No behaviour change: every action, selector rule and save path is what it was. 724 tests pass and `npm run build` is clean.

**Option cards.** A slot's resource tiers are now cards: the resource's emoji, name, "3.0 s base · 10 XP", and "You have N"; the selected one has the skill's accent border and a tinted fill; one the skill's level does not reach is greyed out, still
disabled, and says "Needs level N". They are the same buttons as before (`aria-pressed`, `disabled`, the same `setSlotResource` / pending-choice logic). "Base" because the slot's own cooldown (creature, rarity, form) is the line above it. The assign list is a set of chips in a box that
scrolls (it can hold the whole roster). Roster, Nexus, Settings, Dev, the welcome-back dialog and the quarantine banner take the same tokens (mostly done by checkpoint A's CSS); C adds gold primary buttons (Close, Export save, Fast-forward, Grant, Add, Set level),
stat tiles on the Nexus, a tinted "on" state on the setting rows, and `h2` instead of `h3` in the Dev and Settings panels (a page now has one `h1`, then `h2`s).

**Rebuild.** `package.json` is 0.1.0; `npm run electron:pack` wrote (in `release/`, gitignored):

| File | Size |
|---|---|
| `Aetherbound-Idle-0.1.0-setup.exe` (NSIS installer) | 102,948,971 bytes (98.2 MiB) |
| `Aetherbound-Idle-0.1.0-portable.exe` | 102,665,642 bytes (97.9 MiB) |
| `Aetherbound-Idle-0.1.0-setup.exe.blockmap` | 107,876 bytes |
| `win-unpacked/` | 321 MB on disk |

**The old `Aetherbound-Idle-0.0.0-*` files are still in `release/`** (portable, setup and blockmap); I did not delete them. They are the old UI. Delete them by hand when you like.

`electron/smoke.cjs` is updated, keeping what it proved: load now waits for the Woodcutting page's own `h1` and the sidebar nav (the word "Woodcutting" alone would now appear in the sidebar even if the page broke); progress opens Woodcutting from the sidebar entry, assigns
through the same `article[aria-label="Slot 1"] fieldset.assign button`, and checks the sidebar's current activity lists the Sproutlet, before the XP-versus-time check and the reload. Results, all three checks each time, exit 0: dev (`npm run electron:smoke`; that run's window was NOT
throttled, so it proved less), **`win-unpacked`** (4 ticks of a 100 ms timer in 3 s: throttled; 4 actions of 10 XP in 12.1 s at a 3.0 s cooldown; the same after a reload; single instance) and **the portable exe** (4 ticks in 3 s: throttled; 4 actions in 13.1 s; reload; single instance).
The installer was built and not run.

**A tooling fix.** Rebuilding the exe while the Vite dev server ran crashed the server (`EBUSY` on a file in `release/win-unpacked`, which its watcher tried to watch). `vite.config.ts` now ignores `**/release/**`.

**Manual checklist for 0.1.0** (designer; about 20 minutes, mostly waiting). It replaces the checklist under 1.9 checkpoint C, which is for the 0.0.0 build. Use `release\Aetherbound-Idle-0.1.0-portable.exe`; the save lives in `%APPDATA%\Aetherbound Idle`. Tick each line and write down anything that differs.
1. **Launch.** Double-click it (a few seconds' pause, maybe SmartScreen: More info, Run anyway). Expect one window about 1280 x 800 titled "Aetherbound Idle", no menu bar, dark with gold accents: **a sidebar on the left** (🔮 Aetherbound Idle; SKILLS: Woodcutting; CREATURES: Roster, Nexus; SYSTEM: Settings), the **Woodcutting page** with a level card and one empty slot, and gold, Aether and any resources across the top with a 🔔 at the right end. At the bottom of the sidebar: **Current activity** ("Nothing is working...") and "Autosaves locally". F12 does nothing.
2. **Play.** Under "Assign" click the Sproutlet. Expect: the slot's bar fills every 3.0 s, Oak Log and XP rise, the Oak Log option card's "You have N" goes up, and **Current activity** lists the Sproutlet with a gold bar.
3. **Sidebar keys.** Click a nav entry and press Tab: focus leaves the nav after one stop. Click a nav entry and press Up, Down, Home, End: focus moves through the entries (Enter opens the page). A Roster filter you set is still there after visiting another page and coming back.
4. **The drawer.** Drag the window narrower than about 768 px (it goes down to 375). Expect the sidebar to disappear and a **☰ button** and the game's name to appear in the header. Press ☰: the sidebar slides in over the page and the page behind dims. Escape, the ✕, or a click on the dim area closes it, and focus returns to ☰. Choosing a page closes it. Widen the window: the sidebar is a column again.
5. **A toast and the bell.** With the Sproutlet working, wait for the first level-up (about 75 s). Expect a **toast** bottom-right ("Level up, Woodcutting reached level 2") that leaves after about 5 s, stays while the mouse is on it, and has a working ✕. The 🔔 shows a **1**. Open it: the entry is listed with a time and "new"; "Mark all read" clears the number, "Clear" empties the list, Escape closes it. Close and reopen the game: the list starts empty (it is not saved).
6. **Close and reopen after a few minutes** (at least 3): a **welcome-back dialog** (gold Close button) reports what you earned, the Sproutlet is still working, and the bell stays empty: away time is reported by the dialog, never by notifications.
7. **Minimize** for 3 minutes and restore: the logs and XP jumped by about that much (with the dialog if it was over 2 minutes).
8. **Second launch**: no second window; the first comes to the front. One "Aetherbound Idle" group in Task Manager.
9. **Export.** Settings, "Export save": a native Save dialog suggesting `aetherbound-idle-save-<date>-<time>.json`. Open it in Notepad: one line starting `{"version":1,"state":{`.
10. **Reset.** Settings, tick "Dev panel": a **Dev** entry appears under SYSTEM. Dev, "Reset save...", "Yes, wipe my save": a new game.
11. **Import it back.** Settings, "Import save...": a native Open dialog; pick the file; confirm: the game from step 9 returns (with a welcome-back dialog if over 2 minutes passed).
12. **A bad file.** Import a `.txt`: a red message with the reason, nothing changes.
13. **Optional, the installer.** Run `Aetherbound-Idle-0.1.0-setup.exe`, pick a folder, launch from the Start menu, check it opens with the same save (they share `%APPDATA%\Aetherbound Idle`), then uninstall from Windows Settings, Apps.

**Verified in a real browser** (Vite dev server, Browser pane, Chromium; a fresh save from the Dev panel's Reset save, then 14 granted creatures and Woodcutting set to level 170 for a full roster and four working slots):
- **Every page and screen at 1280, 1024, 768 and 375 px** (Woodcutting, Roster, Nexus, Settings, Dev, with the filter panel open; at 375 also a Roster card expanded, including a working one): no horizontal overflow and no control under 43.5 px in either direction (measured by script over every button, select, input and summary; checkboxes sit in 44 px labels). The welcome-back dialog, the bell panel (at 1280 and at 375, where it sits inside the 16 px gutters) and a toast were also looked at, at 1280 and 375; the quarantine banner (made by writing a corrupt save) at 1280.
- **The drawer with the keyboard** at 375 px: opened, focus on the current page's entry; Down, Up, Home and End (real key events) move focus; Escape closes it and focus is on the menu button; the page column is inert and the body scroll locked while open; choosing a page closes it.
- **A toast**: the first level-up came at 43 to 76 s on fresh saves (bottom-right at 1280, bottom-centred at 375), with the bell's badge counting 1, 2, 3 as levels came; hover and focus pausing and the dismiss button are described under checkpoint B.
- **Scrolled**: the sidebar and (from 1024 px) the header stay pinned while a long Roster scrolls.

**What still looks rough (honestly):**
- The header's stats (gold, Aether, one chip per resource) wrap to two or three lines on a phone and in a narrow tablet window, and will grow with every new resource. On a phone only the menu, the name and the bell are pinned, so it stays slim, but the stats will need a fold or a summary once there are ten resources.
- A slot on a phone is long: three full-width option cards, then the assign list. It is correct, not compact.
- The nav glyphs 🐾 ⚙️ 🌀 render dimmer than the skills' colour emoji, because the system emoji font draws them that way. The skill page's empty right half (one slot in a two-column grid) looks sparse.
- The activity panel's second line ("Woodcutting · 🪵 Oak Log") wraps to two lines at the sidebar's width when the resource name is long.
- Placeholder art throughout: emoji on flat tiles, as CLAUDE.md rule 4 says.

**Not verified:** the window on screen, the native Save and Open dialogs, the second launch bringing the first window to the front, and the installer (all on the manual checklist above); a slot-unlocked toast in a real browser (node-tested); a real pointer hover on a toast (I dispatched the events; focus was a real `focus()`); Enter and Space activating buttons (the Browser pane's key tool cannot send them, see checkpoint A); the live window-resize path while the Browser pane was hidden (a hidden pane delivers no resize or media-query events, which for a while looked like a bug; it worked while the pane was visible, and a fresh load at each width was measured); a real phone or touch device; Firefox and Safari; a screen reader.

### 2026-09-20, step 1.9c checkpoint A: the play-time counter (save version 2)

New: `src/ui/components/PlayTime.tsx`, `test/playtime.test.ts`, `test/fixtures/save-v1.json`. Changed: `types/state.ts`, `sim/state.ts`, `sim/tick.ts`, `sim/offline.ts`, `sim/save.ts`, `state/driver.ts`,
`state/selectors.ts`, `ui/screens/Settings.tsx`, `ui/theme.css`, `data/tuning.json` (`save.version` 1 -> 2), and the migration, fast-forward and import tests that named version 1 by number.

**Why it exists.** The designer pressed the dev panel's fast-forward ten times at 12 hours (120 game hours) and reached Woodcutting 217 in five real days. Nothing in the save could tell that apart from five
days of real play, so neither the designer nor a later session could say what the game's pacing actually feels like. `stats` splits game time by where it came from.

- **`GameState.stats = { onlineMs, awayMs, devMs }`**, milliseconds, persisted.
  - `onlineMs`: the dt an ordinary tick handed to `step`, after the driver's clamping (a backwards clock adds nothing).
  - `awayMs`: the window `applyOffline` **granted** — `summary.elapsedMs`, already capped. Twenty hours away under the 12-hour cap adds twelve, the same twelve it earned.
  - `devMs`: the window the dev panel's fast-forward granted, kept apart so a testing shortcut never looks like play time. **It is not in "Total played".**
- **The plumbing.** The sim still has no clock. `step` takes a `credit` option (`'onlineMs' | 'awayMs' | 'devMs' | 'none'`, default `'onlineMs'`) and `creditPlayTime` in `sim/tick.ts` is the **only** writer of
  `stats`: it adds the same sanitized `dt` the rest of the step used. `applyOffline` calls `step` with the window it granted and `credit: 'awayMs'`, or `'devMs'` when its new `{ dev: true }` option is set;
  only `driver.fastForwardHours` sets it. Nothing counts twice, because the driver's existing anchor rule already sends a long gap through `applyOffline` alone.
- **Save version 1 -> 2**, and the first real migration. `MIGRATIONS[1]` adds `stats` with zeros. History cannot be backfilled: a v1 save never recorded how long it had been played, and `lastSeen` is when it
  was last written, not when it was started. Inventing a number there would make the counter a lie on every old save. The strict schema takes `stats` as three non-negative numbers and nothing else.
- **A real v1 fixture.** `test/fixtures/save-v1.json` was written by this project's own 0.1.0 code before the version was bumped (a mid-game save: two creatures, pool traits, a working slot, fractional Aether,
  a moved RNG). The migration, the chain, and the 1.9 **import** path are all tested against that file rather than a hand-built object, so a later refactor cannot quietly keep the test in step with the code.
- **UI.** Settings has a "Play time" card: Total played (online + away), Online, Away, and a "Dev fast-forward" line that appears only when it is above zero or the Dev panel is on. Values come from
  `selectOnlineMs` / `selectAwayMs` / `selectDevMs` / `selectPlayedMs` and are formatted with the existing `formatDuration`. Reset save starts a new game, so it zeroes them.

**A warning for the designer.** A build older than this one reads a version-2 save as **too-new**: it quarantines it (copies it to `aetherbound-idle:save-broken-<time>` and starts a fresh game) — it does not
delete it. So after this step, do not run the old `Aetherbound-Idle-0.1.0-*.exe` against the same `%APPDATA%\Aetherbound Idle` save. Use the 0.1.1 exe built at the end of 1.9c.

**Mutation-checked** (each mutant was applied, `npm test` run, then reverted):
- counting `requestedMs` instead of the granted `elapsedMs`: **7 tests fail** (including "a 20-hour gap grants, and counts, exactly the 12-hour cap").
- counting fast-forward as away time: **8 tests fail** (the whole "fast-forward is counted apart" group, plus the selector and round-trip tests).

**Decisions.**
1. **Fast-forward is not play time.** It is shown, but never added into "Total played", because the counter exists to answer "how long has this really taken".
2. **The granted window, not the requested one.** The counter measures what the game gave you, so it can never claim more time than it earned.
3. **`credit: 'none'`** exists for a caller that counts a window itself. Nothing uses it in the game; it keeps the option total rather than implicit.
4. Counters are plain milliseconds, not balance, so they are **not** in `tuning.json`.

### 2026-09-20, step 1.9c checkpoint B: when each level was reached (the same migration, 1 -> 2)

New: `src/ui/components/SkillMilestones.tsx`, `test/milestones.test.ts`. Changed: `types/state.ts`, `sim/skills.ts`, `sim/tick.ts`, `sim/state.ts`, `sim/save.ts`, `state/selectors.ts`,
`ui/screens/Settings.tsx`, `ui/theme.css`, `data/tuning.json` + `data/schema.ts` + `test/content.test.ts` (a new `ui.pacingMilestones`), plan.md 3.10, 5 and 6, and the tests that build a `SkillState` by hand.

- **`SkillState.reached`**: a sparse map, level -> `[playedMs, devMs]`, where `playedMs = stats.onlineMs + stats.awayMs` and `devMs = stats.devMs` at that moment. **Absent means unknown, never zero.** Reading
  it: `playedMs` is the real time it took, and a `devMs` that has grown since the level before means the dev panel's fast-forward did part of the work. A new game has level 1 at `[0, 0]`.
- **Accuracy (also in a comment on `StampWindow` in `sim/skills.ts`).** A level reached during an ordinary tick is stamped at that tick, so it is accurate to one `ui.tickMs` (100 ms). A level crossed inside ONE
  offline or fast-forward window is placed by **linear interpolation across the window by XP**, which is approximate: the XP rate is taken as constant for the whole window, and it is not when a slot unlocks
  part-way through, so a twelve-hour window can misplace a level by a good part of an hour. It is never wrong about *which window* a level fell in, only about where inside it. Levels the dev panel's "Set skill
  level" hands out are left **absent**, because no time passed for them. Levels an old save already had are absent too; nothing is invented.
- **Where it lives.** `addSkillXp` already knew every level crossed, so it stamps there, and takes an optional `StampWindow` built by `step` from the counters at the window's two ends. Pure, no clock.
  `raiseSkillToLevel` (the dev panel) passes no window, which is what makes its levels unknown. **The first stamp for a level wins**, so a retune that re-levels a save cannot rewrite its history.
- **Migration 1 -> 2** (the same one as checkpoint A) now also adds `reached` to every skill: `{}` for a skill that has XP, and `{ "1": [0, 0] }` for one that does not (it is still at its starting level, which
  costs nothing). `reconcile` keeps whatever stamps a save has, and gives a skill added by a later content update `{}` — the save cannot say when that player got it, and `[0, 0]` would claim they had it from
  the start. The schema stays strict: the key must be a whole level number and the value exactly two non-negative numbers.
- **UI.** Settings has a "Skill milestones" card: one small table per skill that has earned XP, with a row for each of the skill's slot unlock levels, its max level, and the levels in the new
  `tuning.ui.pacingMilestones`. Columns: level (marked "slot" / "max"), and the real play time when it was reached, with "+ dev 6 h" appended when dev time had been added by then, or "unknown" when there is no
  stamp. `selectSkillMilestones` returns the same array while nothing has moved, so the table does not re-render on every tick.
- **`tuning.ui.pacingMilestones` = [10, 25, 50, 100, 150, 200]** (PLACEHOLDER, designer to adjust). It is display only: it decides which extra rows that table shows and nothing else. Schema, content test
  (ascending, distinct, whole, no higher than a skill's max level) and plan.md 3.10 all carry it, as CLAUDE.md requires for a new UI number.

**Mutation-checked** (applied, `npm test`, reverted):
- stamping every level at the window's end instead of interpolating: **3 tests fail** ("NOT all of them at the end", "the early levels take a small share of the window", and the offline-equals-online test).
- overwriting an existing stamp instead of keeping the first: **1 test fails** ("re-earning a level after a harder curve keeps the original time"), which is the only case where it can happen at all.

**Decisions.**
1. **Interpolation, not segmentation.** Segmenting an offline window per level would make the stamps exact, but `advanceSkills` does its whole window in one bulk pass on purpose (plan 4.5), and cutting it up to
   date a display-only number would slow the one path the whole game runs on. The approximation is written down instead, in the code and here.
2. **Unknown rather than a guess.** Every case where the time is not known (an old save, a dev-granted level, a skill added later) stores nothing and shows "unknown".
3. **`[playedMs, devMs]` as a two-element array**, not an object: it is repeated up to 250 times per skill in the save, and a save is one localStorage string.

### 2026-09-20, step 1.9c checkpoint C: the pacing retune, skill curve growth 1.04 -> 1.045 (designer's decision)

Changed: `data/tuning.json` (`xp.skillCurve.growth` only), `test/pacing.test.ts` (new milestone targets, a new floor test, a new old-save table), design.md section 3, plan.md 3.10, 4.3, 6 and the approval note.
**Nothing else moved**: XP per action, the Woodcutting tiers and their unlock levels, the slot unlock levels, the creature curve and the creature cap are all exactly as they were.

**Why.** With the old growth the designer reached Woodcutting 217 in five days of wall-clock time using ten 12-hour fast-forwards, on a shiny Zenith Lumbercrown (Form 3, hand-picked traits) plus a plain
Sproutlet. Level 217 is only 27% of the XP of level 250 — the last 33 levels cost about three times the first 217 — so that pace put level 250 about 18 days out for that setup, and much less than that for a
fully built account. The target is that the **fastest account the game allows** needs about two weeks for level 250, and that a typical player is far slower.

**What it does.** A level costs `round(250 * 1.045^(L-1))`. Level 250 now needs **319,651,156 XP** in total, up from 108,932,283.

| Level | One lone starter, before | after | change |
|---|---|---|---|
| 2 (first level-up) | 75 s | 75 s | none (the first level always costs `base`) |
| 30 | 46.0 min | 49.3 min | +7% |
| 100 | 8.7 h | 12.3 h | +42% |
| 150 | 2.5 d | 4.6 d | +81% |
| 250 (the cap) | 4.1 months | 12.2 months | +194% |

The early game is almost untouched, because the growth only compounds once there are many levels behind it.

**The account times that matter** (computed from the real data and formulas):

| Account | before (1.04) | after (1.045) |
|---|---|---|
| The fastest the game allows: five slots, Zenith / Form 3 / creature cap, both modifier caps | 4.6 days | **13.3 days** |
| The designer's run: one maxed creature plus a plain Sproutlet | 17.8 days | **52.1 days** |
| One maxed creature, one slot | 20.7 days | **60.7 days** |
| One lone unupgraded starter | 4.1 months | **12.2 months** |

The designer's setup reaching level 217 takes 4.9 days at the old growth, which is exactly the run that was observed, so the model matches what actually happened.

**The floor test** (`test/pacing.test.ts`). It models the best achievable account from the shipped data and the real `cooldown` formula as a deliberately GENEROUS upper bound — every slot filled as
`slotUnlockLevels` opens it, every creature at the top rarity tier, Form 3 and the creature cap, the full `cooldown_reduction` and `bonus_xp` caps from `modifiers.json` applied to every creature at once, always
on the best tier unlocked — and asserts level 250 takes **at least 12 days**. Nothing in the game can beat that model, so the real best case takes at least as long. **It must be revisited when tiers 4 and 5 are
authored, when new trait mechanics land, or when a faster creature is added**: each of those raises the best-case rate. That note is in the test file too.

**Mutation-checked**: putting the growth back to 1.04 fails the floor test at 4.6 days (and five other pacing assertions).

**Old saves.** XP is kept and the level is re-derived under the new curve on load, exactly as `reconcile` has always done; no migration is involved. A new test pins the table:

| old level | 1 | 2 | 15 | 30 | 50 | 100 | 150 | 165 | 200 | 217 | 225 | 250 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **new level** | 1 | 2 | 14 | 28 | 46 | 91 | 136 | 149 | 180 | 196 | 203 | 225 |

Nothing is lost: no creature, no XP, and no slot. The 1.8t grandfathering still holds, so a save keeps every slot it had even where the lower level no longer earns it (a level-250 save becomes level 225 and
keeps all five). Tested across the whole table through the real save path.

**Open item for the designer.** Real pacing still depends on content that does not exist: **tiers 4 and 5** (today all three Woodcutting tiers are open within the first hour, so levels 30 to 250 add nothing new
to cut), **faster creatures**, and whatever Phase 2 breeding and Phase 3 expeditions do to the rate. Re-run the pacing and floor tests, and revisit the growth, when those land.

### 2026-09-20, step 1.9c checkpoint D: the background image

New: `test/assets.test.ts`. Renamed: `src/ui/assets/background/app-bg.png` -> `app-bg.jpg` (it was always JPEG data; the extension was lying). Changed: `ui/theme.css`, `docs/art-brief-background.md`.
`src/state/driver.ts` had already been tidied in checkpoint A (the `})` jammed onto the end of the `queueWelcomeBack` line in `catchUp` is on its own line; no behaviour change).

**How it is wired.** Four `:root` tokens carry it, so swapping the art is a one-line change: `--bg-image`, `--bg-scrim` (the dark gradient), `--bg-position`, plus the two surface alphas. One fixed
pseudo-element, `.shell::before` (`z-index: -1`, `pointer-events: none`, `background-size: cover`), paints the scrim and the image together behind the sidebar, header, cards, dialogs and toasts. It is a fixed
pseudo-element rather than `background-attachment: fixed`, which repaints on every scroll frame. Static: no animation, no filter, and no backdrop blur added (the only one in the theme is the 10 px on the
header, from 1.9b; the new test caps any blur at 12 px). `--bg` (`#0d1015`) stays behind it as the solid fallback and still matches `BACKGROUND` in `electron/main.cjs`, so there is no flash before the image
loads and nothing breaks if it never does.

**`--bg-position: 74% 50%`, and why the portrait file is not used.** The painting's middle third is deliberately empty, and at 375 px `cover` keeps only a narrow vertical slice, so `center` would show nothing
but haze on a phone. 74% keeps the large ring island on the right in frame at 375, 768, 1024 and 1280 px. `app-bg-portrait.png` is therefore **unused** (and, being unreferenced, not bundled by Vite); it stays
in the repo in case the art is later replaced by something that does crop badly.

**Readability, measured rather than guessed.** I composited the real stack in a canvas in the browser — image, then the scrim at its gradient alpha for that height, then the surface at its alpha — and computed
WCAG contrast for the theme's actual text colours. The worst case is not the teal or violet mist (their brightest 64 px blocks are only luminance 0.075 and 0.070) but a **warm gold mote at 80% / 84% of the
image**: its brightest 16 px patch is `rgb(179, 158, 136)`, luminance 0.358. Everything below is measured against that patch, at the scrim alpha that applies at that height (0.61).

| Text | on the page | on a card (`--panel`) | on a raised surface | needs |
|---|---|---|---|---|
| body (`--text`) | **7.88** | **14.57** | **13.55** | 4.5 |
| secondary (`--muted`) | — | **6.66** | **6.19** | 4.5 |
| labels (`--faint`) | — | **5.17** | **4.80** | 4.5 |
| accent (`--gold`) | **4.88** | **9.02** | — | 4.5 |

Two things came out of the measurement:
1. **`--faint` was raised from `#7d8794` to `#869099`.** At the old value it read 4.61 on a card and **4.29** on a raised surface over that gold mote — and it was already only 4.85 / 4.45 in the 1.9b theme with
   no image at all, so it was under 4.5 before this checkpoint. The nudge fixes the existing shortfall and leaves room for the image. It is the eyebrow labels ("SKILLS", "SLOTS", "GATHERING") and the milestone
   table's column headings; barely visible as a change.
2. **The card and button border tokens do not reach 3:1, and the image is not why.** `--line` on a card is 1.23 with the image and was 1.29 without it; `--line-strong` (the button and input outline) is 1.62
   with and was 1.71 without. The image costs about 0.06. Making them 3:1 means roughly doubling their lightness, which is a visible restyle of every button, input and card in the 1.9b theme, so I have not done
   it — **see the question for the designer below.** Worth knowing: the image makes card EDGES easier to see, not harder (a card against the page behind it went from 1.08 to **1.85**), because the panel is now
   darker than what surrounds it rather than nearly the same.

**The scrim was tuned down, not up.** It started at 62% -> 80% and the art was almost invisible; since body text had 10x the contrast it needed, I lightened it to 45% -> 64% and raised the surface alphas from
88/90% to 90/92% to buy the contrast back. The result shows the ring islands and the mist while every figure in the table above still clears its threshold.

**Tests** (`test/assets.test.ts`): the file `theme.css` references exists; the wiring goes through the tokens, over the scrim, at `cover`, with no `background-attachment: fixed`; the layer is static and no
backdrop blur exceeds 12 px; the shipped image is under 1.5 MB; and **every file under `src/ui/assets/` really is the format its extension claims** (PNG, JPEG, WebP or GIF by file signature). That last one is
the guard for the trap this image fell into: `app-bg.png` held JPEG data, which Vite served as `image/png` and the browser sniffed its way past. It worked, but nothing promised it would keep working from
`file://` in the packaged app.

**Question for the designer (not decided here).** The 1.9b theme's borders sit at 1.2 to 1.7:1 against their own surface, below the 3:1 that WCAG 1.4.11 asks for a control's visible boundary. That predates the
background image and the image barely moves it. Raising `--line` and `--line-strong` to 3:1 would make every button, input and card outline noticeably lighter — a real change to the look you signed off in
1.9b. Do you want that, or are the borders decorative enough (every control also has its own fill and its focus ring) to leave alone?

### 2026-09-20, step 1.9c checkpoint E: verified in the browser, and the exe rebuilt as 0.1.1 (step 1.9 complete)

Changed: `package.json` (0.1.0 -> 0.1.1), `electron/smoke.cjs` (the load check now proves the background image loads), `ui/theme.css` (the phone drawer made opaque, see below), `docs/PROGRESS.md`.
`npm run build` is clean and **800 tests pass**.

**Verified in a real browser, on a save reset to zero.**

| What | Result |
|---|---|
| Play time advances in real time | Online climbed tick by tick with the game open; it counts even with nothing assigned, because it is time in the game |
| The first level-up | Stamped at **75.5 s** of work (level 2 at 126,513 ms online, the creature assigned at about 51,000 ms). The pacing test's "about 75 s" is what the app really does |
| A 1 h fast-forward | Dev fast-forward **+3,600,000 ms exactly**; Away +0; Online grew only by the 19.8 s of real time that passed while clicking |
| The Dev line | Hidden on a fresh save with the Dev panel off; appears the moment the Dev panel is switched on, even at 0 s |
| "Total played" | Online + Away only. After the fast-forward it read 4 m 5 s while the Dev line read 1 h |
| The milestone table | Level 10 read `3 m 26 s + dev 10 m 57 s`, level 25 `3 m 26 s + dev 49 m 33 s`: the real time stands still through the fast-forward and the dev column carries it, which is exactly the reading the designer asked for |
| Levels crossed inside the fast-forward | 3 to 27 all stamped inside the one window, in order, distinct, `playedMs` frozen at 206,131 and `devMs` running 300 -> 3,414,900 |
| Dev "Set skill level" to 120 | Levels 29 to 120 **absent**; the table shows 50, 100, 150, 165, 200, 225 and 250 as "unknown" |
| Reset save | Zeroes all three counters, save back to version 2, `reached` back to `{1: [0, 0]}` |
| Reload | Level, the whole `reached` map and `devMs` unchanged; `onlineMs` carried on. `awayMs` gained 94 ms, which is right: the reload gap really is time the tab was not ticking, and it goes through the offline path |
| Export | The downloaded file is **byte for byte the stored save**, version 2, with the counters and all 28 stamps in it |

**The background, at 1280, 1024, 768 and 375 px, on every page.** Honest description: it reads as a dim blue-indigo depth behind the app rather than a picture you look at, which is what the brief asked for. On the
**Nexus** and **Roster** pages, which have the most empty space, it is at its best: the floating islands, the teal mist and the warm gold motes are all legible. On the **skill page** and the **Dev panel** the cards
cover most of it and only the margins show. At **375 px** the crop is tight and the frame is mostly the right-hand ring island and haze; it is still clearly a scene, not a gradient. Nothing anywhere is too bright
or too busy, and no text is harder to read than it was in 1.9b. If anything it errs **slightly flat** in the middle of a wide window, which is the composition doing its job (the painting's centre is deliberately
empty and the content sits there).

- **No horizontal overflow at 375 px** (`scrollWidth - clientWidth` is 0), and **no control under 44 px**, measured over every button, link, input and select on the page.
- **One real problem found and fixed:** the phone **drawer** was translucent like the docked sidebar, and the page's own headings and cards ghosted through it. The drawer covers content, not the image, so it is
  now opaque (`--panel-solid`); the docked sidebar keeps its translucency because what is behind it is the image.
- Checked over the image: every page, the drawer, the notification bell panel, and the welcome-back dialog (it appears over the image with its own backdrop and reads cleanly).

**The exe.** `npm run electron:pack` at **version 0.1.1**:

| File | Size |
|---|---|
| `release/Aetherbound-Idle-0.1.1-setup.exe` | 98.4 MB (103,218,491 bytes) |
| `release/Aetherbound-Idle-0.1.1-portable.exe` | 98.2 MB (102,935,158 bytes) |
| `release/win-unpacked/` | rebuilt in place |

The older `0.0.0` and `0.1.0` files are still in `release/`; nothing was deleted. The image is inside the package (`\dist\assets\app-bg-ClgoUiYD.jpg` in `app.asar`, 292 KB).

**Packaged smoke tests pass on both**, `win-unpacked` and the portable exe, all three checks each. The `load` check now also proves the image: **`background image loaded from file:// (2048x1144)`**. That check
earned its place immediately — the first version of it read the `--bg-image` token and built an `Image` from it, which failed, because a custom property keeps the text it was given (a path relative to the
**stylesheet**) while `new Image()` resolves against the **document**. Reading the resolved `background-image` off `.shell::before` instead is what the browser actually fetches. The app was never broken; the
check was. A CSS background never fires `did-fail-load`, so without this a wrong path would just leave the app on its fallback colour and look deliberate.

**Could not verify, and why.**
- **A toast over the image.** The toast fires and clears in `tuning.ui.toastMs` (5 s) and every Browser-pane round trip costs 2 to 5 s, so I never landed a screenshot inside the window; holding it open through
  its `setTimeout` and through its focus-pause both failed. What I do know: the toast rendered with the right content in the live DOM ("LEVEL UP - Woodcutting reached level 2") while the image was behind it, and
  `.toast` is painted on `--panel-high`, a **fully opaque** colour this step did not touch, so the image cannot reach it (text on it measures 12.0:1). The bell panel, which uses the same surface family, was
  screenshotted. Worth a glance on the manual checklist.
- **The import half of the export/import round trip.** Import needs the OS file picker and the Browser pane has no way to attach a file. Export was verified byte for byte; import of a v2 file (and of the real
  v1 fixture) is covered by node tests. It is on the manual checklist.
- The native Save and Open dialogs, the window on screen, the installer, and a real phone: all still manual, as in 1.9b.

## Manual checklist for 0.1.1 (designer)

Run `release\Aetherbound-Idle-0.1.1-portable.exe`. Everything from the 0.1.0 list below still applies; these are what is new.

1. **The background image** is behind the whole app on every page, and no text anywhere is hard to read. Resize the window from full screen down to a narrow column and back.
2. **Settings -> Play time**: Total played, Online, Away. Leave the game open for a minute and watch Online climb. Close the app for five minutes, reopen, and check that **Away** got those five minutes and Online did not.
3. **Settings -> Skill milestones**: a row per interesting level. On a new save the first entry is "1 slot - 0 s". Anything you have not reached says "unknown".
4. **The Dev fast-forward line** only appears once you have used fast-forward or switched the Dev panel on. Press fast-forward 1 h and check it goes up by exactly 1 h and that **Total played does not move**.
5. **A toast** (any level-up) over the image: it should be solid, not see-through. (This is the one thing I could not photograph.)
6. **Export a save, then import it back** through the real Save and Open dialogs, and check Settings still shows the same Play time and milestones afterwards.
7. **Do not run the old 0.1.0 or 0.0.0 exe against this save.** They read a version-2 save as too-new, set it aside as `save-broken-<time>` and start a fresh game. Nothing is deleted, but you would be playing an empty save.

## Deferred (design.md section 10, needs decisions before it is built)
- ~~**UI shell restyle**~~ **Done as step 1.9b.** What the shell does not have yet, on purpose: the Adventure and Collection sidebar sections (they appear with their screens in Phases 2 to 4), a Skills Overview, Achievements, Inventory, Shop and any queue.
Listed so they are not forgotten. Not in step 1.7 and not started:
- **Bulk release** of creatures. Needs the Aether refund formula (what a release returns) and a rule about what may not be released
  (assigned, locked).
- **Favorite / lock** flag on a creature. Needs a field in the save (`Creature.locked`) plus a **save migration** (`MIGRATIONS[1]`), and
  a decision on what a lock protects against (release, breeding, both).
- **Auto-assign-best** (fill empty slots with the best creature). Needs the definition of "best" per skill and resource.
- **Two tabs or windows on the same save** (found in 1.8a). Each copy autosaves from its own state and they overwrite each other,
  so progress is lost. Not in the design. **The `.exe` has a single-instance lock (done in 1.9)**; the browser build would need a
  cross-tab lock or an "open elsewhere" notice. Designer to decide whether the browser build needs one.
- ~~**Native `<dialog>` cancel path**~~ **Done in 1.8b checkpoint C** (`onCancel` refuses the browser's close and dismisses the summary). Still open: re-check the
  dialog in Firefox and Safari, and with a real Android back press (the event was only dispatched by hand).

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
- **Re-check the pacing once there is more content** (open item recorded with the 1.9c retune). `xp.skillCurve.growth` is 1.045 and the floor test asserts the fastest possible account cannot reach level 250 in
  under 12 days, but that floor is measured against content that does not exist yet: **Woodcutting tiers 4 and 5** (all three shipped tiers are open within the first hour, so levels 30 to 250 add nothing new to
  cut), **faster creatures**, and whatever Phase 2 breeding and Phase 3 expeditions do to the rate. Each of those raises the best-case rate. Re-run `test/pacing.test.ts` and revisit the growth when they land.
- **`tuning.ui.pacingMilestones` is a PLACEHOLDER** ([10, 25, 50, 100, 150, 200]). It only picks which extra rows the Settings "Skill milestones" table shows; say if other levels would be more useful.

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
