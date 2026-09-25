# Aetherbound Idle

A creature-collecting idle game in the style of Melvor Idle: collect **Aetherlings**, put them to work in
skills, breed rarer and hybrid forms, and send a party on idle-combat expeditions to bind wild ones. Built in
**Godot 4.7** (GDScript, GL Compatibility, 1600×900, UI built in code). The old web version is archived on the
`web-archive` branch; its docs are in `docs/archive/web-build/` (history only).

## Read these first

* `docs/HANDOFF.md`: where things stand, what to check first, what's open for the designer.
* `docs/DECISIONS.md`: every decision and why (balance numbers, systems, test count).
* `docs/design.md`: the original design (systems, formulas, scope). `docs/content-data.md`: species, hybrids, traits.
* `docs/TEST_BRIDGE.md`: drive the running game from a script (real clicks, errors, screenshots).

## Layout

| Path | What |
|---|---|
| `project.godot` | The project (repo root). Autoloads: Options, Data, Sfx, Music, Game, TestBridge |
| `data/*.json` | All content and balance numbers (species, items, skills, zones, upgrades, market, tuning) |
| `scripts/sim/` | Game rules as pure static functions on one state Dictionary (no UI) |
| `scripts/ui/` | Title screen, game shell, screens and widgets, built in code |
| `scripts/autoload/` | Data loading, the Game clock and actions, audio, options, the test bridge |
| `tests/` | Headless tests (`test_*.gd`), screenshot tour, balance and one-month pacing probes |
| `tools/` | Icon placeholders (`make_icons.py`), art prompt builder (`art/`), `bridge.py`, `check.sh` |
| `assets/` | Sprites, icons, backdrops, fonts, shaders |

## Rules for working in this repo

1. **Data-driven.** Content and tuning live in `data/*.json`. Never hardcode balance numbers in scripts.
2. **Sim separate from UI.** `scripts/sim/` never touches nodes; the UI reads state and calls `Game` actions.
3. **Offline progress is computed in bulk** (elapsed ÷ cooldown), never by replaying ticks; the window is capped.
4. **Art:** rarity is shown by frames, tints and shader effects, shinies by a runtime hue shift. Never make
   per-rarity or per-shiny art. Any new icon gets a prompt in `tools/art/build_icon_prompts.py` and a placeholder
   in `tools/make_icons.py`. **While the designer paints locally, don't edit those two files from the cloud:**
   put new entries in `tools/art/artnew_merge_me_on_pull.md`. Never commit a regenerated `docs/art-prompts-*.md`
   from a machine without the designer's `D:\AI` art folders (it wipes the "approved" marks).
5. **Don't add systems that aren't in the design** without asking. Keep names as written in the docs.
6. **Tests pass and stay at zero warnings** before any push. Keep the test count in `docs/DECISIONS.md` current,
   and update `docs/HANDOFF.md` and `docs/DECISIONS.md` with what changed and why.
7. **Pacing target:** one month to every skill at 99 and Zenith Spire cleared. Check balance changes with the
   month probe.
8. **Session task list:** keep a task list with each task's percent done and estimated share of the 5-hour
   usage in its title (`[40%] Fix X (est. +3%)`), and post a one-line progress note after each task. See
   `docs/HANDOFF.md`.
9. **Version:** any major code, balance, UI or icon change bumps `config/version` in `project.godot` and
   `file_version`/`product_version` in `export_presets.cfg` (minor for big changes, patch for small ones).
   See `docs/HANDOFF.md`.
10. **Git:** commit as you go with clear messages; fetch and **merge** (never rebase or force-push: the designer
   pushes art to the same branch), then push.

## Commands

| Task | Command |
|---|---|
| Run the game | `godot --path .` (editor: `godot --path . -e`) |
| Import (once after cloning) | `godot --headless --path . --import` |
| Tests | `godot --headless --path . res://tests/test_runner.tscn < /dev/null` (exit 0 = pass; not `--debug`, which hangs on a script error). Warnings: `godot --headless --debug --path . res://tests/test_runner.tscn -- --warnings < /dev/null`. Both: `tools/check.sh [godot]` |
| Screenshot tour | `godot --path . res://tests/tour.tscn -- --out=DIR [--only=market,nexus,...]` (overwrites save slot 3) |
| Pacing probe (~40 s) | `godot --headless --path . res://tests/month_probe.tscn -- --days=35 [--calibrate]` |
| Test bridge | `python tools/bridge.py launch` then `new`, `buttons`, `click "…"`, `errors`, `screenshot`, `monkey` (plays in slot 2, "Autoplay Slot") |
| Bug-test benchmark (~10 min) | `python tools/bridge.py run bugtest_benchmark [--minutes N] [--movie]` (report in `bridge_runs/`; cloud: start the game under `xvfb-run -a -s "-screen 0 1600x900x24"` first) |
| Icon placeholders | `python3 tools/make_icons.py` |
| Windows exe | Editor: Project > Export > Windows Desktop (see README), or `build-exe.bat` |

## GDScript traps that bit this project

* Lambdas capture locals by value: keep late-assigned values (a modal) in a Dictionary holder.
* `:=` can't infer from Dictionary values or untyped calls: give those an explicit type.
* A wrapping Label measured before its container has a width reports a huge height: give it a min width.
* `Sfx` and `Music` do nothing headless; tests read `Sfx.last_played` and `Music.wanted()`.
* Don't shadow built-ins or members (`sign`, `size`, `name`) in parameters and locals: it's a warning.
