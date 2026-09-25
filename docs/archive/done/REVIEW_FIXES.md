# Aetherbound Idle: code review fixes (2026-09-24)

**For the Claude session working in the GitHub repo.** This file is a work order. Work through it top to bottom
and fix everything under "Fixes" yourself, without asking. Commit each fix on its own. Anything under "Do not
change" or "For the designer" stays as it is.

A code review of the whole flattened repo (every script in `scripts/` and `tests/`, plus `data/`, `project.godot`,
`tools/check.sh`, `tools/bridge.py`, `build-exe.bat` and the docs) produced this list. Line numbers are hints from
the reviewed copy and may have moved, so go by the function names.

---

## 0. Before you start

1. **Read `CLAUDE.md` and follow it.** Above all:
   - Data-driven: a new number goes in `data/*.json`, never in a script.
   - Sim separate from UI: `scripts/sim/` never touches nodes or `Game`.
   - Don't add systems.
   - Tests pass with zero warnings.
   - Keep the test count in `docs/DECISIONS.md` current.
   - Update `docs/HANDOFF.md` and `docs/DECISIONS.md`.
   - Fetch and **merge**. Never rebase or force-push, because the designer pushes art to the same branch.
   - **Don't edit `tools/art/build_icon_prompts.py`, `tools/make_icons.py` or `docs/art-prompts-*.md`.** None of
     these fixes needs them.
2. **The repo is flattened now.** `project.godot` is at the repo root, and the web build is gone (it's on the
   `web-archive` branch). `docs/HANDOFF.md` is out of date on this: it still says `godot/` and `godot-rebuild`.
   Fix 17 corrects it. Until then, trust `CLAUDE.md`. Work on the branch the repo is on (`git branch --show-current`).
   Don't switch to `godot-rebuild`.
3. **Get Godot 4.7.2 headless** if `godot` isn't on the PATH, for example:
   ```bash
   cd /tmp && curl -L -o godot.zip https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip \
     && unzip -o godot.zip && export GODOT=/tmp/Godot_v4.7.2-stable_linux.x86_64
   ```
   If that exact file isn't there, take the Linux x86_64 build of the newest 4.7.x stable release. It must be the
   standard build (not .NET), because the project is pure GDScript.
4. **Take a baseline before changing anything:**
   ```bash
   $GODOT --headless --path . --import
   $GODOT --headless --debug --path . res://tests/test_runner.tscn < /dev/null            # expect "105 tests … 0 failures"
   $GODOT --headless --debug --verbose --path . res://tests/test_runner.tscn < /dev/null 2>&1 | grep -i warning   # expect nothing
   ```
   If the baseline already fails, or already has warnings, write down which ones before you start. Afterwards,
   you are only responsible for not adding new ones.

---

## Fixes

Do them in this order. For each fix, make the change, add the test (where one is listed), run the whole suite, and commit.

### P1: can lose saves or buy the wrong thing

#### Fix 1: save writes must be atomic, and the backup must never be overwritten with a broken save
**Files:** `scripts/autoload/game.gd`: `save_game()`, `load_game()`, `slot_info()`, `delete_slot()`, `rename_slot()`.

**Problem:** `save_game()` copies `slot_N.json` over `slot_N.bak.json`, then writes `slot_N.json` in place. If
the PC crashes or loses power partway through a write, the main file is left half-written. `load_game()` then
correctly falls back to `.bak`. But the next autosave (every 20 s) copies the broken main file over the good
backup first, so for that moment both copies are bad and one more crash loses the save. `rename_slot()` also
rewrites the main file in place, with the same risk.

**Change:**
- Add `func tmp_path(n: int) -> String: return "user://slot_%d.tmp.json" % n`.
- Add one private writer that `save_game()` and `rename_slot()` both use:
  ```gdscript
  ## Writes a save without ever leaving a half-written main file: the text goes to .tmp first, the old main
  ## file becomes the backup only if it is a readable save, then .tmp is renamed into place.
  func _write_slot(n: int, text: String) -> bool:
  	var main := ProjectSettings.globalize_path(slot_path(n))
  	var tmp := ProjectSettings.globalize_path(tmp_path(n))
  	var f := FileAccess.open(tmp_path(n), FileAccess.WRITE)
  	if f == null:
  		push_error("Could not write %s (%s)" % [tmp_path(n), error_string(FileAccess.get_open_error())])
  		return false
  	f.store_string(text)
  	f.close()
  	if FileAccess.file_exists(slot_path(n)) and _readable(slot_path(n)):
  		DirAccess.copy_absolute(main, ProjectSettings.globalize_path(backup_path(n)))
  	if FileAccess.file_exists(slot_path(n)):
  		DirAccess.remove_absolute(main)   # Windows can't rename over an existing file
  	return DirAccess.rename_absolute(tmp, main) == OK

  func _readable(path: String) -> bool:
  	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
  	return parsed is Dictionary and parsed.has("version")
  ```
- In `load_game()` and `slot_info()`, try the files in the order **main, tmp, bak**. A `.tmp` only survives if a
  crash hit between the remove and the rename, and then it's the newest good save.
- `delete_slot()` removes `.tmp` too.
- `rename_slot()`: in the branch where the slot isn't loaded, call `_write_slot(n, JSON.stringify(parsed))`
  instead of `FileAccess.open(path, WRITE)`.

**Tests:** add `tests/test_saves.gd`. It must use **slot 99** and delete it at the end, and it must never touch
slots 1 to 3. Cover:
1. A reload gives the same next `Game.rng.randf()` (the no-re-roll rule).
2. A half-written main file (`{"version": 1, "creat`) loads from the backup.
3. **After recovering and saving again, `.bak` still parses.** This is the one that fails today.
4. A leftover `.tmp` with a newer `gold`, when main is missing, is what loads.
5. `rename_slot(99, "  X  ")` keeps the backup readable and `slot_info(99).name == "X"`.
6. `delete_slot(99)` leaves no `.json`, `.bak.json` or `.tmp.json` behind.

The test runner prints script errors when it parses the broken JSON on purpose. That's expected output, not a
warning, but check that `--verbose` shows no new *warnings*.

#### Fix 2: a UI test writes to the player's real save slot 3
**File:** `tests/test_ui.gd`, `test_save_slots_can_be_renamed()`.

**Problem:** it overwrites `user://slot_3.json` and holds the original only in a local variable. If anything
errors before the restore, the save in slot 3 on the machine running the tests is lost. That machine is the
designer's own.

**Change:** use slot 99 and `Game.delete_slot(99)` at the end, like Fix 1's tests. Or move this test into
`test_saves.gd`.

#### Fix 3: after the Market stock changes, "Buy" can buy a different offer than the one on screen
**Files:** `scripts/sim/market.gd` (`buy_offer`, `buy_featured`), `scripts/autoload/game.gd` (`buy_offer`,
`buy_featured_egg`), `scripts/ui/screens/market_screen.gd` (`_tick`), `scripts/ui/screens/egg_market_screen.gd`
(`_tick`).

**Problem:** the stock changes every `rotation.hours` of wall-clock time. `MarketScreen._tick()` only refreshes
while `left <= 0.5`, which is *before* the change (and then it defers a full rebuild every frame for about half a
second). Once the stock has changed, `left` jumps back to about 4 h and nothing refreshes. The page keeps showing
the old offers, but `Game.buy_offer(i)` buys index `i` of the **new** stock, which can be a different item at a
different price. The Egg Market's featured egg has the same problem: it can charge a new, different price for a
different species.

**Change:**
- `Market.buy_offer(s, index, now, rng, expect_window := -1)` and `Market.buy_featured(s, now, rng, expect_window := -1)`:
  when `expect_window >= 0 and expect_window != window(now)`, return `"The stock has just changed. Take another look."`
  without charging anything.
- `Game.buy_offer(index, expect_window := -1)` and `Game.buy_featured_egg(expect_window := -1)` pass it through.
- Both screens: store `var _window := -1`, set it in `refresh()` to `Market.window(Game.now_sec())`, and pass it
  to the buy calls. In `_tick()`, call `refresh()` once when `Market.window(Game.now_sec()) != _window`. Remove
  the `left <= 0.5` branch.

**Test:** in `tests/test_market.gd`, roll the stock at a time `t` in window `w`, then call
`Market.buy_offer(s, 0, t + window_seconds(), rng, w)`. It must return an error and leave `gold` and `left`
unchanged. Do the same for `buy_featured`.

### P2: correctness

#### Fix 4: inheriting traits uses Godot's global RNG
**File:** `scripts/sim/breeding.gd`, `inherit()`: `pool.shuffle()`.

**Problem:** `Array.shuffle()` uses the global generator, not the game's `rng`. Every other roll in the sim uses
`rng` (see the rule in `DECISIONS.md` and `scripts/sim/rng_util.gd`). Because of this, trait inheritance (and the
"never weaker" pass after it) can't be reproduced from a seed.

**Change:** add `Rng.shuffle(rng, arr)` to `scripts/sim/rng_util.gd`, a Fisher–Yates shuffle using
`rng.randi_range(0, i)`, and use it in place of `pool.shuffle()`.

**Test:** in `test_breeding.gd`, call `Breeding.inherit` twice with two generators given the same seed, and call
`seed(12345)` / `randomize()` between the two calls. The trait lists must be equal. Use parents with at least four
traits between them, so the order matters.

#### Fix 5: the pause menu understates how long the game works while closed
**Files:** `scripts/sim/offline.gd` (`apply`), `scripts/ui/main.gd` (`open_pause_menu`, about line 411).

**Problem:** `Offline.apply` caps time away at Dream Anchor hours plus Pearl Hourglass hours. The pause menu
shows only `upgrade_value(... "offline-cap")`, so it's wrong once the Hourglass is bought.

**Change:** add `static func offline_cap_hours(s) -> float` to `GameState`, returning the Dream Anchor hours plus
`pearls.offlineHoursPerLevel` × the Hourglass level. Use it in both places. Also grep for any other text that
shows the cap.

**Test:** in `test_sim.gd`, with `pearl-hourglass` at level 2, `offline_cap_hours` is 4 h more than without it,
and `Offline.apply(s, 1e9, rng).usedSeconds` matches it.

#### Fix 6: Aether Pearls found while away never show in the Welcome Back highlights
**Files:** `scripts/sim/offline.gd` (`diff`: the `notable` filter), `scripts/sim/expedition.gd` (`offline`: the
event keep-list, about line 466).

**Problem:** `Main._show_summary` has a `"pearl"` case, but `Offline.diff` filters events down to
`evolved/captured/...` and `Expedition.offline` doesn't keep `"pearl"` either, so that case never runs.

**Change:** add `"pearl"` to both lists.

**Test:** `Offline.diff(s, Offline.snapshot(s), [{"type": "pearl", "amount": 1, "why": "x"}]).events` has the
pearl event in it.

#### Fix 7: a multi-target ability keeps hitting after thorns have knocked out the attacker
**File:** `scripts/sim/combat.gd`, `_use_ability()`, the `"multi-target-damage"` branch.

**Problem:** the loop checks only `foe[t].alive`. If thorns from the first target kill the attacker, it goes on
hitting the rest of the wave.

**Change:** `if not f.alive: break` at the top of the loop.

**Test:** in `test_combat.gd`, set up an attacker with 1 HP using a multi-target ability against three enemies,
the first with `thornsT > 0`. After the ability, only one `"hit"` event comes from that attacker.

#### Fix 8: worker bubbles log errors during the fade back to the title screen
**File:** `scripts/ui/widgets/worker_bubble.gd`, `_process()`.

**Problem:** `Game.leave()` sets `Game.state = {}`, then the screen fades for 0.4 s. `GameState.creature(Game.state, cid)`
reads `.creatures` from an empty Dictionary, which is an error on every frame of the fade when a skill page is open.

**Change:** `if cid == "" or Game.state.is_empty() or not is_visible_in_tree(): return`.

**Test:** in `test_ui.gd`, make a bubble with `WorkerBubble.make(c, "woodcutting", 58)`, add it under the test layer,
set `Game.state = {}` and call `_process(0.016)`. It must return without error. A script error here stops the test
run under `--debug`, so a clean pass is the check. Put `Game.state` back afterwards.

#### Fix 9: Genesis Pods remembers the parents you picked across save slots
**File:** `scripts/ui/screens/pods_screen.gd`: `static var parent_a`, `parent_b`, `tier`.

**Problem:** these static variables outlive the slot. Creature ids like `c3` exist in every slot, so after you
switch slots, the pods page opens with a *different* creature already chosen.

**Change:** add `static var _for_save := -1`. At the start of `refresh()`, when `int(Game.state.created) != _for_save`,
clear `parent_a`/`parent_b`, set `tier = 1`, and store `_for_save`. Don't make `Game` know about `PodsScreen`.

**Test:** in `test_ui.gd`, pick parents, swap in a new `GameState.new_game()` with a different `created`, then refresh.
Both parent slots are empty.

#### Fix 10: `Market.buy()` with qty ≤ 0 reports success
**File:** `scripts/sim/market.gd`, `buy()`.

**Problem:** it returns `""` for `qty <= 0`, so `Game.market_buy` plays the coin sound and says "Bought 0× …".

**Change:** `return "Choose how many to buy."`.

**Test:** in `test_market.gd`, `Market.buy(s, id, 0)` and `(s, id, -5)` return an error, and gold and the item
count don't change.

#### Fix 11: the bulk-release message leaves out Aether Pearls
**File:** `scripts/autoload/game.gd`, `bulk_release()`.

**Problem:** releasing Resplendent or Zenith Aetherlings gives Pearls (`Economy.release`). A single release
reports them, but bulk release only mentions Aether.

**Change:** do what `release()` does. Count `aether-pearl` before and after, and add
`" and %d Aether Pearl(s)"` when it's above 0.

### P3: robustness, tools and docs

#### Fix 12: dragging an Options slider writes `options.cfg` on every tick
**Files:** `scripts/autoload/options.gd` (`set_value`), `scripts/ui/widgets/options_panel.gd` (`_slider`).

**Change:** keep `set_value` applying the change right away, but save through a debounce. Add a one-shot Timer
child of about 0.4 s that `set_value` restarts and whose `timeout` calls `save_options()`. Also save on
`NOTIFICATION_WM_CLOSE_REQUEST`. Don't save only on `drag_ended`, because keyboard and wheel changes never fire it.

**Test:** in `test_ui.gd` or a new small test, 20 `set_value` calls in a row leave the file written at most once
after the timer runs. Make the timer's wait time a member variable, so the test can shorten it.

#### Fix 13: `Data._read` depends on `assert`, which exported builds remove
**File:** `scripts/autoload/data.gd`, `_read()`.

**Change:** parse with a `JSON` instance, so a failure can say where it is:
```gdscript
var json := JSON.new()
if json.parse(text) != OK:
	push_error("Could not parse res://data/%s, line %d: %s" % [file, json.get_error_line(), json.get_error_message()])
	assert(false)
	return null
return json.data
```
A broken data file then explains itself in a release build instead of crashing later with a null access. Nothing
to test beyond `test_content`, which already loads every file.

#### Fix 14: the test bridge can wipe or rename any save slot
**File:** `scripts/autoload/test_bridge.gd`, `_handle` → `"new"`/`"load"` → `_start()`.

**Problem:** `new <slot>` starts *any* slot fresh, and both `new` and `load` rename the slot to "Autoplay Slot".
So `load 1` renames the player's own slot 1, and `new 1` wipes it. `docs/TEST_BRIDGE.md` promises "your own saves
are never touched".

**Change:**
- `new` works only on `SLOT`, unless the request has `"force": true`.
- `load` doesn't rename a slot other than `SLOT`.
- Update `docs/TEST_BRIDGE.md` and, if it passes a slot, `tools/bridge.py`'s usage text.

**Test:** in `tests/test_bridge.gd`, call `TestBridge._handle({"cmd": "new", "slot": 1})`. It returns `ok: false`
and doesn't touch slot 1. Stub or skip the scene change, so it stays headless-safe.

#### Fix 15: the Expeditions log's "ago" times freeze
**File:** `scripts/ui/screens/expedition_screen.gd`, `_render_log()` / `_process()`.

**Problem:** the log only redraws when a new line arrives, so "now" and "3m" stay stale. Each redraw also rebuilds
up to 56 cards, each with its own StyleBox, plus a portrait for every capture.

**Change:** keep references to the "when" labels and update just their text once a second from `_process`. Leave
the full rebuild for when a new line actually arrives. It's optional to add only the new card at the top instead
of rebuilding; do it only if it stays simple.

#### Fix 16: two comments are in the wrong place
- `scripts/sim/skills.gd`: the comment `## The item of an element type at a tier …` (about line 201) sits above
  `work_perks`. Move it above `element_item`. The comment `## Expected output per hour for one worker (for the UI).`
  (about line 305) sits above `work_rates`. Move it above `per_hour`.
- `scripts/ui/widgets/arena.gd` line 18: two comments were merged onto `_announced`. Put
  `# the boss track is playing because of this arena` back on `_boss_music`.

#### Fix 17: `docs/HANDOFF.md` describes the old repo layout
**Problem:** "Ground rules" and "Running things" still say to work in `godot/` on branch `godot-rebuild`, that the
web build is on `main`, and to run `--path godot`. A new session reads HANDOFF first and would follow them.

**Change:** rewrite those two sections to match `CLAUDE.md`:
- The project is at the repo root, and the commands use `--path .`.
- The web build is on `web-archive`.
- Say which branch to push to, using the one you're on. Don't invent one.

Keep "Recently done", "Not yet seen" and "Open for the designer", but add this session's fixes to "Recently done".

#### Fix 18: `tools/check.sh` runs the tests differently from `CLAUDE.md`
**Change:** the test line becomes `"$GODOT" --headless --debug --path . res://tests/test_runner.tscn < /dev/null`.
`--debug` matches the documented command, and closing stdin stops a script error from hanging at the debugger prompt.

---

## Do not change

- **The no-re-roll rule.** The RNG state is saved, and every committed roll saves at once. This is deliberate
  (`DECISIONS.md`) and the designer confirmed it. Fix 1 has to keep it working.
- **`*.uid` in `.gitignore`.** Deliberate, see its comment. Scenes reference scripts by path.
- **`build-exe.bat` pointing at the .NET (mono) Godot.** That's the designer's local install.
- **Balance and prices.** Don't touch Market prices, Pearl rates or XP. `CLAUDE.md` rule 7 says a balance change
  needs the month probe and the designer.
- **The art files and art docs** listed in section 0.

## For the designer (report these, don't fix them)

1. **Offline boss XP:** an extrapolated boss kill while away (`Expedition.offline` → `_on_boss_defeated`) gives XP
   only to `_alive_party()`, meaning whoever was standing when the simulated stretch ended. If that stretch ended
   in a rest after a wipe, those boss kills give no XP. Using the whole party would give more XP while away, which
   is a balance change.
2. **A Pearl source bought with gold:** the "Shimmering egg" limited offer (always shiny, 8× the grade price) gives
   +1 Pearl when it hatches and +2 when released. That's rare and capped at one per stock, but it's a way to turn
   gold into Pearls. Is that wanted?
3. **New games have no `goals.id`** until the first goal is claimed, so `Goals.migrate` reads them against the old
   26-goal list. That's harmless today (index 0 is `"work"` in both lists), but setting `goals.id` in
   `GameState.new_game()` would close it. It's a one-line change, so do it if you agree it isn't a design question.

---

## When you're done

1. Run the whole suite with `--debug`: 0 failures. Run it again with `--verbose`: no new warnings.
2. Update the test count in `docs/DECISIONS.md` (it was 105 when this was written; add the new tests). Add a short
   entry for these fixes and why, and update `docs/HANDOFF.md` (Fix 17).
3. `git fetch`, then `git merge` (never rebase or force). Run the tests again if the merge brought anything in, then push.
4. Reply with:
   - a table of the fixes: done, skipped (and why), or blocked;
   - the new test count;
   - anything from "For the designer" that you think is more urgent than it looks.
