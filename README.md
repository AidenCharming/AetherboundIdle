# Aetherbound Idle (Godot)

A creature-collecting idle game: collect Aetherlings, put them to work, explore the islands to bind wild
ones, and breed rarer and hybrid forms. Built with Godot 4.7 (the earlier web version is archived on the `web-archive` branch).

What changed from the web version's design, and why: [`docs/DECISIONS.md`](docs/DECISIONS.md).

See `docs/HANDOFF.md` for where things stand and what is open, and `docs/CHANGELOG.md` for what was done or fixed.

Bug testing with a script or a local Claude session driving the running game: [`docs/TEST_BRIDGE.md`](docs/TEST_BRIDGE.md).

## Open and run

1. Install **Godot 4.7** (the standard build, not .NET): <https://godotengine.org/download>. It is a
   single executable; no installer needed.
2. Start Godot. In the Project Manager choose **Import**, pick `project.godot` in this repo, then
   **Import & Edit**. The first open takes a minute while Godot imports the sprites and icons.
3. Press **F5** (or the ▶ Play button, top right) to run the game.

From a terminal: `godot --path .` runs the game; `godot --path . -e` opens the editor.

## Build a Windows .exe

1. In the editor: **Editor > Manage Export Templates > Download and Install** (once per Godot version).
2. **Project > Export**, choose **Windows Desktop**, **Export Project**, and save it as
   `Aetherbound Idle.exe`. The result is one self-contained file (about 130 MB).

The `export/` folder is git-ignored.

## Where things are

| Path | What |
|---|---|
| `data/*.json` | All content and balance numbers (species, traits, items, skills and actions, zones, upgrades, goals, tuning) |
| `scripts/sim/` | The game rules as pure functions on one state Dictionary; no nodes, no UI |
| `scripts/autoload/` | `Data` (content), `Game` (state, clock, saves, player actions), `Options`, `Music`, `Sfx` |
| `scripts/ui/` | Title screen, game shell, screens and widgets (built in code) |
| `assets/creatures/` | Creature sprites, `<species id>-f<form>.png`, 512×512 transparent PNG |
| `assets/icons/` | Generated item and interface icons (`tools/make_icons.py`) |
| `assets/shaders/` | Sky, creature (shiny palettes, silhouettes), hybrid placeholder, egg, light rays |
| `tests/` | Headless tests, a screenshot tour, a balance probe and a one-month pacing probe (`month_probe.tscn`) |

Saves are in three slots under Godot's user folder (on Windows
`%APPDATA%\Godot\app_userdata\Aetherbound Idle\`). The game keeps working while closed, up to 12 hours
(more with the Dream Anchor upgrade).

## Tests

```
godot --headless --path . --import                       # once, after cloning
godot --headless --path . res://tests/test_runner.tscn   # exit code 0 = all passed
```

Or `tools/check.sh [path-to-godot]`, which does both.

Visual tour (needs a display; writes a PNG of every screen and dialog; overwrites save slot 3):

```
godot --path . res://tests/tour.tscn -- --out=/some/folder
```

Balance probe (prints how far sample parties get on each island):

```
godot --headless --path . res://tests/balance_probe.tscn
```

Month probe (a dedicated player's first month through the real sim: the day each skill reaches 10/30/50/70/
90/99 and each island is first cleared; about 40 s; `--calibrate` and `--rates` are the tuning modes
described in docs/DECISIONS.md under Pacing):

```
godot --headless --path . res://tests/month_probe.tscn -- --days=35
```

## Adding art

Drop `<species id>-f1.png`, `-f2.png` and `-f3.png` (512×512, transparent) into `assets/creatures/` and
open the project in the editor. Any species with a file uses it; the rest show the aether-blob
placeholder. The ids are in `data/species.json`, and `docs/DECISIONS.md` lists the ones still missing.

## Painted icons (FLUX.2 in ComfyUI)

Every item and interface icon has a ready-to-paste prompt in [`docs/art-prompts-icons.md`](docs/art-prompts-icons.md),
built by `tools/art/build_icon_prompts.py` (edit its table and rerun). `tools/art/icon_runner.py` runs them through
ComfyUI with the same graphs as the creature pipeline and uses its `batch_runner.py` and `sprite_tools.py` from
`D:\AI\tools`:

```
python build_icon_prompts.py            writes the prompt doc and D:\AI\tools\icons.json
python icon_runner.py run --count 4     candidates for every icon (resumable)
python icon_runner.py pick oak-log 3    approve one
python icon_runner.py finish            cut out approved icons and copy them into assets/icons/
```

A `<id>.png` in `assets/icons/items/` or `assets/icons/ui/` replaces that icon's SVG placeholder automatically.

## Island backdrops

Each expedition island has a painted battle backdrop prompt in [`docs/art-prompts-zones.md`](docs/art-prompts-zones.md)
(same builder and runner, `--group zone`). `finish --group zone` square-crops the approved picture to 1024 px and copies
it to `assets/zones/<zone id>.jpg`. Until a file exists, the battle view draws a simple landscape in the island's
colour. Creatures stand at 84% of the height (back row 77%), so the bottom third of a backdrop must be flat ground.

## Adding items

Add the item to `data/items.json` with an `icon` entry (`{"shape": "ore", "color": "#d27a3c"}`; the
shapes are in `tools/make_icons.py`) and run `python3 tools/make_icons.py` from this folder.
