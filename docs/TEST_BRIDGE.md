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
| `state` | Scene, page, gold, Aether, skills (level, workers, slots), expedition, pods, boosts, fps, memory, error count, open dialogs, window size and mode |
| `get <path>` | A value from the save by dotted path: `get gold`, `get skills.mining.level`, `get expedition.party` |
| `buttons` | Every button a player could click now: text, centre `x,y`, size, disabled. While a dialog is open, only its buttons |
| `click "<text>" [index]` | A real mouse click (move, press, release) on the button with that text: exact match first, then "contains". Scrolls a list with the mouse wheel to reach a button that's out of view |
| `click_at <x> <y>` | A real click at a point in the game's 1600×900 layout (the `x,y` that `buttons` reports) |
| `scroll <x> <y> [steps]` | Mouse-wheel at a point; positive steps scroll down |
| `key <name>` | A key press: `Escape`, `Enter`, `1` … `9` (page shortcuts), `F11` |
| `go <screen> [arg]` | Jump to a page without clicking: `sanctum`, `skill woodcutting`, `nexus`, `pods`, `expeditions`, `aetherlog`, `inventory`, `market`, `eggmarket`, `works` |
| `new [slot]` / `load [slot]` | Start slot 2 fresh / load it, and open the game screen |
| `title` | Leave to the title screen |
| `skip <hours>` | Fast-forward as time away (the offline summary appears) |
| `game <method> [args…]` | Call any `Game` method, e.g. `game dev_add gold 50000`, `game dev_grant emberfang 3 20 false`, `game start_expedition whisperleaf-hollow` |
| `eval "<expression>"` | A GDScript expression with `Game`, `Data`, `S` (the save) and `M` (the game screen): `eval "S.gold"`, `eval "M.current"` |
| `errors [since]` | Engine and script errors (with a script backtrace when there is one) since error number `since` |
| `screenshot [file.png]` | Saves exactly what the window shows and returns the path |
| `wait <seconds>` | Lets the game run |
| `quit` | Closes the game |
| `monkey [--steps N] [--seed S] [--delay 0.2] [--shots DIR]` | Clicks random enabled buttons (never quit/delete/reset/leave), logs every step, and on the first new error saves a screenshot and prints the errors with the last steps that led to them |

Every reply is JSON with `"ok": true` or `"ok": false, "error": "…"`; the exit code is 0 or 1.

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
