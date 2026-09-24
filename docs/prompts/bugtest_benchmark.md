# Build: `python bridge.py run bugtest_benchmark`

A scripted bug-test run that plays Aetherbound Idle like a real player for about 10 minutes through the test
bridge, then writes a report. The designer's whole job should be: open a terminal in `tools/`, type
`python bridge.py run bugtest_benchmark`, walk away, and come back to a report that says what broke.

## Read first

* `CLAUDE.md` (rules, layout, commands, git). Work on `godot-rebuild`; fetch and **merge** (never rebase or
  force-push, the designer pushes art); push to both `main` and `godot-rebuild`.
* `docs/TEST_BRIDGE.md`, `scripts/autoload/test_bridge.gd`, `tools/bridge.py`: what the bridge can do today.
  It has real mouse clicks by button text (with auto-scroll), `buttons`, `state`, `get <path>`, `errors
  [since]`, `screenshot`, `go`, `key`, `skip <hours>`, `wait`, `game <method> …`, `eval`, `new`/`load` (slot 2,
  "Autoplay Slot"). There's a random-click `monkey` mode. This task adds a *purposeful* player.
* `data/goals.json` and `scripts/sim/goals.gd`: Overseer Vance's goal chain. There are 112 goals, one active
  at a time. `goals.index` in the save points at the active one, and `goals.id` holds its id. Each goal has a
  `check.kind`, and `Goals.KINDS` lists every kind the game understands. The first screen after a new
  game shows a "Let's start: open Woodcutting" button (`scripts/ui/main.gd`).
* `scripts/autoload/game.gd`: the player actions (assign, set_action, set_party, start_expedition,
  retry_pending, breed, hatch, sell, buy_upgrade, market_buy, claim_goal, …). The benchmark should reach these
  **through UI clicks**. That is the point, since clicks exercise the screens. Read the screen scripts in
  `scripts/ui/screens/` to learn which button texts do what.

## What to build

1. **`run <scenario>` in `tools/bridge.py`.**
   * It loads `tools/scenarios/<scenario>.py` and calls its `run(ctx)`.
   * It must work when started from the repo root *and* from `tools/`. The designer runs it on Windows
     from `D:\GameDev\AetherboundGodot\tools`.
   * If the game isn't answering, it launches it. Use `GODOT` or `--godot PATH`, the same as `launch`, and
     print a clear message when neither is set.
   * Flags:
     * `--minutes N`: default 10.
     * `--seed N`.
     * `--out DIR`: default `bridge_runs/<scenario>-<timestamp>/`. Add `bridge_runs/` to `.gitignore`.
     * `--compress H`: in-game hours to fast-forward, spread evenly over the run with the bridge `skip`.
       Default about 8, so the goal chain gets somewhere in 10 real minutes. `0` = pure real time.
     * `--keep`: don't quit the game at the end.
   * Standard library only.
2. **A small helper layer**, for example `tools/scenarios/_player.py`, holding the `ctx` passed to
   scenarios:
   * `ctx.click("text")` → bool. `ctx.has_button("text")` / `ctx.buttons()`. `ctx.go(screen, arg)`.
   * `ctx.state()`, `ctx.get(path)`.
   * `ctx.check()`: new errors plus invariants.
   * `ctx.shot(label)`. `ctx.log(msg)`. `ctx.stuck(reason)`: logs, takes a screenshot, and moves on,
     never hangs.
   * A time budget.

   Prefer clicking by visible text. Use `game`/`eval` only to **read**, or as a logged fallback when a
   click path doesn't exist. Every fallback counts as a "UI gap" in the report.
3. **`tools/scenarios/bugtest_benchmark.py`: the normal gameplay loop.**
   * Start fresh in slot 2 (`new`) unless `--continue` is given. Click through the intro/tutorial.
   * Then loop until the time runs out:
     * **Goal-driven.** Read the current goal and click its claim button when it's done. Pick the next
       action from the goal's `check.kind`, with one handler per kind:
       * `working`: assign an Aetherling to that skill.
       * `item`: pick that gathering action.
       * `expedition`: set a party and start the zone.
       * `captures`: make sure vessels are selected and binds are retried.
       * `creatures`: keep binding.
       * `skill_level`: work it.
       * `counter` bred/hatches: breed in the Genesis Pods, then hatch (and speed up if affordable).
       * `zone`: stronger party and the right zone.
       * `slots`: buy a work slot.
       * `upgrades`: build something in Sanctum Works.
       * `rarity`, `creature_level`, `total_level`, `skills_at`: these need no action of their own. Keep
         breeding, fighting and working until they're done.
       * `species`, `hybrids`, `specials`: breed different pairs.
       * Handle every kind in `Goals.KINDS`; the chain uses all of them.
     * **Housekeeping each lap:**
       * Assign idle Aetherlings to the skill with free slots.
       * Switch skills to their best unlocked action.
       * Keep an expedition running.
       * Hatch ready eggs and re-breed.
       * Sell surplus and buy an affordable upgrade or market item now and then.
       * Claim milestones.
       * Dismiss modals and popups.
     * **Coverage sweep every few minutes:**
       * Visit every screen in the nav: Sanctum, each skill, Nexus, Pods, Expeditions, Aether-Log,
         Inventory, Market (every tab), Egg Market, Works, Options.
       * Screenshot each one once per run.
     * **Once per run each:**
       * Save → back to the title → load slot 2. Compare key numbers before and after: gold, aether,
         creature count, skill levels, within tolerance.
       * An offline-style jump: a `skip` of a few hours. Check the return summary and that nothing went
         negative or NaN.
4. **Invariants checked after every action.** Any break is a finding, with a screenshot:
   * No new engine or script errors (the bridge `errors since`).
   * gold, aether and item counts are finite and ≥ 0.
   * For every skill, workers ≤ slots.
   * No creature in two jobs.
   * Modals don't pile up: more than 2 open, or one open for 60 s, is a finding.
   * The screen shown matches the one just asked for.
   * fps stays above 20 (sample it and report the minimum and median).
   * memory_mb doesn't grow without bound: report start, peak and end, and flag more than +50% growth.
   * No button click returns "not found" for a button that `buttons` just listed.
5. **Report**, written to the out dir and summarised in the terminal. The exit code is non-zero when there
   were errors or invariant breaks.
   * `report.md`, human-readable:
     * PASS/FAIL headline;
     * goals reached, with real and in-game times;
     * errors (text, the action before them, a screenshot link);
     * invariant breaks, stuck events and UI gaps;
     * screens covered;
     * fps and memory;
     * the last ~30 actions before each problem.
   * `report.json`, the same data for tools.
   * Screenshots.
   * `actions.log`: every step.

## Bridge changes (fine to make, keep them debug-only)

The bridge is off unless the build is debug and `--bridge` is passed, and it must stay that way
(`tests/test_bridge.gd` checks this). Add what the player needs rather than scraping. For example:

* the current goal id, its text and whether it's done;
* inventory counts;
* idle creature ids;
* the unlocked actions per skill;
* a modal's title and buttons.

Keep `state` compact. Put larger data behind `get` or new commands. Update `docs/TEST_BRIDGE.md` for every
addition.

## Rules

* **No cheats in the benchmark.** No `dev_*` calls and no free gold. The only time acceleration is
  `--compress` through `skip`, and the report says how much was used. A separate `--cheat` flag for
  a later "late-game smoke" scenario is fine but optional.
* **Never wipe other slots.** Play slot 2 only. Skip buttons like the monkey's `MONKEY_SKIP` (quit,
  delete, reset, import, export, …) except for the deliberate save/load round trip.
* **Deterministic enough to compare runs:** seeded choices, and the log records the seed.
* **Robust:** a missing button or an unexpected popup is logged and worked around, never an endless loop
  or a crash of the script. Every bridge call has a timeout. If the game dies, write the report with what
  was collected and say the game exited.
* **Verify in the cloud** under xvfb:
  `xvfb-run -a -s "-screen 0 1600x900x24" $G --path . -- --bridge`, then run
  `python3 tools/bridge.py run bugtest_benchmark --minutes 2` and then the full 10 minutes.
  * Read the report and fix real game bugs it finds. Keep game-bug fixes small; list anything bigger in
    `docs/HANDOFF.md` for the designer.
  * Tests stay green at zero warnings.
  * Update `docs/TEST_BRIDGE.md` (how to run a scenario, how to write a new one),
    `docs/HANDOFF.md` and `docs/DECISIONS.md` (test count if it changes), and the Commands table in
    `CLAUDE.md`.
* When done, tell the designer the exact command, what a PASS looks like, how far the goal chain got in
  10 minutes, and what the first run found.
