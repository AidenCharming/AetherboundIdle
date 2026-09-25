# Handoff: where the Godot rebuild stands

For the next session (local or cloud, any model). Read this, then `docs/DECISIONS.md` (the long record of what was
decided and why) and `README.md` (how to run things).

## Ground rules

- The Godot project is at the repo root (`project.godot`); `CLAUDE.md` is the short version of these rules. The
  old web build is archived on the `web-archive` branch and is never touched. Its docs are in
  `docs/archive/web-build/` (history only).
- Work on the branch you were given, **but first check it contains `origin/godot-rebuild`**
  (`git log --oneline HEAD..origin/godot-rebuild` should print nothing). The 2026-09-25 session started from an
  older base, missed a night of fixes and redid some of them; if that command lists commits, merge
  `origin/godot-rebuild` before anything else. Push to your branch and to `godot-rebuild` at the end. Fetch and
  **merge** before pushing, never rebase or force-push: the designer pushes art to the same branches.
- **Session task list (designer's request):** at the start, make a task list (the task tools) with each task's
  percent done and estimated share of the 5-hour usage in its title, e.g. `[40%] Fix X (est. +3%)`. Keep one
  task in progress, update the percent as you go, and after each finished task post a one-line progress note
  (tasks done, overall %, ETA). The designer reports their usage %; use it to re-estimate what's left.
- Godot 4.7 GDScript, GL Compatibility, base size 1600×900, UI built in code. Autoloads: Options, Data, Sfx, Music,
  Game, TestBridge. The sim is pure static functions in `scripts/sim/`; the UI is in `scripts/ui/`; content and
  balance are JSON in `data/`. Never hardcode balance numbers.
- Commit as you go with clear messages, and keep `docs/DECISIONS.md` current (it states the test count).
- **Version number (designer's request):** any major code, balance, UI or icon change bumps the version in
  `project.godot` (`config/version`, shown on the title screen) and `export_presets.cfg` (`file_version`,
  `product_version`) in the same change. Semantic: minor (0.3.0 -> 0.4.0) for new systems, balance passes, UI
  reworks or new art sets; patch (0.3.0 -> 0.3.1) for smaller fixes. Note the new number in `docs/DECISIONS.md`.
  Current: 0.3.0 (2026-09-25).
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
- Tests: `godot --headless --path . res://tests/test_runner.tscn < /dev/null`, or `tools/check.sh [godot]`. Not
  `--debug`: a script error then stops at a debugger prompt forever, even with stdin closed (seen on Windows).
  The runner counts script errors, so a test that crashes fails instead of printing `ok`. Warnings only print
  with `--debug`, so `-- --warnings` loads every script in `scripts/`, `tests/` and `tools/` in that mode without
  running any and fails on any warning; `tools/check.sh` runs both. Keep it at zero warnings. Tests that touch save files use slot 99 only, never the player's slots 1–3.
- Driving the running game (real clicks, errors, screenshots): `docs/TEST_BRIDGE.md`.
- Screenshots: `godot --path . res://tests/tour.tscn -- --out=DIR --only=nexus,expeditions,...` (needs a display;
  overwrites save slot 3).
- Pacing probe (about 40 s): `godot --headless --path . res://tests/month_probe.tscn -- --days=35
  [--skills|--rates|--calibrate|--split]`. Its `_combat` rounds party levels down to multiples of 3. `--split`
  (8 s) prints, per island, how much stronger its waves alone and its boss alone can get before the calibration
  party stops winning: keep waves near x1.45 everywhere and each boss a little tougher (about x1.3).
- Big rosters: Developer tools > "Every Aetherling" grants 3,726 (every species, form, rarity, shiny). Use it
  to check a change doesn't slow the game with thousands of Aetherlings.

## GDScript traps that bit this project

- Lambdas capture locals by value: keep a modal or other late-assigned value in a Dictionary holder.
- `:=` can't infer from Dictionary values or untyped calls: give those an explicit type.
- `Sfx.play` and `Music` do nothing headless; tests read `Sfx.last_played` and `Music.wanted()`.
- A wrapping Label measured before its container gives it a width reports thousands of pixels of height.
- Tweens that move a fighter are bound to that fighter's node so they die with it.

## Latest (2026-09-25, third session, v0.4.1)

- **Even cards:** every Market tab (stock, vessels, materials, boosts, work slots) gives all its cards the size of
  the largest, so a locked card is as big as an open one (`UI.even_sizes`, measured one frame after the flow
  enters the tree, once the theme applies and nested chip rows have wrapped). Use it for any other grid of cards.
- Fixed a Nexus error (a delayed scroll ran after its list was freed; now `set_deferred`).
- **Designer's request, not started: sharp text and icons at every resolution.** The game lays out at
  1600x900 and `canvas_items` stretches it (1.2x at 1920x1080, times the Interface scale). MSAA won't help
  (it only smooths drawn shapes). Try, comparing 1920x1080 screenshots: font hinting none instead of light
  (`theme_factory.gd`), turning off `2d/snap/snap_2d_transforms_to_pixel`, checking font oversampling at
  non-integer scales, and 512 px icons instead of 256 (`icon_runner.py finish --size`, sources in D:\AI).
  The designer also dislikes icons that look different sizes anywhere.

## Start here (2026-09-25, second session: merged into godot-rebuild)

This session's branch (`claude/vigilant-meitner-d7539t`) started from before last night's work, then merged
`godot-rebuild` in; both branches now hold everything. Done (details in the commits and `DECISIONS.md`):
- **Wild forms (designer's request):** a wild Aetherling rolls its form, capped by its level: Form 1 anywhere,
  Forms 1-2 from Lv 20, 1-3 from Lv 40 (`creature.wildForm`). Creatures store `form`; one caught below its
  level's form evolves one form per level-up. Replaces last night's `combat.wildFormUp`.
- **Expedition curve:** bosses were pushovers from island 5 on (they broke at x2.1-2.4 against waves at
  x1.24-2.15). Islands 2-10 now have one wave margin (x1.45) and bosses slightly tougher than their waves;
  first clears days 1,1,1,2,3,6,7,10,14,22; skills 99 by day 33. The last gap (Stormsea to Zenith) is gated by
  breeding to Zenith rarity, not by stats.
- **Big rosters:** a roster index in `GameState` (workers per skill, perch holders; outside the save, rebuilt
  when a creature is added, removed, changes job or rerolls traits: call `GameState.roster_changed()` if you
  add another such place). The Nexus and creature picker build 120 cards at a time. 3,726 Aetherlings went
  from ~1 fps to normal.
- **Bulk release:** rarity range over all tiers, type, species, level cap, keep the best N of each species,
  opt-ins for shinies and working ones, a live preview with why each other one stays.
- Dev tool: grant one species or all of them in every form, rarity and shiny.
- Kept from last night where both fixed the same thing: the closing-dialog fix, Works Build buttons, the
  benchmark's exact island pick, the hold-the-rebuild-while-the-mouse-is-down, the Nexus dropdowns, sorting
  and Put to work menu.

**Next session: rarity balancing (designer's pick).** Read this file, then work on the early-game balance
item below; the designer runs the bug-test benchmark locally. **The designer adds: rare rarities pop up too
often on expeditions; include the wild rarity odds (`rarityWeights` per zone in `data/zones.json`, the Glimmer
Lure) in the balance pass.** A friend played 3–4 hours on 2026-09-24 and loves it so far.

**Still open:** the early-game balance item below (a Luminous party at Lv 1-3 beating Old Thicketroll; breeding
two Steadys into Gleaming) was not touched; `month_probe --split` can measure it.

## Earlier: after merging claude/new-session-18lsuu into godot-rebuild

Done this round (details in the commits): XP from every kill shows at once (fighters refresh on level-up, ally
XP bars); fish drop on islands 1-3 so Cooking works before Aqueous; closing dialogs no longer eat clicks (the
bridge bugs, benchmark re-run PASS); Sanctum Works Build buttons stay live; every sidebar tab has a rebindable
key (Options > Controls; 1-9 in sidebar order, F1-F10 and F12 for skills, F11 stays fullscreen) shown as a
keycap; egg speed-ups cost about the egg's Aether; bulk release by level; pickers show status under the note;
Fill empty slots (Best time removed); Nexus filters as one row of dropdowns and a tidier detail panel; wild
Aetherlings sometimes a form or two up (`combat.wildFormUp`); idle breathing/sway/hop on sprites; Sturdy
Vessels only in Vessel Crafting (Fabrication's duplicate recipe removed).

**Still open:**
1. **Balance** (the friend's hour: Gleaming by breeding two Steadys, many Minor/Major traits, a Luminous
   Mossgear party at Lv 1-3 beating Old Thicketroll). Not changed yet. Candidates: a gentler Dim → Faint →
   Steady `statMultiplier` ramp in `data/rarities.json`, breeding `mutationPlusOne` / `ceilingByTier`, trait
   strength odds, Mossgear's lean. Measure with `tests/balance_probe.tscn` and the month probe.
2. Windowed mode small text (see DECISIONS); the parse-error-exits-0 test runner issue below.
3. The sidebar is 276 px wide now (keycaps); Sanctum station cards are 288 px so they stay two across.

Tools that helped: `tests/tour.tscn` now takes `--size=WxH` and `--ui-scale=N`, and has shots named
`autobind`, `attune`, `folded`, `tooltip`, `milestones` (run under `xvfb-run -a -s "-screen 0 1920x1400x24"`
in the cloud). A new `class_name` needs `godot --headless --path . --import` before the tests see it.
**The test runner exits 0 even when a test file fails to parse** (the parse errors print, the suite still
passes); watch for `SCRIPT ERROR` in its output. Fixing that in `tests/test_runner.gd` would be worth it.

## Recently done (this session)

**Second code review (0.4.0),** see `DECISIONS.md` ("Code review fixes, second review"): crashing tests fail and
warnings are a separate enforced check; session-start and pre-import save copies; checked imports; thorns,
Nexus paging and stable sort, the bridge refuses HTTP, bad inputs refused, eight numbers moved to data.
**Dev tools:** "Next wave: boss / a shiny / the rarest rarity" (see the real entrances and sounds in the
arena) and "Rarity preview" (every rarity plain and shiny, any species and form, a button per sound).
**Art:** every vessel tier and Market icon is painted (checked 2026-09-25).

**Repo housekeeping:** `.gitattributes` forces LF (the ~390 "changed" `.import` files were CRLF/LF noise, not
edits). Finished and web-era docs moved to `docs/archive/` (see its README); the `art-*` docs stay where the art
window expects them.

**Bulk release switches (0.3.1):** "Release shinies too" and "Release working ones too" were plain
CheckButtons, whose icon the theme blanks, so they showed as bare text. They are `ToggleSwitch`es now, and the
filters and switches each sit on an Inset card like the Options pages.

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

- **Clicks lost on the other screens** (skill pages, pods, Works, Market, which rebuild on every `Game.changed`):
  fixed in `Main`. While the left mouse button is held, a `Game.changed` only marks the screen as owed a rebuild;
  it runs just after the release (deferred, so the click lands on the button first). Rebuilding only the parts
  that changed would still be nicer for performance, but clicks are no longer lost.

## Not yet seen or heard in the real game (check these first)

- The shiny and rare entrance burst and its two sounds (`shiny_appear`, `rare_appear`), and the type attack sounds.
  None has been heard; the sprite effects' motion (sweep, pulse, orbiting lights, Zenith motes) has only been seen
  as still frames. The shiny entrance and burst were seen working on 2026-09-25 (bridge screenshot); hear them
  with Developer tools > "Next wave: a shiny" / "the rarest rarity", and "Rarity preview" plays every sound.
- The Options window-mode fix could not be reproduced on Linux (the bug was on Windows fullscreen). The cause was
  found and guarded three ways; confirm on Windows.

## Open for the designer

- Overseer Vance now has 112 goals (was 26), ordered along the month probe. The texts and rewards are a first
  pass: read them in `data/goals.json` and play the first day to see whether the order feels right. The last
  three (three special recipes, 50 species) may be hard; they end the chain, so they block nothing.

- The Market (market.json): egg, work-slot, boost and limited-offer prices are first guesses, since the month
  probe doesn't track gold. Check them against real play, and whether buying materials makes gathering
  feel pointless.

- Aether Pearl drop rates are estimates from timed runs (3–7 a day at the end); check them in play.

- Play-test pacing (one-month target) and creature XP. Fights now weigh levels (`combat.levelGap`) and
  Fractured Quarry is tougher; check the early islands feel right.
- Whether work XP should be raised.
- Hybrid art: 135 sprites; the game shows a placeholder blob until then. FLUX prompts could be written.
- Gear stays out (it would upset the balance).
- Cosmetics: `docs/cosmetics.md` lists hats and other ideas to choose from; nothing is built yet.

## Ideas worth doing next

- Rarity pips in the hatch reveal: check one hatch (the Aether-Log's cards and collected-rarity dots were
  checked 2026-09-25 and look right).
