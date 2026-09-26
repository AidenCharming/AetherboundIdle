# Handoff: where the Godot rebuild stands

For the next session (local or cloud, any model). This file is only **the rules, how to run things, where things
stand and what is open**. What was done or fixed is in `docs/CHANGELOG.md` (newest first); how each system works
and why is in `docs/DECISIONS.md`. When you finish something, move it out of "Open" below into a CHANGELOG entry.

## Where things stand (2026-09-25, v0.7.0)

- Current version **0.7.0** (Achievements). All 183 tests pass, zero warnings. The third code review (`docs/codereview.md`) is
  done except its deferred #10–#12 (see the CHANGELOG).
- **Art is done:** every sprite and icon is in the game; the art docs are in `docs/archive/art/`.
- **Benchmarks are the designer's to run** (not Claude's, on the local PC): `python tools/bridge.py run
  bugtest_benchmark [--movie]`. The 2026-09-25 movie run passes once reprocessed (fps isn't judged under
  `--movie`, and the clip step no longer crashes); a run without `--movie` is the real fps check.
- Godot on the designer's PC: `D:\GameDev\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe`
  (not on PATH in Git Bash).

## Open: code and balance

1. Performance, nice to have: the Nexus keeps unchanged cards now (12 ms a refresh with 600 Aetherlings). Still
   rebuilding everything on each `Game.changed` at 600: the Aether-Log (~40 ms), Expeditions and skill pages
   (~25 ms), Market (~18 ms).
## Open: for the designer

- **Paint the achievement art (0.7.0):** 57 paintings, each in its island backdrop's style. With ComfyUI running:
  `python tools/art/achievement_art.py run --category secret` (or skills, nexus, adventure, breeding; `--dry-run`
  first), look at the sheet in `D:\AIchievements\sheets\` (each row starts with its backdrop), `pick KEY N`,
  then `finish` to install them at 512 px. Prompts: `docs/archive/art/art-prompts-achievements.md`; edit the `ART`
  table in the tool and run `prompts`. The trophy nav icon has a prompt in `build_icon_prompts.py` (`--only
  achievements` in icon_runner).
- **Play-test the achievements and secrets (0.7.0):** reward sizes (`data/achievements.json`), names and hints,
  and the secrets' feel: poke an Aetherling three times quickly (Nexus, work slots), rub the mouse over the Nexus
  portrait, poke a perched one five times, knock an egg, click wild ones in battle, the rail's name (7 clicks),
  the empty bell, the title screen's drifters and an old code there. Judge the runaway animation and the boing.
- **Play-test the 0.6.5 rarity ladder:** each island brings one new rarity (Whisperleaf all Dim, Quarry adds
  Faint, … Stormsea adds Zenith) and the new top rarity, **Aetheric**, lives only on Zenith Spire (0.1% of its
  wilds, or a 4% mutation from two Zeniths on tier-10 materials). Judge the Aetheric look (grant one in
  Developer tools; its sprite halo shows in battle), and whether an all-Dim Whisperleaf feels right.
  **The rarity sprite effects (outline glow from Luminous up, shine, pulse, rainbow edge, motes) never rendered
  before 0.6.5a**, so judge all of them fresh: strength, colours, and whether the glow is too much on small
  cards. Still
  from 0.6.4: fewer traits on catches, rarer egg mutations, a half-strength Glimmer Lure, a weaker Old
  Thicketroll (Dims win at level 7) and a smaller attack-speed edge from rarity. The last benchmark party (three at Lv 10)
  failing Smoldering Caldera (Lv 15–25) is expected: that island's calibration party is Faint at Lv 23.

- **Sound and music (designer's playtest, 2026-09-25):** `rare_appear` works but feels "meh"; the type attack
  sounds and the sounds and music in general may need real recordings from an open-source (CC0) library instead
  of the ones synthesized in `scripts/autoload/sfx.gd`. Plan the source and licences with the designer first.
- **Close button is too purple** (designer, 2026-09-25): tone down `face_sat` / `face_value` in
  `assets/shaders/flat_icon.gdshader` (or set them per button in `modal.gd`'s `close_x`).
- **Confirm on Windows:** the Options window-mode fix (the bug was on Windows fullscreen; guarded three ways).
- **Balance only play can judge:** Overseer Vance's 113 goals (order, texts, rewards in `data/goals.json`),
  Market prices (`data/market.json`, and whether buying materials makes gathering pointless), Aether Pearl drop
  rates (3–7 a day at the end), work XP, early-island pacing (`combat.levelGap`, Fractured Quarry).
- **Cosmetics:** pick from `docs/cosmetics.md`; nothing is built.
- Gear stays out (it would upset the balance).
- Check one hatch reveal's rarity pips.
- **Kill XP is now split across the party** (0.6.3d) with the per-kill base tripled so a trio keeps its
  pace: judge in play whether solo/duo parties now level too fast.

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
  commit a regenerated `docs/archive/art/art-prompts-*.md` from a machine without the designer's `D:\AI` art folders**: the
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
