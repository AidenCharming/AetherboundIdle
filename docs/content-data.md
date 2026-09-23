# Aetherbound Idle: Content Data

Convert these tables into JSON under `src/data/` (species.json, hybrids.json, traits.json, etc.). Names are final. Do not rename. Strength tags (Minor/Moderate/Major) map to numbers in a tuning file, not here.

Ability effect vocabulary: single-target damage, multi-target damage, heal (instant), heal-over-time, party buff (Power or Guard), shield (self or party), thorns (Verdant only). Tempo: Quick / Standard / Heavy.

## Base species (24)
Form 1 uses the species name. Every species has 3 forms.

| Species | Type | Form 2 | Form 3 | Primary skill | Signature trait [strength] | Stat lean | Ability (effect, damage type) | Tempo | Secondary aptitude |
|---|---|---|---|---|---|---|---|---|---|
| Sproutlet | Verdant | Timberhorn | Lumbercrown | Woodcutting | Overgrowth: chance for extra output [Moderate] | Guard | Leaf Shield (party shield) | Standard | Scavenging |
| Brambletrundle | Verdant | Briarburl | Thicketroll | Woodcutting | Briar Patch: rare-drop chance within tier [Moderate] | Guard | Thorn Roll (thorns shield) | Standard | Fabrication |
| Mossgear | Verdant | Mosscrank | Mossbastion | Herbalism | Lubricated Joints: cooldown reduction [Minor] | Health | Soothing Spores (instant party heal) | Quick | Fabrication |
| Buzzbud | Verdant | Pollenwing | Bloomqueen | Herbalism | Pollinator: rare-drop chance within tier [Moderate] | Power | Rotor Gust (single-target, Verdant) | Standard | Scavenging |
| Quakemaw | Telluric | Faultjaw | Craterchomp | Mining | Deep Excavator: rare-drop chance within tier [Moderate] | Power | Stone Crunch (single-target, Telluric) | Heavy | Scavenging |
| Geodecore | Telluric | Crystalheart | Prismpulse | Mining | Resonant Frequency: aura, cooldown reduction for other active miners, strongest aura only [Minor] | Guard | Crystal Barrier (party Guard buff) | Standard | Fabrication |
| Pebblescoot | Telluric | Shalestride | Bedrockbound | Mining | Rhythmic Tunnels: cooldown reduction [Minor] | Health | Shell Bash (single-target, Telluric) | Quick | Scavenging |
| Tuskcub | Telluric | Ridgecrest | Summitspike | Mining | Mineral Diviner: chance for extra output [Moderate] | Power | Tusk Charge (single-target, Telluric) | Standard | Fabrication |
| Emberfang | Pyric | Smolderbite | Emberroar | Smithing | Searing Bite: chance to save materials [Moderate] | Power | Searing Swipe (single-target, Pyric) | Quick | Scavenging |
| Cinderpup | Pyric | Cinderbark | Cinderhowl | Smithing | Eager Fetcher: bonus XP [Minor] | Health | Happy Bark (party Power buff) | Quick | Scavenging |
| Roastbelly | Pyric | Oventummy | Smolderplump | Cooking | Slow Cooker: chance to save ingredients [Moderate] | Guard | Heat Sink (multi-target, Pyric) | Heavy | Fabrication |
| Charwhisk | Pyric | Coalstir | Hearthblend | Cooking | Culinary Flow: chance for extra output [Moderate] | Power | Cinder Gust (multi-target, Pyric) | Standard | Fabrication |
| Dewdrop | Aqueous | Rillstream | Tideflow | Fishing | Pure Filter: rare-catch chance within tier [Moderate] | Health | Purifying Splash (instant party heal) | Quick | Scavenging |
| Puddlescoop | Aqueous | Basincatch | Lakehaul | Fishing | Wide Net: chance for extra output [Moderate] | Guard | Bucket Block (strong self shield) | Heavy | Scavenging |
| Frothsprite | Aqueous | Foamspirit | Brinesoul | Fishing | Sea Breeze: aura, cooldown reduction for active Aqueous creatures, strongest aura only [Minor] | Health | Mist Veil (party shield) | Standard | Fabrication |
| Splashfin | Aqueous | Wavegill | Tidetail | Fishing | Deep Diver: chance at sunken-treasure drops [Major] | Power | Hydro Jet (single-target, Aqueous) | Standard | Fabrication |
| Voltfluff | Voltaic | Staticfleece | Arcwool | Circuitry | Static Cling: chance to save materials [Moderate] | Health | Static Shock (single-target, Voltaic) | Quick | Scavenging |
| Joulebug | Voltaic | Ohmroach | Wattbeetle | Circuitry | High Voltage: cooldown reduction [Minor] | Guard | Capacitor Shell (self shield) | Standard | Fabrication |
| Plasmaplug | Voltaic | Ionjack | Surgeport | Circuitry | Daisy Chain: chance for extra output [Moderate] | Power | Arc Strike (multi-target, Voltaic) | Heavy | Fabrication |
| Coilchirp | Voltaic | Wirebeak | Gridtrill | Circuitry | Overclocked: small stacking cooldown reduction that resets on task completion [Moderate] | Power | Sonic Zap (single-target, Voltaic) | Quick | Scavenging |
| Eclipsa | Void | Umbrax | Penumbrum | Aether-Weaving | Void Resonance: chance to save Aether materials [Moderate] | Guard | Dark Eclipse (party shield) | Heavy | Fabrication |
| Riftsneak | Void | Nullprowl | Gloamstalk | Vessel Crafting | Spatial Pocket: chance for extra vessel output [Moderate] | Power | Shadow Strike (single-target, Void) | Quick | Scavenging |
| Hushflutter | Void | Hushglide | Silentwing | Aether-Weaving | Silent Weaver: chance for extra output [Moderate] | Health | Void Breeze (heal-over-time) | Standard | Scavenging |
| Netherpod | Void | Chasmshell | Astralcarapace | Vessel Crafting | Starlight Infusion: increases bind rate of vessels it crafts [Moderate] | Guard | Nebula Shell (party shield) | Heavy | Fabrication |

### Base species form descriptions (for placeholder art prompts, later)
- Sproutlet: tiny glowing leafy quadruped with a sapling on its head → sturdy bark-armored quadruped with wooden antler buds → majestic forest beast with a glowing canopy of antlers.
- Brambletrundle: chaotic rolling ball of thorny vines and glowing bolts → bigger, sturdier mossy tumbleweed golem: a vine ball around a wooden core, with moss, small white flowers, bark arms and clawed feet → ancient, hulking, gentle wood-and-vine giant with tree-trunk arms and legs and a small kind face.
- Mossgear: fuzzy green cog-shaped sphere → bipedal mossy mechanism → gentle lumbering botanical machine with emerald aura.
- Buzzbud: small fuzzy pollinator bee holding a closed flower bud → bigger bee with two pairs of wings and the bud now in bloom → grand flower-crowned queen bee with four ornate wings. (Replaces Petalsprocket, scrapped 2026-09-22 in the art window: the flower-rotor concept never generated a visible evolution across several batches. See `docs/art-pipeline.md` for the art-side record.)
- Quakemaw: stout jaw-heavy lizard with a glowing throat → armored reptile with shovel underbite → friendly earth-dragon with crystal teeth.
- Geodecore: floating hollow stone orb with humming crystal → faceted floating crystal creature, amber light → orbiting stones around a bright crystal nucleus.
- Pebblescoot: skittish shale-carapace beetle → multi-legged excavator → gentle plated centipede giant.
- Tuskcub: playful boar with tiny crystal tusks → sturdy boar with mineral armor → proud woolly mineral beast with crystal spikes.
- Emberfang: fire-maned kitten with bright teeth → sleek ash-coated feline → regal blazing tiger.
- Cinderpup: hyperactive hound with a spark tail → bouncy fiery dog leaving embers → majestic hound howling glowing ash. (Stays cute.)
- Roastbelly: round sleepy salamander with a warm belly → chubby waddler with a belly window showing fire → massive affectionate salamander radiating cozy heat.
- Charwhisk: bird with a tail that stirs coals → crane-like bird with metallic legs → fire-peacock with glowing culinary-tool feathers.
- Dewdrop: gelatinous water orb → serpentine water elemental with silver bands → serene looping water spirit.
- Puddlescoop: bucket-headed amphibian → turtle with a basin of water on its back → gentle giant carrying a small pond.
- Frothsprite: bubbly seafoam spirit that giggles → misty elemental riding tiny waves → radiant airy figure of seafoam.
- Splashfin: curious robotic fish → sleek mechanical dolphin → mechanical whale making gentle whirlpools.
- Voltfluff: Pomeranian-like ball of static → electrified sheepdog in crackling wool → majestic fluffy canine discharging harmless arcs. (Stays cute.)
- Joulebug: tiny glowing insect → metallic beetle with conductive antennae → friendly scarab like a walking battery.
- Plasmaplug: snake with a pronged tail it chases → insulated serpent → gentle cobra with a socket-hub hood.
- Coilchirp: metallic bird wrapped in copper wire → conductive singing avian → electric eagle.
- Eclipsa: silent floating dark disk with a soft rim → crescent shadow entity → multi-ringed dark body bending light.
- Riftsneak: shy shadowy biped peeking from portals → sleek cat-like shadow → elegant starry void panther.
- Hushflutter: dark-energy moth with starry wingtips → floating manta ray of twilight → four-winged phantom glider.
- Netherpod: dark metallic chrysalis with inner starlight → floating nautilus of condensed void → slow void-tortoise carrying a tiny nebula.

## Default hybrids (15)
Each pair's default hybrid is produced by any two species from those types that have no special recipe. A hybrid works both parents' locked skills: full efficiency in its primary skill, reduced in the others. Signature traits for hybrids follow one pattern: chance for a **bonus drop of the partner type's element resource** while working the primary skill. Ability damage type is one of the two parent types.

| Hybrid | Pair | Form 2 | Form 3 | Primary skill | Covered skills | Signature trait [strength] | Stat lean | Ability (effect, damage type) | Tempo | Secondary aptitude |
|---|---|---|---|---|---|---|---|---|---|---|
| Ashwood | Verdant/Pyric | Emberbark | Hearthtrunk | Woodcutting | Woodcutting, Herbalism, Cooking, Smithing | Kindled Sap: bonus Pyric resource drop [Moderate] | Guard | Sylvan Heat (multi-target, Pyric) | Heavy | Fabrication |
| Brambletide | Verdant/Aqueous | Briarripple | Thicketwave | Fishing | Woodcutting, Herbalism, Fishing | Verdant Current: bonus Verdant resource drop [Moderate] | Health | Briar Wash (instant party heal, Aqueous) | Quick | Scavenging |
| Sproutfault | Verdant/Telluric | Timbershale | Lumbercrag | Herbalism | Woodcutting, Herbalism, Mining | Rooted Vein: bonus Telluric resource drop [Moderate] | Power | Earth Spike (single-target, Telluric) | Heavy | Scavenging |
| Mosscoil | Verdant/Voltaic | Mossfuse | Canopygrid | Circuitry | Woodcutting, Herbalism, Circuitry | Static Leaf: bonus Verdant resource drop [Moderate] | Health | Static Sprout (single-target, Voltaic) | Quick | Fabrication |
| Mudskulker | Telluric/Aqueous | Shaleflow | Bedrocktide | Fishing | Mining, Fishing | Silt Filter: bonus Telluric resource drop [Moderate] | Guard | Silt Cannon (single-target, Aqueous) | Standard | Scavenging |
| Quakeforge | Telluric/Pyric | Slagfist | Craterhearth | Mining | Mining, Cooking, Smithing | Tectonic Heat: bonus Pyric resource drop [Moderate] | Power | Magma Slam (single-target, Pyric) | Quick | Fabrication |
| Geodegrid | Telluric/Voltaic | Crystalwire | Prismvolt | Mining | Mining, Circuitry | Conductive Vein: bonus Voltaic resource drop [Moderate] | Guard | Facet Ward (party Guard buff, Telluric) | Standard | Fabrication |
| Cinderbasin | Pyric/Aqueous | Steamrill | Kettlebrine | Cooking | Cooking, Smithing, Fishing | Steaming Catch: bonus Aqueous resource drop [Moderate] | Health | Warm Tides (instant party heal, Aqueous) | Quick | Scavenging |
| Embersurge | Pyric/Voltaic | Blazearc | Infernodynamo | Smithing | Smithing, Cooking, Circuitry | Thermal Loop: bonus Voltaic resource drop [Moderate] | Power | Voltaic Fang (multi-target, Voltaic) | Heavy | Fabrication |
| Brinecore | Aqueous/Voltaic | Rillarc | Tidebolt | Fishing | Fishing, Circuitry | Galvanized Hook: bonus Voltaic resource drop [Moderate] | Health | Hydro Shock (single-target, Aqueous) | Standard | Scavenging |
| Eclipseed | Void/Verdant | Starsap | Nightbloom | Aether-Weaving | Aether-Weaving, Vessel Crafting, Woodcutting, Herbalism | Twilight Root: bonus Verdant resource drop [Moderate] | Guard | Twilight Bough (party shield, Verdant) | Standard | Fabrication |
| Nullshale | Void/Telluric | Riftrock | Abysscrag | Vessel Crafting | Aether-Weaving, Vessel Crafting, Mining | Void Ore: bonus Telluric resource drop [Moderate] | Power | Void Fang (single-target, Void) | Quick | Scavenging |
| Gloamforge | Void/Pyric | Muteember | Hushkiln | Vessel Crafting | Aether-Weaving, Vessel Crafting, Cooking, Smithing | Dark Ash: bonus Pyric resource drop [Moderate] | Guard | Obsidian Shroud (party shield, Void) | Heavy | Fabrication |
| Hushflow | Void/Aqueous | Nullstream | Riftcurrent | Aether-Weaving | Aether-Weaving, Vessel Crafting, Fishing | Twilight Tide: bonus Aqueous resource drop [Moderate] | Health | Twilight Mend (heal-over-time, Void) | Standard | Scavenging |
| Gridrift | Void/Voltaic | Corewire | Lodestar | Circuitry | Aether-Weaving, Vessel Crafting, Circuitry | Singularity Glow: bonus Aether emission while benched [Major] | Power | Arc Storm (multi-target, Voltaic) | Heavy | Fabrication |

Notes: Void hybrids keep Void's skills plus the partner's. Void creatures never change type. Gridrift is the endgame Aether-infrastructure creature. Ashwood, Mudskulker are user-chosen names.

## Trait pool (30)
Strength (Minor/Moderate/Major) is rolled per creature. Void-only traits roll Moderate minimum. Suggested roll weights: Geneticist, Champion, and the Void-only traits are rare. Everything else common or uncommon.

| Trait | Category | Effect |
|---|---|---|
| Night Owl | Universal Econ | Chance for extra output while offline |
| Swift Worker | Universal Econ | Cooldown reduction for all tasks |
| Geneticist | Universal Econ | Small capped bonus to mutation odds during breeding |
| Fertile | Universal Econ | Decreases egg hatch time |
| Resourceful | Universal Econ | Chance to save materials on any task |
| Bountiful | Universal Econ | Chance for extra output on any task |
| Scholar | Universal Econ | Bonus XP from tasks |
| Lucky | Universal Econ | Rare-drop chance within the current tier |
| Glimmer | Universal Econ | Bonus Aether emission while benched |
| Captivating | Universal Econ | Bonus bind/capture rate when in the active party |
| Vitality | Universal Combat | Bonus Health |
| Brawn | Universal Combat | Bonus Power |
| Stalwart | Universal Combat | Bonus Guard |
| Haste | Universal Combat | Ability cooldown reduction |
| Veteran | Universal Combat | Bonus combat XP |
| Champion | Universal Combat | Bonus Power and Guard (low roll weight or smaller per-stat value) |
| Green Thumb | Verdant | Chance for extra output on Woodcutting or Herbalism |
| Spreading Roots | Verdant | Cooldown reduction for Woodcutting or Herbalism |
| Hard Hat | Telluric | Chance to save materials during Mining |
| Prospector | Telluric | Rare-drop chance within the current tier for Mining |
| Forge-Tested | Pyric | Chance to save materials during Smithing or Cooking |
| White-Hot | Pyric | Cooldown reduction for Smithing or Cooking |
| Steady Stream | Aqueous | Chance for extra output during Fishing |
| Sunken Tide | Aqueous | Chance for sunken-treasure drops while fishing |
| Grounded | Voltaic | Chance to save materials during Circuitry |
| Short Circuit | Voltaic | Cooldown reduction for Circuitry |
| Aether-Drenched | Void-only | Increases Aether emission while this creature is benched |
| Rift-Tethered | Void-only | Reduces the Aether cost of attunement for this creature |
| Starlight Magnet | Void-only | Increases vessel bind rate when this creature is in the active party |
| Void Grasp | Void-only | One free vessel bind attempt per zone run (Moderate = 1, Major = 2) |

## Special recipes
Not included yet (content in progress). Build the recipe table so entries are `{parentA, parentB, result}` species IDs, order-independent, with a fallback to the pair's default hybrid. Add a `hint` string field per recipe for the Aether-Log.

## Misc names (working)
Skills: Woodcutting, Herbalism, Mining, Cooking, Smithing, Fishing, Circuitry, Aether-Weaving, Vessel Crafting, Scavenging, Fabrication.
Bosses: Granitusk (Fractured Quarry, Telluric), Ignis Prime (Smoldering Caldera, Pyric), Leviathan Core (Whispering Tides, Aqueous), The Aetherial Apex (Null Horizon, Void).
Buildings: Resonance Extractors, Aether Pipelines. Bench/habitat: The Nexus (or The Menagerie). Incubators: Genesis Pods. Creaturedex: The Aether-Log. Tutorial NPC: Overseer Vance.
