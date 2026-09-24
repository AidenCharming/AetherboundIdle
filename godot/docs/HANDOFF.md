# Handoff: where the Godot rebuild stands

For the next session (local or cloud, any model). Read this, then `docs/DECISIONS.md` (the long record of what was
decided and why) and `README.md` (how to run things).

## Ground rules

- Work in `godot/` on branch `godot-rebuild`. The web build on `main` (`src/`, `electron/`, top-level files) is
  never touched.
- Godot 4.7 GDScript, GL Compatibility, base size 1600×900, UI built in code. Autoloads: Options, Data, Sfx, Music,
  Game. The sim is pure static functions in `scripts/sim/`; the UI is in `scripts/ui/`; content and balance are JSON
  in `data/`. Never hardcode balance numbers.
- Commit as you go with clear messages, keep `docs/DECISIONS.md` current (it states the test count, now 86), and
  push to `godot-rebuild`.
- **Art rule (designer's request):** any new icon gets a prompt in `tools/art/build_icon_prompts.py` and a placeholder
  in `tools/make_icons.py` in the same change; regenerate `docs/art-prompts-icons.md`. The designer's script lists
  what still needs painting.

## Running things

- Tests: `godot --headless --debug --path godot res://tests/test_runner.tscn < /dev/null` (close stdin: with
  `--debug` a script error waits at a debugger prompt). Add `--verbose` to see warnings; keep it at zero warnings.
- Screenshots: `godot --path godot res://tests/tour.tscn -- --out=DIR --only=nexus,expeditions,...` (needs a display).
- Pacing probe (about 40 s): `res://tests/month_probe.tscn -- --days=35 [--skills|--rates|--calibrate]`. Its
  `_combat` rounds party levels down to multiples of 3.

## GDScript traps that bit this project

- Lambdas capture locals by value: keep a modal or other late-assigned value in a Dictionary holder.
- `:=` can't infer from Dictionary values or untyped calls: give those an explicit type.
- `Sfx.play` and `Music` do nothing headless; tests read `Sfx.last_played` and `Music.wanted()`.
- A wrapping Label measured before its container gives it a width reports thousands of pixels of height.
- Tweens that move a fighter are bound to that fighter's node so they die with it.

## Recently done (this session)

The fixes, all pushed: the Options panel going blank after going fullscreen, the Nexus panel pushed off screen,
music dropping out, blurry text, the Sanctum expedition card not updating, fighters facing the wrong way. The
features: a harder first boss, inherited traits never getting weaker, new nameplates, type-specific attack sounds,
damage numbers that spread out, the owned badge, rarity pips, animated top-tier colours, sprite and frame effects
by rarity, shiny and rare entrance effects, and save slots that can be renamed.

## Not yet seen or heard in the real game (check these first)

- The shiny and rare entrance burst and its two sounds (`shiny_appear`, `rare_appear`), and the type attack sounds.
  None has been heard; the sprite effects' motion (sweep, pulse, orbiting lights, Zenith motes) has only been seen
  as still frames. A small test scene that spawns a shiny and a rare wild Aetherling on demand would help.
- The Options window-mode fix could not be reproduced on Linux (the bug was on Windows fullscreen). The cause was
  found and guarded three ways; confirm on Windows.

## Open for the designer

- Play-test pacing (one-month target) and creature XP.
- Whether work XP should be raised.
- Hybrid art: 135 sprites; the game shows a placeholder blob until then. FLUX prompts could be written.
- Gear stays out (it would upset the balance).

## Ideas worth doing next

- A dev scene to preview every rarity effect, entrance and sound together.
- Rarity pips and effects in the Aether-Log and the hatch reveal (they already show wherever a portrait is used; check
  that each looks right).
- A "Dev tools" button to jump an expedition straight to a shiny or boss wave, for testing.
