# Aetherbound (Godot rebuild): decisions

What the Godot rebuild changed, added or dropped compared with the reference material (`CLAUDE.md`,
`docs/design.md`, `docs/content-data.md`, `docs/PROGRESS.md`, `src/data/*.json`, `src/sim/`), and why. The
web build on `main` is untouched; everything here lives under `/godot` on the `godot-rebuild` branch.

Sections: [Engine and setup](#engine-and-project-setup) · [Art](#art) · [Sprite files](#sprite-files) ·
[What the game is now](#what-the-game-is-now) · [Added](#added) · [Changed](#changed) ·
[Dropped or not built](#dropped-or-not-built) · [Numbers](#numbers-first-pass) · [Open questions](#open-questions-for-the-designer)

## Engine and project setup

- **Godot 4.7.2 (latest stable), GDScript.** No C#: the game is data plumbing and UI, GDScript is fast
  enough (see "Speed" below), and it keeps the project openable
  in the standard (non-.NET) editor.
- **Renderer: GL Compatibility.** It is a 2D UI game; Compatibility runs on older laptops and integrated
  GPUs and starts faster than Forward+.
- **Base resolution 1600×900**, `canvas_items` stretch with `expand`, so it reflows from 1280×720 to 4K.
  Options has window mode, window size, VSync, a frame-rate cap and an interface scale.
- **Content is JSON under `godot/data/`**, loaded once by the `Data` autoload; balance numbers are in
  `data/tuning.json`. Adding a species, item, action, zone, upgrade or goal is a data change.
- **Speed:** a busy mid-game save (13 workers across every skill plus an expedition) resolves a full
  12-hour offline window in about half a second here; `tests/test_perf.gd` guards it.
- **The simulation is separate from the UI.** `scripts/sim/` holds pure static functions on one state
  Dictionary (no nodes, no scenes). The `Game` autoload owns that state, runs the clock and exposes every
  player action; screens only read the state and call `Game`. Same rule as the web build, and it is what
  makes offline progress and the headless tests simple.
- **Offline progress is elapsed ÷ cooldown in bulk**, never a tick replay. The away window is split into
  40 slices so production chains feed each other (ore mined in slice 3 is smelted in slice 4). Random
  outcomes over many actions use binomial sampling. Expeditions run the real battle for up to 30 runs,
  then extrapolate the rest of the window from the kill and boss rates those runs produced.
- **Saves:** three slots (`user://slot_1.json` … `slot_3.json`), each with a `.bak.json` copy of the
  previous save; JSON, versioned, with a migration step that fills in anything a newer build adds. The
  64-bit random generator state is saved (as a string, since JSON numbers lose precision) and every
  committed roll (breeding, hatching, attunement, binding) saves at once, so a reload can never re-roll
  anything. Options are separate (`user://options.cfg`) and shared by all slots. On Windows `user://` is
  `%APPDATA%\Godot\app_userdata\Aetherbound Idle\`. The pause menu can copy a save to the clipboard and
  restore one from pasted text.
- **Tests:** `tests/test_*.gd`, 72 tests (including `test_ui.gd`, which presses real dialog buttons), run headless (see the README). Also `tests/tour.tscn`, which
  renders every screen and dialog to PNG (for visual checks), and `tests/balance_probe.tscn`, which prints
  how far sample parties get on each island.
- **Export:** `export_presets.cfg` has a Windows Desktop preset (one self-contained `.exe` with the app
  icon, ~130 MB) and a Linux one. Both were exported and the Linux build was booted to confirm the
  packed data loads. The `.exe` itself is not committed (it is over GitHub's file size limit, and build
  output doesn't belong in git).

## Art

- **The 72 approved sprites were already in the repo.** The brief said they were only on the designer's
  machine (`D:\AI\sprites\cutouts`), but commit `42dad21` on `main` ("Art: all 24 base species' sprites in
  the repo") had copied all 72 cutouts into `src/ui/assets/creatures/`. I copied them (not moved; `src/` is
  untouched) into `godot/assets/creatures/`, so **the real art is in the game now**. See "Sprite files"
  for what is still missing (all hybrids) and how to add it.
- **Hybrids without art show an intentional placeholder:** a soft "aether blob" in the hybrid's two type
  colours, with eyes, blush and a crest that grows with its form, drawn by a shader in the sprites' dark
  outline style. It looks like a sketch waiting for art, not a missing file.
- **Item and interface icons are generated**, not downloaded: `tools/make_icons.py` (standard library
  Python) draws every item from ~30 shape templates (log, ore, gem, fish, ingot, meal, vessel, spool…) in
  the item's colour with the same thick outline the creature sprites use, plus ~30 interface icons
  (skills, navigation, currencies, stats). New item → give it an `icon` entry in `items.json` → run the
  script.
- **Painted icons are optional and drop-in:** `docs/art-prompts-icons.md` has a FLUX.2 prompt for all 92 icons
  (90 to generate; the top bar's vessel and meal reuse item icons), built by `tools/art/build_icon_prompts.py` with
  the creature pipeline's rules (magenta key, green for pink and purple things, no glow words, everything opaque).
  `tools/art/icon_runner.py` generates, picks and cuts them out with the existing `batch_runner.py` and
  `sprite_tools.py`, and installs them into `assets/icons/`. The game uses a PNG icon whenever one exists and the
  SVG placeholder otherwise. New PNGs import with mipmaps (a project import default), so they stay smooth at 24 px.
- **Battle backdrops** (designer's request: fighters used to hover over two floating island ovals). The
  battle is now a side-view stage: every fighter stands on one ground line (front row at 84% of the view's
  height, back row at 77% and a little smaller), placed by the lowest opaque pixel of its sprite so empty
  space under the art never lifts it, with a soft shadow at its feet and its name and health bars above its
  head. Behind them is a painted backdrop per island, `assets/zones/<id>.jpg`, with prompts in
  `docs/art-prompts-zones.md` (10 islands; `icon_runner.py --group zone`). Until one exists the game draws a
  landscape in the island's type colour: haze, two ranges of hills, open ground.
- **Fonts:** Fredoka (headings; rounded, fits "cute stays cute") and Nunito (body). Both SIL Open Font
  License; licence files are next to them in `assets/fonts/`. They cover Latin only, so interface text
  avoids symbols outside that range.
- **Look:** night-sky indigo glass panels, a luminous aether cyan for anything magical or interactive,
  firefly gold for rewards and currency, all taken from the designer's approved Sanctum background
  (reused on the title screen and the Sanctum hub). Other screens use an animated shader sky tinted per
  screen and per island. Type colours stay reserved for creatures.
- **Rarity** is a coloured rim arc and a glow around the art plate. No per-rarity art, same rule as before.
- **Shinies (reworked at the designer's request):** instead of one global hue rotation (which turned most
  shinies blue), each type has its own shiny palette, applied as a gradient map that keeps the dark
  outline, the shading and the white highlights: Verdant *autumn gold*, Telluric *rose quartz*, Pyric
  *blue flame*, Aqueous *sunset coral*, Voltaic *neon violet*, Void *aurora teal* (keeping the designer's
  earlier teal choice for Void). Shinies also get a slow sparkle sweep and twinkling four-point glints.
  Hybrids use their first type's palette. The palettes are three colours per type in `data/types.json`
  (`"shiny": {dark, mid, light}`), easy to retune. The Aether-Log shows each species' shiny colours once
  you own that shiny.
- **Music and sound effects are synthesised in code** (no audio files), with separate Music and SFX volume
  sliders.
  - **Tracks** (`Music.TRACKS`): title, Sanctum and expedition are calm, built from a pad, a sub bass and a
    bell arpeggio. The **boss** track is D minor, i-VI-VII-V with a chord every bar at 138 bpm (expedition is
    104 with a chord every two bars). It has plucked saw sixteenths, a pulsing saw bass, a kick and hi-hat,
    and a square lead in its B section.
  - **Boss switching:** the arena plays the boss track while a boss wave is fighting on screen. Victory, a
    wipe, stopping the run or switching to another island's page brings the expedition track back. It
    follows the battle state, not just the banner, so leaving mid-boss and coming back is handled.
    `Music.play` does the usual 2-second crossfade.
  - **Variation:** each loop plays its four chords four times, in an A / A2 / B / A form:
    - A2 fills the arpeggio's rests with soft ghost notes and ends on a rising run.
    - B turns the arpeggio upside down an octave higher. On a track with a lead, the lead sings the top line
      instead.
    - The pad and bass stay the same throughout, so each track is still one piece. Loops now run 55 s (boss)
      to 2 min (title).
  - **Timbres:** besides pad, bell and sine, there are PolyBLEP saw and square voices, each through a two-pole
    low-pass that opens at the attack. Two filtered-noise drums: a kick (a falling sine plus low-passed
    noise) and a hat (high-passed noise). Title, Sanctum and expedition use only pad, bell and sine, as
    before.
  - **Space:** the Music bus carries an `AudioEffectDelay` with taps at 3/4 and 1.5 beats, re-timed to each
    track's tempo when it starts, the same echo the samples used to have baked in. After it come an
    `AudioEffectReverb` and a hard limiter. The hand-rolled echo that wrapped round the loop point is gone.
  - **Level:** every loop is normalised to the same loudness (RMS 0.17, peaks at most 0.95), so a track change
    doesn't jump in volume.
  - **Rendering:** tracks render on a worker thread the first time, about 25 s in total with the title track
    first (about 7 s). They are cached in `user://music/`, keyed by the track's settings and
    `Music.RENDER_VERSION`, and stale renders are deleted.
  - **Sound effects:** a dozen short effects. **Evolution** has its own: two voices sweep up two octaves into a
    full major chord with a sparkle run, where hatching is a single run of notes.
- **Bosses reuse approved art:** each boss is a species' Form 3 sprite with its own name and stats
  (Granitusk is Tuskcub's Form 3, Ignis Prime is Emberfang's, and so on).

## Sprite files

All live in `godot/assets/creatures/` as `<species id>-f<form>.png`, **512×512 RGBA PNG with a transparent
background**, creature centred. Form 1 is the base form, 2 and 3 the evolutions. **To add or replace art,
drop a file with that name into the folder and open the project in the editor** (it imports new files on
launch). No JSON edit is needed: a species uses its sprite as soon as the file exists, and the aether-blob
placeholder otherwise.

**Present (72):** `<id>-f1.png`, `-f2.png`, `-f3.png` for all 24 base species: sproutlet, brambletrundle,
mossgear, buzzbud, quakemaw, geodecore, pebblescoot, tuskcub, emberfang, cinderpup, roastbelly, charwhisk,
dewdrop, puddlescoop, frothsprite, splashfin, voltfluff, joulebug, plasmaplug, coilchirp, eclipsa,
riftsneak, hushflutter, netherpod.

**Still needed (135): every hybrid, three forms each** (`<id>-f1.png`, `<id>-f2.png`, `<id>-f3.png`):

| Default hybrid id | Forms | Types |
|---|---|---|
| `ashwood` | Ashwood / Emberbark / Hearthtrunk | Verdant / Pyric |
| `brambletide` | Brambletide / Briarripple / Thicketwave | Verdant / Aqueous |
| `sproutfault` | Sproutfault / Timbershale / Lumbercrag | Verdant / Telluric |
| `mosscoil` | Mosscoil / Mossfuse / Canopygrid | Verdant / Voltaic |
| `mudskulker` | Mudskulker / Shaleflow / Bedrocktide | Telluric / Aqueous |
| `quakeforge` | Quakeforge / Slagfist / Craterhearth | Telluric / Pyric |
| `geodegrid` | Geodegrid / Crystalwire / Prismvolt | Telluric / Voltaic |
| `cinderbasin` | Cinderbasin / Steamrill / Kettlebrine | Pyric / Aqueous |
| `embersurge` | Embersurge / Blazearc / Infernodynamo | Pyric / Voltaic |
| `brinecore` | Brinecore / Rillarc / Tidebolt | Aqueous / Voltaic |
| `eclipseed` | Eclipseed / Starsap / Nightbloom | Void / Verdant |
| `nullshale` | Nullshale / Riftrock / Abysscrag | Void / Telluric |
| `gloamforge` | Gloamforge / Muteember / Hushkiln | Void / Pyric |
| `hushflow` | Hushflow / Nullstream / Riftcurrent | Void / Aqueous |
| `gridrift` | Gridrift / Corewire / Lodestar | Void / Voltaic |

| Secret hybrid id | Forms (animal) | Types |
|---|---|---|
| `sorrelcliff` | Sorrelcliff / Fernscarp / Highhorn (a mountain goat) | Verdant / Telluric |
| `hazelslate` | Hazelslate / Mossflint / Grovepeak (a tortoise) | Verdant / Telluric |
| `brackensear` | Brackensear / Thornkiln / Scaldhearth (a hedgehog) | Verdant / Pyric |
| `yarrowflare` | Yarrowflare / Bloomember / Petalblaze (a sunbird) | Verdant / Pyric |
| `sedgestilt` | Sedgestilt / Reedcurrent / Willowmire (a heron) | Verdant / Aqueous |
| `rowanboulder` | Rowanboulder / Fernbrook / Alderfalls (an otter) | Verdant / Aqueous |
| `ivyflux` | Ivyflux / Vinespark / Leafcharge (a dragonfly) | Verdant / Voltaic |
| `burrbolt` | Burrbolt / Quillspark / Quillstatic (a squirrel) | Verdant / Voltaic |
| `cliffscorch` | Cliffscorch / Sunspire / Blazingpeak (a scorpion) | Telluric / Pyric |
| `nettlemesa` | Nettlemesa / Spurmesa / Spinehearth (a horned lizard) | Telluric / Pyric |
| `gravelnip` | Gravelnip / Reefpincer / Boulderclaw (a crab) | Telluric / Aqueous |
| `ripplesnap` | Ripplesnap / Slatesnout / Ridgehide (a crocodile) | Telluric / Aqueous |
| `cairnflit` | Cairnflit / Pumiceglide / Fluxwing (a bat) | Telluric / Voltaic |
| `flintlamb` | Flintlamb / Ampcurl / Mesahorn (a ram) | Telluric / Voltaic |
| `coralpeep` | Coralpeep / Flarewade / Pyreplume (a flamingo) | Pyric / Aqueous |
| `drizzlenub` | Drizzlenub / Brooksoak / Lavabask (a capybara) | Pyric / Aqueous |
| `coalgrub` | Coalgrub / Arcflicker / Blazefly (a firefly) | Pyric / Voltaic |
| `boltkit` | Boltkit / Brandtail / Scorchfox (a fox) | Pyric / Voltaic |
| `eddyelver` | Eddyelver / Kelpeel / Dynamoeel (an eel) | Aqueous / Voltaic |
| `sprayfledge` | Sprayfledge / Pulsedart / Voltfisher (a kingfisher) | Aqueous / Voltaic |
| `murkroot` | Murkroot / Palevine / Loamgrove (a mole) | Void / Verdant |
| `duskbloom` | Duskbloom / Wanevine / Waneflower (a hare) | Void / Verdant |
| `riftshale` | Riftshale / Chasmclaw / Gravelgrit (a badger) | Void / Telluric |
| `nethershale` | Nethershale / Grimplate / Grimstone (an armadillo) | Void / Telluric |
| `wraithcoal` | Wraithcoal / Ashgloam / Ashplume (a vulture) | Void / Pyric |
| `duskflare` | Duskflare / Wanescorch / Sunflare (a jackal) | Void / Pyric |
| `murkmire` | Murkmire / Murkveil / Sootveil (a jellyfish) | Void / Aqueous |
| `hollowstream` | Hollowstream / Hollowbrook / Palepool (a newt) | Void / Aqueous |
| `wraithwire` | Wraithwire / Wanewire / Faintpulse (a mantis) | Void / Voltaic |
| `duskvolt` | Duskvolt / Wanecoil / Faintweb (a spider) | Void / Voltaic |

To replace any of the 72 existing sprites with newer cutouts, overwrite the file of the same name.

## What the game is now

A creature-collecting idle game in five loops that feed each other:

1. **Work.** Eleven skills, each with five tiers of actions. Aetherlings in work slots complete actions on
   their own cooldown (faster with level, rarity, form, traits and fit). Gathering (Woodcutting,
   Herbalism, Mining, Fishing, Scavenging) feeds crafting (Smithing, Cooking, Circuitry, Aether-Weaving,
   Vessel Crafting, Fabrication).
2. **Explore.** Six islands of waves ending in a boss, fought automatically in real time by a party of
   three. Defeated wild Aetherlings can be bound with Aether Vessels (the only way to get base species).
   Beating a boss opens the next island.
3. **Breed.** Two parents plus Aether and element materials lay an egg in a Genesis Pod; its species comes
   from the parents (type-pair hybrids and 30 secret exact-pair recipes), its rarity from the materials'
   tier and the parents' rarity, with mutation, shiny and trait inheritance rolls. Eggs hatch with a
   reveal.
4. **Grow the Sanctum.** Resting Aetherlings on perches make Aether; gold and crafted parts build Sanctum
   Works upgrades (pods, perches, an Aether extractor, longer offline time, more meals per run).
5. **Collect.** The Aether-Log tracks species, forms, recipes, rarities and shinies, with milestone rewards
   and titles; secret recipes show a hint until found. Every rarity of every species is its own entry:
   owning a species at a rarity you have not had before is announced ("New in the Aether-Log: Faint
   Buzzbud") and pays 5 × 2^(rarity − 1) Aether (Faint 10 … Zenith 1,280; `collection.json` `newRarity`).
   The Creaturedex opens with a strip of all five tracks' counts (designer's request).

Onboarding is a chain of 26 goals from "Overseer Vance" on the Sanctum screen, each paying a small reward.

## Added

- **Title screen, three save slots, Options and in-game pause menu** (designer's request during the
  build): Continue (most recent slot), New Game (pick a slot; overwriting asks first), Load Game (slot
  cards show play time, creatures, species, best skill, islands cleared, last played; delete with
  confirmation), Options, Credits, Quit. The pause menu (Esc) has Resume, Options, Save now, Back up or
  restore, Developer tools (optional), Save and return to title, Save and quit.
- **Options:** master / music / sound-effect volume, mute in the background, window mode (windowed,
  borderless fullscreen, exclusive fullscreen), window size (1280×720 to 3840×2160), VSync, frame-rate cap
  (30 to 240 or unlimited, with the monitor's refresh rate shown), background frame rate, interface scale,
  reduce motion, damage numbers, screen shake, toast notifications, developer tools.
- **The Sanctum hub:** every skill as a station with its workers, live progress rings and floating
  pickups; perches; the expedition and pods at a glance; the current goal.
- **Overseer Vance's goal chain** (`data/goals.json`): the reference had "tutorial script: TBD"; this is a
  light version that walks through every system once.
- **Perches:** only a limited number of resting Aetherlings (4 at first, 16 with upgrades) emit Aether,
  rarest first. Without a cap, a big roster of Dim creatures would out-earn rarity; with it, rarity is what
  the bench rewards, and roster growth has a direction.
- **Sanctum Works upgrades** (`data/upgrades.json`): Genesis Pods (2 → 6), Nexus Perches (4 → 16),
  Resonance Extractor (the reference's "Aether infrastructure buildings": flat Aether per minute), Dream
  Anchor (offline cap 12 → 24 h; the reference listed "offline-cap extension" as a sink), Supply Crates
  (meals per run). They cost gold plus crafted parts, which gives Circuitry and Fabrication their purpose.
- **Meals:** Cooking makes expedition food; the party eats one between waves when anyone is below 60%
  Health. This is Cooking's job in the economy.
- **Vessel market:** Tinker's Vessels always buyable for gold, so a player can never be stuck without a
  way to bind.
- **Sell prices follow two rules** (designer's, checked by `test_content.gd` `test_market_prices`):
  anything the shop sells sells back for at most half its shop price, so buy-and-resell never pays
  (Tinker's Vessel: buy 30, sell 12, was 5); and every crafted item sells for at least 1.25× its inputs,
  so crafting and selling always beats selling the raw materials. The first pass broke the second rule:
  vessels sold for about half their inputs and circuitry parts and the Aether Lantern for barely more,
  so those were raised (Sturdy 15 → 50, Polished 40 → 110, Resonant 90 → 225, Luminescent 200 → 450,
  coils to dynamos about 1.3× their inputs, Aether Lantern 300 → 385).
- **Aether Crystals:** a rare drop from every crafting skill, shattered in the Inventory for Aether.
- **Scavenging** yields salvage (scrap, springs, lenses, clockwork, starglass) plus a little gold per
  action; Fabrication and Circuitry use the salvage.
- **Specialist bonus:** a base species works its own primary skill 10% faster (in the reference only
  hybrids used their primary skill).
- **Nicknames, locking, releasing for Aether, and bulk release** in the Nexus (the reference's roster
  tool): releases resting, unlocked, non-shiny Aetherlings up to a chosen rarity, and always keeps the
  best of each species.
- **Developer tools** (off by default): grant any species at any rarity, level and shiny; add Aether,
  gold or items; fast-forward; finish eggs; set skill levels. For testing art, shinies and balance.
- **Keyboard shortcuts:** 1–7 for the main screens, Esc for the menu.
- **Void first-clear reward:** beating The Aetherial Apex the first time brings a Void Aetherling home
  (the reference's "guaranteed first capture from the final zone's boss").

## Changed

### Pacing
- **Creature XP curve** (designer feedback: one cleared Fractured Quarry run gave ten levels): now
  `6 × level^2.9` XP per level (was `40 × 1.13^(level − 1)`, which was cheap early and exploded after 60).
  Measured with `tests/balance_probe.tscn`, a party fighting at its own level takes about 3–5 minutes per
  level early on, 10–20 in the middle islands and 30–45 at the top: roughly 30 hours of expedition time to
  level 100, with offline time counting. One run at your level is now a fraction of a level
  (`test_one_run_is_a_fraction_of_a_level`). Saves keep every creature's level: migration resets XP to the
  start of the saved level when the curve no longer matches it.
- **Skill max level 99** (reference 250) with a new XP curve, `10 × level² × 1.06^(level-1)`, found by
  modelling a team that grows as slots open against targets: first level in seconds, level 10 in about
  half an hour, 30 in about 8 hours, 50 in about 2 days, 99 in about two months for a full team.
  `tests/test_pacing.gd` guards the lone-starter landmarks.
- **Five action tiers in every skill, at levels 1/10/25/45/70**, and **work slots at the same levels**, so
  each new tier comes with a new worker. The reference spread five slots over a year of play
  (1/50/100/165/225), which left the roster with nothing to do for months.
- **Creature max level 60, forms at 20 and 40** (reference 99, 30 and 60), so evolutions (with their
  reveal) happen in the first sessions. **Working creatures earn half the skill XP they produce**; the
  reference only gave combat XP, so a creature that never fought never evolved.
- **Rarity stat multipliers softened** to 1.0 → 6.8 (reference 1 → 24), so a high-level Dim is still
  useful and rarity is an upgrade rather than a wall. Bench emission doubled (Dim 2/min, doubling per
  tier) to make early breeding reachable.

### Breeding
- **The pool-trait roll** (an open question in the reference, blocking its Phase 2): a new creature rolls
  0/1/2/3 pool traits with weights 35/40/20/5; strength Minor 65%, Moderate 28%, Major 7%; a trait of the
  creature's own type is 3× as likely; Void-only traits only on Void creatures and at Moderate minimum.
  Offspring inherit each parent trait with 40% chance (strength can drift one step), fill up with fresh
  rolls if nothing passed down, and have a 5% chance of one extra mutation trait. All in `tuning.json`.
- **Rarity:** the materials' tier sets the ceiling (tiers 1–5 → Faint, Steady, Luminous, Brilliant,
  Zenith). The odds centre on the parents' average rarity and fall off by `stepWeight` (0.18) for each tier
  away from it, never below the weaker parent. Then the two mutation rolls (+1 at 15%, +2 at 2.5%, halved
  for the top two tiers) can pass the ceiling. The full odds are shown before laying. With tier 1
  materials: Dim + Dim → Faint 25%; Dim + Faint → Faint 49%, Steady 9%; Faint + Faint → never Dim, Steady
  15%. (First version: the odds started at the *rounded-down* average with a 0.45 falloff, so Dim + Dim
  gave Faint 36% and Dim + Faint was exactly the same as Dim + Dim. Designer feedback: too generous for
  two Dims, and a rarer parent must help.)
- **Materials:** 5 per parent of that parent's element at the chosen tier (logs, ores, bars, fish,
  components, threads) plus Aether 100 → 25,600. The reference's special Void-offspring rule is
  simplified: Void just needs threads.
- **Hybrid parents breed true** (a hybrid × anything gives one of the two parents' species), same-type
  pairs give one of the two parents, and the reference's rare "sibling species" is not built (no content).
- **Eggs:** 2 minutes to 4 hours by tier, sped up with Aether; the shell glow shows the true rarity 75% of
  the time and a neighbouring tier otherwise ("sometimes misleading").

### Expeditions and combat
- Real-time automatic battles (attacks on the creature's own interval, abilities on tempo cooldowns,
  damage `power² / (power + guard)` × type wheel × ability multiplier). The type wheel and Void rules are
  the reference's. All seven ability effects are implemented, with Quick/Standard/Heavy tempos.
- **Islands:** the reference's four named zones plus a named starter island (*Whisperleaf Hollow*, boss
  *Old Thicketroll*; the reference had "none/tutorial") and a named Voltaic island (*Thunderhum Steppe*,
  boss *Stormcrest, the Relay Eagle*; the reference had "TBD"). **Islands open by beating the previous
  boss** instead of gear requirements (gear is not built).
- **Four late islands for levels 59–95** (designer's request), each unlocked by the one before:
  *Verdigris Canopy* (Verdant, 59–67, boss *Lumbercrown, the Canopy King*), *Magmaglass Rift* (Pyric,
  68–76, *Craterchomp, the Magma Maw*), *Stormsea Expanse* (Aqueous, 77–85, *Brinesoul, the Drowned
  Storm*) and *Zenith Spire* (Void, 86–95, *The Hollow Sovereign*, level 97). Their wild pools mix two or
  more types, their rarity odds climb (Zenith Spire can field Resplendent), they drop tier-5 materials and
  Aether Crystals, bosses pay Luminescent Vessels, and each first clear gives a Gleaming or Luminous
  creature. The **creature level cap is now 100** (was 60) so these islands have somewhere to go. Balance
  probe: a Gleaming party handles the Rift at 72, the Expanse needs Luminous, the Spire wants Radiant (or
  Luminous in the 90s). Four goals follow the old last boss goal.
- A wiped party rests 20 seconds and tries again (the reference's "briefly exhausted").
- **The party is locked while an expedition runs.** Adding, swapping, removing, putting a member to work,
  resting or releasing one is refused until the expedition is stopped. (At first a party change restarted
  the run, which let a new member join mid-boss and threw away the run in progress.) Moving the party to
  another island is still allowed: it is an explicit "abandon this run" action.
- **Vessels: five tiers** (Tinker's, Sturdy, Polished, Resonant, Luminescent). Flimsy was dropped (weaker-
  sounding than the starter) and Aetheric Matrix too (and "Aetheric" is on the banned-root list). Bind
  chance = vessel base × falloff^(rarity − 1) × party bind bonus. Fabrication makes Tinker's and Sturdy;
  Vessel Crafting (Void) makes the higher tiers.
- First capture of each type is free and guaranteed; shinies always get a throw, never flee, and wait in
  a pending list if no vessel is left; auto-bind has an on/off switch, a vessel choice, a minimum rarity
  and "always try species I don't own" (all from the reference), plus **"keep at most N per species"**
  (default 5; a copy rarer than your best is always tried). The default minimum is Faint. Found by
  simulation: with the reference's rules a mid-game save bound about 4,600 Aetherlings in 12 hours away;
  with these defaults it binds a few dozen.

### Traits
- **The worker picker shows what each creature brings to the job** (designer's request): under the speed
  line, one green line per trait bonus that does something on the current action, as the numbers the sim
  uses (double output, materials saved on crafting actions only, rare and treasure finds as the boost to
  their rate, XP, partner-element drops). `Skills.work_perks()` computes them; `Describe.work_perk()` words them.
- **Overclocked** (ambiguous in the reference): +2% speed per completed action, up to +10%, reset when the
  creature is moved or its task changes.
- Rare-drop and treasure traits multiply the base chance (`× (1 + 10 × bonus)`), so a Moderate trait
  doubles a 1% drop rather than adding 10% flat.
- Special-recipe traits that only made sense in combat ("bonus Health while working Cooking") became
  unconditional stat bonuses; "bind rate while working Herbalism" became a party bind-rate bonus.

### Skills
- **Aether-Weaving** makes threads from Aether and herbs (Void breeding material and vessel parts)
  instead of "enchanting" gear, since gear is not built. **Circuitry** makes components for Sanctum Works.
  **Fishing** has a treasure drop.
- **Action cards end with a "You have" block**: a live count, in large type, of the thing the task makes, its
  rare drop (with the drop chance) and, for Fishing, the treasure. The earlier layout had only a small
  "You have N" line for the product and never showed how many rare drops you held.

## Dropped or not built

- **Gear** (weapon, armor, charm) and the gear rarity ladder. Creature level, rarity, form, traits and
  meals carry combat progression, and gear would have needed a second inventory system and a full item
  list the reference hadn't written ("full gear list: ask the designer"). Worth adding later.
- **Catalysts, awakening/stars, region unlocks with Aether:** listed as Aether sinks in the reference, not
  designed; the sinks here are breeding, attunement, egg speed-ups and thread weaving.
- **Auto-assign best for skill** (roster tool). The worker picker sorts by best fit instead.
- **Collection rewards like rarity-floor eggs and cosmetic frames**: rewards are Aether, gold, vessels,
  titles and recipe reveals.
- **The web build's Electron wrapper** is not needed: Godot exports a native `.exe`.

## Numbers (first pass)

All in `data/tuning.json`, `zones.json`, `skills.json`, `upgrades.json`. Balance was checked with the
pacing model and `tests/balance_probe.tscn`: a lone starter reaches about wave 3 of the first island;
three creatures around levels 6–8 beat its boss; a party at an island's upper levels usually beats that
island's boss and a weaker one reaches the boss but loses. It is a first pass and deserves play-testing.

## Open questions for the designer

1. **Chunk 1 recipes:** `docs/naming/chunk1-claude.md` says its pair assignments are a reconstruction you
   hadn't reviewed. They are in the game as written; changing a pair is an edit to `data/recipes.json`.
2. **Hybrid art:** 45 hybrids × 3 forms, listed above.
3. **Gear:** leave it out, or design a gear list for a later pass?
4. **Pacing:** the curve targets about two months to 99 for a dedicated team. Faster or slower?
