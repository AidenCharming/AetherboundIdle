# Bridge bugs to fix

From `bridge_runs/bugtest_benchmark-20260924-183259/` (`report.md`, `report.json`, `actions.log`, `shots/`), a
10-minute automated play-test (seed 1, 8 h compressed). It failed on 3 invariant breaks and hit 2 stuck points.
Read the full report first: `bridge_runs/bugtest_benchmark-20260924-183259/report.md`.

## Prompt

Read `bridge_runs/bugtest_benchmark-20260924-183259/report.md` in full, then fix these, in order of how much they'd
block a real player. For each: reproduce it (the report's `actions.log` excerpt and screenshot pin the exact
repro steps), find the cause, fix it, and add or extend a `test_ui.gd` test that would have caught it. Re-run
`python tools/bridge.py run bugtest_benchmark` when done and confirm PASS.

1. **Navigating to Sanctum sometimes lands on Pods instead** (`shots/045_break.png`, ~4:02 in-run). Right after
   laying an egg in the Genesis Pods (closing two dialogs, picking a tier, laying), clicking the Sanctum nav
   button keeps the Pods screen showing instead of switching. Likely a stuck screen-state or a dialog `Close`
   not fully returning control to `main.gd`'s `show_screen`.
2. **A finished goal's Claim button doesn't show on the Sanctum** (`shots/046_break.png`, ~4:04), immediately
   following #1 — goal `frames` (Make 4 Timber Frames) completed but no Claim appeared. May be the same root
   cause as #1 (wrong screen showing), or a second instance of the "goal card doesn't rebuild" issue HANDOFF.md
   already describes for other screens.
3. **Sanctum Works: a Build click did nothing** (`shots/054_break.png`, ~6:33) — upgrade levels read 6 before and
   after clicking Build, no error, no level change. Happened once during a run of skipped/compressed time and
   several other clicks right before it; check whether a stale affordability/enabled state survives a time-skip.
4. **Whisperleaf Hollow's Explore button was missing right at the start** (`shots/003_stuck.png`, ~0:32) — after
   adding an Aetherling to the party and selecting the zone, no visible "Explore" button. The same zone's
   Explore worked fine later in the same run (~169.7s), so this looks timing-related: maybe the button isn't
   enabled until some async state (party validation? zone unlock check?) settles.
5. **Sanctum Works: Genesis Pods was affordable but Build stayed disabled** (`shots/044_stuck.png`, ~3:26) —
   possibly the same stale-enabled-state family as #3, or an off-by-one in the affordability check.

Secondary, not blocking: fps dipped to a min of 22 (10th percentile 30, median 30) and memory grew 82 → 101 → 89
MB (+9%) over the 10-minute run. Worth a look if there's time, not urgent.

## Outcome (2026-09-25)

All five fixed; `bugtest_benchmark` re-run in the cloud (xvfb, seed 1, 8 h compressed): **PASS**, 0 errors,
0 invariant breaks, 0 stuck, 35 goals claimed, 45 screens.

1. and 2. **Sanctum click landed on Pods; no Claim.** Reproduced with the bridge. A dialog fading out (0.1 s)
   still took every click and still counted as open, so the scenario clicked the parent picker's Close a
   second time; that click fell through to the Pods page and opened another picker, which swallowed the
   rail click (and the Sanctum check then ran on the Pods page). Fixed in `modal.gd`: a closing dialog
   ignores the mouse and isn't open. Changing page also closes a page's dialogs, and a picker whose page
   is gone just closes. Tests: `test_a_closing_dialog_lets_clicks_through`, `test_changing_page_closes_its_dialogs`.
3. and 5. **Works Build did nothing / stayed disabled.** The page rebuilt every card on each `Game.changed`
   (a capture could free the button mid-click), and set `disabled` only when built (gold from work doesn't
   emit `changed`). Cards now rebuild only when an upgrade level changes; affordability is checked four times
   a second. Test: `test_works_build_buttons_stay_put_and_follow_the_gold`.
4. **No Explore for Whisperleaf Hollow** was the scenario, not the game: with the island list folded, its
   loose click on "Whisperleaf Hollow" matched the Explore button's tooltip and started the run. The
   scenario now selects islands by exact name.
