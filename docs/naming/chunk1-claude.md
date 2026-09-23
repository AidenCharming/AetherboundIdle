# Special recipes, Chunk 1 (Claude)

Ten special recipes, two for each of Verdant/Telluric, Verdant/Pyric, Verdant/Aqueous, Verdant/Voltaic
and Telluric/Pyric. Same rules as Chunk 2 (`chunk2-claude.md`): an order-independent pair of two
specific base species (one from each type) produces a unique hybrid instead of the type pair's
default hybrid.

**Recovery note.** The 10 names below (Sorrelcliff, Rowanboulder, Hazelslate, Nettlemesa,
Brackensear, Yarrowflare, Sedgestilt, Ivyflux, Burrbolt, Cliffscorch) were locked by the designer in
an earlier session that was never written down; I'm recovering them from my own memory of this
project, not from any file. Everything past the bare name — which pair each belongs to, the animal,
Form 2/3, breeding species, skill, trait, ability, stat lean, tempo, aptitude, description and hint
— was never decided and is reconstructed here from scratch. **The 10 names are fixed; the pair
assignment below is my best reconstruction, not recovered fact**, and is the single thing most
worth the designer double-checking: I read each name as two roots (one per parent type, following
the "root+root" style visible in the names themselves, distinct from Chunk 2's "root+animal-part"
style), and four of the ten (Sorrelcliff, Rowanboulder, Hazelslate, Nettlemesa) could plausibly read
as Verdant/Telluric rather than the pairs I settled them into. I split them 2-and-2 across
Verdant/Telluric and Verdant/Aqueous (Rowanboulder) or Telluric/Pyric (Nettlemesa) to get a clean 2
recipes per pair; if the designer recalls the real split, only the Pair, Parent species, Animal and
Covered-skills cells need to move, not the names.

Conventions (same as Chunk 2): covered skills = primary skill first, then the primary's own type's
remaining skill(s), then the other type's skill(s) in canonical order (Verdant: Woodcutting,
Herbalism; Telluric: Mining; Pyric: Cooking, Smithing). Every ability's damage type is one of the
two parent types. Every signature trait reads "Name: mechanic while working <primary skill>
[strength]", using a mechanic from `content-data.md` section 4 that does not repeat either parent's
own signature-trait mechanic.

## Special recipes (Chunk 1)

| Hybrid | Pair | Parent species (A + B) | Animal | Form 2 | Form 3 | Primary skill | Covered skills | Signature trait [strength] | Stat lean | Ability (effect, damage type) | Tempo | Secondary aptitude | Cosmetic description | Aether-Log hint |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Sorrelcliff | Verdant/Telluric | Sproutlet + Tuskcub | a mountain goat | Fernscarp | Highhorn | Woodcutting | Woodcutting, Herbalism, Mining | Sure Footing: chance to save materials while working Woodcutting [Moderate] | Guard | Mountain Stance (party Guard buff, Telluric) | Standard | Fabrication | A young mountain goat with a sorrel-brown coat and small stone-flecked horns, sure-footed among loose scree. | A sure-footed climber with a reddish coat grazes where the rock crumbles underfoot. |
| Hazelslate | Verdant/Telluric | Mossgear + Pebblescoot | a tortoise | Mossflint | Grovepeak | Mining | Mining, Woodcutting, Herbalism | Slow Seam: rare-drop chance within the current tier while working Mining [Moderate] | Guard | Stone Bulwark (party Guard buff, Telluric) | Heavy | Scavenging | A slow, mossy tortoise whose shell is layered like flat grey slate, dotted with tiny hazel-brown flecks. | Patience wears a shell of stacked grey plates and waits for the seam to open. |
| Brackensear | Verdant/Pyric | Brambletrundle + Cinderpup | a hedgehog | Thornkiln | Scaldhearth | Woodcutting | Woodcutting, Herbalism, Cooking, Smithing | Bristle Puff: chance for extra output while working Woodcutting [Moderate] | Power | Scald Curl (single-target, Pyric) | Quick | Scavenging | A small hedgehog rolled into a ball of dry bracken fronds, with a faint warm glow between its curled spines. | Curl tight, roll fast, and the dry thicket catches before anything else does. |
| Yarrowflare | Verdant/Pyric | Buzzbud + Roastbelly | a sunbird | Bloomember | Petalblaze | Herbalism | Herbalism, Woodcutting, Cooking, Smithing | Nectar Focus: bonus XP while working Herbalism [Minor] | Health | Sun Sip (instant party heal, Pyric) | Quick | Fabrication | A tiny sunbird with yarrow-white feathers and a throat that glows like a low ember. | A small bright flyer sips warmth from blossoms that never quite go out. |
| Sedgestilt | Verdant/Aqueous | Mossgear + Dewdrop | a heron | Reedcurrent | Willowmire | Fishing | Fishing, Woodcutting, Herbalism | Still Water: chance at sunken-treasure drops while working Fishing [Moderate] | Power | Reed Spear (single-target, Aqueous) | Standard | Scavenging | A slender heron standing on reed-thin legs in a bed of tall sedge grass. | Long legs, longer patience, standing still until the water gives something up. |
| Rowanboulder | Verdant/Aqueous | Sproutlet + Frothsprite | an otter | Fernbrook | Alderfalls | Woodcutting | Woodcutting, Herbalism, Fishing | Slick Coat: bonus Health while working Woodcutting [Moderate] | Health | River Roll (multi-target, Aqueous) | Standard | Fabrication | A sleek river otter with a rowan-red sheen to its fur, sunning itself on a smooth wet boulder. | It naps on the biggest stone in the stream and swims like the current owes it something. |
| Ivyflux | Verdant/Voltaic | Buzzbud + Coilchirp | a dragonfly | Vinespark | Leafcharge | Circuitry | Circuitry, Woodcutting, Herbalism | Jolt Wing: bonus Power while working Circuitry [Moderate] | Power | Copper Dart (single-target, Voltaic) | Quick | Fabrication | A quick dragonfly with wings veined in trailing ivy and a faint crackle following each turn. | Green wings trail a live current; blink and it has already turned twice. |
| Burrbolt | Verdant/Voltaic | Brambletrundle + Joulebug | a squirrel | Quillspark | Quillstatic | Woodcutting | Woodcutting, Herbalism, Circuitry | Nut Hoard: bonus Voltaic resource drop while working Woodcutting [Moderate] | Power | Acorn Volley (multi-target, Verdant) | Quick | Scavenging | A bright-eyed squirrel with a coat of clinging burrs that spark faintly when it leaps. | It hoards prickly seeds that tingle, and leaps before the static settles. |
| Cliffscorch | Telluric/Pyric | Quakemaw + Emberfang | a scorpion | Sunspire | Blazingpeak | Mining | Mining, Cooking, Smithing | Fast Claws: cooldown reduction while working Mining [Minor] | Power | Magma Lance (single-target, Pyric) | Standard | Fabrication | A stone-plated scorpion whose pincers glow faint orange at the tips, like scorched rock cooling. | Two heated claws wait under a slab that never quite stops being warm. |
| Nettlemesa | Telluric/Pyric | Geodecore + Charwhisk | a horned lizard | Spurmesa | Spinehearth | Cooking | Cooking, Smithing, Mining | Spined Hide: bonus Guard while working Cooking [Moderate] | Guard | Sunbaked Bastion (self shield, Telluric) | Heavy | Scavenging | A horned lizard the color of sun-baked mesa clay, its spines tipped with a dull, stubborn heat. | Flat, dry, and spiky, it suns itself on the hottest ledge and refuses to move first. |

## Why these pairs (and species)

| Recipe | Why |
|---|---|
| Sproutlet + Tuskcub | Antlered sapling-deer plus tusked mountain boar: a sure-footed goat. |
| Mossgear + Pebblescoot | Mossy cog-sphere plus a layered shale beetle: a slow stone-shelled tortoise. |
| Brambletrundle + Cinderpup | A rolling ball of thorns plus a spark-tailed pup: a hedgehog that curls and glows. |
| Buzzbud + Roastbelly | A pollinator bee plus a warm sleepy salamander: a nectar-sipping sunbird. |
| Mossgear + Dewdrop | Mossy cog-sphere plus a water bead: a heron standing still in a mossy marsh. |
| Sproutlet + Frothsprite | Sapling-deer plus a giggling seafoam spirit: a river otter. |
| Buzzbud + Coilchirp | A darting pollinator plus a copper-wire songbird: a live-wire dragonfly. |
| Brambletrundle + Joulebug | A thorny rolling ball plus a glowing beetle: a squirrel that crackles when it leaps. |
| Quakemaw + Emberfang | A jaw-heavy digger plus a fire-fanged kitten: a heated stone scorpion. |
| Geodecore + Charwhisk | A humming crystal orb plus a fire-whisk bird: a sun-baked horned lizard. |

Species reuse: Sproutlet, Brambletrundle, Mossgear and Buzzbud (all four Verdant base species) each
appear in exactly two recipes, with a different partner each time. All ten recipes use a different
specific species pair; none repeats.

## Revision (2026-09-23): machine-checked and root-reuse fixed

A checker script (parses `content-data.md`, `chunk2-claude.md` and this file directly, not
hardcoded) confirmed the structural rules and then flagged 5-letter-stem reuse across the whole
game. Every stem the script flagged that traced back to a name in this file was changed:
`Timbercrag`→`Ridgehorn`, `Patient Digger`→`Slow Seam`, `Slate Ward`→`Stone Bulwark`,
`Bramblehearth`→`Scaldhearth`, `Bramble Roll`→`Bristle Puff`, `Ember Curl`→`Scald Curl`,
`Warm Nectar`→`Sun Sip`, `Patient Wader`→`Still Water`, `Thick Pelt`→`Slick Coat`,
`Ivy Charge`→`Live Current`, `Static Dart`→`Copper Dart`, `Charged Cache`→`Nut Hoard`,
`Scorchspire`→`Sunspire`, `Quick Sting`→`Fast Claws`, `Magma Sting`→`Magma Lance`,
`Thornmesa`→`Spurmesa`, `Sunbaked Shell`→`Sunbaked Bastion`. Stems that were already at or past the
threshold from pre-existing names alone (Void, Cinder, Aether, Briar, Eclipse, and others) were left
alone, since none of that reuse is mine to fix and none of it involves a name from a sprite-generated
line. **A second rerun then caught two mistakes in that first pass**: `Ridgehorn` collided with the
pre-existing Ridgecrest/Ridgehide (fixed to `Highhorn`), and `Live Current` collided with
pre-existing Verdant Current plus my own `Still Current` in Chunk 3 (fixed to `Jolt Wing`). The
recheck after that passed clean. Note the checker's limits: it matches a flat 5-letter prefix, so a
shared shorter root (for example "Sun-" now starting four different names here) would not be caught
by it.

## Self-review: what I could not verify

Unlike Chunk 2, I did not have (and did not attempt to rebuild) the automated checker script, so
none of this is machine-verified — treat it as a careful hand pass, not a guarantee.

1. **Pair assignment is a reconstruction, not a recovered fact** (see the note at the top). This is
   the one thing I'd most want the designer to confirm or correct.
2. **Name-collision checking was done by memory and by rereading `content-data.md`, not by a script.**
   I avoided the roots I could recall as heavily used (tide, thicket, crag, ember, cinder, hush) but
   may have missed others. Moderate reuse I did allow on purpose: "grove" and "peak" each appear
   twice, "thorn" appears twice (Brackensear's Form 2, Nettlemesa's Form 2).
3. **Trait-mechanic collisions against parents were checked by hand** (each recipe's mechanic avoids
   both its parents' own signature-trait mechanics), and the ten mechanics used are mutually
   distinct: save-materials, rare-drop, extra-output, bonus-XP, treasure, bonus-Health, bonus-Power,
   resource-drop, cooldown, bonus-Guard. I have not checked them against Chunk 2's ten.
4. **Covered-skills ordering.** I used "primary skill first, then own-type's other skill(s), then
   the other type's skills in canonical order," matching Chunk 2's stated rule and most of the
   default-hybrid table. Three default-hybrid rows (Brambletide, Mudskulker, Brinecore) actually
   order by the Pair column instead, ignoring which skill is primary — I judged that an authoring
   inconsistency in the original table rather than the real rule, since Chunk 2 explicitly states
   "primary skill first" and demonstrates it (Gravelnip vs. Ripplesnap, same pair, different primary,
   different order). Worth a second opinion if it matters.
5. **Support/damage ratio:** 4 support (Sorrelcliff, Hazelslate, Yarrowflare, Nettlemesa) to 6 damage,
   matching Chunk 2's ratio.
6. **Ability and trait names were checked against each other within this batch only** (no two share
   a first word), not against Chunk 2's or the base/default tables' ability and trait names.
7. **Animals:** ten distinct animals (goat, tortoise, hedgehog, sunbird, heron, otter, dragonfly,
   squirrel, scorpion, horned lizard), none repeated within this batch; not checked against Chunk 2's
   ten or Chunk 3's.
8. **Not machine-checkable, judged by me:** hints avoid the animal word and the parent/result names,
   are 11-16 words, and are cosmetic rather than mechanical; no real-world IP in any name.
