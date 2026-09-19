# Progress

Read this at the start of every session. Update it after every checkpoint (see Session protocol in CLAUDE.md).

## Next up
**Step 1.3: content data.** Read `docs/plan.md` section 3 and `docs/content-data.md`, then create every
file in `src/data/` plus `schema.ts` and `index.ts`, and a content load test proving every species,
hybrid, trait, ability and resource loads and cross-resolves. Delete `test/smoke.test.ts` once the
real content test exists.

## Phase 1: Economy core
- [x] 1.1 Plan: folder structure and JSON schemas written to `docs/plan.md`. **Wait for designer's OK.** *(approved 2026-09-19 with six amendments)*
- [x] 1.2 Scaffold Vite + React + TS + Zustand + Vitest. Build and test commands work. Commands filled in CLAUDE.md. First git commit. *(2026-09-19)*
- [ ] 1.3 Convert `docs/content-data.md` into JSON in `src/data/` (types, skills, species, hybrids, traits, tuning knobs) plus loaders with type-checked schemas. Test that every species and hybrid loads.
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

## Open questions for the designer

### Needs an answer before Phase 3
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
