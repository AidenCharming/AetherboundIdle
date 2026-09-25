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
