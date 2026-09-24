# Test bridge: let a script (or a local Claude session) play the game

The game has a small test bridge (`scripts/autoload/test_bridge.gd`) that a script can drive while the game
runs: click buttons with real mouse clicks, scroll, press keys, jump between pages, skip time, read the save,
collect every engine and script error, and take screenshots. `tools/bridge.py` is the command-line client
(Python 3, standard library only).

**It's off unless you ask for it:** the game must be started with `-- --bridge`, and only a debug build (the
editor, or a debug export) opens it. A release export never listens. It listens on `127.0.0.1` only (port
47625; change it with `--bridge-port=N` and the `BRIDGE_PORT` environment variable for the client).

**It plays in save slot 2, named "Autoplay Slot"**, so your own saves are never touched (`new` wipes slot 2).

## Start

```
set GODOT=C:\path\to\Godot_v4.7.2-stable_win64.exe      (PowerShell: $env:GODOT="C:\...\Godot.exe")
python tools/bridge.py launch          # opens the game window with the bridge on, waits until it answers
python tools/bridge.py new             # a fresh game in slot 2 ("Autoplay Slot"), on the game screen
```

Or start the game yourself: `Godot.exe --path . -- --bridge`.

## Commands

| Command | What it does |
|---|---|
| `ping` | Is the game listening? Returns the current scene |
| `state` | Scene, page, gold, Aether, skills (level, workers, slots), expedition, pods, boosts, the active goal, the reveal, fps (and its cap, focus, renderer), memory, error count, open dialogs, window size and mode, frame number, whether Movie Maker records |
| `get <path>` | A value from the save by dotted path: `get gold`, `get skills.mining.level`, `get expedition.party` |
| `buttons` | Every button a player could click now: text, centre `x,y`, size, disabled, `tip` (its tooltip) and `cid` (on an Aetherling card). While a dialog is open, only the top dialog's buttons; while a hatch or evolution reveal plays, only "Click to continue" |
| `click "<text>" [index]` | A real mouse click (move, press, release) on the button with that text: exact text, then exact tooltip, then "contains". An exact match that's scrolled out of view is wheeled into view first (a button counts as visible when its centre is). `raw '{"cmd":"click","cid":"c12"}'` clicks that Aetherling's card (pickers, Nexus) |
| `goal` | Overseer Vance's active goal: index, id, text, check, have/need, done |
| `player` | One read of what a player sees: Aetherlings (types, rarity, level, job, power), skills (slots, workers, every task and whether it's unlocked and makeable, work-slot price), the expedition and islands, pods, items (with category), Sanctum Works upgrades (affordable?), counters |
| `modals` | Open dialogs (title, how long open, buttons) and the reveal state |
| `invariants` | Broken rules in the save: gold/Aether/items finite and ≥ 0, workers ≤ slots, nobody in two jobs, party consistent, pods, levels |
| `breed_check` | `raw '{"cmd":"breed_check","pairs":[["c1","c2"]],"tier":1}'`: whether each pair can lay an egg, the cost and what could hatch (new to the log?) |
| `focus` | Act as if the window had focus (lifts the background frame-rate cap), as a player looking at it |
| `click_at <x> <y>` | A real click at a point in the game's 1600×900 layout (the `x,y` that `buttons` reports) |
| `scroll <x> <y> [steps]` | Mouse-wheel at a point; positive steps scroll down |
| `key <name>` | A key press: `Escape`, `Enter`, `1` … `9` (page shortcuts), `F11` |
| `go <screen> [arg]` | Jump to a page without clicking: `sanctum`, `skill woodcutting`, `nexus`, `pods`, `expeditions`, `aetherlog`, `inventory`, `market`, `eggmarket`, `works` |
| `new [slot]` / `load [slot]` | Start slot 2 fresh / load it, and open the game screen |
| `title` | Leave to the title screen |
| `skip <hours>` | Fast-forward as time away (the offline summary appears); returns the summary's numbers |
| `game <method> [args…]` | Call any `Game` method, e.g. `game dev_add gold 50000`, `game dev_grant emberfang 3 20 false`, `game start_expedition whisperleaf-hollow` |
| `eval "<expression>"` | A GDScript expression with `Game`, `Data`, `S` (the save) and `M` (the game screen): `eval "S.gold"`, `eval "M.current"` |
| `errors [since]` | Engine and script errors (with a script backtrace when there is one) since error number `since` |
| `screenshot [file.png]` | Saves exactly what the window shows and returns the path |
| `wait <seconds>` | Lets the game run |
| `quit` | Closes the game |
| `monkey [--steps N] [--seed S] [--delay 0.2] [--shots DIR]` | Clicks random enabled buttons (never quit/delete/reset/leave), logs every step, and on the first new error saves a screenshot and prints the errors with the last steps that led to them |

Every reply is JSON with `"ok": true` or `"ok": false, "error": "…"`; the exit code is 0 or 1.

## Scenarios: `run`

```
python tools/bridge.py run bugtest_benchmark                 (from the repo root or from tools/)
    [--minutes 10] [--seed 1] [--compress 8] [--out DIR] [--keep] [--continue] [--godot PATH] [--min-fps 20] [--movie]
```

Loads `tools/scenarios/<name>.py` and calls its `run(ctx)`. If the game isn't answering it starts it (set `GODOT`
or pass `--godot`). At the end it quits the game (unless `--keep`), prints a summary and writes to
`bridge_runs/<name>-<time>/` (gitignored): `report.md` (PASS/FAIL, goals with real and in-game times, errors
with the action before them and the last 30 steps, invariant breaks, stuck events, UI gaps, screens covered,
fps and memory, the save/load table), `report.json` (the same for tools), `actions.log` (every step) and
`shots/`. The exit code is 0 for PASS and 1 for FAIL.

**bugtest_benchmark** starts slot 2 fresh (or `--continue`s it), clicks through the welcome, then loops: claim
the goal when it's done and work on it (one handler per goal kind), one chore per lap (assign idle Aetherlings,
best tasks, keep an expedition running, hatch and breed, sell/build/shop, milestones, vessels), a sweep of every
page, tab and menu every three minutes (a screenshot of each, once), `--compress` hours skipped in slices, and once
each a save → title → load round trip and a jump of up to 3 hours away. It never presses quit, delete, reset,
overwrite, release, import or export buttons, and plays slot 2 only. A PASS means no engine or script errors and
no invariant breaks; stuck events and UI gaps are listed but don't fail the run. On a software renderer the fps
check is reported, not judged.

**`--movie`** starts the game itself with Movie Maker (`--write-movie out/movie/frame.png --fixed-fps 30`). The game
then runs on a fixed 1/30 s step per rendered frame, so a recorded run is slower than real time and `wait` is
game time. Scenarios mark clips with `with ctx.clip("name"):` (the benchmark records the first goal claim, hatch
reveal and a few seconds of battle); afterwards every 5th frame of each clip (up to 16) goes to `clips/<name>/`
with a verdict from `tools/frame_stats.gd` (a jump, a flicker, or motion that never settles), and every other
frame is deleted. Look at the sampled frames too: the stats only point at candidates.

**Writing a scenario:** a file `tools/scenarios/<name>.py` with `def run(ctx):` (return a dict to add to the
report). `ctx` (in `_player.py`) has `click(text, index, cid=)`, `button(text)`, `buttons()`, `has_button(text)`,
`go(screen, arg)` (clicks the rail and checks the page), `state()`, `get(path)`, `player()`, `goal()`, `modals()`,
`clear_overlays()`, `wait(s)`, `wait_for(pred, s)`, `skip(hours)`, `check(where)` (call after every action),
`shot(label)`, `log(msg)`, `note(msg)`, `stuck(reason)` (log, screenshot, move on), `gap(what)` (a bridge
shortcut used where no click path existed), `breach(text)` (an invariant broke), `clip(name)`, `time_left()` and
`rng` (seeded). Read with the bridge; act with clicks.

## Recording video (with sound)

Godot's Movie Maker records the game, sound included, frame-perfect:

```
Godot.exe --path . --write-movie C:\temp\run.avi -- --bridge
```

Drive it with the bridge as usual; the video is written when the game quits (`python tools/bridge.py quit`).
It runs at a fixed frame rate, so it can be slower than real time. Pull frames out with ffmpeg to check motion
(`ffmpeg -i run.avi -vf fps=2 frames/%04d.png`) and look for silence with `ffmpeg -i run.avi -af silencedetect -f null -`.

## For a local Claude session

Start the game with `launch`, then `new`, and work in a loop: `buttons` to see what's there, `click` to act,
`errors` after anything that might break, `screenshot` to look. Useful checks: every page opens without an
error, every dialog opens and closes, window modes (click through the Options dialog), long runs (`skip 12`, then `state` for memory and fps), and a `monkey` run of a few
hundred steps.
