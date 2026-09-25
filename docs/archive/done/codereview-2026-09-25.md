# Code review: Aetherbound Idle (Godot), full codebase, 2026-09-25

Scope: all of `scripts/sim/` and `scripts/autoload/`, `scripts/ui/main.gd`, `ui.gd`, the nexus and expedition screens, the arena and creature-card widgets, config files, `tests/test_runner.gd`, `tests/test_saves.gd`, and `tools/bridge.py` (scanned). The other UI screens and widgets were skimmed. The data JSON, docs, art tools and assets were not reviewed.

## Summary
The code is well built. Sim and UI are cleanly separated, offline progress is done in bulk, RNG state is persisted, and writes are atomic. Nothing critical. The two issues worth fixing soon are the save-backup strategy and the test runner reporting crashed tests as passing.

## Issues
| # | File | Line | Issue | Severity |
|---|------|------|-------|----------|
| 1 | scripts/autoload/game.gd | 261-274, 390-402 | `.bak` is just the previous autosave, so it protects against torn writes but not bad data. After a wrong restore, or a sim bug that corrupts state, the good save survives only until the next autosave (about 20 s). `import_text` checks only for the `version` and `creatures` keys. | Medium |
| 2 | tests/test_runner.gd | 31-37 | A runtime script error inside a test aborts that test without adding a failure, so the test is printed as `ok`. | Medium |
| 3 | scripts/autoload/test_bridge.gd | 75-93, 189 | A cross-protocol attack is possible: a browser POST to 127.0.0.1:47625 puts the body on its own line, which gets executed (including `eval`). This only applies to debug builds started with `--bridge`. | Low |
| 4 | scripts/sim/combat.gd | 396-406 | A fighter knocked out by thorns during its own ability still lands its auto-attack in the same substep. | Low |
| 5 | scripts/ui/screens/nexus_screen.gd | 86-95 | Every `Game.changed` event (captures, evolutions) rebuilds the grid from page 1, so "Show more" pagination is lost mid-browse. `sort_custom` isn't stable, so cards with equal keys can shuffle. | Low |
| 6 | scripts/ui/main.gd | 18, 43 | `static var instance` is never cleared, so after returning to the title it points to a freed node. | Low |
| 7 | scripts/autoload/game.gd | 270 | Every autosave re-reads and re-parses the whole main file (`_readable`) before copying it. As the roster grows, this adds main-thread hitches on top of `stringify`. | Low |
| 8 | several | — | Balance numbers are hardcoded, which goes against repo rule #1. Examples: breeding.gd:105 (0.2) and 110 (0.25), creatures.gd:338 (/20, ×0.5), combat.gd:496 (0.85), expedition.gd:411 (rarity 3) and 428 (−10), market.gd:279 (×15), creatures.gd:312. | Low |
| 9 | game.gd, breeding.gd, market.gd, collection.gd | — | Actions don't validate indices or tiers. `tier 0` becomes `aetherCost[-1]`. A negative offer index reads the last offer. `attune` or `claim` with a bad id or index errors. The UI guards these, but the bridge's `game` command doesn't. | Low |
| 10 | options.gd / main.gd | 30 / 518 | Dev tools can be enabled in release builds. That's fine if it's intentional. | Nit |
| 11 | .claude/settings.json | — | The committed file gives blanket allow for Bash, WebFetch and Write. | Nit |
| 12 | scripts/sim/skills.gd | 261 | `levelTimes` uses the wall clock inside the sim, so every level gained offline gets the same "now" timestamp. | Nit |

## Suggested fixes
1. Keep a separate pre-restore copy (`slot_N.pre-restore.json`) and a session-start or daily backup that the autosave never overwrites. Validate an import by running `migrate` on a copy and doing a smoke test before adopting it.
2. Register a `Logger` (as the bridge does) that counts script errors, and fail the current test when the count rises.
3. Require a random token, written to `user://bridge/token` at launch, in every request. Alternatively, drop the connection if a line starts with an HTTP method.
4. After `_use_ability`, add `if not f.alive: continue` before the attack block.
5. Keep the number of loaded pages and the scroll position across a refresh. Alternatively, coalesce `changed` into one deferred refresh per frame. Add the id as a tiebreaker in the sort keys.
6. Add `func _exit_tree(): if instance == self: instance = null`.
7. Track "the last write succeeded" in memory instead of re-parsing, or rotate the backup less often.
8. Move these numbers into `data/tuning.json`.

## What looks good
- Save writes are atomic (tmp, then backup, then rename) and there is a tmp fallback. Tests use slot 99.
- RNG seed and state are stored as strings, and outcomes are rolled at lay time, so reloading can never re-roll a result.
- Offline progress is computed in bulk (binomial or Poisson), with capped real runs for expeditions followed by extrapolation, and boosts are pro-rated.
- The roster index cache and the top-N perch selection both scale to large rosters.
- A click is never lost to a rebuild: refreshes are deferred while the mouse button is held.
- Market lot pricing guarantees an offer can't be flipped for profit.
- Options writes are debounced and flushed on quit.
- The bridge is gated on a debug build, `--bridge` and localhost.

## Verdict
Approve with follow-ups: #1 and #2 first, the rest when convenient.
