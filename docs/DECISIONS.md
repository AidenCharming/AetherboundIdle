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
  - **2D transforms snap to whole pixels.** At 1920×1080 the UI is scaled 1.2×, and without snapping some
    glyphs land on pixel edges (sharp) and others between them (soft), so text looked unevenly blurry.
    Movement now steps in whole screen pixels.
  - **Wrapping labels are measured again when the window changes size.** A wrapping label measured
    before its container has given it a width reports a height of thousands of pixels. Switching to
    fullscreen on Windows could make that stick, and the Options panel stretched off both ends of the
    screen as a blank box. Modals re-measure on resize, the Options notes have a fixed width, and the
    Display tab rebuilds a frame after the mode change. In fullscreen the Window size row shows the
    screen's own size.
  - **Nothing may widen a screen.** Screen header subtitles wrap instead of forcing a width (the Nexus
    header once pushed the detail panel off the right edge), and zone card lines end in "…". A test
    checks every screen's minimum width fits beside the sidebar at 1600.
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
- **Test bridge** (designer's request): `scripts/autoload/test_bridge.gd` lets a script or a local Claude session drive
  the running game (real mouse clicks and wheel, keys, pages, time skips, the save, errors, screenshots) through
  `tools/bridge.py`. Off unless started with `-- --bridge` on a debug build, localhost only, and it plays in save
  slot 2, named "Autoplay Slot". See `docs/TEST_BRIDGE.md`.
- **Bug-test benchmark** (designer's request): `python tools/bridge.py run bugtest_benchmark` plays about ten
  minutes like a player (Overseer Vance's goals, workers, expeditions, breeding, the Market, every screen, a
  save/load round trip, a jump of hours away) through real clicks, checks errors and invariants after every
  action and writes a PASS/FAIL report to `bridge_runs/`. No cheats: the only time acceleration is `--compress`
  (in-game hours skipped through the bridge, 8 by default), and the report says how much was used. The player's
  reads are debug-only bridge commands (`player`, `goal`, `modals`, `invariants`, `breed_check`, `focus`), so
  it never scrapes text. The fps check is skipped on a software renderer (the cloud's llvmpipe runs ~13 fps).
  `--movie` records the run with Movie Maker and keeps sampled frames of each animation clip with a
  jump/flicker/settle check (`tools/frame_stats.gd`).
- **Tests:** `tests/test_*.gd`, 123 tests (including `test_ui.gd`, which presses real dialog buttons), run headless (see the README). Also `tests/tour.tscn`, which
  renders every screen and dialog to PNG (for visual checks), `tests/month_probe.tscn`, which runs a dedicated player's first month through the real sim (see Pacing), and `tests/balance_probe.tscn`, which prints
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
- **Standing rule (designer's request):** whenever the game needs a new icon, it gets a prompt in
  `tools/art/build_icon_prompts.py` (and a placeholder in `tools/make_icons.py`) in the same change, and
  `docs/art-prompts-icons.md` is regenerated. The designer's script lists whatever still needs painting
  after a pull.
- **Painted icons are optional and drop-in:** `docs/art-prompts-icons.md` has a FLUX.2 prompt for every icon
  (150 now; the top bar's vessel and meal reuse item icons), built by `tools/art/build_icon_prompts.py` with
  the creature pipeline's rules (magenta key, green for pink and purple things, no glow words, everything opaque).
  `tools/art/icon_runner.py` generates, picks and cuts them out with the existing `batch_runner.py` and
  `sprite_tools.py`, and installs them into `assets/icons/`. The game uses a PNG icon whenever one exists and the
  SVG placeholder otherwise. New PNGs import with mipmaps (a project import default), so they stay smooth at 24 px.
- **Battle backdrops** (designer's request: fighters used to hover over two floating island ovals). The
  battle is now a side-view stage: every fighter stands on one ground line (front row at 84% of the view's
  height, back row only 3% higher, so each side reads as a line), placed by the lowest opaque pixel of its
  sprite so empty space under the art never lifts it, with a soft shadow at its feet and its name and health
  bars above its head (back-row name tags sit a step higher so neighbours don't overlap). Every fighter is
  sized for a full side of three, so a lone enemy is the same size as one of three, and each is kept a
  small margin inside the backdrop. Bosses stay 1.45× bigger.
  - **Facing:** the sprites are painted facing left (`combat.spriteFacing` in tuning.json), so the party
    on the left is mirrored to look right and wild Aetherlings are drawn as painted, looking left. A form
    whose sprite faces another way can set `facing` ("left", "right" or "front") in species.json.
  - **Nameplates** (designer's request): each fighter has a small glass plate edged in its rarity colour
    (gold for a boss). It shows the owned badge for wild Aetherlings whose species you have, the name, a
    level chip in the rarity colour, the health bar, and a shield bar that appears only while a shield holds.
    Front-row plates sit over the head, back-row plates a step higher, and every plate stays inside the
    arena. Ability names float up from above the plate instead of through it.
  - **Telling rarity and shinies apart in battle** (designer's request): rarity pips, one small diamond per
    tier, sit on the nameplate's top edge and along the bottom of every portrait rim, so the tier can be
    counted, not just read from its colour. The top tiers' colours move: Zenith cycles a soft rainbow,
    Resplendent and Brilliant pulse (`Data.rarity_color_live`). Gleaming moved from green to teal so it
    no longer looks like Faint. A shiny's nameplate has the shiny mark and a gold name. When a shiny or a
    rare wild Aetherling enters a fight (a rarity the island rolls at most `combat.rareAnnounceChance`,
    10%, of the time), a burst of light, a "Shiny!" or rarity word and a sound (`shiny_appear`, a glittering
    run; `rare_appear`, a bell chime) announce it once per wave.
  - **Sprite and frame effects by rarity** (designer's request, no new art: all in `creature.gdshader`,
    following each sprite's outline, set by `fx` in `data/rarities.json`). Luminous and Radiant get an
    outline glow in their colour; Brilliant adds a band of light sweeping across the body; Resplendent's
    glow pulses; Zenith has a rainbow edge, a soft rainbow sheen and motes rising around it. On the
    portrait frame, lights orbit the rim for the top three tiers (one, two, three) and Zenith's whole rim
    is a moving rainbow.
- **Expeditions page layout** (designer's request): the right column is Aetherlings waiting for a vessel (a pulsing
  gold panel with Throw and Throw at all, shown first when any are waiting; the Expeditions menu entry also pulses
  "N to bind!") and the expedition log filling the rest. Log lines are small cards with an icon (a portrait for
  captures), the text and how long ago, edged in the line's colour. Party, Auto-bind and Supplies sit under the
  battle as three tabs. The island list and the log column each fold to a slim strip (the battle widens), and the
  choice is remembered (`exp_zones_open`, `exp_log_open` in options.cfg). Auto-bind shows the bind chance for each rarity as a pill in that rarity's colour, for the vessel it would throw. Folded, the log strip still lists its latest 16 lines as small icon tiles in the line's colour (hover for the text and time, click to unfold). The run controls (Explore or Stop, Repeat) sit on the
  tab row. The painted backdrop covers the arena resting on its bottom edge (a wide arena crops sky, never ground),
  and the fighters' ground line follows the image as drawn, so they always stand on the painted ground. Party members on a running expedition are no longer offered in the worker picker.
- **Welcome back** (designer's request): a headline with the time away, big tiles for Aether, gold, tasks and ready
  eggs, items as named cards, level-ups with before and after, highlights with icons, and captures grouped by kind
  with portraits (shinies first).
- **Owned badge** (designer's request): a species you already own shows a green paw badge on the bottom-right
  of its portrait in an island's "Aetherlings seen here" list (it replaced the "· owned" text), and beside a
  wild fighter's name tag in battle. Its icon is `ui/owned` in `docs/art-prompts-icons.md`; until the
  painted PNG exists, `tools/make_icons.py` draws a placeholder. Behind them is a painted backdrop per island, `assets/zones/<id>.jpg`, with prompts in
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
    `Music.play` does the usual 2-second crossfade. A new crossfade cancels the one still running, so
    switching screens back and forth quickly can't stop the track that has just come back.
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
  - **Attacks sound like their type** (designer's request). Each type has a hit and an ability cast:
    Verdant a leafy swish and woody pluck, Telluric a low thud with grit, Pyric a crackling burst, Aqueous
    a rising bloop, Voltaic a falling square-wave zap, Void a detuned downward wobble. A super-effective hit
    adds a bright ping. Hits vary their pitch a little so a flurry doesn't drone. The six hits sit within 2×
    of each other in loudness (low sounds get more energy, as they sound quieter), and a test checks it.
  - **Damage numbers take lanes:** numbers landing on one fighter within about half a second start centre,
    left, right, then a row higher, so a flurry reads as separate numbers. They show whole numbers ("9",
    not "8.8").
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
| `burrbolt` | Burrbolt / Quillspark / Stormbristle (a squirrel) | Verdant / Voltaic |
| `cliffscorch` | Cliffscorch / Kilnclaw / Pyrestinger (a scorpion) | Telluric / Pyric |
| `nettlemesa` | Nettlemesa / Spurback / Spinehearth (a horned lizard) | Telluric / Pyric |
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
| `duskbloom` | Duskbloom / Wanehop / Moonwarren (a hare) | Void / Verdant |
| `riftshale` | Riftshale / Chasmclaw / Abyssburrow (a badger) | Void / Telluric |
| `nethershale` | Nethershale / Grimplate / Umbralith (an armadillo) | Void / Telluric |
| `wraithcoal` | Wraithcoal / Ashgloam / Cinderwraith (a vulture) | Void / Pyric |
| `duskflare` | Duskflare / Wanescorch / Gloamfang (a jackal) | Void / Pyric |
| `murkmire` | Murkmire / Murkveil / Abyssbloom (a jellyfish) | Void / Aqueous |
| `hollowstream` | Hollowstream / Stillgill / Palepool (a newt) | Void / Aqueous |
| `wraithwire` | Wraithwire / Wanewire / Shadescythe (a mantis) | Void / Voltaic |
| `duskvolt` | Duskvolt / Wanecoil / Gloomweaver (a spider) | Void / Voltaic |

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
- **The Market** (designer's request: the old shop only sold Tinker's Vessels), `data/market.json` and
  `scripts/sim/market.gd`, on two pages (Market, Egg Market) next to the Inventory:
  - **Prices:** the Market sells every material, part and vessel at sell value × 1.25, to the nearest gold and
    always a gold more, so a thing sells back for a little less than it costs (the designer's rule: a small
    gap, and crafting stays the cheaper way). Materials open a tier per island cleared; vessels have their own
    unlocks. Tinker's Vessels are always for sale, so a player is never stuck without a way to bind. Any
    item's detail panel in the Inventory can buy more of it.
  - **Extra work slots** (design.md: an endgame gold sink): once a skill's five slots are open (level 70),
    slots six to ten are bought per skill for 250K, 750K, 2M, 5M and 12M gold. Ten is the cap (designer's
    request); the Sanctum's station cards show workers five to a row, so a full skill is two tidy rows.
  - **Bulk selling** in the Inventory: this category (or everything but vessels and rare finds), up to a
    tier, keeping 0/10/100/1000 of each. Any item can be locked from its detail panel to stay out of it.
  - **Today's stock** rotates every 4 hours, the same for everyone watching that window (rolled from the
    save's creation time and the window): four offers (discounted bundles of top-tier materials or vessels,
    a boost at 25% off, a crate of Aether Crystals), each buyable 3 times. A 35% chance adds a rare
    **limited** offer, one only, drawn with a running rainbow-gold frame and sparkles, its menu entry pulsing
    "limited!": an Aether Pearl (250K, from 8 islands cleared), a Shimmering egg (always shiny), a Gilded
    egg (a grade above the best on sale) or a Crystal hoard.
  - **Boosts** start when bought and keep running offline (a boost that ends while away counts for its share
    of the time): Aether Incense +50% Aether, Battle Tonic +50% party XP, Glimmer Lure makes rarities above
    Dim twice as common, Tinker's Brew +20% work speed. 30–60 minutes a purchase, stacking to 8 hours;
    prices grow ×1.55 per island cleared. They show in the top bar with their time left.
  - **Market eggs** hold a random base Aetherling of a type you own, in grades that open with islands
    cleared (Common Dim+ 600 gold, Fine Faint+ 6K, Choice Steady+ 40K, Prime Gleaming+ 200K, Royal
    Luminous+ 900K; 70/25/5 odds from the floor up) and hatch in a Genesis Pod. They can hatch shiny at the
    base chance but never count toward the shiny pity, so gold can't buy a shiny that way. A featured egg
    (a named Aetherling a grade up, 2.5× the price, one only) changes with the stock.
  - Gold prices for eggs, slots and the limited Pearl are first guesses: the month probe doesn't track gold.
- **Sell prices follow two rules** (designer's, checked by `test_content.gd` `test_market_prices`):
  anything the Market sells sells back for a little less than it costs (at least 75%, or a gold less for the
  cheapest things), so buy-and-resell never pays; and every crafted item sells for at least 1.25× its inputs,
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

### Code review fixes (2026-09-24)
A review of the whole repo found save, purchase and correctness bugs; each fix is its own commit with a test.
- **Saves are atomic.** `Game._write_slot()` writes `slot_N.tmp.json`, copies the old main file to the backup
  only if it parses, then renames `.tmp` into place. Before, a crash mid-write left a broken main file, and the
  next autosave copied it over the good backup. Load order is main, `.tmp`, backup. The no-re-roll rule is
  unchanged (the rng state is still saved with every save). `tests/test_saves.gd` uses slot 99 only; the old
  slot-rename test wrote the player's real slot 3.
- **A Market buy names its stock window.** The stock changes every `rotation.hours`; a page showing the old stock
  could buy index i of the new one (another item, another price). `Market.buy_offer`/`buy_featured` take the
  window the page showed and refuse when it moved on; the screens refresh once when it does. `Market.buy()`
  refuses a quantity of 0 or less instead of reporting "Bought 0×".
- **Every sim roll uses the game's rng:** `Rng.shuffle()` replaces `Array.shuffle()` in trait inheritance.
- **One time-away cap:** `GameState.offline_cap_hours()` (Dream Anchor + Pearl Hourglass), used by
  `Offline.apply` and the pause menu, which showed the Anchor alone.
- Pearls found while away reach Welcome Back; thorns that knock out an attacker end its multi-target ability;
  bulk release reports Pearls like a single release.
- UI: worker bubbles skip frames while the state is empty (the fade to the title); Genesis Pods forget picked
  parents when the slot or save changes; the Expeditions log's "ago" times update every second without a rebuild.
- **Lost clicks:** `Main` holds a `Game.changed` screen rebuild while the left mouse button is down and runs it
  just after the release, so a capture or level-up can't free the button being clicked (found by the bug-test
  benchmark on skill pages, pods, Works and the Market).
- Robustness: options.cfg is written 0.4 s after the last change (and on quit), not on every slider tick; a
  broken data file is reported with its line through `push_error`, which release builds keep (assert is
  stripped); the test bridge's `new` only wipes slot 2 unless forced, and only slot 2 is renamed.
- Tools and docs: `tools/check.sh` runs the tests with `--debug` and stdin closed; `docs/HANDOFF.md` describes the
  flattened repo.

### No faint grey numbers (designer's request)
- **Numbers are chips or coloured**, the way the Aether-Log's dex numbers are: `UI.chip` / `UI.count_chip`
  (new `UI.set_chip` recolours one in place). Done for the goal counter ("Goal N / 112", gold) and progress,
  the nav rail's skill levels and badges (aether when someone works there), the top bar's working/perched,
  zone level ranges, party cards (level chip + stat icons), Works levels, Nexus counts and card levels,
  pods, Market tiers/stock/slots, inventory tier and sell price (gold icon), milestones' "to go", locked
  slot levels, XP and XP/h, rare-drop odds and the level-up list.
- Creature card status lines take a colour by job: green working, gold on an expedition, aether perched.
- Faint grey stays for prose only (descriptions, hints), never for a number.

### Overseer Vance's goals: 26 → 112
- **Why:** the designer asked for at least 100 missions over the month; the old chain ended after the bosses.
- **Pacing:** ordered along the month probe's timeline (islands cleared on days 1-22, rarity caps, party levels,
  skills 30/50/70/90/99 on days ~0.5/2.5/8/19/28), so a goal is rarely finished long before it comes up.
  The chain opens every skill once its type is bound, then mixes skill totals, "every skill at N", rarities,
  Aetherling levels, captures, kills, boss kills, eggs, hybrids, species, upgrades, slots and key crafts.
  It ends on all eleven skills at 99, three special recipes and 50 species.
- **Rewards** grow with the phase's Aether income (tens early, hundreds of thousands at the end) and hand out
  vessels a tier ahead of what the player crafts.
- **New check kinds** (`goals.gd`): `rarity` (best rarity owned), `creature_level` (highest level),
  `total_level` (sum of skill levels), `skills_at` (skills at or above a level). No new systems.
- **Saves:** the active goal's id is stored (`goals.id`); an old save's index is read against the old 26-goal
  chain (`Goals.OLD_CHAIN`), so nobody jumps to a different goal. The Sanctum panel shows "N / 112".

### Creature names and descriptions
- **Reviewed against the sprites** (designer's request): all 72 base forms were checked on contact sheets.
  - Every base name fits its art, so none changed.
  - 23 descriptions that described something not in the art, or said too little, were rewritten to what is
    drawn. For example, Rillstream is a water drop on silver-banded legs, not "serpentine"; Bedrockbound is
    an upright rock beetle, not a centipede; and Quakemaw wears an orange scarf rather than a glowing throat.
- **Every hybrid form now has a description.** The 15 default hybrids had none and the 30 secret hybrids
  only had their first form's, so 105 were written. Each follows its first form's animal, or the two parent
  types for the default hybrids, so they can double as art briefs.
- **14 hybrid form names changed**; species ids are unchanged, so saves are unaffected:
  - They started with a rarity's name: Faintpulse → Shadescythe, Faintweb → Gloomweaver.
  - They repeated the form before them: Quillstatic → Stormbristle, Spurmesa → Spurback,
    Hollowbrook → Stillgill, Grimstone → Umbralith, Ashplume → Cinderwraith, Sootveil → Abyssbloom.
  - They read as places or plants rather than the animal:
    - the scorpion: Sunspire / Blazingpeak → Kilnclaw / Pyrestinger;
    - the hare: Wanevine / Waneflower → Wanehop / Moonwarren;
    - Gravelgrit → Abyssburrow, and Sunflare → Gloamfang.

### Pacing
- **One month to finish** (designer's request, replacing the earlier two-month target). This is for a
  dedicated player: every work slot filled, checking in through the day, with offline time counting.
  - **The target:** every skill at 99 and Zenith Spire cleared by a party in the 90s at about day 30, with
    both tracks moving together. The target curve is level 10 in an hour, 30 in half a day, 50 by day 3–4,
    70 by day 9–10, and 90 by day 20–22.
  - **How it's checked:** `tests/month_probe.tscn` (a dev tool, about 40 s) runs that player through the
    real sim. It fills every slot with a specialist and keeps each supply chain fed, so a skill makes
    whatever a later skill is short of. It breeds workers up to one rarity below what the materials allow,
    and levels a party on the hardest island it can clear, with XP from real battles. `--calibrate` finds
    each island's strength for a target party, and `--rates` measures party XP along the target timeline
    for curve fitting.
  - **Result:** every skill reaches 99 between day 28.5 and day 33. Islands are first cleared on days
    1, 1, 1, 2, 3, 5, 5, 7, 11 and about 24, with the party at level 98–100 by day 30.
  - **The first boss is a wall, not a formality.** Play-testing showed Old Thicketroll falling to a
    level 2–4 party (one Faint, two Dim). Early on, levels add little (level 1 to 8 is about +40% power),
    so an island's gate is its boss's strength against the party's rarity. Old Thicketroll's multipliers
    went up by 1.3× (health 3.1, power 1.24, guard 1.3). An all-Dim party now loses at levels 1–4, wins
    2 fights in 8 at level 5 and 6 in 8 at levels 6–7. A Faint in the party helps a little; an all-Faint
    party still wins early. Fractured Quarry already had this shape (Dim needs about level 14–18 against
    its level-16 boss, all-Faint wins from about 10), so it is unchanged. The month probe's `_combat`
    rounds party levels down to multiples of 3, which is why the level-4 target had really been tested
    at level 3.
  - **Levels matter in a fight** (designer's play-test: a level 5–6 Dim/Faint party cleared Fractured Quarry
    and its boss easily, and nearly beat a level-24 Caldera wild). Two causes: one rarity step (×1.3 stats)
    was worth about ten levels, and islands scale their wilds down (`enemyMult` below 1), so a nameplate's
    level overstated its strength. Every hit is now multiplied by `1.04^(attacker level − target level)`,
    clamped to 0.4–2.5 (`combat.levelGap`); equal levels change nothing. Fractured Quarry's wilds went
    from ×0.72 to ×0.85 with 1–3 per wave (was 1–2). Measured with that party (8 runs each): an all-Dim
    party clears the Quarry from about level 12–14, all-Faint from 8–10, all-Steady from 6; a level-3 party
    falls around wave 4, and a level-6 party is wiped by the Caldera's first wave. The month probe still
    reaches 99 in every skill around day 29–33; islands now clear on days 1, 1, 1, 2, 3, 5, 6, 10, 15 and
    22 (the late middle islands later, the Spire, gated by the Zenith rarity cap, a little sooner).
- **Skill XP curve** `1.0 × level³ × 1.028^(level−1)`, and **creature XP curve** `8.45 × level^3.3 × 1.014^(level−1)`.
  Both were fitted to the target timeline from the probe's measured XP rates.
  - **Skills:** the old skill curve (`10 × level² × 1.06^(level−1)`) was quick in the middle and slow at the
    end.
  - **Creatures:** the old creature curve (`6 × level^2.9`) got a party to level 100 in about a day and a
    half of fighting.
  - **Saves** keep every skill's and creature's level (`SAVE_VERSION` 3): migration resets XP to the start of
    the saved level whenever a curve no longer matches it.
  - **Tests:** `tests/test_pacing.gd` guards the lone-starter landmarks (level 10 in about 20 minutes, 30 in
    about 21 hours).
- **Crafting reshaped so the supply chains can keep up.**
  - **Crafting actions** take twice as long and give twice the XP, and a smelt yields 2 bars. Before, one
    Smithing team had to feed Circuitry, Vessel Crafting and Fabrication, and every bar also cost two ore.
  - **Aether-Weaving** threads cost 1–12 Aether, down from 15–5,000; the old costs starved Weaving for the
    whole game.
  - **Per-skill XP** is scaled so all eleven finish together. Cooking's actions give a little less. Vessel
    Crafting and Fabrication give more, because their top recipes (at 55 and 70) carry them to 99.
- **Late islands are harder** (Null Horizon ×1.15, Verdigris Canopy ×1.16, Magmaglass Rift ×1.52, Stormsea
  Expanse ×1.68 and Zenith Spire ×2.2 on wild enemies and boss).
  - **Why:** rarity outgrew them, and a Brilliant party at level 70 cleared Zenith Spire.
  - **Now:** each late island wants the rarity its material tier can breed, around the day that tier opens,
    at the top of its level band. The first five islands are unchanged; they gate by level and were tuned for
    a lone starter.
- **Ten material tiers, one per island** (designer's request; names approved by the designer), unlocking at
  skill levels 1/10/20/.../90:
  - **Which skills:** the five gathering skills, and Smithing, Cooking, Circuitry and Aether-Weaving.
  - **Recipes:** a smelt of ore ×2 plus a log a tier down gives two bars; meals take a fish plus a herb a
    tier down; components take a bar plus salvage; and threads take a little Aether plus a herb.
  - **Islands:** island *n* drops tier-*n* materials, and its boss drops a stack of them plus that tier's bars.
  - **Unchanged:** Vessel Crafting and Fabrication keep their products (the vessel ladder and the Sanctum
    parts).
  - **Work slots** still open at 1/10/25/45/70. The reference spread five slots over a year of play
    (1/50/100/165/225), which left the roster with nothing to do for months.
  - **Prices:** every crafted item sells for at least 1.25× its inputs (`test_market_prices`). Thread prices
    also count the Aether they cost.
  - **Icons:** placeholder icons come from `tools/make_icons.py`. The FLUX prompts are in
    `docs/art-prompts-icons.md`.
- **Creature max level 100, forms at 20 and 40** (reference 99, 30 and 60), so evolutions (with their
  reveal) happen in the first sessions. **Working creatures earn half the skill XP they produce**; the
  reference only gave combat XP, so a creature that never fought never evolved.
- **Rarity stat multipliers softened** to 1.0 → 6.8 (reference 1 → 24), so a high-level Dim is still
  useful and rarity is an upgrade rather than a wall. Bench emission doubled (Dim 2/min, doubling per
  tier) to make early breeding reachable.

### Breeding
- **The pool-trait roll** (an open question in the reference, blocking its Phase 2): a new creature rolls
  0/1/2/3 pool traits with weights 35/40/20/5; strength Minor 65%, Moderate 28%, Major 7%; a trait of the
  creature's own type is 3× as likely; Void-only traits only on Void creatures and at Moderate minimum.
  Offspring inherit each parent trait with 40% chance, at the same strength or (15%) one step stronger, never
  weaker (the designer's rule: no step down), fill up with fresh
  rolls if nothing passed down, and have a 5% chance of one extra mutation trait. All in `tuning.json`.
- **Aether Pearls, the endgame currency** (designer's request: a free way to boost shinies and more at the
  end). Sources: the last two islands' bosses drop one rarely (`bossLoot.pearlChance`: Stormsea 0.15%, Zenith
  Spire 0.4% per clear; a strong party clears 25–110 an hour, so about 3–7 a day of play), releasing a
  Resplendent (1) or Zenith (3) (`releasePearls` in rarities.json), and shinies (1 for hatching or binding one,
  2 more for releasing one). They buy six Pearl upgrades in Sanctum Works, 5 levels each, costing 3/6/10/15/20
  pearls (54 per upgrade, 324 for all): Pearl Lens (+0.5% shiny chance per level on eggs, as the designer asked,
  and +0.1% on wild encounters, which happen far more often), Pearl Resonator (+20% rarity mutation per level),
  Pearl Crucible (attunement 10% cheaper, inherited traits 5% likelier to grow, per level), Pearl Incubator (8%
  faster hatching per level), Pearl Binding (+5% bind chance per level) and Pearl Hourglass (+2 hours away per
  level). All numbers in `tuning.json` → `pearls`. The icon is `items/aether-pearl` in the art prompts.
- **Shiny parents** (designer's request): each shiny parent adds half of the egg's shiny chance
  (`shiny.shinyParentBonus` 0.5): 0.5% becomes 0.75% with one shiny parent and 1% with two. It multiplies the pity
  chance too, capped at 25%. The Genesis Pods odds line says when the bonus applies.
- **Rarity:** the materials' tier sets the ceiling. There are ten egg tiers, one per material tier (the
  designer asked whether five was enough; it wasn't once materials went to ten). Tiers 1–10 cap at Faint,
  Steady, Steady, Gleaming, Gleaming, Luminous, Radiant, Brilliant, Resplendent and Zenith, so the rarest
  eggs need the late islands' materials.
  - **Odds:** they centre on the parents' average rarity and fall off by `stepWeight` (0.18) for each tier
    away from it, never below the weaker parent. Each tier above the first lifts that centre by
    `centreLiftPerTier` (0.05 of a rarity step), so a tier sharing its ceiling with the one below still has
    better odds.
  - **Mutation:** two rolls (+1 at 15%, +2 at 2.5%, halved for the top two rarities) can pass the ceiling.
    The full odds are shown before laying.
  - **Examples:** with tier 1 materials, Dim + Dim → Faint 25%; Dim + Faint → Faint 49%, Steady 9%;
    Faint + Faint → never Dim, Steady 15%. Two Resplendents on tier 10 → Zenith about half the time.
  - **Climb:** a player who always breeds their best pair on the cheapest tier that can beat it needs about
    30 eggs from Dim to a first Zenith (10–90%: 20–43). So the real pace is set by when each material tier
    opens and by Aether, not by luck.
  - **History:** the first version started the odds at the *rounded-down* average with a 0.45 falloff, so
    Dim + Dim gave Faint 36% and Dim + Faint was exactly the same as Dim + Dim. Designer feedback: too
    generous for two Dims, and a rarer parent must help.
- **Materials:** 5 per parent of that parent's element at the chosen tier (logs, ores, bars, fish,
  components, threads) plus Aether 100 → 64,000. The reference's special Void-offspring rule is
  simplified: Void just needs threads.
- **Hybrid parents breed true** (a hybrid × anything gives one of the two parents' species), same-type
  pairs give one of the two parents, and the reference's rare "sibling species" is not built (no content).
- **Eggs:** 2 minutes to 6 hours by tier, sped up with Aether; the shell glow shows the true rarity 75% of
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
- A wiped party rests 10 seconds and tries again (the reference's "briefly exhausted"; 20 until the designer asked for 10).
- **The party is locked while an expedition runs.** Adding, swapping, removing, putting a member to work,
  resting or releasing one is refused until the expedition is stopped. (At first a party change restarted
  the run, which let a new member join mid-boss and threw away the run in progress.) Moving the party to
  another island is still allowed: it is an explicit "abandon this run" action.
- **Vessels: ten tiers** (Tinker's, Sturdy, Polished, Resonant, Luminescent, then Gloaming, Prismatic,
  Emberheart, Stormglass and Celestial, added at the designer's request so Vessel Crafting has a ladder like
  the other skills). Flimsy was dropped (weaker-sounding than the starter) and Aetheric Matrix too (and
  "Aetheric" is on the banned-root list). Bind chance = vessel base × falloff^(rarity − 1) × party bind
  bonus; falloff climbs 0.75 → 0.99 up the tiers. Fabrication makes Tinker's and Sturdy; Vessel Crafting
  (Void) makes Sturdy to Celestial at levels 1, 10, …, 80, each from the same-tier bar and the thread a
  tier below. The last three islands' bosses drop Gloaming, Prismatic and Emberheart; Stormglass and
  Celestial are crafted (or bought once every island is cleared). With the old ladder, Vessel Crafting sat
  on the Luminescent recipe (Aether Ingot + Veil Thread) from level 55 and starved Fabrication's Aether
  Lantern; spreading the demand made several skills faster, so the Aether Lantern went from 480 to 210 XP
  and Aether-Weaving's top five threads were scaled down by about a quarter. The month probe has every
  skill at 99 between day 26.8 and 31.1.
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
- **The worker picker ranks by what the job needs** (designer's request), with three buttons in place of
  "Best fit":
  - **Best output:** product per hour, counting speed and extra-output rolls. The picker opens on this one.
  - **Best time:** time per task.
  - **Best secondary:** rare drop, treasure and partner-element drops per hour.

  Each card's note shows the figure being sorted by. `Skills.work_rates()` computes all three with the same
  numbers `complete()` rolls. Party and parent pickers keep "Best fit".
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
- **Auto-assign best for skill** (roster tool). The worker picker ranks by output, time or secondary finds instead.
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
