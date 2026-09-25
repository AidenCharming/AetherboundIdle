# Aetherbound (Godot rebuild): changelog

Everything that is done or fixed, newest first, with the reasons. `HANDOFF.md` has what is open now;
`DECISIONS.md` has how each system works and why. Player-facing notes are in `data/patch_notes.json`.

## 0.6.3a (2026-09-25): third code review, Nexus speed, first-run window, version letters

- **Version letters (designer's request):** the numbers climb slowly. Minor only for a new system, patch for a
  rework or balance pass, a letter for small fixes (0.6.3a, exported as `0.6.3.1`). `test_content` orders
  letters and checks the export matches.
- **Third code review** (`docs/codereview.md`, v0.6.3):
  - #1: the `--warnings` pass loaded cached scripts, so the autoloads' classes (most of `sim/`) were never
    checked. Each script is compiled afresh (not the runner itself, whose fresh copy replaced it mid-call).
    Proved by planting an unused local in `creatures.gd`.
  - #5: a `push_error` from game code fails the test (engine messages, like the headless shader compiler's,
    don't); `t.expect_error(text)` for one triggered on purpose.
  - #2: an import whose containers or creatures aren't records is refused before `migrate` can stop on it.
  - #3: `slot_N.session.prev.json` keeps the session copy from a launch earlier; a load that falls back to a
    session copy notifies the player.
  - #4: `dev_next_wave` during the rest after a wipe starts a fresh run first.
  - #6: portraits animate (rarity frames, shiny glints, bob) only while on screen: scrolled-out Creaturedex
    cards counted as visible.
  - #7 (design call: reveal less): the Show bar's Form 2/3 keep a never-seen species at its Form 1 shape; its
    page has no thumbnails.
  - #8 / HANDOFF small text: first run picks the largest window that fits the screen (≤ 1920×1080) and the
    1.15 interface scale when it's smaller. `power_rating` weights moved to `tuning.creature.powerRating`.
  - #9 stale 1600×900 text; #10 `Sfx.sound_names()` and preview buttons that play with their group off.
  - Still deferred to the designer: #10–#12 of the first review (dev tools in release builds,
    `.claude/settings.json`, `levelTimes` on the wall clock).
- **Nexus refresh (HANDOFF performance):** 109 ms → 12 ms a `Game.changed` with 600 Aetherlings. Cards carry
  their look (`CreatureCard.look`); unchanged ones stay in the grid and are only moved into sorted order.
  (Re-adding them to the tree was itself 50 ms, so they are never removed.)
- **Benchmark `--movie` stats:** the stats step started Godot with `--path tools` (the root was worked out one
  level short from `tools/scenarios/_player.py`), so `res://tools/frame_stats.gd` never loaded and the report
  only said "no such file". Fixed; a failed stats run now reports Godot's last lines. The bridge also writes
  `bridge_runs/.gdignore`, so Godot (and an open editor) stops importing run frames as project files.
- **Bridge games keep their frame rate in the background** (designer noticed runs capped while unfocused):
  `Options.full_fps_in_background`, set when started with `--bridge`. They still mute when unfocused.
  Not confirmed on a full run yet (the designer runs benchmarks).

## 0.6.3 (2026-09-25): the Aether-Log species page and the Creaturedex Show bar

- **Species page (designer asked for it).** The old page put three 204 px portraits in a row, each description
  squeezed into its column, so the columns came out uneven. Now it shows one form at a time: a 260 px portrait
  on the left with the three forms as clickable thumbnails (silhouettes until found), opening on the highest
  form found; on the right, at full width, the form's name, "Form N of 3 · grows into it at Lv X · stats ×Y"
  (from `formLevels` / `formStatMult`), its description, then the types, skills, signature trait and ability,
  rarities owned, shiny colours and where to find it.
- **Show bar on the Creaturedex (designer's request).** Best form / Form 1 / Form 2 / Form 3, plus Highest
  rarity (the card shows the top rarity owned, with its frame and shader) and Shiny (the shiny hue once one
  is caught). A form not found shows as a plain silhouette.
- The patch notes have an "Aether-Log" area colour. The tour has a `dexpage` shot.
- Tests: `test_aetherlog_species_page_shows_one_form_at_a_time`, `test_aetherlog_cards_show_chosen_form_rarity_and_shiny`.

## 0.6.2 (2026-09-25): sprites for the 45 hybrids and specials

- 103 creature sprites into `assets/creatures/`: Forms 1 and 2 of all 15 hybrids and 30 specials, and Form 3 of
  the 13 approved so far (Ashwood, Mosscoil, Cinderbasin, Gloamforge, Quakeforge, Embersurge, Brinecore,
  Hazelslate, Coalgrub, Nethershale, Brackensear, Coralpeep, Eclipseed). Cut out from `D:\AI\sprites\approved\`
  with `sprite_tools.py cutout --size 512` (default settings, checked on the dark plate). No code change: the game
  loads `<id>-f<form>.png` by name, and a form without a file keeps the placeholder blob (the designer is fine with
  that until the other 32 Form 3s are approved).
- `docs/art-prompts.md` rebuilt from `D:\AI\tools\build_prompts.py`: a Form 3 redo table (EVO3) for the 32
  weak Form 3s: a new pose, a size stated relative to Form 2, and lost signature parts back in the keep list.
  Designer's rule: a weak Form 3 is regenerated, never approved as a compromise.

## 0.6.1 (2026-09-25): painted icons, benchmark fixes

- The designer's paint pass: 111 item icons and 40 interface icons, plus `docs/art-prompts.md` from their art
  run (every species has prompts; Form 3 sprites are being made).
- **Bridge:** `_reveal` (scrolling a button into view) now checks the button still exists on every wheel turn.
  A screen that rebuilds while it scrolls (the Aether-Log after a milestone Claim) freed it, which raised a script
  error and made the benchmark report "2 milestone rewards still claimable". It now finds the new button (up to
  3 tries).
- **Benchmark:** after picking an island it waits 0.3 s before clicking Explore/Move here. The click came in the
  same instant as the panel redraw and was lost ("clicked 'Move here' but the expedition is at ..."). The game's
  own start/move code was fine.
- **Font hinting:** tried none instead of light at 1920x1080 (1:1). No visible difference, so light stays. The
  sharpness item left is 512 px icons, which waits on the art pipeline.
- The test runner already fails on a test file that doesn't compile (checked with a broken file: `FAIL ...
  (does not compile)`, exit 1); the old HANDOFF note saying otherwise was stale.
- The designer confirmed the Sanctum "claim!" chip is what they meant by "a tooltip on the nexus for missions
  ready to collect". 160 tests.

## 0.6.0 (2026-09-25): patch notes, sound switches, item sources, claim chip

- **Patch notes on the title screen.** `data/patch_notes.json` holds every Godot version newest first (0.2.0 on;
  the 0.1.x builds were the web game). Each change is `[area, text]`, shown as "Area: text" (UI, Nexus,
  Expeditions, ...), grouped as New / QOL / Bugfixes / Balancing, with filter chips (`PatchNotes` widget, right
  side of the title). **Add an entry with every version bump**: a test checks the newest entry matches
  `config/version`, the order, the kinds and that each area has a colour (`PatchNotes.AREA_COLORS`).
  **The notes are for players:** no developer tools, code, data files, engine or tooling. The version shows only
  on the patch notes (the title's bottom line just says progress saves automatically).
- **A switch per kind of sound** (Options > Audio): rare finds, notifications, battle, interface (`Sfx.GROUPS`,
  options `sfx_rare`, `sfx_notify`, `sfx_battle`, `sfx_ui`). Sounds are grouped by name (`Sfx.GROUP_OF`; `hit_*`
  and `cast_*` are battle, anything unlisted is interface). Switching a kind on plays one of its sounds.
- **Where to get it** (Inventory detail): `Economy.sources(id)` lists skill actions that make the item, rare finds
  and treasure (chance per action), island loot (chance per wild beaten, amount), boss rewards and the Market, at
  base odds. Sources not reached yet are dimmed. The detail panel now scrolls.
- **Ready to claim:** the Sanctum rail tab shows a gold "claim!" chip when Overseer Vance's goal is done, with the
  goal in its tooltip; the Pods and Expeditions chips got tooltips too. The Aether-Log already had its claim chip.
  160 tests.

## 0.5.2 (2026-09-25): smoother edges

- Code-filled polygons (rarity pips, portrait and frame sparkles) had hard edges, since Godot fills polygons
  without anti-aliasing; `UI.fill_polygon` adds a thin anti-aliased outline in the same colour.
- The first run on a screen 1440 px wide or less starts the Interface scale at 115%. Textures were checked: all
  build mipmaps.

## 0.5.1 and 0.5.0 (2026-09-25): sharp art, 1920x1080 base

- **Linear texture filtering (0.5.1).** `rendering/textures/canvas_textures/default_texture_filter=2` (Linear
  Mipmap). It was 3, which that setting reads as Nearest Mipmap, so art drawn smaller than its source looked
  jagged. Filled circles drawn in code are anti-aliased, and boxes use 16 corner segments. 155 tests.
- **1920×1080 base (0.5.0).** The designer chose "same size, sharper" over a smaller UI with more room. Every size
  literal in `scripts/ui/` (theme fonts and boxes, helper arguments and defaults, overrides, minimum sizes, offsets,
  drawn pixels, tween distances) was raised ×1.2 and rounded to whole pixels; `project.godot` is 1920×1080. The
  default window stays 1600×900 (a 1920 window doesn't fit a 1080p desktop with a taskbar). 155 tests.

## 0.4.1 (2026-09-25): even card sizes

- The designer wants no uneven cards: a locked Market card was smaller than an open one. `UI.even_sizes(flow)` sets
  every card to the largest card's real size a frame after the flow is shown (earlier, before the theme and
  wrapping apply, the sizes are wrong). All five Market tabs use it. 155 tests.
- The 1920x1080 question was asked and answered (see 0.5.0).

## 0.4.0 (2026-09-25): second code review

The review is in `docs/archive/done/codereview-2026-09-25.md`. Fixed, one commit each group:
- **Tests (#2):** a runtime error aborted a test without a failure, so it printed `ok`. The runner counts script
  errors with a `Logger`. Under `--debug` the error instead stopped at a debugger prompt forever (Windows, even
  with stdin closed), so the tests run without `--debug`, and `-- --warnings` loads every script in `--debug`
  without running any and fails on a warning. That found 7 warnings in the month probe and tour.
- **Saves (#1, #7):** `slot_N.session.json` (the save as the session started, never autosaved over, the last
  load fallback) and `slot_N.pre-import.json` (the game an import replaced). An import is migrated on a copy
  and refused unless its containers have the right shape. The autosave trusts a main file it wrote itself
  while its size is unchanged instead of parsing it every 20 s.
- **Combat (#4):** a fighter knocked out by thorns during its own ability no longer attacks in that substep.
- **UI (#5, #6):** a `Game.changed` refresh keeps the Nexus pages shown and the scroll; `UI.sort_by_key` is
  stable. `Main.instance` is cleared when the game screen leaves the tree.
- **Bridge (#3):** a connection whose first line looks like HTTP is dropped before its body can run.
- **Actions (#9):** bad breeding tiers, egg grades or types, milestone tracks or indices and missing Aetherlings
  are refused in the sim.
- **Data (#8):** `shiny.hatchPityMax`/`hatchCap`, `aether.releaseLevelsPerStep`/`releasePerForm`,
  `combat.healBelow`/`bossXpRarity`/`firstClearLevelBelowBoss`, `market.offerQtyBase` (same values as before).
- **Not changed:** #12 (`levelTimes` uses the wall clock; nothing reads it), #10 (dev tools in release builds)
  and #11 (`.claude/settings.json` allows all Bash) wait for the designer.

## 0.3.0 and 0.3.1 (2026-09-25): play-test fixes, version rule

- **Bulk release switches (0.3.1):** "Release shinies too" and "Release working ones too" were plain
  CheckButtons, whose icon the theme blanks, so they showed as bare text. They are `ToggleSwitch`es now, and the
  filters and switches each sit on an Inset card like the Options pages.

### Version 0.3.0 and a version rule

- Bumped to **0.3.0** (`project.godot` `config/version`, shown on the title screen; `export_presets.cfg` file and
  product version) for the 2026-09-25 bug-fix and balance work. From now on any major code, balance, UI or icon
  change bumps the version in the same change (minor for big changes, patch for small ones); see `CLAUDE.md`.
- **Merge fix:** a local commit (party XP event per kill, `8db3007`) and the cloud's `_party_xp` (refreshes a
  fighter who levels mid-run) did the same job twice after the merge, and wild kills lost the `party_xp` event.
  They are now one `_party_xp` that does both; the offline path calls it with an empty battle. 150 tests.

### Expeditions: bosses a match for their waves

- **The problem:** a friend got stuck on later islands' waves until he levelled, then beat their bosses easily.
  `month_probe --split` measures, for each island's calibration party, the strength factor at which the waves
  alone (boss made trivial) and the boss alone (waves made trivial) beat it. Bosses from Thunderhum Steppe on
  broke at x2.1-2.4 while the waves broke at x1.24-2.15, unevenly.
- **Now** islands 2-10 have their waves at about x1.45 and their boss at about x1.3 (a little tougher than the
  waves; Stormsea x1.49), by scaling each island's `enemyMult` and boss `mult`. Old Thicketroll stays the wall
  the designer asked for. Stormsea (x0.87), Magmaglass (x0.97) and Zenith (x0.92) were then eased to spread the
  clears: days 1, 1, 1, 2, 3, 6, 7, 10, 14, 22 (was 1, 1, 1, 2, 3, 4, 6, 8, 12, 24). Zenith Spire waits on
  breeding a Zenith party, so easing it further doesn't move it.

### Big rosters stay smooth

- With the 3,726 Aetherlings of the new dev tool the game ran at ~1 fps: the perches sorted the whole roster
  every tick (working out each rate once per comparison, 469 ms), and workers per skill and auras scanned
  every creature every frame. `GameState` now keeps a roster index (workers per skill, perch holders) outside
  the save, rebuilt only when a creature is added or removed, changes job, or rerolls traits
  (`GameState.roster_changed()`), or when another save is loaded. Perch holders are picked in one pass.
- The Nexus and the creature picker build 120 cards at a time with a "Show more" button (`UI.fill_paged`) and
  sort on keys worked out once (`UI.sort_by_key`; the same orders as before). Opening the Nexus with 3,726:
  32 s and 737 MB before, 2 s and 104 MB after.

### Bulk release, fuller

- A friend found it wouldn't release shinies and sometimes released nobody: it silently kept shinies and
  working ones and only went up to Gleaming. It now takes a rarity range over all tiers, a type, a species, a
  level cap, how many of each species to keep (default 1, by rarity, then level, then shiny), and opt-ins for
  shinies and working ones (they leave their jobs). Locked ones, the party and your last Aetherling always stay.
  The preview lists who goes, the Aether and Pearls, and how many stay for each reason; releasing nobody says so.

### Merging the two 2026-09-25 sessions

- This session started from before `godot-rebuild`'s night of fixes. Where both fixed the same thing, the
  better version stayed: `godot-rebuild`'s closing-dialog fix (it also disables focus), Works Build buttons,
  benchmark island pick and hold-the-rebuild; its Nexus dropdowns, sorting and Put to work menu (with this
  session's paging on top). This session's wild-form rule replaced `combat.wildFormUp` (designer's choice).

### Play-test feedback, first round

A friend's first hours of play, reported with screenshots. Each change is its own commit.
- **The window stays maximized.** `Options.apply()` ran on every option change and every alt-tab and set the
  window size again, undoing a maximize. Window mode and size now apply only at start-up and when one of them
  changes (`Options.WINDOW_KEYS`); picking a size still leaves a maximized window. **Alt+Enter and F11** switch
  between a window and the fullscreen kind used last.
- **Market stock discounts are real.** Material and vessel offers are priced by the lot (per-unit rounding ate
  the 10% on 3-gold Scrap), never below the lot's sell-back value, and the chip shows the true discount. Boost
  offers follow the boost's current price (it grows per island cleared) instead of the price at roll time.
- **Attune locks cost by strength:** `attunement.lockMultByStrength` (Minor ×1.5, Moderate ×2.25, Major ×3)
  replaces `lockMult` by count; two Major locks still cost ×9. The designer asked for Minor to be cheaper.
- **UI:** `ToggleSwitch` (an anti-aliased, sliding switch drawn in code) replaces the pixel texture switch;
  Attune uses Lock pills. The panel under the battle keeps the tallest tab's height. Folded panels show their
  icon with an arrow. Binds and escapes in the log show the chance they had. The rail shows the game icon,
  keycaps for number-key shortcuts, and the mouse's back/forward buttons walk page history. Tooltips are styled
  cards (0.35 s delay); item chips show a rich card with what the item is for (`Economy.uses`). The Inventory
  lists an item's uses, calls items nothing uses "treasure", and has **Sell treasure**; its tiles have bright,
  two-line names and a count pill. Aether-Log milestone cards are roomier. Task cards read as a recipe:
  Uses each time / Makes / Sometimes finds, with live counts.
- **Windowed text:** checked at 1280×720. The font settings already render best (hinting light); text is small
  because the 1600×900 layout is scaled to 80%. A bigger scale floor overflows the Expeditions page (its log
  column is cut), so that needs the layout to reflow narrower first. Not changed.

## 2026-09-24 and earlier

### Code review fixes (2026-09-24)

A review of the whole repo found save, purchase and correctness bugs; each fix is its own commit with a test.
- **Saves are atomic.** `Game._write_slot()` writes `slot_N.tmp.json`, copies the old main file to the backup
  only if it parses, then renames `.tmp` into place. Before, a crash mid-write left a broken main file, and the
  next autosave copied it over the good backup. Load order is main, `.tmp`, backup. The no-re-roll rule is
  unchanged (the rng state is still saved with every save). `tests/test_saves.gd` uses slot 99 only; the old
  slot-rename test wrote the player's real slot 3.
- **A Market buy names its stock window.** The stock changes every `rotation.hours`; a page showing the old stock
  could buy index i of the new one (another item, another price). `Market.buy_offer`/`buy_featured` take the
  window the page showed and refuse when it moved on; the screens refresh once when it does. `Market.buy()`
  refuses a quantity of 0 or less instead of reporting "Bought 0×".
- **Every sim roll uses the game's rng:** `Rng.shuffle()` replaces `Array.shuffle()` in trait inheritance.
- **One time-away cap:** `GameState.offline_cap_hours()` (Dream Anchor + Pearl Hourglass), used by
  `Offline.apply` and the pause menu, which showed the Anchor alone.
- Pearls found while away reach Welcome Back; thorns that knock out an attacker end its multi-target ability;
  bulk release reports Pearls like a single release.
- UI: worker bubbles skip frames while the state is empty (the fade to the title); Genesis Pods forget picked
  parents when the slot or save changes; the Expeditions log's "ago" times update every second without a rebuild.
- **Lost clicks:** `Main` holds a `Game.changed` screen rebuild while the left mouse button is down and runs it
  just after the release, so a capture or level-up can't free the button being clicked (found by the bug-test
  benchmark on skill pages, pods, Works and the Market).
- Robustness: options.cfg is written 0.4 s after the last change (and on quit), not on every slider tick; a
  broken data file is reported with its line through `push_error`, which release builds keep (assert is
  stripped); the test bridge's `new` only wipes slot 2 unless forced, and only slot 2 is renamed.
- Tools and docs: `tools/check.sh` runs the tests with `--debug` and stdin closed; `docs/HANDOFF.md` describes the
  flattened repo.

### Bug-test benchmark: first runs (2026-09-24)

`python tools/bridge.py run bugtest_benchmark` plays ten minutes like a player and writes a PASS/FAIL report to
`bridge_runs/` (see `docs/TEST_BRIDGE.md`). The first cloud run (xvfb, seed 1, 8 h compressed) passed: 32 goals,
45 screens, no errors, memory 77 → 82 MB. What its first runs found and fixed:
- **The Sanctum's goal card never showed Claim for item and counter goals** while you stayed on the Sanctum (it
  only rebuilt on structural changes). It now watches the goal's progress every half second.
- **A Claim click could be lost**: the card was rebuilt on every `Game.changed`, freeing the button between mouse
  down and up. It now rebuilds only when the goal or its progress moves.
- **Clicks lost on the other screens** (skill pages, pods, Works, Market): while the left mouse button is held, a
  `Game.changed` only marks the screen as owed a rebuild; it runs just after the release.
- Bridge: clicks pick an exact match scrolled out of view before a visible partial match; only the top dialog's
  buttons are listed; a button counts as visible only when its centre is in its scroll area.

### Earlier fixes and features

- Fixes: the Options panel going blank after going fullscreen, the Nexus panel pushed off screen, music dropping
  out, blurry text, the Sanctum expedition card not updating, fighters facing the wrong way.
- Features: a harder first boss, inherited traits never getting weaker, nameplates, type-specific attack sounds,
  spread-out damage numbers, the owned badge, rarity pips, animated top-tier colours, sprite and frame effects by
  rarity, shiny and rare entrance effects, renamable save slots, shiny parents raising the egg's shiny chance, and
  Aether Pearls (the endgame currency, six Pearl upgrades in Sanctum Works).
- Dev tools: "Next wave: boss / a shiny / the rarest rarity", "Rarity preview" (every rarity plain and shiny, a
  button per sound), grant one species or all of them in every form, rarity and shiny.
- Repo: `.gitattributes` forces LF (the ~390 "changed" `.import` files were line-ending noise). Finished and
  web-era docs moved to `docs/archive/`.
