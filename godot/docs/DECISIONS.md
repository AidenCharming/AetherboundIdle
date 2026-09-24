# Aetherbound (Godot rebuild): decisions

This file records what the Godot rebuild changed, added or dropped compared with the reference material
(`CLAUDE.md`, `docs/design.md`, `docs/content-data.md`, `docs/PROGRESS.md`, `src/data/*.json`, `src/sim/`),
and why. The web build on `main` is untouched; everything here lives under `/godot`.

It is written as a running log: newest decisions are added to the relevant section as the build goes.

## Engine and project setup

- **Godot 4.7.2 (latest stable), GDScript.** No C#: the whole game is data plumbing and UI, GDScript is
  plenty fast for it, and it keeps the project openable with the standard (non-.NET) editor.
- **Renderer: GL Compatibility.** It is a 2D UI game; Compatibility runs on older laptops and integrated
  GPUs that Forward+ (Vulkan/D3D12) can struggle with, and it starts faster.
- **Base resolution 1600x900, `canvas_items` stretch, `expand` aspect.** The layout reflows from 1280x720 up
  to 4K; the Options screen also has an interface-scale setting.
- **Content is JSON under `godot/data/`**, loaded once by the `Data` autoload. Balance numbers live in
  `data/tuning.json`. Adding a species, item, action, zone or upgrade is a data change, no code.
- **The simulation is separate from the UI.** `scripts/sim/` holds pure static functions on one state
  Dictionary (no nodes, no scenes). The `Game` autoload owns that state, runs the clock and exposes the
  player actions; screens only read the state and call `Game`. This is what makes offline progress and the
  headless tests straightforward (same rule as the web build).
- **Tests:** `tests/test_*.gd`, run headless with `godot --headless --path godot res://tests/test_runner.tscn`
  (or `godot/tools/check.sh`). Exit code 0 means everything passed.
- **Saves:** three save slots, `user://slot_1.json` … `slot_3.json`, each with a `.bak.json` copy of the
  previous save. Versioned (`version` key) with a migration step that fills in anything a newer build adds.
  The 64-bit RNG state is saved (as a string) so a reload can never re-roll a hatch or a capture. Options
  (audio, display) are separate, in `user://options.cfg`, shared by all slots.
- On Windows `user://` is `%APPDATA%\Godot\app_userdata\Aetherbound Idle\`.

## Art

- **The 72 approved sprites are already in the repo.** The brief said the sprite files were only on the
  designer's machine (`D:\AI\sprites\cutouts`), but commit `42dad21` on `main` ("Art: all 24 base species'
  sprites in the repo") had copied all 72 cutouts into `src/ui/assets/creatures/`. I copied them (not
  moved; `src/` is untouched) into `godot/assets/creatures/`, so **the real art is in the game now** and
  nothing needs dropping in. See "Sprite files" below for the exact list, in case the designer wants to
  replace them with newer cutouts.
- **Hybrids have no art yet** (15 default + 30 special). They show as an intentional placeholder: a soft
  "aether blob" in the hybrid's two type colours, with eyes, drawn by a shader. It is clearly a
  placeholder, but on purpose, and it matches the outlined sprite style.
- **Item and interface icons are generated**, not downloaded: `godot/tools/make_icons.py` (standard library
  Python) draws every item from ~30 shape templates (log, ore, gem, fish, ingot, meal, vessel, …) in the
  item's colour, with the same thick dark outline the creature sprites use, plus ~30 interface icons
  (skills, navigation, currencies, stats). Add an item → give it an `icon` entry in `items.json` → run the
  script.
- **Fonts:** Fredoka (headings, rounded, fits "cute stays cute") and Nunito (body text). Both SIL Open Font
  License; the licence files are next to the fonts in `assets/fonts/`.
- **Background:** the designer's approved Sanctum background (`app-bg.jpg`, floating islands at night) is
  reused as the backdrop, plus shader-drawn skies elsewhere.
- **Look:** night-sky indigo glass panels, a luminous aether-cyan accent for anything magical or
  interactive, firefly gold for currency and rewards. Type colours stay reserved for creatures.
- Rarity is a frame colour and glow; shinies are a runtime hue shift (per-type hue, Void shifts to teal like
  the web build). No per-rarity or per-shiny art, same rule as before.

### Sprite files

All at `godot/assets/creatures/<species id>-f<form>.png`, **512x512 RGBA PNG with transparent background**,
creature centred, facing roughly the same way as the existing ones. Form 1 is the base form, 2 and 3 are
the evolutions. To replace or add art, drop a file with the same name over the old one; Godot re-imports it
on the next editor launch. The 72 files present now:

| Species (id) | Files |
|---|---|
| sproutlet, brambletrundle, mossgear, buzzbud | `<id>-f1.png`, `<id>-f2.png`, `<id>-f3.png` |
| quakemaw, geodecore, pebblescoot, tuskcub | same pattern |
| emberfang, cinderpup, roastbelly, charwhisk | same pattern |
| dewdrop, puddlescoop, frothsprite, splashfin | same pattern |
| voltfluff, joulebug, plasmaplug, coilchirp | same pattern |
| eclipsa, riftsneak, hushflutter, netherpod | same pattern |

Hybrids, when their art exists: same naming with the hybrid's id (for example `ashwood-f1.png`), and set
`"sprite": "<id>"` on that species in `data/species.json` (it is `null` today, which is what makes the
placeholder appear). The ids are the lower-case names in `data/species.json`.

## Content taken from the reference

- All 24 base species, 15 default hybrids, 30 pool traits and all signature traits, names unchanged.
- **The 30 drafted special recipes** from `docs/naming/chunk1-3-claude.md` are in (as special hybrids with
  their own forms, trait, ability and Aether-Log hint). Chunk 1's pair assignments were flagged in that file
  as a reconstruction the designer had not reviewed; they are used as written. Mechanics in those drafts
  that only make sense in combat ("bonus Health while working Cooking") were made unconditional stat
  bonuses, and "bind rate while working Herbalism" became a party bind-rate bonus.
- Type wheel, Void rules (1.25 dealt / 0.75 taken, half for Void hybrids), rarity ladder names, vessel
  names, zone and boss names are the reference ones.

## Changes to the reference design

### Pacing and levels
- **Skill max level 99** (reference: 250), XP curve base 100 × 1.12^(level-1), and **work slots at levels
  1/15/30/50/75** (reference: 1/50/100/165/225). The 250 cap spread five slots over a year of play, so the
  roster (the heart of a creature collector) had nothing to do for months. With the shorter curve the
  first level comes in about a minute, a second slot in the first half hour, level 50 in days and 99 in
  weeks of a dedicated team.
- **Five resource tiers per skill at levels 1/10/25/45/70.** The reference authored three Woodcutting tiers
  only; every skill now has five.
- **Creature max level 60, forms at 20 and 40** (reference: 99, 30 and 60), so evolutions happen in the first
  sessions. Creatures now earn **half of the skill XP they produce** while working, as well as combat XP; the
  reference only gave combat XP, which meant a creature that never fought never evolved.
- **Primary skill matters for base species too:** +10% speed on their own primary skill
  (`skills.specialistBonus`). In the reference only hybrids used it.

(more sections are added below as systems land)
