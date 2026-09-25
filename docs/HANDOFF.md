# Handoff: where the Godot rebuild stands

For the next session (local or cloud, any model). This file is only **the rules, how to run things, where things
stand and what is open**. What was done or fixed is in `docs/CHANGELOG.md` (newest first); how each system works
and why is in `docs/DECISIONS.md`. When you finish something, move it out of "Open" below into a CHANGELOG entry.

## Where things stand (2026-09-25, v0.6.3a)

- Current version **0.6.3a**. All 166 tests pass, zero warnings. The third code review (`docs/codereview.md`) is
  done except its deferred #10–#12 (see the CHANGELOG).
- The designer is painting in `D:\AI`: every prompt is written, and Form 3 and hybrid sprites are being generated
  and reviewed there. Leave the art files alone (see the art rules below).
- **Benchmarks are the designer's to run** (not Claude's, on the local PC): `python tools/bridge.py run
  bugtest_benchmark --movie`. 0.6.3a fixed the `--movie` frame stats (wrong project path) and the background
  frame-rate cap on bridge games; the next full run should confirm both and that it passes.
- Godot on the designer's PC: `D:\GameDev\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe`
  (not on PATH in Git Bash).

## Open: code and balance

1. **Rarity and early-game balance (next session, designer's pick).**
   - Rare rarities show up too often on expeditions: the wild rarity odds (`rarityWeights` per zone in
     `data/zones.json`) and the Glimmer Lure.
   - A Luminous Mossgear party at Lv 1–3 beats Old Thicketroll; breeding two Steadys gives Gleaming; many
     Minor/Major traits. Candidates: a gentler Dim → Faint → Steady `statMultiplier` ramp in `data/rarities.json`,
     breeding `mutationPlusOne` / `ceilingByTier`, trait strength odds, Mossgear's lean.
   - The last benchmark's party (three at Lv 10) failed Smoldering Caldera (Lv 15–25) for 4 minutes.
   - Measure with `tests/balance_probe.tscn`, `month_probe --split` and the month probe.
2. **Sharpness:** 512 px icons instead of 256 (`icon_runner.py finish --size`, sources in `D:\AI`), after the
   current art run. Font hinting none vs light made no difference at 1080p. The designer dislikes icons that look
   different sizes anywhere.
3. Performance, nice to have: the Nexus keeps unchanged cards now (12 ms a refresh with 600 Aetherlings). Still
   rebuilding everything on each `Game.changed` at 600: the Aether-Log (~40 ms), Expeditions and skill pages
   (~25 ms), Market (~18 ms).
## Open: for the designer

- **Not yet seen or heard in the real game:** the shiny and rare entrance sounds (`shiny_appear`, `rare_appear`),
  the type attack sounds, and the sprite effects' motion. Developer tools > "Next wave: a shiny" / "the rarest
  rarity", and "Rarity preview" plays every sound.
- **Confirm on Windows:** the Options window-mode fix (the bug was on Windows fullscreen; guarded three ways).
- **Balance only play can judge:** Overseer Vance's 112 goals (order, texts, rewards in `data/goals.json`),
  Market prices (`data/market.json`, and whether buying materials makes gathering pointless), Aether Pearl drop
  rates (3–7 a day at the end), work XP, early-island pacing (`combat.levelGap`, Fractured Quarry).
- **Chunk 1 recipes:** their pair assignments were never reviewed (`docs/archive/done/naming/chunk1-claude.md`).
- **Cosmetics:** pick from `docs/cosmetics.md`; nothing is built.
- Gear stays out (it would upset the balance).
- Check one hatch reveal's rarity pips.
- Look over the new Aether-Log species page and the Creaturedex Show bar (0.6.3).

## Ground rules

- The Godot project is at the repo root (`project.godot`); `CLAUDE.md` is the short version of these rules. The
  old web build is on the `web-archive` branch and is never touched; its docs are in `docs/archive/web-build/`.
- Work on the branch you were given, **but first check it contains `origin/godot-rebuild`**
  (`git log --oneline HEAD..origin/godot-rebuild` should print nothing; if it lists commits, merge first). Push to
  your branch and to `godot-rebuild` at the end. Fetch and **merge** before pushing, never rebase or force-push:
  the designer pushes art to the same branches.
- **Session task list (designer's request):** at the start, make a task list with each task's percent done and
  estimated share of the 5-hour usage in its title, e.g. `[40%] Fix X (est. +3%)`. Keep one task in progress,
  and after each finished task post a one-line progress note (tasks done, overall %, ETA). The designer reports
  their usage %; use it to re-estimate.
- Godot 4.7 GDScript, GL Compatibility, base size 1920×1080 (first-run window: the largest that fits the screen, up to 1920×1080, with larger text below that), UI built in code.
  Autoloads: Options, Data, Sfx, Music, Game, TestBridge. The sim is pure static functions in `scripts/sim/`, the
  UI is in `scripts/ui/`, content and balance are JSON in `data/`. Never hardcode balance numbers.
- Commit as you go. Keep the test count in `docs/DECISIONS.md` current, and add a `docs/CHANGELOG.md` entry for
  what you did.
- **Version number (designer's request):** any major code, balance, UI or icon change bumps `config/version` in
  `project.godot` and `file_version`/`product_version` in `export_presets.cfg`. Keep the numbers climbing slowly
  (the designer doesn't want to reach 1.0 soon): minor (0.6 → 0.7) only for a new system or a big rework; patch
  (0.6.3 → 0.6.4) for a balance pass, a UI rework or a new art set; a letter (0.6.3 → 0.6.3a → 0.6.3b) for small
  fixes and tweaks. The export needs four numbers, so the letter is the fourth: 0.6.3a is `0.6.3.1`, 0.6.3b is
  `0.6.3.2` (a test checks both files agree). **Every bump also
  adds an entry to `data/patch_notes.json`** (shown on the title screen; a test checks the newest matches). The
  notes are for players: no developer tools, code, data files or tooling.
- **Art (designer's request):** any new icon gets a prompt in `tools/art/build_icon_prompts.py` and a placeholder
  in `tools/make_icons.py`. **While the designer paints locally, don't edit those two files from the cloud:** put
  new prompts and placeholders in `tools/art/artnew_merge_me_on_pull.md` (say where each block goes). **Never
  commit a regenerated `docs/art-prompts-*.md` from a machine without the designer's `D:\AI` art folders**: the
  "approved" marks come from there and would be wiped.

## Running things

All commands run from the repo root.

- Import once after cloning, and after adding a `class_name`: `godot --headless --path . --import`.
- Tests: `godot --headless --path . res://tests/test_runner.tscn < /dev/null`, or `tools/check.sh [godot]` (tests
  and warnings). Not `--debug`: a script error then stops at a debugger prompt forever. A test file that doesn't
  compile or a test that crashes fails the run. Warnings only print with `--debug`, so `-- --warnings` loads every
  script without running any and fails on any warning. Tests that touch saves use slot 99 only.
- Driving the running game (real clicks, errors, screenshots): `docs/TEST_BRIDGE.md`. The bug-test benchmark:
  `python tools/bridge.py run bugtest_benchmark [--movie]` (ten minutes, PASS/FAIL report in `bridge_runs/`).
- Screenshots: `godot --path . res://tests/tour.tscn -- --out=DIR --only=nexus,... [--size=WxH] [--ui-scale=N]`
  (needs a display, cloud: `xvfb-run -a -s "-screen 0 1920x1400x24"`; overwrites save slot 3).
- Pacing probe (about 40 s): `godot --headless --path . res://tests/month_probe.tscn -- --days=35
  [--skills|--rates|--calibrate|--split]`. `--split` (8 s) prints, per island, how much stronger its waves and its
  boss can get before the calibration party stops winning: keep waves near x1.45 and each boss about x1.3.
- Big rosters: Developer tools > "Every Aetherling" grants 3,726 (every species, form, rarity, shiny). Use it to
  check a change doesn't slow the game down.

## GDScript traps that bit this project

- Lambdas capture locals by value: keep a modal or other late-assigned value in a Dictionary holder.
- `:=` can't infer from Dictionary values or untyped calls: give those an explicit type.
- `Sfx.play` and `Music` do nothing headless; tests read `Sfx.last_played` and `Music.wanted()`.
- A wrapping Label measured before its container gives it a width reports thousands of pixels of height.
- Tweens that move a fighter are bound to that fighter's node so they die with it.
- A plain CheckButton is invisible under the theme: use `ToggleSwitch`.
- Grids of cards: `UI.even_sizes(flow)` so a locked card is as big as an open one.
- A screen that rebuilds after a click can free the button mid-click: rebuild only when the data it shows moves,
  or defer (see `Main`'s mouse-held rebuild).
- The roster index (workers per skill, perch holders) lives outside the save: call `GameState.roster_changed()`
  anywhere a creature is added, removed, changes job or rerolls traits.
