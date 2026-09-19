# Progress

Read this at the start of every session. Update it after every checkpoint (see Session protocol in CLAUDE.md).

## Next up
Step 1.1 is written but **not ticked**: `docs/plan.md` exists and is waiting on the designer's OK
(see "Decisions that need your OK" at the end of that file). Once approved, tick 1.1 and start 1.2
(scaffold Vite + React + TS + Zustand + Vitest).

## Phase 1: Economy core
- [ ] 1.1 Plan: folder structure and JSON schemas written to `docs/plan.md`. **Wait for designer's OK.** *(plan written, awaiting approval)*
- [ ] 1.2 Scaffold Vite + React + TS + Zustand + Vitest. Build and test commands work. Commands filled in CLAUDE.md. First git commit.
- [ ] 1.3 Convert `docs/content-data.md` into JSON in `src/data/` (types, skills, species, hybrids, traits, tuning knobs) plus loaders with type-checked schemas. Test that every species and hybrid loads.
- [ ] 1.4 Sim core in `src/sim/` (pure functions): creature stats, action cooldown with floor, skill XP and levels, slot unlocks, Aether emission. Unit tests.
- [ ] 1.5 Offline progress calculation (time elapsed ÷ cooldown, bulk, capped window) plus save/load with versioning. Unit tests.
- [ ] 1.6 UI: skills screen with a Woodcutting slot and progress bars, top bar with resources.
- [ ] 1.7 UI: roster screen with placeholder art cards (type colors, emoji, rarity frame), filter and sort, assign to slot.
- [ ] 1.8 Bench and Aether emission display, "welcome back" offline summary, polish pass. Phase 1 playable.

## Phase 2: Breeding and hatching
Not started. Break into steps at the start of the phase.

## Phase 3: Expeditions and capture
Not started.

## Phase 4: Depth
Not started.

## Decisions and deviations from the design
- **2026-09-19, step 1.1:** repo had no git history; `git init` was run as part of this checkpoint so
  the protocol's per-checkpoint commits can start here rather than at 1.2.
- All six items in `docs/plan.md` section 8 are proposed decisions, **not yet approved**. Nothing has
  been built on them.

## Open questions for the designer
Blocking step 1.2 (all six are listed with rationale in `docs/plan.md` section 8):
1. Add `zod` for the type-checked JSON loaders?
2. Signature and pool traits in one `traits.json` rather than two files?
3. Max level 99 for both skills and creatures?
4. Woodcutting tier unlocks at skill level 1 / 15 / 30, 3s base action?
5. Offline cap of 12 hours as the starting tunable value?
6. Seeded, persisted RNG (so a reload cannot reroll a pending breed or hatch)?

Not blocking, carried from `docs/design.md` section 15 for later phases:
- Full resource lists, prices and gold values per skill (placeholders in JSON for now).
- Full gear list, zone wild-species assignments, the Voltaic zone, the tutorial script.
- Special-recipe content (`recipes.json` ships with an empty `special` list).
- Exact reward tables for collection milestones.
- Same-type "sibling" species (design section 6 marks this TBD; the roll exists and resolves to nothing).
