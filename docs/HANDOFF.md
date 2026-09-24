# Handoff: where the Godot rebuild stands

For the next session (local or cloud, any model). Read this, then `docs/DECISIONS.md` (the long record of what was
decided and why) and `README.md` (how to run things).

## Ground rules

- The Godot project is at the repo root (`project.godot`); `CLAUDE.md` is the short version of these rules. The
  old web build is archived on the `web-archive` branch and is never touched. `docs/PROGRESS.md` and
  `docs/plan.md` describe that web build and are history only.
- Work on the branch you were given (this session: `claude/new-session-18lsuu`); don't switch to the old
  `godot-rebuild` branch. Fetch and **merge** before pushing, never rebase or force-push: the designer pushes art
  to the same branch.
- Godot 4.7 GDScript, GL Compatibility, base size 1600×900, UI built in code. Autoloads: Options, Data, Sfx, Music,
  Game, TestBridge. The sim is pure static functions in `scripts/sim/`; the UI is in `scripts/ui/`; content and
  balance are JSON in `data/`. Never hardcode balance numbers.
- Commit as you go with clear messages, and keep `docs/DECISIONS.md` current (it states the test count).
- **Art rule (designer's request):** any new icon gets a prompt in `tools/art/build_icon_prompts.py` and a placeholder
  in `tools/make_icons.py` in the same change; regenerate `docs/art-prompts-icons.md`. The designer's script lists
  what still needs painting. **Don't commit a regenerated `docs/art-prompts-*.md` from a machine without the
  designer's `D:\AI` art folders** (the cloud): the "approved" marks come from that folder and would be wiped.
  Add the prompt to the builder and let the designer's run regenerate the docs.
- **While the designer works on art locally:** don't edit `tools/art/build_icon_prompts.py` or
  `tools/make_icons.py` from the cloud. Put new prompts and placeholder drawings in
  `tools/art/artnew_merge_me_on_pull.md` (say where each block goes) so a pull never conflicts; commit the
  placeholder SVGs themselves as usual.

## Running things

All commands run from the repo root.

- Import once after cloning: `godot --headless --path . --import`.
- Tests: `godot --headless --debug --path . res://tests/test_runner.tscn < /dev/null` (close stdin: with
  `--debug` a script error waits at a debugger prompt), or `tools/check.sh [godot]`. Add `--verbose` to see
  warnings; keep it at zero warnings. Tests that touch save files use slot 99 only, never the player's slots 1–3.
- Driving the running game (real clicks, errors, screenshots): `docs/TEST_BRIDGE.md`.
- Screenshots: `godot --path . res://tests/tour.tscn -- --out=DIR --only=nexus,expeditions,...` (needs a display;
  overwrites save slot 3).
- Pacing probe (about 40 s): `godot --headless --path . res://tests/month_probe.tscn -- --days=35
  [--skills|--rates|--calibrate]`. Its `_combat` rounds party levels down to multiples of 3.

## GDScript traps that bit this project

- Lambdas capture locals by value: keep a modal or other late-assigned value in a Dictionary holder.
- `:=` can't infer from Dictionary values or untyped calls: give those an explicit type.
- `Sfx.play` and `Music` do nothing headless; tests read `Sfx.last_played` and `Music.wanted()`.
- A wrapping Label measured before its container gives it a width reports thousands of pixels of height.
- Tweens that move a fighter are bound to that fighter's node so they die with it.

## Recently done (this session)

**Code review fixes (2026-09-24),** one commit each, see `DECISIONS.md` ("Code review fixes"):
- Saves are written atomically (`.tmp`, then rename); the backup is only ever a readable save, and a leftover
  `.tmp` is loaded before the backup. The slot-rename test no longer writes the player's slot 3 (slot 99 now).
- The Market and Egg Market refuse a buy made from a stock window that has since changed, and refresh once when
  the stock changes. `Market.buy()` refuses 0 or fewer.
- Trait inheritance shuffles with the game's rng (reproducible from a seed). The pause menu's time-away cap counts
  the Pearl Hourglass. Pearls found while away show in Welcome Back. Thorns that knock out an attacker stop its
  multi-target ability. Bulk release reports Pearls.
- Worker bubbles skip frames during the fade to the title; Genesis Pods forget picked parents when the save
  changes; options.cfg is written once a change settles; a broken data file is reported with its line; the
  test bridge's `new` only wipes slot 2 unless forced, and only slot 2 is renamed; the Expeditions log's "ago"
  times tick; three misplaced comments moved; `tools/check.sh` runs the tests like `CLAUDE.md` does.

**Earlier:**

The fixes, all pushed: the Options panel going blank after going fullscreen, the Nexus panel pushed off screen,
music dropping out, blurry text, the Sanctum expedition card not updating, fighters facing the wrong way. The
features: a harder first boss, inherited traits never getting weaker, new nameplates, type-specific attack sounds,
damage numbers that spread out, the owned badge, rarity pips, animated top-tier colours, sprite and frame effects
by rarity, shiny and rare entrance effects, save slots that can be renamed, shiny parents raising the egg's
shiny chance, and Aether Pearls (the endgame currency with six Pearl upgrades in Sanctum Works).

## Bug-test benchmark (new)

`python tools/bridge.py run bugtest_benchmark` (from the repo root or `tools/`, with `GODOT` set or the game
already running with `-- --bridge`) plays ten minutes like a player and writes a PASS/FAIL report to
`bridge_runs/`. See `docs/TEST_BRIDGE.md` ("Scenarios"). Add `--movie` to record animation clips with Movie Maker.

The last cloud run (xvfb, software renderer, seed 1, 8 h compressed) passed: 32 goals claimed in 10 minutes (on
goal 33, `total150`), 45 screens covered, no errors, no invariant breaks, memory 77 → 82 MB. **Not yet run: `--movie`**
(written but untested; run it locally and check the clips section of the report).

What its first runs found and fixed:
- **The Sanctum's goal card never showed Claim for item and counter goals** while you stayed on the Sanctum
  (it only rebuilt on structural changes). It now watches the goal's progress every half second.
- **A Claim click could be lost**: the card was rebuilt on every `Game.changed` (captures, level-ups), freeing
  the button between mouse down and up. It now rebuilds only when the goal or its progress moves.
- Bridge fixes: clicks pick an exact match that's scrolled out of view before a visible partial match; only the
  top dialog's buttons are listed; a button counts as visible only when its centre is in its scroll area.

Still open (bigger than a quick fix): the same "rebuild everything on `Game.changed`" pattern is used by most
screens (skill pages, pods, Works, Market), so a click there can be lost the same way during a busy expedition.
Rebuilding only the parts that changed would fix it for good.

## Not yet seen or heard in the real game (check these first)

- The shiny and rare entrance burst and its two sounds (`shiny_appear`, `rare_appear`), and the type attack sounds.
  None has been heard; the sprite effects' motion (sweep, pulse, orbiting lights, Zenith motes) has only been seen
  as still frames. A small test scene that spawns a shiny and a rare wild Aetherling on demand would help.
- The Options window-mode fix could not be reproduced on Linux (the bug was on Windows fullscreen). The cause was
  found and guarded three ways; confirm on Windows.

## Open for the designer

- Overseer Vance now has 112 goals (was 26), ordered along the month probe. The texts and rewards are a first
  pass: read them in `data/goals.json` and play the first day to see whether the order feels right. The last
  three (three special recipes, 50 species) may be hard; they end the chain, so they block nothing.

- The Market (market.json): egg, work-slot, boost and limited-offer prices are first guesses, since the month
  probe doesn't track gold. Check them against real play, and whether buying materials makes gathering
  feel pointless.
- Vessels now have ten tiers; the five new ones (Gloaming, Prismatic, Emberheart, Stormglass, Celestial) and the
  seven new Market icons need paintings. Their prompts are in `tools/art/artnew_merge_me_on_pull.md`.

- Aether Pearl drop rates are estimates from timed runs (3–7 a day at the end); check them in play.

- Play-test pacing (one-month target) and creature XP. Fights now weigh levels (`combat.levelGap`) and
  Fractured Quarry is tougher; check the early islands feel right.
- Whether work XP should be raised.
- Hybrid art: 135 sprites; the game shows a placeholder blob until then. FLUX prompts could be written.
- Gear stays out (it would upset the balance).
- Cosmetics: `docs/cosmetics.md` lists hats and other ideas to choose from; nothing is built yet.

## Ideas worth doing next

- A dev scene to preview every rarity effect, entrance and sound together.
- Rarity pips and effects in the Aether-Log and the hatch reveal (they already show wherever a portrait is used; check
  that each looks right).
- A "Dev tools" button to jump an expedition straight to a shiny or boss wave, for testing.
