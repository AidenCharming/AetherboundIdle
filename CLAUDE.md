# Aetherbound Idle

A creature-collecting incremental (idle) game in the style of Melvor Idle. Players collect **Aetherlings**, assign them to skills, breed them into rarer and hybrid forms, and send them on simple idle-combat expeditions to capture new species.

## Read these first

* `docs/design.md`: full design (systems, rules, formulas, scope, build phases)
* `docs/content-data.md`: every species, hybrid, and trait as tables. Convert these into JSON under `src/data/`.

## Stack (change only if you have a strong reason, and tell me)

* Vite + React + TypeScript
* Zustand for game state
* All content and balance numbers live in JSON under `src/data/`. **Never hardcode balance numbers in components or logic.**
* Saves to localStorage (versioned, with a migration hook). Offline progress is computed on load from `lastSeen` timestamp.
* Vitest for unit tests on the core sim (cooldowns, offline progress, breeding rolls, mutation odds, pity counters).
* **Delivery: Windows `.exe`.** The designer wants the game to run as a desktop app, not a browser link. It is packaged in step 1.9 (after 1.8b) with a desktop wrapper (Electron recommended; see "Desktop packaging" in `docs/PROGRESS.md`). Until then, keep the app a plain static Vite build with no server dependency and no absolute-URL assumptions, and put no wrapper code in `src/`.

## Rules for working in this repo

1. **Data-driven.** Species, traits, skills, resources, zones, recipes, and tuning knobs are JSON. Adding content must not need code changes.
2. **Sim is separate from UI.** The game loop lives in `src/sim/` as pure functions on state (no React imports). UI only reads state and dispatches actions. This makes offline progress and tests easy.
3. **Offline progress = time elapsed ÷ cooldown**, calculated in bulk, not by replaying ticks. Cap the offline window with a tunable value.
4. **Placeholder art first.** Use emoji or generated SVG on colored cards. Type colors: Verdant green, Telluric brown, Pyric orange, Aqueous blue, Voltaic yellow, Void purple. Rarity is shown by frame/tint/glow, and shinies by a hue shift applied at runtime. Never create per-rarity or per-shiny art assets.
5. **Build in phases** (see design.md, "Build phases"). Finish and run each phase before starting the next. Show me something playable after each phase.
6. **Don't add systems that aren't in the design.** If something seems missing or contradictory, list it and ask me before deciding. Where the design says "placeholder" or "tunable," pick a sensible value and put it in JSON.
7. Keep names as written in the docs. Do not rename species, forms, traits, or types.
8. Keep the UI responsive (desktop first, must work on a phone-width screen).

## Session protocol (usage limits and resuming)

I may hit usage limits or switch models mid-project. Always leave the repo in a state where a fresh session can continue with no loss.

1. **Start of every session:** read `docs/PROGRESS.md` first, then continue from "Next up."
2. **Work in small checkpoints.** Each checkpoint is one step from the phase checklist in PROGRESS.md, ends with the project building and tests passing, and gets its own git commit with a clear message. Never leave a half-finished step uncommitted or the build broken.
3. **Update `docs/PROGRESS.md` after every checkpoint:** tick the step, note any decisions or deviations from the design, and update "Next up" and "Open questions."
4. **Save the plan.** The approved plan (folder structure, JSON schemas) goes in `docs/plan.md` so later sessions don't need to re-derive it.
5. **If I say I'm running low on usage, or a limit warning appears:** stop starting new work, finish or cleanly revert the current step, commit, and update PROGRESS.md. Then tell me the exact next step.
6. Prefer several small steps over one large one. Do not attempt a whole phase in a single pass.
7. **Session naming.** Sessions use the format "Aetherbound P<phase> · <steps> <topic> (<model>)", e.g. "Aetherbound P1 · 1.4-1.5 Sim core + offline (Opus)". At the START of a session, tell me the suggested name for this session based on the steps I asked you to do, and give me the exact /rename command to paste. At the END of a session, when you tell me the next step, also give me the suggested name and the exact `/rename` command for the next session's first message.

## Commands

| Task | Command | Notes |
|---|---|---|
| Dev server | `npm run dev` | Vite on http://localhost:5173 |
| Build | `npm run build` | Type-checks with `tsc --noEmit`, then `vite build` |
| Test | `npm test` | `vitest run`, one pass (specs in `test/`); `npm run test:watch` for watch mode |
| Desktop app (dev) | `npm run electron:start` | Builds, then opens the built game in the Electron window (`electron/main.cjs`). Shares the real save with the packaged app; DevTools with F12 |
| Wrapper smoke test | `npm run electron:smoke` | Builds, then launches Electron hidden three times on a throw-away profile: load (page shows "Woodcutting", no console error), progress (a minimized, throttled window earns exactly the time that passed, and survives a reload), single instance. Exit 0 or 1. Never touches the real save. Add `-- --only=load` for one check |

