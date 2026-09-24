# Cosmetics: ideas to pick from

The designer asked for a list ("maybe hats for your Aetherlings"). Nothing here is built yet. Cosmetics
change looks only, never stats (design.md: no big permanent bonuses), so they are safe gold and Pearl sinks.
Pick what to build; every piece of art gets a prompt in `tools/art/build_icon_prompts.py` as usual.

## How they could work

- **One painting per cosmetic, never per creature.** A hat is painted once and placed on any Aetherling:
  the game already knows where each sprite's drawn body is (`Data.opaque_rect`, used to stand fighters on
  the ground), so a hat sits at the top-centre of that box, scaled to the sprite's width. A small
  per-form nudge (`species.json` `"hatOffset"`) fixes the odd head that isn't at the top (tails, antennae).
- **Shown everywhere a portrait is:** the Nexus, work slots, battle, the hatch reveal.
- **Where they come from:** the Market's stock (a cosmetic slot that rotates), rare limited offers with the
  rainbow frame, Aether-Log milestones (design.md already lists "cosmetics/titles/frames" as late rewards),
  boss first-clears, and Aether Pearls for the very best.
- **A wardrobe** tab in the Nexus: equip one hat (and one of each other kind) per Aetherling.

## Hats (worn on the sprite)

| Hat | Look | Idea for how to get it |
|---|---|---|
| Acorn Cap | a little brown acorn cap with a stalk | Whisperleaf Hollow boss, first clear |
| Leaf Beret | a floppy green leaf worn like a beret | Market stock |
| Flower Crown | a ring of small pink and yellow flowers | Herbalism level 50 |
| Toadstool Cap | a red spotted mushroom cap | Market stock |
| Miner's Helmet | a yellow hard hat with a small lamp | Mining level 50 |
| Bucket Hat | a green fisher's bucket hat with a fishing fly pinned on | Fishing level 50 |
| Chef's Toque | a tall white chef's hat | Cooking level 50 |
| Tinker's Goggles | brass goggles pushed up on the head | Circuitry or Fabrication level 50 |
| Star Wizard Hat | a tall violet pointed hat with gold stars | Aether-Weaving level 75 |
| Scavenger's Bandana | a patched red bandana | Scavenging level 50 |
| Top Hat | a black top hat with a violet band | Market stock (pricey) |
| Party Hat | a striped cone with a pom-pom | the game's first anniversary / a limited offer |
| Pom-pom Beanie | a knitted beanie in the type's colour | Market stock |
| Straw Sunhat | a wide straw hat with a ribbon | Market stock |
| Pirate Tricorn | a black tricorn with a white skull-less badge | Stormsea Expanse boss |
| Horned Helm | a round helm with two small horns | Thunderhum Steppe boss |
| Ember Crown | a crown of little flames (drawn solid, no glow) | Magmaglass Rift boss |
| Coral Tiara | a tiara of pink and orange coral | Whispering Tides boss |
| Void Hood | a dark violet hood with star specks | Null Horizon boss |
| Bunny Ears | a headband with floppy ears | limited offer |
| Cat Ears | a headband with pointed ears | limited offer |
| Big Bow | a large ribbon bow | Market stock |
| Graduation Cap | a mortarboard with a tassel | Aether-Log: every base species |
| Golden Crown | a small gold crown with gems | Aether-Log: 100 species |
| Halo | a thin gold ring floating above the head | a Zenith Aetherling bred |
| Aether Pearl Circlet | a silver circlet set with one pearl | Aether Pearls (top tier) |
| Zenith Diadem | an ivory-and-gold diadem with a star | Zenith Spire first clear |

## Other kinds

- **Nameplate frames** for battle nameplates and portrait rims: Vine, Stone, Ember, Tide, Storm, Void,
  Gilded, Starlit. Drawn in code like the rarity rims, so no painting needed.
- **Battle trails**: a little effect that follows an Aetherling when it attacks: falling leaves, sparkles,
  bubbles, embers, snowflakes, music notes. Particles in code.
- **Vessel skins**: how the thrown vessel looks when binding (a different orb colour or shape): cosmetic
  only, the vessel's tier still sets the chance.
- **Egg shells**: a pattern for eggs in the Genesis Pods (stripes, stars, speckles). Shell tint in code.
- **Sanctum themes**: the backdrop and colours of the Sanctum page (spring, autumn, starry night, sunset).
- **Perch ornaments**: small decorations shown by perched Aetherlings in the Nexus (a lantern, a flower
  pot, a little flag).
- **Titles** for the player, shown on the Sanctum and the title screen ("The Architect", "Shiny Hunter",
  "Island Walker"). The Aether-Log already has a titles list to build on.

## Suggested first step

Hats are the most fun and need the least new code: a hat slot per Aetherling, the auto-placement above, a
wardrobe tab, and 8 to 10 hats to start (Acorn Cap, Leaf Beret, Toadstool Cap, Miner's Helmet, Bucket Hat,
Chef's Toque, Top Hat, Party Hat, Golden Crown, Halo), with the Market's stock offering one now and then.
