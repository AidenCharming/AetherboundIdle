# Code review: Aetherbound Idle v0.6.3 (2026-09-25)

This is the third pass. It re-checks the first review (`docs/archive/done/codereview-2026-09-25.md`, fixed in 0.4.0) and covers everything changed since: 0.4.0 to 0.6.3.

**Scope:** every changed script, test and data file since v0.3.1. The sim, saves, test bridge, test runner, Sfx and Options changes were read line by line, as were the new `patch_notes.gd`, `rarity_preview.gd` and the 0.6.3 Aether-Log species page. The 1920x1080 re-layout was skimmed: most of it is sizes and fonts, plus anti-aliased drawing. This was a read-only review; the game and the tests were not run.

## Summary
All nine main issues from the first review are fixed, and most fixes come with a test. There are no critical problems. The main open item is that the new `--warnings` check probably skips most of the scripts it is meant to cover. Everything else is small.

## First review: status
| # | Issue | Status |
|---|---|---|
| 1 | The only backup was the rolling `.bak` | ✅ Fixed: `slot_N.session.json` and `slot_N.pre-import.json`, and an import is migrated on a trial copy first. Tested. |
| 2 | Crashed tests printed `ok` | ✅ Fixed: an `ErrorCounter` logger checks each test and each script load. |
| 3 | Bridge: a web page could POST a command | ✅ Fixed: a first line that looks like HTTP drops the connection. |
| 4 | Thorns: a knocked-out fighter still attacked | ✅ Fixed. |
| 5 | Nexus lost its pages on refresh | ✅ Fixed: the pages shown and the scroll position are kept, and `sort_by_key` is stable. |
| 6 | `Main.instance` pointed at a freed node | ✅ Fixed in `_exit_tree`. |
| 7 | Autosave re-parsed the whole main file | ✅ Fixed: it trusts a file it wrote itself while the size is unchanged. |
| 8 | Hardcoded balance numbers | ✅ Mostly fixed. The `power_rating` weights are still in code (`creatures.gd:94`). |
| 9 | Bad indices and tiers | ✅ Fixed, with `tests/test_guards.gd`. |
| 10-12 | Dev tools in release builds, `.claude/settings.json`, wall clock in `levelTimes` | ⏸ Deferred to the designer (CHANGELOG 0.4.0). |

## Open issues
| # | File | Line | Issue | Severity |
|---|------|------|-------|----------|
| 1 | tests/test_runner.gd | 72-80 | `--warnings` calls `load(p)`, but the autoloads and every class they reference are already compiled before the logger is added. That covers almost all of `sim/`, plus `Main`, `Modal` and `F`. `load()` returns the cached script, so their warnings never reach the logger, and the pass can report 0 while sim code has warnings. | 🟠 Medium |
| 2 | scripts/autoload/game.gd | `import_text` | The shape check runs after `migrate`, but `migrate` itself errors on some bad input (for example `creatures` as an array). The import then aborts without a message. Nothing is damaged. | 🟡 Low |
| 3 | scripts/autoload/game.gd | `start_slot` | The session copy is replaced on every launch. If a bug saves a bad state and the player restarts, the copy holds the bad state too. A load that falls back to the session copy also doesn't tell the player that progress since launch is gone. | 🟡 Low |
| 4 | scripts/sim/expedition.gd | `dev_next_wave` | Used during the rest after a wipe, it starts a wave while every ally is still knocked out, so the party wipes again at once. Dev tool only. | 🟡 Low |
| 5 | tests/test_runner.gd | 53-59 | Only `ERROR_TYPE_SCRIPT` fails a test, so a `push_error` from game code (for example "Could not write save") doesn't. | 🟡 Low |
| 6 | scripts/ui/screens/aetherlog_screen.gd | `_entry`, `_display_bar` | (0.6.3) With "Highest rarity" on, every owned card is drawn at its top rarity, and the top tiers animate every frame. A late-game Creaturedex could have about 90 animated shader portraits on screen. Check it with `frame_stats` or `test_perf`. | 🟡 Low |
| 7 | scripts/ui/screens/aetherlog_screen.gd | `_entry` | (0.6.3) "Form 3" shows the Form 3 silhouette of species never seen. Before, an unseen species only showed its Form 1 shape. This is a design call on how much to reveal. | Nit |
| 8 | scripts/autoload/options.gd | 25 | The viewport is 1920x1080, but the default window is still option 2 (1600x900), so new players start at 83% scale. | Nit |
| 9 | CLAUDE.md:5, :67; tests/test_runner.gd:3 | — | Stale text: 1600x900 in the intro and in the xvfb screen size, and the runner's usage line still says `--debug` for tests. | Nit |
| 10 | scripts/ui/widgets/rarity_preview.gd | 198 | It reads the private `Sfx._streams`. Its sound buttons stay silent when that sound group is switched off. | Nit |

## Suggested fixes
1. Load with `ResourceLoader.load(p, "", ResourceLoader.CACHE_MODE_IGNORE)`. To prove the check works, add an unused local to a sim script and confirm the pass fails.
2. Type-check `parsed` before migrating: the top-level containers must be Dictionaries and every creature must be a Dictionary.
3. Keep the previous session copy too (`session.prev.json`) or one per day, and show a toast when a load falls back to an older copy.
4. Refuse `dev_next_wave` unless the phase is `fight` or `gap`, or start a fresh run first.
5. Count `ERROR_TYPE_ERROR` as well, with an allow-list for errors a test expects.
6. Cache each portrait's top-rarity look, or animate only the portraits that are visible.

## What looks good
- The import path: migrate on a copy, refuse damaged shapes, keep the replaced game, and delete that copy along with the slot. Each part is tested.
- `check.sh` runs the tests without `--debug`, then a separate pass for warnings.
- The Sfx sound groups default to on. The toggle saves the option before it plays its sample.
- The patch notes escape BBCode in entries. The item-sources panel and the species page are built entirely from data.
- The species page reads `formLevels` and `formStatMult` from tuning rather than repeating them, and it is covered by new UI tests.
- The version bumps follow repo rule 9. The CHANGELOG maps each fix back to the review number.

## Verdict
**Approve.** Fix #1 soon, since it backs the zero-warnings rule. The rest can wait.
