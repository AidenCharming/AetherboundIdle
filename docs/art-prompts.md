# Creature sprite prompts (ready to paste)

Generated 2026-09-21 from `D:\AI\tools\build_prompts.py` (edit the table there, rerun, and this file and `D:\AI\tools\creatures.json` are rebuilt). Recipe and lessons: `docs/art-pipeline.md`. Nothing here is wired into the game.

## Status of the source material (read this first)

- **24 base species:** names, types and form lines come from `docs/content-data.md`. The four done lines (Sproutlet, Emberfang, Brambletrundle, Riftsneak) are approved. The other 20 are written here from the design's placeholder descriptions, reworded to be art-safe (no "glowing" or "aura"; transparent things made opaque; pink kept away from the key colour).
- **15 default hybrids:** the design only gives names, types and skills, never a look. The animals and designs here are **my invention** (an assistant proposal) and need the designer's review before any of them are generated. Cheap to change: edit the table, rerun.
- **10 special recipes (Chunk 2):** from `docs/naming/chunk2-claude.md` (names and cosmetic lines). **Provisional**: that batch has not been reviewed yet, so the names may still change.
- **All 69 species have prompts.** The last 20 specials (Chunks 1 and 3) were written 2026-09-24 from the final names and form descriptions in `godot/data/species.json`.
- **Not counted:** eggs, vessels, icons and zone art are separate tasks.

## How to use these

Two graphs in ComfyUI, both with **klein 4B distilled**:
1. **Form 1**: the *Flux.2 [Klein] 4B Text to Image* graph, **8 steps, CFG 1.0**, 1024x1024, run **5**. Paste the Form 1 prompt, pick the best, save it as `D:\AI\sprites\approved\<id>-f1.png`.
2. **Form 2**: the *edit* graph (4B files swapped in), **8 steps, CFG 1.0**, reference = the approved Form 1, run **5**, paste the Form 2 prompt. Approve as `<id>-f2.png`.
3. **Form 3**: the same edit graph, reference = the approved Form 2. Approve as `<id>-f3.png`.

**Fastest order:** do a whole *stage* at a time (all Form 1s, then all Form 2s, then all Form 3s), so you never switch graphs. About 22 s per Form 1 set and 90 s per Form 2 or 3 set of five, so roughly 3.5 minutes of generation per creature and about 2.5 hours for all 45, plus picking time.

**Picking checklist:** reject extra twigs or floating parts, a second head-like blob, one-eyed or melted faces, a stray signature, a visible floor shadow, glow or haze around the outline, and for Forms 2 and 3 anything that kept the old pose or size (the ratio wording is what makes the growth happen). If a Form 2 or 3 batch barely changes the body, rerun with the same prompt first; only then strengthen the ratio wording.

**Key colour:** magenta `#FF00FF` for everything except **green `#00FF00` for Void creatures and Coralpeep** (purple and pink sit too close to magenta). Each prompt already contains the right one. **Void creatures** are written in "rich mid-violet with lighter lavender highlights" (from the Riftsneak pilot): a near-black body vanishes on the game's dark plate.

**Lessons from the four finished lines (apply while picking):**
- **Form 3 keep list is face-only** (face, eyes, one head feature, a colour if needed). A long "keep the same ..." list anchors the reference's proportions and the body barely grows. If a Form 3 batch still barely changes, strengthen the ratio wording and redraw from the best candidate.
- **Biped to quadruped (or the reverse):** the pose wording must state the stance every time ("prowling on all four legs, low and stalking, not upright").
- **Fixing one detail** (a ring, a tail tip): use the best candidate as the reference and write "The same character as the reference image, with exactly the same ... Change only ...", locate the target by place with a size number, and name everything else as unchanged. A small detail is dropped unless it is a headline feature or is named in the keep list. Do not delete rejected candidates until the final pick.
- **Style drift:** Forms 2 and 3 tend to come out darker and more textured than the glossy Form 1. Reject the dull ones and check saturation in the game.

**After approving a creature, cut it out** (magenta ones, then green ones):
```
"D:\AI\ComfyUI\python_embeded\python.exe" "D:\AI\tools\sprite_tools.py" cutout --halo --qa --out "D:\AI\sprites\cutouts" "D:\AI\sprites\approved\<id>-f1.png" "D:\AI\sprites\approved\<id>-f2.png" "D:\AI\sprites\approved\<id>-f3.png"
```
For a green-key creature add `--bg #00FF00`. Add `--halo-strict` only if a pink haze is visible after a normal cut (never for a creature that is meant to have pink). Open the `--qa` image (the sprite over bright cyan) and zoom in on the feet and where a leg meets the body: a dark shaded part can be mistaken for the cast shadow and bitten away. If so, protect it with `--keep X0,Y0,X1,Y1` (see `docs/art-pipeline.md`).

**Ratio ladder used** (from the Emberfang test): `animal` = Form 1 about 1x (chibi), Form 2 about 3x, Form 3 about 4x plus "noticeably larger and more massive"; `cute` (Cinderpup, Voltfluff, Roastbelly) = about 2x then 2.5x with the head kept large; `structure` (orbs, machines, insects, plants, jelly) = no ratio, the growth is described in words.

## Checklist

| # | Creature | Types | Forms | Group | Key | Ratio | Status |
|---|---|---|---|---|---|---|---|
| 1 | Sproutlet | Verdant | Sproutlet > Timberhorn > Lumbercrown | base | magenta | animal | DONE |
| 2 | Brambletrundle | Verdant | Brambletrundle > Briarburl > Thicketroll | base | magenta | structure | DONE |
| 3 | Mossgear | Verdant | Mossgear > Mosscrank > Mossbastion | base | magenta | structure | F1 [x]  F2 [x]  F3 [x] |
| 4 | Buzzbud | Verdant | Buzzbud > Pollenwing > Bloomqueen | base | magenta | structure | F1 [x]  F2 [x]  F3 [x] |
| 5 | Quakemaw | Telluric | Quakemaw > Faultjaw > Craterchomp | base | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 6 | Geodecore | Telluric | Geodecore > Crystalheart > Prismpulse | base | magenta | structure | F1 [x]  F2 [x]  F3 [x] |
| 7 | Pebblescoot | Telluric | Pebblescoot > Shalestride > Bedrockbound | base | magenta | structure | F1 [x]  F2 [x]  F3 [x] |
| 8 | Tuskcub | Telluric | Tuskcub > Ridgecrest > Summitspike | base | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 9 | Emberfang | Pyric | Emberfang > Smolderbite > Emberroar | base | magenta | animal | DONE |
| 10 | Cinderpup | Pyric | Cinderpup > Cinderbark > Cinderhowl | base | magenta | cute | F1 [x]  F2 [x]  F3 [x] |
| 11 | Roastbelly | Pyric | Roastbelly > Oventummy > Smolderplump | base | magenta | cute | F1 [x]  F2 [x]  F3 [x] |
| 12 | Charwhisk | Pyric | Charwhisk > Coalstir > Hearthblend | base | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 13 | Dewdrop | Aqueous | Dewdrop > Rillstream > Tideflow | base | magenta | structure | F1 [x]  F2 [x]  F3 [x] |
| 14 | Puddlescoop | Aqueous | Puddlescoop > Basincatch > Lakehaul | base | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 15 | Frothsprite | Aqueous | Frothsprite > Foamspirit > Brinesoul | base | magenta | structure | F1 [x]  F2 [x]  F3 [x] |
| 16 | Splashfin | Aqueous | Splashfin > Wavegill > Tidetail | base | magenta | structure | F1 [x]  F2 [x]  F3 [x] |
| 17 | Voltfluff | Voltaic | Voltfluff > Staticfleece > Arcwool | base | magenta | cute | F1 [x]  F2 [x]  F3 [x] |
| 18 | Joulebug | Voltaic | Joulebug > Ohmroach > Wattbeetle | base | magenta | structure | F1 [x]  F2 [x]  F3 [x] |
| 19 | Plasmaplug | Voltaic | Plasmaplug > Ionjack > Surgeport | base | magenta | structure | F1 [x]  F2 [x]  F3 [x] |
| 20 | Coilchirp | Voltaic | Coilchirp > Wirebeak > Gridtrill | base | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 21 | Eclipsa | Void | Eclipsa > Umbrax > Penumbrum | base | green | structure | F1 [x]  F2 [x]  F3 [x] |
| 22 | Riftsneak | Void | Riftsneak > Nullprowl > Gloamstalk | base | green | structure | DONE |
| 23 | Hushflutter | Void | Hushflutter > Hushglide > Silentwing | base | green | structure | F1 [x]  F2 [x]  F3 [x] |
| 24 | Netherpod | Void | Netherpod > Chasmshell > Astralcarapace | base | green | structure | F1 [x]  F2 [x]  F3 [x] |
| 25 | Ashwood | Verdant/Pyric | Ashwood > Emberbark > Hearthtrunk | hybrid | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 26 | Brambletide | Verdant/Aqueous | Brambletide > Briarripple > Thicketwave | hybrid | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 27 | Sproutfault | Verdant/Telluric | Sproutfault > Timbershale > Lumbercrag | hybrid | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 28 | Mosscoil | Verdant/Voltaic | Mosscoil > Mossfuse > Canopygrid | hybrid | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 29 | Mudskulker | Telluric/Aqueous | Mudskulker > Shaleflow > Bedrocktide | hybrid | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 30 | Quakeforge | Telluric/Pyric | Quakeforge > Slagfist > Craterhearth | hybrid | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 31 | Geodegrid | Telluric/Voltaic | Geodegrid > Crystalwire > Prismvolt | hybrid | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 32 | Cinderbasin | Pyric/Aqueous | Cinderbasin > Steamrill > Kettlebrine | hybrid | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 33 | Embersurge | Pyric/Voltaic | Embersurge > Blazearc > Infernodynamo | hybrid | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 34 | Brinecore | Aqueous/Voltaic | Brinecore > Rillarc > Tidebolt | hybrid | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 35 | Eclipseed | Void/Verdant | Eclipseed > Starsap > Nightbloom | hybrid | green | animal | F1 [x]  F2 [x]  F3 [x] |
| 36 | Nullshale | Void/Telluric | Nullshale > Riftrock > Abysscrag | hybrid | green | animal | F1 [x]  F2 [x]  F3 [x] |
| 37 | Gloamforge | Void/Pyric | Gloamforge > Muteember > Hushkiln | hybrid | green | animal | F1 [x]  F2 [x]  F3 [x] |
| 38 | Hushflow | Void/Aqueous | Hushflow > Nullstream > Riftcurrent | hybrid | green | structure | F1 [x]  F2 [x]  F3 [x] |
| 39 | Gridrift | Void/Voltaic | Gridrift > Corewire > Lodestar | hybrid | green | structure | F1 [x]  F2 [x]  F3 [x] |
| 40 | Gravelnip | Telluric/Aqueous | Gravelnip > Reefpincer > Boulderclaw | special | magenta | structure | F1 [x]  F2 [x]  F3 [ ] |
| 41 | Ripplesnap | Telluric/Aqueous | Ripplesnap > Slatesnout > Ridgehide | special | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 42 | Cairnflit | Telluric/Voltaic | Cairnflit > Pumiceglide > Fluxwing | special | magenta | structure | F1 [x]  F2 [x]  F3 [x] |
| 43 | Flintlamb | Telluric/Voltaic | Flintlamb > Ampcurl > Mesahorn | special | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 44 | Coralpeep | Pyric/Aqueous | Coralpeep > Flarewade > Pyreplume | special | green | animal | F1 [x]  F2 [x]  F3 [x] |
| 45 | Drizzlenub | Pyric/Aqueous | Drizzlenub > Brooksoak > Lavabask | special | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 46 | Coalgrub | Pyric/Voltaic | Coalgrub > Arcflicker > Blazefly | special | magenta | structure | F1 [x]  F2 [x]  F3 [x] |
| 47 | Boltkit | Pyric/Voltaic | Boltkit > Brandtail > Scorchfox | special | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 48 | Eddyelver | Aqueous/Voltaic | Eddyelver > Kelpeel > Dynamoeel | special | magenta | structure | F1 [x]  F2 [x]  F3 [x] |
| 49 | Sprayfledge | Aqueous/Voltaic | Sprayfledge > Pulsedart > Voltfisher | special | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 50 | Sorrelcliff | Verdant/Telluric | Sorrelcliff > Fernscarp > Highhorn | special | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 51 | Hazelslate | Verdant/Telluric | Hazelslate > Mossflint > Grovepeak | special | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 52 | Brackensear | Verdant/Pyric | Brackensear > Thornkiln > Scaldhearth | special | magenta | cute | F1 [x]  F2 [x]  F3 [x] |
| 53 | Yarrowflare | Verdant/Pyric | Yarrowflare > Bloomember > Petalblaze | special | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 54 | Sedgestilt | Verdant/Aqueous | Sedgestilt > Reedcurrent > Willowmire | special | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 55 | Rowanboulder | Verdant/Aqueous | Rowanboulder > Fernbrook > Alderfalls | special | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 56 | Ivyflux | Verdant/Voltaic | Ivyflux > Vinespark > Leafcharge | special | magenta | structure | F1 [x]  F2 [x]  F3 [x] |
| 57 | Burrbolt | Verdant/Voltaic | Burrbolt > Quillspark > Stormbristle | special | magenta | cute | F1 [x]  F2 [x]  F3 [x] |
| 58 | Cliffscorch | Telluric/Pyric | Cliffscorch > Kilnclaw > Pyrestinger | special | magenta | structure | F1 [x]  F2 [x]  F3 [x] |
| 59 | Nettlemesa | Telluric/Pyric | Nettlemesa > Spurback > Spinehearth | special | magenta | animal | F1 [x]  F2 [x]  F3 [x] |
| 60 | Murkroot | Void/Verdant | Murkroot > Palevine > Loamgrove | special | green | cute | F1 [x]  F2 [x]  F3 [x] |
| 61 | Duskbloom | Void/Verdant | Duskbloom > Wanehop > Moonwarren | special | green | animal | F1 [x]  F2 [x]  F3 [x] |
| 62 | Riftshale | Void/Telluric | Riftshale > Chasmclaw > Abyssburrow | special | green | animal | F1 [x]  F2 [x]  F3 [x] |
| 63 | Nethershale | Void/Telluric | Nethershale > Grimplate > Umbralith | special | green | animal | F1 [x]  F2 [x]  F3 [x] |
| 64 | Wraithcoal | Void/Pyric | Wraithcoal > Ashgloam > Cinderwraith | special | green | animal | F1 [x]  F2 [x]  F3 [x] |
| 65 | Duskflare | Void/Pyric | Duskflare > Wanescorch > Gloamfang | special | green | animal | F1 [x]  F2 [x]  F3 [x] |
| 66 | Murkmire | Void/Aqueous | Murkmire > Murkveil > Abyssbloom | special | green | structure | F1 [x]  F2 [x]  F3 [x] |
| 67 | Hollowstream | Void/Aqueous | Hollowstream > Stillgill > Palepool | special | green | animal | F1 [x]  F2 [x]  F3 [x] |
| 68 | Wraithwire | Void/Voltaic | Wraithwire > Wanewire > Shadescythe | special | green | structure | F1 [x]  F2 [x]  F3 [ ] |
| 69 | Duskvolt | Void/Voltaic | Duskvolt > Wanecoil > Gloomweaver | special | green | structure | F1 [x]  F2 [x]  F3 [x] |

## Base species

### 1. Sproutlet > Timberhorn > Lumbercrown (Verdant)

**DONE.** Approved. Prompts are in docs/art-pipeline.md. Cut out with --halo-strict.

### 2. Brambletrundle > Briarburl > Thicketroll (Verdant)

**DONE.** Approved line (2026-09-21): Form 1 = F1 batch #3; Form 2 = image #2 of the batch made from the tank (the round mossy golem with wooden arms and clawed feet; the F2 prompt below is a reconstruction of that look, NOT the prompt that produced it, so a rerun from Form 1 may differ); Form 3: the first batch (5 candidates, prompt that said keep the same moss, flowers and core) barely changed the body, candidate 3 was best but not bulky enough; the current F3 prompt is the heavy redraw recipe (face-only keep, body about four times the face) and was run from that F3 candidate 3 as reference (second batch, brambletrundle-f3 prefix). APPROVED Form 3 = second-batch candidate 5 (upright hulking wood-and-vine giant), saved as brambletrundle-f3.png; cut out with --keep 388,742,466,850. Form 2 cut out with --keep 385,808,468,850. The tank-on-thorn-treads Form 2 (batch pick #3) is kept as brambletrundle-f2tank.png, an alternate. The design line in content-data.md still says tank on tracks: reconcile doc and JSON later. Key colour drifts to mauve after edits; the cut-out copes. The design still calls Form 2 Briartread: renamed Briarburl by the designer, not yet applied to content-data.md and species.json.

Prompts as written in the table, for the record (the approved images came from the variants described above; see `docs/art-pipeline.md`):
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-green outlines and vibrant saturated colours. A small chaotic rolling ball made of tangled bright-green thorny vines, with two big glossy dark-brown eyes and a wide happy open mouth on the front of the ball, a few small yellow zigzag lightning-bolt marks painted on the vines, small soft thorns, and two short stubby vine feet peeking out at the bottom. Three-quarter view facing left, rolling along the ground, tilted slightly forward, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
```
Redraw the same character as the reference image as its second form, a bigger, sturdier tumbleweed golem. Keep the same round face, the same big glossy dark-brown eyes and the same green thorny vines with small yellow zigzag bolt marks, the same dark-green outlines and the same art style. Make it noticeably larger and more complex overall. Now much bigger and rounder: a big ball of thick green thorny vines wrapped around a brown wooden barrel-like core that shows between the vines, patches of green moss and a few small white flowers, two bark-wood arms with hands held out wide, and two thick stubby wooden feet with blunt claws. Three-quarter view facing left, standing on two thick stubby feet with both arms held out wide, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
```
Redraw the same character as the reference image as its final form, an ancient, hulking, gentle giant. Keep the same face, the same big glossy brown eyes, the same gentle smile and the same green skin, the same dark-green outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A huge barrel-like wooden trunk of a body wrapped in thick green thorny vines with small blunt thorns, thick with moss and dotted with small white flowers, two enormous tree-trunk arms with big bark-covered hands held wide open for a hug, two thick tall tree-trunk legs with big clawed feet, and a few small saplings on its shoulders. Gentle and kind. Three-quarter view facing left, standing tall on its two thick legs with both arms open wide for a hug, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 3. Mossgear > Mosscrank > Mossbastion (Verdant)

`id: mossgear` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark-green | note: Mechanical: a candidate to retest with the base model (see art-pipeline.md).

**Form 1, Mossgear** (text to image, 8 steps, CFG 1.0, file `mossgear-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-green outlines and vibrant saturated colours. A small round fuzzy sphere covered in soft bright-green moss, shaped like a cog with short rounded gear teeth around its rim, a small brass gear set into the middle of its forehead, two big round friendly amber eyes, a tiny smile and two tiny stubby feet. Three-quarter view facing left, sitting on the ground, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Mosscrank** (edit, reference = `mossgear-f1.png`, 8 steps, CFG 1.0, file `mossgear-f2.png`)
```
Redraw the same character as the reference image as its second form, a bipedal mossy mechanism. Keep the same round friendly face, the same big amber eyes and the same bright-green mossy colouring, the same dark-green outlines and the same art style. Make it noticeably larger and more complex overall. Now an upright little machine with a body about three times the size of the head: a barrel-shaped mossy torso, a cog-toothed round head, jointed brass-and-wood legs, small arms and a brass crank handle on its back. Three-quarter view facing left, standing upright on two legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Mossbastion** (edit, reference = `mossgear-f2.png`, 8 steps, CFG 1.0, file `mossgear-f3.png`)
```
Redraw the same character as the reference image as its final form, a gentle lumbering botanical machine. Keep the same friendly face, the same big round amber eyes and the same bright-green mossy colouring, the same dark-green outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A huge, broad, slow-moving machine-golem with a body about four times the size of the head, mossy plates over a brass and stone frame, a large gear set in its chest, ferns and small flowers growing from its shoulders and back, thick strong legs, and still a gentle kind face. Three-quarter view facing left, standing upright on two thick legs with its arms hanging low, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 4. Buzzbud > Pollenwing > Bloomqueen (Verdant)

`id: buzzbud` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark-green | note: Replaces Petalsprocket (scrapped 2026-09-22): the flower-rotor concept never grew visibly across several batches, partly because the keep list anchored the petal SHAPE while the growth text asked that shape to change - a direct contradiction found after the fact. New concept is a pollinator bee with concrete, unambiguous growth (wing count doubles, the bud it carries blooms open, size stated as an explicit multiple each stage), and it ties directly into the existing Pollinator trait and explains the Rotor Gust ability as the blur of a fast-beating bee's wings. Same slot: Verdant, Herbalism, same stats/ability/trait untouched, only the name and visual concept changed.

**Form 1, Buzzbud** (text to image, 8 steps, CFG 1.0, file `buzzbud-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-green outlines and vibrant saturated colours. A small round fuzzy bee with soft yellow-and-green fuzzy stripes, two simple pale-green translucent wings, big round dark eyes, two small antennae each tipped with a tiny leaf, thin legs, and a small closed flower bud held between its front legs like a little bundle. Three-quarter view facing left, hovering in mid-air, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Pollenwing** (edit, reference = `buzzbud-f1.png`, 8 steps, CFG 1.0, file `buzzbud-f2.png`)
```
Redraw the same character as the reference image as its second form, a bigger pollen-carrying bee, its bud now in bloom. Keep the same round face, the same big dark eyes, the same yellow-and-green fuzzy colouring, and its small leaf-tipped antennae, the same dark-green outlines and the same art style. Make it noticeably larger and more complex overall. Now about twice the size of the reference: two pairs of wings instead of one, larger and more richly patterned yellow-and-green fuzzy stripes, a light dusting of pollen across its legs, and the small bud it carries has bloomed open into a bright flower held between its front legs. Three-quarter view facing left, hovering in mid-air, the bloomed flower held in its front legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Bloomqueen** (edit, reference = `buzzbud-f2.png`, 8 steps, CFG 1.0, file `buzzbud-f3.png`)
```
Redraw the same character as the reference image as its final form, Bloomqueen, a grand flower-crowned queen bee. Keep the same round face, the same big dark eyes and the same yellow-and-green fuzzy colouring, the same dark-green outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A large, majestic queen bee about twice the size of the second form, with four big, ornately patterned wings, a thick fuzzy mane of yellow-and-green stripes, and a grand crown of blooming flowers around its head where the bud once was; stately and gentle, not fierce. Three-quarter view facing left, hovering in mid-air, wings spread wide, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 5. Quakemaw > Faultjaw > Craterchomp (Telluric)

`id: quakemaw` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark-brown | note: Pose changed 2026-09-22: two straight batches of scale-only wording (even with an explicit "bigger" anchor) left it the exact same standing size as Form 2. Forcing a reared-up pose gives the edit model a genuinely different silhouette to draw instead of the same stance scaled up, which is what unstuck every other stuck species this round.

**Form 1, Quakemaw** (text to image, 8 steps, CFG 1.0, file `quakemaw-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-brown outlines and vibrant saturated colours. A stout little lizard with a big square jaw and a wide friendly grin, grey-brown rocky-textured skin with small pebble-like bumps, big round golden-yellow eyes, a bright amber-orange throat pouch, short thick legs with stubby claws and a short thick tail. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Faultjaw** (edit, reference = `quakemaw-f1.png`, 8 steps, CFG 1.0, file `quakemaw-f2.png`)
```
Redraw the same character as the reference image as its second form, an armoured reptile with a shovel underbite. Keep the same big square jaw, the same big round golden-yellow eyes and the same grey-brown rocky skin with the amber-orange throat, the same dark-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now with grey stone armour plates along its back and a broad flat shovel-shaped lower jaw that juts out in an underbite with a few blunt teeth, and a thicker tail. Three-quarter view facing left, walking on all four legs, low and heavy, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Craterchomp** (edit, reference = `quakemaw-f2.png`, 8 steps, CFG 1.0, file `quakemaw-f3.png`)
```
Redraw the same character as the reference image as its final form, a friendly earth-dragon. Keep the same friendly face, the same big round golden-yellow eyes and the same grey-brown colouring, the same dark-brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. Now a large, friendly earth-dragon reared up onto its hind legs and thick tail, mouth open in a mighty roar with front claws raised high, a stone-plated back, small blunt horn ridges over its brow, a row of large clear pale-blue crystal teeth along its wide jaw and short pale-blue crystal spikes along its spine and tail, calm and kind despite the roar. Three-quarter view facing left, reared up on its hind legs and tail like a tripod, front claws raised, chest puffed out, mouth open in a roar, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 6. Geodecore > Crystalheart > Prismpulse (Telluric)

`id: geodecore` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark-brown | note: Reimagined 2026-09-22 after the first Form 3 batch just glued a few extra pebbles onto the unchanged Form 2 ball shape: the new version gives the crystal core actual arms and legs and turns the stones into a genuinely orbiting ring instead of decoration.

**Form 1, Geodecore** (text to image, 8 steps, CFG 1.0, file `geodecore-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-brown outlines and vibrant saturated colours. A round hollow grey-brown stone orb with a rough surface, two big round dark eyes on the upper front of the stone, and a single small pale-blue crystal held in a round opening in the front centre, like a stone shell cradling a gem. Three-quarter view facing left, floating in mid-air, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Crystalheart** (edit, reference = `geodecore-f1.png`, 8 steps, CFG 1.0, file `geodecore-f2.png`)
```
Redraw the same character as the reference image as its second form, a faceted floating crystal creature. Keep the same two big round dark eyes, the same grey-brown stone and the same pale-blue crystal, the same dark-brown outlines and the same art style. Make it noticeably larger and more complex overall. Now a larger body made of faceted amber-orange crystal with brown stone plates on its sides, with sharp clean facets and small pale highlights painted on each facet. Three-quarter view facing left, floating in mid-air, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Prismpulse** (edit, reference = `geodecore-f2.png`, 8 steps, CFG 1.0, file `geodecore-f3.png`)
```
Redraw the same character as the reference image as its final form, a brilliant crystal colossus encircled by an asteroid ring. Keep the same two big round dark eyes, the same dark-brown outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. Completely reimagined and dramatically bigger: the stone shell has cracked open into four stone shoulder-plates, revealing a tall crystal body underneath, faceted amber-orange and pale-blue, with crystal-shard arms and legs and the same eyes. A ring of five grey-brown stones orbits around its waist like a small asteroid belt, each stone clearly separate from the body, not touching it. Three-quarter view facing left, floating upright in mid-air, arms held slightly out, the stone ring visibly orbiting around its waist, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 7. Pebblescoot > Shalestride > Bedrockbound (Telluric)

`id: pebblescoot` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark-brown | note: Redesigned 2026-09-22: the first Form 3 batch kept the exact six-legs-low-to-the-ground shape and just sprinkled crystal specks on it. The designer wanted a real shape change (bipedal, boss-monster stance), so Form 3 now rears up onto two legs instead of extending into a centipede.

**Form 1, Pebblescoot** (text to image, 8 steps, CFG 1.0, file `pebblescoot-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-brown outlines and vibrant saturated colours. A small skittish round beetle with a slate-grey shell made of layered shale plates, six small stubby legs, two big round dark eyes, two short antennae and a nervous little smile. Three-quarter view facing left, standing on six legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Shalestride** (edit, reference = `pebblescoot-f1.png`, 8 steps, CFG 1.0, file `pebblescoot-f2.png`)
```
Redraw the same character as the reference image as its second form, a multi-legged excavator. Keep the same two big round dark eyes and the same slate-grey layered shale shell, the same dark-brown outlines and the same art style. Make it noticeably larger and more complex overall. Now a longer, segmented body about three times as long, with eight strong legs, two broad shovel-shaped front claws for digging and thicker shale plates. Three-quarter view facing left, walking on all its legs, low to the ground, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Bedrockbound** (edit, reference = `pebblescoot-f2.png`, 8 steps, CFG 1.0, file `pebblescoot-f3.png`)
```
Redraw the same character as the reference image as its final form, a towering plated bipedal colossus. Keep the same two big round dark eyes, the same dark-brown outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. Completely transformed and dramatically bigger: reared up onto two thick hind legs like a towering boss monster, with two massive shovel-shaped front claws held up and out, a huge layered dome of bedrock shale plates rising up its back into jagged ridges, small bright pale-blue crystal spots along the plates. Exactly two legs and two large clawed arms, no extra limbs. Three-quarter view facing left, reared up on its two hind legs, front claws raised, broad and imposing, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 8. Tuskcub > Ridgecrest > Summitspike (Telluric)

`id: tuskcub` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark-brown

**Form 1, Tuskcub** (text to image, 8 steps, CFG 1.0, file `tuskcub-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-brown outlines and vibrant saturated colours. A playful chubby young boar piglet with tan-brown bristly fur, a cream belly, big round friendly dark eyes, a round brown snout, two tiny pale-blue crystal tusks, small hooves and a short curly tail. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Ridgecrest** (edit, reference = `tuskcub-f1.png`, 8 steps, CFG 1.0, file `tuskcub-f2.png`)
```
Redraw the same character as the reference image as its second form, a sturdy boar with mineral armour. Keep the same round friendly face, the same big dark eyes and the same tan-brown fur with the cream belly, the same dark-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now with grey mineral armour plates over its shoulders and back, longer pale-blue crystal tusks and thick strong legs. Three-quarter view facing left, standing on all four legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Summitspike** (edit, reference = `tuskcub-f2.png`, 8 steps, CFG 1.0, file `tuskcub-f3.png`)
```
Redraw the same character as the reference image as its final form, a proud woolly mineral beast. Keep the same friendly face and the same big round dark eyes, the same dark-brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A large, proud, shaggy beast with thick woolly brown fur, a row of big pale-blue crystal spikes along its back, large curved crystal tusks and grey mineral armour on its shoulders. Three-quarter view facing left, standing on all four legs, low, wide and powerful, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 9. Emberfang > Smolderbite > Emberroar (Pyric)

**DONE.** Approved (emberfang-f1/f2/f3; Form 3 is the tiger candidate). Only the Form 3 wording is recorded verbatim in the session; use the ladder below for reference.

### 10. Cinderpup > Cinderbark > Cinderhowl (Pyric)

`id: cinderpup` | key: **magenta #FF00FF** | ratio: **cute** | outline: dark red-brown | note: Design says "stays cute": milder ratio ladder, but pushed to an extreme 2026-09-23 after TWO rounds (scale-only wording, then a mid-leap pose change) both still rendered it the exact same puppy size as Form 2. This version states an explicit size comparison (horse-sized) and adds a framing instruction so the model has to compose a bigger subject, not just describe one.

**Form 1, Cinderpup** (text to image, 8 steps, CFG 1.0, file `cinderpup-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark red-brown outlines and vibrant saturated colours. A small hyperactive round puppy with charcoal-grey fur, an orange belly and paws, big round dark eyes, floppy ears, a happy open mouth with its tongue out, and a short tail ending in a tiny orange flame-shaped tuft drawn as a crisp flat shape. Three-quarter view facing left, standing on all four legs with its tail up, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Cinderbark** (edit, reference = `cinderpup-f1.png`, 8 steps, CFG 1.0, file `cinderpup-f2.png`)
```
Redraw the same character as the reference image as its second form, a bouncy fiery dog. Keep the same round face, the same big dark eyes, the same floppy ears, the same charcoal-grey and orange colouring, and its flame-shaped tail tuft, which must stay clearly flame-shaped and grow bigger, the same dark red-brown outlines and the same art style. Change the body proportions: a clearly bigger, sturdier, young-adult body about twice the size of the head, visibly longer and stronger legs and a fuller chest — a real, obvious size increase from the reference, not a subtle one — while keeping the head large and round so it still reads as cute. Now a bigger, bouncier, more middle-aged looking dog: a longer snout, less floppy ears, a thicker neck ruff, a few ember spots on its back, and a bigger, brighter tail flame-tuft. Exactly four legs, no extra limbs. Three-quarter view facing left, trotting on all four legs, one front paw lifted, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Cinderhowl** (edit, reference = `cinderpup-f2.png`, 8 steps, CFG 1.0, file `cinderpup-f3.png`)
```
Redraw the same character as the reference image as its final form, a majestic hound. Keep the same friendly face, the same big round dark eyes and the same floppy ears, the same dark red-brown outlines and the same art style. Change the body proportions further: a large, mature body about two and a half times the size of the head, a full broad chest and strong legs, clearly and obviously bigger and more grown-up than the second form, while keeping a big friendly head so it stays cute and warm, not fierce. Now truly enormous, not a puppy anymore but a huge hound the size of a horse, thick powerful legs, a massive broad chest, head raised in a howl, a thick ash-grey mane down its neck with orange ember spots, and a huge blazing flame-shaped tail tuft. Still friendly, never fierce. Three-quarter view facing left, leaping forward mid-stride, front paws off the ground, framed to nearly fill the frame, close and looming, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 11. Roastbelly > Oventummy > Smolderplump (Pyric)

`id: roastbelly` | key: **magenta #FF00FF** | ratio: **cute** | outline: dark red-brown | note: Chubby species: milder ratio ladder.

**Form 1, Roastbelly** (text to image, 8 steps, CFG 1.0, file `roastbelly-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark red-brown outlines and vibrant saturated colours. A round, sleepy little salamander with plump orange-red skin, half-closed sleepy eyes with a contented smile, a warm cream-orange belly, four stubby legs and a short thick tail. Three-quarter view facing left, sitting on its belly on the ground, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Oventummy** (edit, reference = `roastbelly-f1.png`, 8 steps, CFG 1.0, file `roastbelly-f2.png`)
```
Redraw the same character as the reference image as its second form, a chubby waddler with a belly window. Keep the same sleepy half-closed eyes, the same round face and the same orange-red skin with the cream-orange belly, the same dark red-brown outlines and the same art style. Change the body proportions: a clearly bigger, sturdier, young-adult body about twice the size of the head, visibly longer and stronger legs and a fuller chest — a real, obvious size increase from the reference, not a subtle one — while keeping the head large and round so it still reads as cute. Now bigger and chubbier, with a small round oven-style window set into its belly, framed in dark metal and showing a small flame drawn as a crisp flat shape inside. Three-quarter view facing left, waddling on all four legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Smolderplump** (edit, reference = `roastbelly-f2.png`, 8 steps, CFG 1.0, file `roastbelly-f3.png`)
```
Redraw the same character as the reference image as its final form, a colossal, cozy hearth-salamander. Keep the same sleepy half-closed eyes, the same friendly face and the same orange-red skin, the same dark red-brown outlines and the same art style. Change the body proportions further: a large, mature body about two and a half times the size of the head, a full broad chest and strong legs, clearly and obviously bigger and more grown-up than the second form, while keeping a big friendly head so it stays cute and warm, not fierce. Now truly colossal, a warm and beloved giant: a grand row of chimney-stack ridges along its spine, each with a small ember window like the belly one, ember-crack patterns across its skin, and a huge oven-belly window big enough for two crackling flames. Still the same sleepy, half-closed, content expression -- a gentle giant, never fierce. Three-quarter view facing left, sitting contentedly on the ground, huge and round, completely at ease, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 12. Charwhisk > Coalstir > Hearthblend (Pyric)

`id: charwhisk` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark red-brown

**Form 1, Charwhisk** (text to image, 8 steps, CFG 1.0, file `charwhisk-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark red-brown outlines and vibrant saturated colours. A small round bird with charcoal-black and orange feathers, a small red crest tuft, big round amber eyes, a small orange beak, thin legs, and a tail shaped like a wire kitchen whisk with a few small orange embers caught in its loops. Three-quarter view facing left, standing on two thin legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Coalstir** (edit, reference = `charwhisk-f1.png`, 8 steps, CFG 1.0, file `charwhisk-f2.png`)
```
Redraw the same character as the reference image as its second form, a crane-like bird with metallic legs. Keep the same round face, the same big amber eyes, the same small beak, the same charcoal-black and orange feathers, and its distinctive wire-whisk-shaped tail with its loops and caught embers, which must stay clearly whisk-shaped, the same dark red-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now taller, with a longer neck, long thin steel-grey metallic legs, and its whisk-shaped tail grown longer but still obviously shaped like a wire kitchen whisk with clear wire loops, not a plain feathered bird tail. Three-quarter view facing left, standing on two long legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Hearthblend** (edit, reference = `charwhisk-f2.png`, 8 steps, CFG 1.0, file `charwhisk-f3.png`)
```
Redraw the same character as the reference image as its final form, a fire-peacock with kitchen-tool feathers. Keep the same friendly face, the same big round amber eyes, the same small orange beak, the same charcoal-black body feathers, and its wire-whisk-shaped tail, which must stay clearly whisk-shaped, the same dark red-brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A magnificent peacock-like bird with a huge fanned tail of feathers each shaped like a kitchen tool, whisks, ladles, spatulas and spoons, in orange, copper and red with small pale-gold highlights, on long steel-grey legs. Three-quarter view facing left, standing on two long legs with its tail fanned out behind it, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 13. Dewdrop > Rillstream > Tideflow (Aqueous)

`id: dewdrop` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark navy-blue | note: Redesigned 2026-09-22 (again): the first redesign (round blob that grows taller with a wave-crest hairdo) generated exactly as written but read as only incrementally bigger, not a real transformation. Now the wave itself becomes part of the silhouette, curling up behind the blob like a hood, instead of sitting on its head as decoration. Keep it opaque: anything see-through lets the key colour bleed in and ruins the cut-out.

**Form 1, Dewdrop** (text to image, 8 steps, CFG 1.0, file `dewdrop-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark navy-blue outlines and vibrant saturated colours. A round bead-shaped blob of glossy light-blue jelly, drawn as a solid opaque body with a few white highlight shapes painted on it, two big round dark-blue eyes and a tiny smile. Three-quarter view facing left, resting on the ground, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Rillstream** (edit, reference = `dewdrop-f1.png`, 8 steps, CFG 1.0, file `dewdrop-f2.png`)
```
Redraw the same character as the reference image as its second form, a taller standing blob with new limbs. Keep the same round face, the same big dark-blue eyes, the same light-blue colouring, and its round bead/teardrop silhouette, which must stay round and compact, not stretched into a long snake-like body, the same dark navy-blue outlines and the same art style. Make it noticeably larger and more complex overall. Now noticeably bigger and taller, standing upright on two short stubby jelly legs with two short stubby jelly arms, still a solid round bead-shaped body (not elongated), with extra silver highlight bands and a wide ring of gentle ripples painted on the ground around its feet like a shallow puddle it is standing in; the body stays solid and opaque. Three-quarter view facing left, standing upright on its two stubby legs, arms held slightly out, a shallow puddle rippling around its feet, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Tideflow** (edit, reference = `dewdrop-f2.png`, 8 steps, CFG 1.0, file `dewdrop-f3.png`)
```
Redraw the same character as the reference image as its final form, a towering tidal guardian. Keep the same friendly face, the same big round dark-blue eyes, and its round bead-shaped body, which must stay round and compact, not a long snake-like body, the same dark navy-blue outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. Completely transformed and dramatically bigger: the round bead-shaped body now rises from the curl of a small crashing wave that sweeps up and over behind it like a hood, still a solid round compact core (not elongated or serpentine), sturdier jelly arms and legs, a deep sea-blue gradient shading darker toward the base, and a wide swirling pool of water at its feet; solid and opaque throughout, calm and serene. Three-quarter view facing left, standing tall within the curl of its own crashing wave, arms held out, a swirling pool of water at its feet, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 14. Puddlescoop > Basincatch > Lakehaul (Aqueous)

`id: puddlescoop` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark navy-blue

**Form 1, Puddlescoop** (text to image, 8 steps, CFG 1.0, file `puddlescoop-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark navy-blue outlines and vibrant saturated colours. A small round blue-green amphibian with big round yellow eyes and a wide mouth, wearing a small wooden bucket on its head with a little water inside, short stubby legs with webbed feet. Three-quarter view facing left, sitting like a frog, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Basincatch** (edit, reference = `puddlescoop-f1.png`, 8 steps, CFG 1.0, file `puddlescoop-f2.png`)
```
Redraw the same character as the reference image as its second form, a turtle with a basin of water on its back. Keep the same big round eyes and the same blue-green skin, the same dark navy-blue outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a turtle-like creature with a wide wooden basin-shaped shell on its back holding a small pool of blue water drawn inside crisp outlines, sturdy flippers, and the same face and eyes. Three-quarter view facing left, standing on four flipper-legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Lakehaul** (edit, reference = `puddlescoop-f2.png`, 8 steps, CFG 1.0, file `puddlescoop-f3.png`)
```
Redraw the same character as the reference image as its final form, a gentle giant carrying a small pond. Keep the same big round yellow eyes and the same blue-green skin, the same dark navy-blue outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A huge, gentle, slow turtle-like giant whose back carries a small pond with a tiny reed and a lily pad, all drawn inside crisp outlines, thick strong legs and a kind old face with the same eyes. Three-quarter view facing left, standing on four thick legs, big and low, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 15. Frothsprite > Foamspirit > Brinesoul (Aqueous)

`id: frothsprite` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark navy-blue | note: Foam is pale and near-white: check the cut-out edges.

**Form 1, Frothsprite** (text to image, 8 steps, CFG 1.0, file `frothsprite-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark navy-blue outlines and vibrant saturated colours. A small bubbly seafoam spirit, a cloud of round white and pale-aqua bubbles each with its own outline, a small round face with two big round aqua eyes and a giggling open mouth, and two tiny foam hands. Three-quarter view facing left, floating in mid-air, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Foamspirit** (edit, reference = `frothsprite-f1.png`, 8 steps, CFG 1.0, file `frothsprite-f2.png`)
```
Redraw the same character as the reference image as its second form, a taller foam elemental riding tiny waves. Keep the same small round face, the same big aqua eyes and the same white and pale-aqua colouring, the same dark navy-blue outlines and the same art style. Make it noticeably larger and more complex overall. Now bigger, a taller spirit of layered foam rising from a small curling wave, with frilled foam shoulders and the same giggling face. Three-quarter view facing left, floating above a small curling wave, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Brinesoul** (edit, reference = `frothsprite-f2.png`, 8 steps, CFG 1.0, file `frothsprite-f3.png`)
```
Redraw the same character as the reference image as its final form, a serene, airy figure of seafoam. Keep the same small round face and the same big aqua eyes, the same dark navy-blue outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A tall, graceful figure made of layered white and pale-aqua foam with long flowing frills like a gown, a crown of small seashell shapes and a calm smile, drawn with crisp outlines. Three-quarter view facing left, standing tall, floating slightly above a curl of foam, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 16. Splashfin > Wavegill > Tidetail (Aqueous)

`id: splashfin` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark navy-blue | note: Mechanical: a candidate to retest with the base model (see art-pipeline.md).

**Form 1, Splashfin** (text to image, 8 steps, CFG 1.0, file `splashfin-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark navy-blue outlines and vibrant saturated colours. A small round robotic fish with a blue-and-silver metal body held together with small rivets, two big round curious eyes, a wide friendly mouth, a small fan-shaped tail fin and two little side fins. Three-quarter view facing left, swimming pose, floating in mid-air, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Wavegill** (edit, reference = `splashfin-f1.png`, 8 steps, CFG 1.0, file `splashfin-f2.png`)
```
Redraw the same character as the reference image as its second form, a sleek mechanical dolphin. Keep the same big round curious eyes and the same blue and silver metal colouring, the same dark navy-blue outlines and the same art style. Make it noticeably larger and more complex overall. Now a sleek, streamlined dolphin-shaped machine of silver and blue plates, with a long snout, a curved dorsal fin and a strong tail fluke. Three-quarter view facing left, swimming pose, floating in mid-air, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Tidetail** (edit, reference = `splashfin-f2.png`, 8 steps, CFG 1.0, file `splashfin-f3.png`)
```
Redraw the same character as the reference image as its final form, a mechanical whale. Keep the same big round curious eyes, the same dark navy-blue outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A huge, gentle mechanical whale with a hull of overlapping blue and silver plates and rivets, a big tail fluke, a spiral pattern painted on its belly plates and a kind eye. Three-quarter view facing left, swimming pose, floating in mid-air, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 17. Voltfluff > Staticfleece > Arcwool (Voltaic)

`id: voltfluff` | key: **magenta #FF00FF** | ratio: **cute** | outline: dark brown | note: Design says "stays cute": milder ratio ladder, but pushed to an extreme 2026-09-23 after TWO rounds (scale-only wording, then a mid-bounce pose change) both still rendered it visually identical to Form 2. This version states an explicit size comparison (bear-sized) and adds a framing instruction so the model has to compose a bigger subject, not just describe one.

**Form 1, Voltfluff** (text to image, 8 steps, CFG 1.0, file `voltfluff-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark brown outlines and vibrant saturated colours. A small Pomeranian-like ball of fluffy cream and yellow fur in spiky tufts, big round dark eyes, a small black nose, small pointed ears, a curled fluffy tail and a few small yellow zigzag lightning marks painted in the fur. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Staticfleece** (edit, reference = `voltfluff-f1.png`, 8 steps, CFG 1.0, file `voltfluff-f2.png`)
```
Redraw the same character as the reference image as its second form, Staticfleece, a sheepdog with wool puffed out by static. Keep the same round face, the same big dark eyes, the same small black nose, the same cream and yellow fluffy fur, and its yellow zigzag lightning marks, which must stay clearly visible, the same dark brown outlines and the same art style. Change the body proportions: a clearly bigger, sturdier, young-adult body about twice the size of the head, visibly longer and stronger legs and a fuller chest — a real, obvious size increase from the reference, not a subtle one — while keeping the head large and round so it still reads as cute. Now clearly bigger, about twice the size of the reference, its wool grown extremely poofy, puffed out on end like static, plus a big fluffy tail plume and longer legs. Three-quarter view facing left, standing on all four legs, wool puffed out all over, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Arcwool** (edit, reference = `voltfluff-f2.png`, 8 steps, CFG 1.0, file `voltfluff-f3.png`)
```
Redraw the same character as the reference image as its final form, a majestic fluffy canine. Keep the same friendly face, the same big round dark eyes and the same small black nose, the same dark brown outlines and the same art style. Change the body proportions further: a large, mature body about two and a half times the size of the head, a full broad chest and strong legs, clearly and obviously bigger and more grown-up than the second form, while keeping a big friendly head so it stays cute and warm, not fierce. Now truly enormous, not a small dog anymore but a massive fluffy beast the size of a bear, thick powerful legs, a huge broad chest, a mane of cream and yellow wool in huge static-spiked tufts, a plume tail flared wide, with lightning-bolt shapes across its fur. Gentle despite its size. Three-quarter view facing left, mid-bounce, all four huge paws off the ground, framed to nearly fill the frame, looming, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 18. Joulebug > Ohmroach > Wattbeetle (Voltaic)

`id: joulebug` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark brown

**Form 1, Joulebug** (text to image, 8 steps, CFG 1.0, file `joulebug-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark brown outlines and vibrant saturated colours. A tiny round bug with a glossy yellow-and-black striped shell, two long thin antennae, big round friendly eyes, six tiny legs, and a small round bright-yellow bulb at the tip of its tail. Three-quarter view facing left, standing on six legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Ohmroach** (edit, reference = `joulebug-f1.png`, 8 steps, CFG 1.0, file `joulebug-f2.png`)
```
Redraw the same character as the reference image as its second form, a metallic beetle with conductive antennae. Keep the same big round friendly eyes and the same yellow and black colouring, the same dark brown outlines and the same art style. Make it noticeably larger and more complex overall. Now a larger beetle with a silver and copper metallic shell in overlapping plates, long antennae tipped with small metal balls, and sturdy jointed legs. Three-quarter view facing left, standing on six legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Wattbeetle** (edit, reference = `joulebug-f2.png`, 8 steps, CFG 1.0, file `joulebug-f3.png`)
```
Redraw the same character as the reference image as its final form, a friendly scarab shaped like a walking battery. Keep the same big round friendly eyes and the same yellow and black colouring, the same dark brown outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A large, friendly scarab whose rounded shell looks like a battery, with a plus mark, a minus mark and a yellow lightning-bolt symbol on it, copper contact terminals, and sturdy legs. Three-quarter view facing left, standing on six legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 19. Plasmaplug > Ionjack > Surgeport (Voltaic)

`id: plasmaplug` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark brown | note: Mechanical: a candidate to retest with the base model (see art-pipeline.md). Redesigned 2026-09-22: the old Form 3 (hood grows more socket holes) was an incremental decoration change on the same shape, and the tail plug kept vanishing because nothing anchored it. Now the cable closes into a loop with its own tail plug (a real shape change) and the plug is anchored in keep3.

**Form 1, Plasmaplug** (text to image, 8 steps, CFG 1.0, file `plasmaplug-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark brown outlines and vibrant saturated colours. A small snake with one single continuous body, no extra coils or tangled loops, a bright-yellow body marked with dark stripes, a rounded head with big round curious eyes facing forward toward the viewer, and a two-pronged electric plug at the tip of its tail. Three-quarter view facing left, resting in a simple flat spiral with its head raised at the front, facing the viewer, and the plug-tipped tail resting in the coil behind it, only one head and one tail, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Ionjack** (edit, reference = `plasmaplug-f1.png`, 8 steps, CFG 1.0, file `plasmaplug-f2.png`)
```
Redraw the same character as the reference image as its second form, an insulated serpent. Keep the same big round eyes and the same yellow-and-black colouring, the same dark brown outlines and the same art style. Make it noticeably larger and more complex overall. Now a longer, thicker snake wrapped in black rubbery insulation bands between yellow segments, with copper ring collars and a bigger plug tail. Three-quarter view facing left, coiled with its head raised, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Surgeport** (edit, reference = `plasmaplug-f2.png`, 8 steps, CFG 1.0, file `plasmaplug-f3.png`)
```
Redraw the same character as the reference image as its final form, a titanic breaker-hub serpent. Keep the same big round curious eyes and the same yellow-and-black colouring, the same dark brown outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. Completely transformed and dramatically bigger: a huge cobra whose hood has become a wide circular breaker-panel bristling with round socket ports and switches, a thick rubber-insulated cable looping down from the hood to plug directly into the socket at the tip of its own tail, forming a closed loop, its body coiled in several tall stacked loops like a power-transformer tower, calm kind face. Three-quarter view facing left, coiled in several tall stacked loops, hooded head raised high, the cable looping from its hood down to its own tail plug, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 20. Coilchirp > Wirebeak > Gridtrill (Voltaic)

`id: coilchirp` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark brown | note: Wirebeak: named for the wire coil ON THE BEAK, added to the keep list 2026-09-22 after the first Form 2 batch dropped it (nothing anchored it, so the edit model treated it as optional).

**Form 1, Coilchirp** (text to image, 8 steps, CFG 1.0, file `coilchirp-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark brown outlines and vibrant saturated colours. A small round songbird with a body wrapped in coppery wire coils, a yellow chest, big round dark eyes, a small dark beak with a coil of copper wire wound around it like a spring, open mid-chirp, and a coiled wire tail. Three-quarter view facing left, perched on two thin legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Wirebeak** (edit, reference = `coilchirp-f1.png`, 8 steps, CFG 1.0, file `coilchirp-f2.png`)
```
Redraw the same character as the reference image as its second form, a conductive singing bird. Keep the same round face, the same big dark eyes, the same copper-wire and yellow colouring, and the small coil of copper wire wound around its beak, which must stay clearly visible, the same dark brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a larger, longer-bodied bird with a crest of copper wire, a sharper beak with a bigger, clearly visible coil of copper wire wound around it, and longer tail feathers wrapped in wire. Three-quarter view facing left, perched on two thin legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Gridtrill** (edit, reference = `coilchirp-f2.png`, 8 steps, CFG 1.0, file `coilchirp-f3.png`)
```
Redraw the same character as the reference image as its final form, an electric eagle. Keep the same big round dark eyes, the same copper-wire and yellow colouring, and the coil of copper wire wound around its beak, which must stay clearly visible, the same dark brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A large, noble eagle with broad feathers edged in copper wire and tipped in yellow, a strong hooked beak with a thick coil of copper wire wound around its base, a copper wire crest, and powerful talons. Three-quarter view facing left, perched upright with its wings folded, proud, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 21. Eclipsa > Umbrax > Penumbrum (Void)

`id: eclipsa` | key: **green #00FF00** | ratio: **structure** | outline: dark indigo | note: Void: green key, mid-violet body (reads on the dark plate). Keep the rim, rays and rings crisp, not soft. Redesigned 2026-09-22 (again): rings alone around the same crescent read as decoration, not a transformation. Closing the crescent into a full disc with a bursting corona gives Form 3 an actually different silhouette from Form 2, matching a total eclipse rather than a partial one.

**Form 1, Eclipsa** (text to image, 8 steps, CFG 1.0, file `eclipsa-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark indigo outlines and vibrant saturated colours. A silent floating flat round disc in rich mid-violet with lighter lavender highlights, seen at a three-quarter angle, with a thin crisp pale-lavender rim, two calm round pale-lavender eyes on its face and a small gentle mouth. Three-quarter view facing left, floating in mid-air, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Umbrax** (edit, reference = `eclipsa-f1.png`, 8 steps, CFG 1.0, file `eclipsa-f2.png`)
```
Redraw the same character as the reference image as its second form, Umbrax, the deep totality shadow of an eclipse. Keep the same two calm round pale-lavender eyes and the same rich mid-violet with lighter lavender highlights, the same dark indigo outlines and the same art style. Make it noticeably larger and more complex overall. Now clearly larger, roughly twice the size of the reference: a bold crescent-moon shape in rich mid-violet, most of the disc in solid shadow like the dark core of a total eclipse, with a thin, bright, crisp pale-lavender rim of light painted along the curved edge where the shadow ends, and the same calm eyes. Three-quarter view facing left, floating in mid-air, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Penumbrum** (edit, reference = `eclipsa-f2.png`, 8 steps, CFG 1.0, file `eclipsa-f3.png`)
```
Redraw the same character as the reference image as its final form, Penumbrum, the great corona of a total eclipse. Keep the same two calm round pale-lavender eyes and the same gentle face, the same dark indigo outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. Completely transformed and dramatically bigger: the crescent has closed into a full dark circular disc in rich mid-violet, totally eclipsed, surrounded by a ring of long pointed light rays bursting outward on all sides like a total solar eclipse corona, plus a couple of bold pale-lavender rings further out still, all drawn as crisp flat shapes, with the same calm eyes on its face. Three-quarter view facing left, floating in mid-air, the corona rays bursting outward on all sides, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 22. Riftsneak > Nullprowl > Gloamstalk (Void)

**DONE.** Void: green key. Biped to cat: state the four-legged stance every time. Pilot 2026-09-21: Form 1 approved = batch candidate 10 (a violet kitten with cat ears holding a stone ring); runner-up 8. Green key cut out clean, no spill. Form 2 approved = the ring-on-tail batch, candidate 8 (a mid-stride prowling cat with a riveted stone ring worn near the tail tip); the ring becomes a signature detail carried into Form 3. Form 3 approved = candidate 4 of the first Form 3 batch (a realistic-faced starry panther with whiskers, the riveted ring worn near a dark tail tip); chosen by the designer and a friend. Then reworked into the FINAL Form 3 (2026-09-21): ring armour (collar, shoulder ring, a bracelet on each leg, tail ring) with fluffier tufted fur, then a thicker tail ring; final image = riftsneak-f3.png; alternates riftsneak-f3plain.png and riftsneak-f3v21.png. Line complete. Full prompts are in docs/art-pipeline.md.

Prompts as written in the table, for the record (the approved images came from the variants described above; see `docs/art-pipeline.md`):
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark indigo outlines and vibrant saturated colours. A small shy humanoid creature in rich mid-violet with lighter lavender highlights on its head and shoulders, a big round head, big round pale-lavender eyes, hunched shoulders, peeking sideways, holding a small round stone-ring frame in front of it like a shield. Three-quarter view facing left, standing on two feet, hunched and peeking, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
```
Redraw the same character as the reference image as its second form, a sleek cat-like shadow. Keep the same face, the same big pale-lavender eyes, the same pointed cat ears and the same rich mid-violet colouring with lighter lavender highlights, the same dark indigo outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a sleek, long-bodied cat-like prowler with rich mid-violet fur and lighter lavender highlights, a long tail, and tiny pale star dots painted along its flank, still with the same face. Three-quarter view facing left, prowling on all four legs, low and stalking, not upright, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
```
Redraw the same character as the reference image as its final form, an elegant starry void panther. Keep the same face structure, the same big pale-lavender eyes and the same pointed cat ears, the same dark indigo outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A large, elegant, powerful panther with a coat of rich violet with lighter lavender highlights, tiny pale stars dotted along its flank and back, a long graceful tail with the small riveted grey stone ring still worn near the tip, and a calm, confident, noble expression, still friendly. Three-quarter view facing left, prowling on all four legs, tall and elegant, not upright, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 23. Hushflutter > Hushglide > Silentwing (Void)

`id: hushflutter` | key: **green #00FF00** | ratio: **structure** | outline: dark indigo | note: Void: green key, mid-violet body. Strengthened 2026-09-22: earlier batches kept the exact Form 2 manta shape and only added a thin tail.

**Form 1, Hushflutter** (text to image, 8 steps, CFG 1.0, file `hushflutter-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark indigo outlines and vibrant saturated colours. A small round fuzzy moth in rich mid-violet with lighter lavender highlights, with two feathery antennae, big round pale-lavender eyes, small rounded wings marked with pale star spots at the tips, and exactly four tiny dangling legs in two symmetrical pairs, evenly spaced and matching in size. Three-quarter view facing left, hovering in mid-air, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Hushglide** (edit, reference = `hushflutter-f1.png`, 8 steps, CFG 1.0, file `hushflutter-f2.png`)
```
Redraw the same character as the reference image as its second form, a floating manta ray of twilight. Keep the same big pale-lavender eyes and the same soft mid-violet fur with lighter lavender highlights, the same dark indigo outlines and the same art style. Make it noticeably larger and more complex overall. Now a larger, wide manta-ray-shaped body in rich mid-violet fading to lighter lavender at the edges, gliding, with pale star dots along its wings and the same face. Three-quarter view facing left, gliding in mid-air, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Silentwing** (edit, reference = `hushflutter-f2.png`, 8 steps, CFG 1.0, file `hushflutter-f3.png`)
```
Redraw the same character as the reference image as its final form, a four-winged phantom glider. Keep the same face and the same big round pale-lavender eyes, the same dark indigo outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. Completely transformed and dramatically bigger than the second form: a large elegant phantom with a diamond-shaped body about twice the width of the second form, four long tapered wings in two stacked pairs spread wide open (not folded or tucked), each wing clearly longer than the body itself, rich mid-violet fading to lighter lavender at the tips, pale star dots scattered across the wings, and a long slender tail streaming behind. Three-quarter view facing left, gliding with all four wings spread wide open, tail trailing behind, its wingspan clearly wider than the second form, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 24. Netherpod > Chasmshell > Astralcarapace (Void)

`id: netherpod` | key: **green #00FF00** | ratio: **structure** | outline: dark indigo | note: Void: green key, mid-violet body. Form 3 redesigned 2026-09-22: the original "slow void-tortoise" had no connection to Form 2's legless floating nautilus shell, so it hatched into a humanoid being wearing the shell as armour -- but that read as "a man in a shell" and looked wrong. Now it stays a small round compact body peeking out of the shell, not a tall human-proportioned figure.

**Form 1, Netherpod** (text to image, 8 steps, CFG 1.0, file `netherpod-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark indigo outlines and vibrant saturated colours. A small oval chrysalis pod made of rich mid-violet metallic plates with lighter lavender highlights, with two big round pale-lavender eyes on its front, a narrow strip of tiny pale stars painted across the plate below them, and two tiny feet. Three-quarter view facing left, standing upright on two tiny feet, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Chasmshell** (edit, reference = `netherpod-f1.png`, 8 steps, CFG 1.0, file `netherpod-f2.png`)
```
Redraw the same character as the reference image as its second form, a floating nautilus of condensed void. Keep the same big pale-lavender eyes and the same mid-violet metallic plating, the same dark indigo outlines and the same art style. Make it noticeably larger and more complex overall. Now a larger nautilus-shaped body with a spiral shell of mid-violet metal with lighter lavender highlights and pale star dots along the spiral, the same eyes at the front. Three-quarter view facing left, floating in mid-air, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Astralcarapace** (edit, reference = `netherpod-f2.png`, 8 steps, CFG 1.0, file `netherpod-f3.png`)
```
Redraw the same character as the reference image as its final form, a void being peeking out from its shell, wearing it as an astral carapace. Keep the same big round pale-lavender eyes and the same kind face, the same dark indigo outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. Now dramatically bigger: peeking out from the spiral shell, a small round mid-violet void body with the same calm eyes, short stubby arms and legs (rounded, not long or human-proportioned), wearing the broken shell across its back like a grand astral carapace of mid-violet plates with pale star dots, one fragment curving over its head like a hood, and a small swirling nebula in lavender and pale blue cradled in a gap of the shell. Stays round and compact, not a tall humanoid figure. Three-quarter view facing left, crouched low on its stubby legs, the shell carapace worn across its back, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

## Default hybrids (designs proposed by the assistant, need review)

### 25. Ashwood > Emberbark > Hearthtrunk (Verdant/Pyric)

`id: ashwood` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark brown

**Form 1, Ashwood** (text to image, 8 steps, CFG 1.0, file `ashwood-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark brown outlines and vibrant saturated colours. A small round bear cub with ash-grey and cream bark-textured fur, big round warm-brown eyes, small round ears, a tiny leafy green sprig on top of its head, thin orange ember cracks painted between its bark plates, and a short tail ending in a tiny flame-shaped leaf tuft drawn as a crisp flat shape. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Emberbark** (edit, reference = `ashwood-f1.png`, 8 steps, CFG 1.0, file `ashwood-f2.png`)
```
Redraw the same character as the reference image as its second form, a lanky young bark bear. Keep the same face, the same eyes and the same colouring, the same leafy sprig on its head and the same orange cracks, the same dark brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a much taller, leaner young bear with a long body, long legs and a longer snout, charred black bark plates across its shoulders with orange ember cracks between them, and its tail tuft grown into a bigger flame-shaped leaf drawn as a crisp flat shape. Exactly four legs, no extra arms. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, rearing up on its two hind legs, both front paws raised, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Hearthtrunk** (edit, reference = `ashwood-f2.png`, 8 steps, CFG 1.0, file `ashwood-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge tree-trunk bear. Keep the same friendly face, the same big round warm-brown eyes and the same small round ears, the same dark brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A massive bear with a body like a great tree trunk covered in thick charred bark, a round hearth-like hollow in its chest showing a cosy flame drawn as a crisp flat shape, and a crown of small leafy branches along its back with flame-shaped leaf tips. Three-quarter view facing left, standing on all four legs, low, wide and powerful, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 26. Brambletide > Briarripple > Thicketwave (Verdant/Aqueous)

`id: brambletide` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark-green

**Form 1, Brambletide** (text to image, 8 steps, CFG 1.0, file `brambletide-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-green outlines and vibrant saturated colours. A small round otter pup with teal-blue fur, a cream belly, big round dark-teal eyes, tiny round ears, a collar of small thorny green vines and leaves around its neck, and a flat tail with a leaf-shaped tip. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Briarripple** (edit, reference = `brambletide-f1.png`, 8 steps, CFG 1.0, file `brambletide-f2.png`)
```
Redraw the same character as the reference image as its second form, a tall river otter. Keep the same face, the same eyes and the same colouring, the same dark-green outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a long, slim river otter with a long neck and body, webbed paws, armour-like plates of woven thorny vines over its back and shoulders, leaf-shaped fins along its forearms, and a long flat rudder tail. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, standing up tall on its hind legs, alert, its long tail resting on the ground, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Thicketwave** (edit, reference = `brambletide-f2.png`, 8 steps, CFG 1.0, file `brambletide-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge wave-crested otter. Keep the same friendly face, the same big round dark-teal eyes, the same small round ears and the same teal-blue fur and the same collar of thorny vines, the same dark-green outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A big, heavy river otter with a broad chest, a tall crest of vines and broad leaves curling over its back like a breaking wave, woven thorny vine armour on its shoulders, and a thick tail with wave-shaped leaf frills. Three-quarter view facing left, standing on all four legs, low and long, head raised and its tail curling up behind it like a wave, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 27. Sproutfault > Timbershale > Lumbercrag (Verdant/Telluric)

`id: sproutfault` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark-brown

**Form 1, Sproutfault** (text to image, 8 steps, CFG 1.0, file `sproutfault-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-brown outlines and vibrant saturated colours. A small round mountain goat kid with a grey-brown coat, a cream chin tuft, big round golden eyes, two tiny stone horns, a small green sapling sprouting between the horns, and small hooves. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Timbershale** (edit, reference = `sproutfault-f1.png`, 8 steps, CFG 1.0, file `sproutfault-f2.png`)
```
Redraw the same character as the reference image as its second form, a stocky armoured goat. Keep the same face, the same eyes and the same colouring and the same small sprout on its head, the same dark-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a big, stocky goat with a thick neck and broad chest, a heavy coat of layered shale plates like armour, and big curled horns of bark and stone with small leaves. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, rearing up on its hind legs, head lowered to butt, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Lumbercrag** (edit, reference = `sproutfault-f2.png`, 8 steps, CFG 1.0, file `sproutfault-f3.png`)
```
Redraw the same character as the reference image as its final form, a majestic crag-goat. Keep the same friendly face, the same big round golden eyes and the same cream chin tuft, the same dark-brown outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A huge, towering crag-goat with a massive chest, heavy curled stone horns with small trees and moss growing on them, a body armoured in big grey rock plates like a cliff face with moss patches and small ferns, a long shaggy beard, and thick pillar-like legs. Three-quarter view facing left, standing tall on all four legs, chest out and head raised high, huge and heavy, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 28. Mosscoil > Mossfuse > Canopygrid (Verdant/Voltaic)

`id: mosscoil` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark-green

**Form 1, Mosscoil** (text to image, 8 steps, CFG 1.0, file `mosscoil-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-green outlines and vibrant saturated colours. A small round baby sloth with mossy bright-green fur, a cream face patch, big round dark eyes with a sleepy smile, long arms with small claws, and a small copper wire coil wound around one arm with a tiny yellow zigzag mark on it. Three-quarter view facing left, sitting on the ground, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Mossfuse** (edit, reference = `mosscoil-f1.png`, 8 steps, CFG 1.0, file `mosscoil-f2.png`)
```
Redraw the same character as the reference image as its second form, a big wire-woven mossy sloth. Keep the same face, the same eyes and the same colouring, the same dark-green outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a much bigger, taller sloth with very long arms and long curved claws, a shaggy coat of moss, and copper wire coils woven through its fur and around both arms with small yellow zigzag marks. Its face stays clear, with no wire across it. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, standing up tall on its hind legs, both long arms raised overhead, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Canopygrid** (edit, reference = `mosscoil-f2.png`, 8 steps, CFG 1.0, file `mosscoil-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge sloth carrying a canopy. Keep the same sleepy face and the same big round dark eyes, the same dark-green outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A huge, gentle sloth whose back carries a small leafy tree canopy strung with copper wires and small round yellow lamp bulbs, moss-covered fur and thick arms. Three-quarter view facing left, on all four limbs, huge and low, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 29. Mudskulker > Shaleflow > Bedrocktide (Telluric/Aqueous)

`id: mudskulker` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark navy-blue

**Form 1, Mudskulker** (text to image, 8 steps, CFG 1.0, file `mudskulker-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark navy-blue outlines and vibrant saturated colours. A small round mudskipper, a fish with mottled brown-blue skin, big round bulging eyes on top of its head, a wide friendly mouth, two small front fins that work like stubby legs, and a small tail fin. Three-quarter view facing left, propped up on its front fins on the ground, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Shaleflow** (edit, reference = `mudskulker-f1.png`, 8 steps, CFG 1.0, file `mudskulker-f2.png`)
```
Redraw the same character as the reference image as its second form, a walking shale mudskipper. Keep the same big bulging eyes on top of the head and the same brown-blue skin, the same dark navy-blue outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a much longer fish with a big head, long strong front fins shaped like arms, slate-grey shale plates along its back, a tall sail-like dorsal fin, and fully opaque solid-coloured skin with no pale patches. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, propped high on its long front fins, chest raised, tail curling up behind, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Bedrocktide** (edit, reference = `mudskulker-f2.png`, 8 steps, CFG 1.0, file `mudskulker-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge bedrock amphibian. Keep the same big bulging eyes on top of the head, the same wide friendly mouth and the same brown-blue skin, the same dark navy-blue outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. Now a huge, heavy amphibious beast whose front fins have grown into four thick stubby legs, with a broad armoured head, thick slabs of grey bedrock stacked along its back like a ridge of stones, a tall sail-like dorsal fin edged with wave-shaped ripples, and a thick tail fin. Three-quarter view facing left, standing on four thick legs with its body lifted off the ground and its head raised, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 30. Quakeforge > Slagfist > Craterhearth (Telluric/Pyric)

`id: quakeforge` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark red-brown

**Form 1, Quakeforge** (text to image, 8 steps, CFG 1.0, file `quakeforge-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark red-brown outlines and vibrant saturated colours. A small round ape cub with a body of stone-grey rocky skin, orange ember cracks painted on its belly, big round amber eyes, a small flat nose, stubby arms with round fists, and a tiny smile. Three-quarter view facing left, sitting on the ground, leaning on its knuckles, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Slagfist** (edit, reference = `quakeforge-f1.png`, 8 steps, CFG 1.0, file `quakeforge-f2.png`)
```
Redraw the same character as the reference image as its second form, a heavy-fisted slag ape. Keep the same round face, the same big amber eyes and the same stone-grey skin with orange cracks, the same dark red-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now bigger, with huge fists of dark slag rock, heavy shoulder plates and orange ember cracks across its chest and arms. Three-quarter view facing left, standing, leaning on its knuckles, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Craterhearth** (edit, reference = `quakeforge-f2.png`, 8 steps, CFG 1.0, file `quakeforge-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge crater-backed ape. Keep the same friendly face, the same big round amber eyes and the same tiny smile, the same dark red-brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A huge, broad ape with a shallow crater-shaped hollow on its back holding a small campfire flame drawn as a crisp flat shape, thick slag-rock armour, giant fists and a calm strong face. Three-quarter view facing left, standing, leaning on its knuckles, huge and broad, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 31. Geodegrid > Crystalwire > Prismvolt (Telluric/Voltaic)

`id: geodegrid` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark-brown | note: Keep the crystals pale blue and amber, never pink.

**Form 1, Geodegrid** (text to image, 8 steps, CFG 1.0, file `geodegrid-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-brown outlines and vibrant saturated colours. A small round hedgehog with a grey-brown body, a cream face and belly, big round dark eyes, a small dark nose, and a back covered in short pale-blue crystal quills with a thin copper wire wrapped around a few of them. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Crystalwire** (edit, reference = `geodegrid-f1.png`, 8 steps, CFG 1.0, file `geodegrid-f2.png`)
```
Redraw the same character as the reference image as its second form, a crystal-quilled porcupine. Keep the same face, the same eyes and the same colouring, the same dark-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a much bigger porcupine with a long body and strong clawed paws, a crown of long pale-blue crystal quills fanned out wide behind it like a peacock tail, and strands of copper wire linking the quills. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, standing up on its hind legs, quills raised and fanned out wide, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Prismvolt** (edit, reference = `geodegrid-f2.png`, 8 steps, CFG 1.0, file `geodegrid-f3.png`)
```
Redraw the same character as the reference image as its final form, a great prism porcupine. Keep the same friendly face, the same big round dark eyes and the same small dark nose, the same dark-brown outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A large porcupine with a great flared fan of big faceted crystal quills in pale blue and amber, each several times longer than before, radiating out from its back like a crown and joined by copper wires with small yellow zigzag marks between the crystals, a broad chest, and thick strong legs with big claws. Three-quarter view facing left, rearing up on its hind legs with its crystal quills flared wide, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 32. Cinderbasin > Steamrill > Kettlebrine (Pyric/Aqueous)

`id: cinderbasin` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark red-brown

**Form 1, Cinderbasin** (text to image, 8 steps, CFG 1.0, file `cinderbasin-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark red-brown outlines and vibrant saturated colours. A small round hippo calf with soft blue-grey skin, an orange-red belly, big round dark eyes, a wide round snout, tiny round ears, stubby legs, and a small shallow basin-shaped dip on its back holding a tiny puddle of water. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Steamrill** (edit, reference = `cinderbasin-f1.png`, 8 steps, CFG 1.0, file `cinderbasin-f2.png`)
```
Redraw the same character as the reference image as its second form, a big wading hippo. Keep the same face, the same eyes and the same colouring and the same orange snout, the same dark red-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a much bigger, longer, heavier hippo with its huge mouth wide open showing two stubby tusks, thick legs, a wide stone basin on its back holding a small pool with a thin white steam curl drawn as a crisp outlined shape, and orange-red cinder speckles across its blue-grey skin. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, standing on all four thick legs, mouth wide open in a happy yawn, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Kettlebrine** (edit, reference = `cinderbasin-f2.png`, 8 steps, CFG 1.0, file `cinderbasin-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge hippo carrying a kettle. Keep the same sleepy kind face and the same big round dark eyes, the same dark red-brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A huge, gentle hippo carrying a big round copper kettle on its back, with a thin white steam curl from the spout drawn as a crisp outlined shape, orange-red speckles across its blue-grey skin, and a sleepy kind face. Three-quarter view facing left, standing on all four legs, low, wide and powerful, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 33. Embersurge > Blazearc > Infernodynamo (Pyric/Voltaic)

`id: embersurge` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark red-brown

**Form 1, Embersurge** (text to image, 8 steps, CFG 1.0, file `embersurge-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark red-brown outlines and vibrant saturated colours. A small round foal with a warm orange-red coat, a bright-yellow lightning-shaped blaze down its face, big round amber eyes, and a small flame-shaped mane tuft and tail tuft drawn as crisp flat shapes. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Blazearc** (edit, reference = `embersurge-f1.png`, 8 steps, CFG 1.0, file `embersurge-f2.png`)
```
Redraw the same character as the reference image as its second form, a rearing young stallion. Keep the same face, the same eyes and the same colouring and the same yellow blaze, the same dark red-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a tall, lean young stallion with a long neck, long slim legs, a flowing mane and tail of orange flame shapes, and yellow lightning-bolt patterns on its flanks. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, rearing up on its hind legs, front hooves kicking in the air, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Infernodynamo** (edit, reference = `embersurge-f2.png`, 8 steps, CFG 1.0, file `embersurge-f3.png`)
```
Redraw the same character as the reference image as its final form, a massive war-stallion. Keep the same face, the same big round amber eyes, the same bright-yellow lightning-shaped blaze and the same orange-red coat, the same dark red-brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A massive, powerful stallion with a great mane and tail of flame shapes, bold yellow lightning stripes across its body, and dark metal plates on its hooves and shoulders. Three-quarter view facing left, standing on all four legs, tall, wide and powerful, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 34. Brinecore > Rillarc > Tidebolt (Aqueous/Voltaic)

`id: brinecore` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark navy-blue

**Form 1, Brinecore** (text to image, 8 steps, CFG 1.0, file `brinecore-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark navy-blue outlines and vibrant saturated colours. A small round seal pup with a smooth blue-grey pelt, a cream belly, big round dark eyes, tiny whiskers, small flippers, a yellow lightning-shaped stripe along its flank, and a small round copper-and-blue core gem set in its chest. Three-quarter view facing left, resting on its belly with its head raised, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Rillarc** (edit, reference = `brinecore-f1.png`, 8 steps, CFG 1.0, file `brinecore-f2.png`)
```
Redraw the same character as the reference image as its second form, a big sea lion. Keep the same face, the same eyes and the same colouring and the same chest gem, the same dark navy-blue outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a big sea lion with a long thick neck, a broad chest, a longer body, big strong front flippers, curved yellow lightning stripes across its blue-grey coat, and a larger gem in its chest. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, sitting upright on its front flippers, chest high, head raised proudly, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Tidebolt** (edit, reference = `brinecore-f2.png`, 8 steps, CFG 1.0, file `brinecore-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge bull sea lion. Keep the same friendly face, the same big round dark eyes, the same tiny whiskers and the same blue-grey coat, the same dark navy-blue outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A huge, powerful bull sea lion with a thick neck mane, bold yellow lightning stripes and a large copper-and-blue core gem set in its chest. Three-quarter view facing left, resting on its front flippers with its head high, huge and broad, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 35. Eclipseed > Starsap > Nightbloom (Void/Verdant)

`id: eclipseed` | key: **green #00FF00** | ratio: **animal** | outline: dark indigo | note: Void: green key, mid-violet body. No green foliage, or it will fight the green key: leaves are deep violet.

**Form 1, Eclipseed** (text to image, 8 steps, CFG 1.0, file `eclipseed-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark indigo outlines and vibrant saturated colours. A small round owlet with rich mid-violet with lighter lavender highlights feathers, big round pale-lavender eyes, a small pale beak, tiny talons, and a small sprout on top of its head with one pale-gold bud on it, the sprout leaves deep violet. Three-quarter view facing left, perched on two legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Starsap** (edit, reference = `eclipseed-f1.png`, 8 steps, CFG 1.0, file `eclipseed-f2.png`)
```
Redraw the same character as the reference image as its second form, a tall star owl. Keep the same big pale-lavender eyes and the same mid-violet feathers with lighter lavender highlights, the same dark indigo outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a much taller, slimmer owl with long legs, long wings spread wide open showing tiny pale star dots across the feathers, a tall crest of branch-like feathers carrying small pale-gold buds, and long tail feathers. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, standing tall with both wings spread wide open, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Nightbloom** (edit, reference = `eclipseed-f2.png`, 8 steps, CFG 1.0, file `eclipseed-f3.png`)
```
Redraw the same character as the reference image as its final form, a night-blooming owl. Keep the same big round pale-lavender eyes and the same small pale beak, the same dark indigo outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A large, majestic owl whose head crest is a big night-blooming flower with layered pale-gold and white petals and deep-violet leaves, tiny pale star dots across its wings, and strong talons. Three-quarter view facing left, perched upright with its wings folded, proud, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 36. Nullshale > Riftrock > Abysscrag (Void/Telluric)

`id: nullshale` | key: **green #00FF00** | ratio: **animal** | outline: dark indigo | note: Void: green key, mid-violet body.

**Form 1, Nullshale** (text to image, 8 steps, CFG 1.0, file `nullshale-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark indigo outlines and vibrant saturated colours. A small round pangolin with rich mid-violet with lighter lavender highlights skin covered in overlapping slate-grey shale scales, big round pale-lavender eyes, a small pointed snout, small claws and a short thick tail. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Riftrock** (edit, reference = `nullshale-f1.png`, 8 steps, CFG 1.0, file `nullshale-f2.png`)
```
Redraw the same character as the reference image as its second form, a rearing stone pangolin. Keep the same big pale-lavender eyes and the same mid-violet and slate-grey colouring, the same dark indigo outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a much longer pangolin with big overlapping slate-grey and mid-violet stone plates with thin pale-lavender crack lines between them, long curved front claws, and a long thick tail. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, standing up on its hind legs, balanced on its thick tail, front claws curled, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Abysscrag** (edit, reference = `nullshale-f2.png`, 8 steps, CFG 1.0, file `nullshale-f3.png`)
```
Redraw the same character as the reference image as its final form, a towering crag pangolin. Keep the same big round pale-lavender eyes and the same small pointed snout, the same dark indigo outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A huge, towering pangolin whose back and tail are covered in big jagged crag-like rock plates in slate-grey and mid-violet that rise into spikes along its spine, pale-lavender crack lines painted between them, long heavy digging claws on its front arms, and a long heavy tail. Three-quarter view facing left, standing upright on its thick hind legs, its heavy tail resting on the ground behind it, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 37. Gloamforge > Muteember > Hushkiln (Void/Pyric)

`id: gloamforge` | key: **green #00FF00** | ratio: **animal** | outline: dark indigo | note: Void: green key, mid-violet body (not black: black vanishes on the dark plate).

**Form 1, Gloamforge** (text to image, 8 steps, CFG 1.0, file `gloamforge-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark indigo outlines and vibrant saturated colours. A small round bull calf with glossy obsidian-like skin in rich mid-violet with lighter lavender highlights, thin dull orange ember cracks painted on its shoulders, big round pale-lavender eyes, small blunt horns and small hooves. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Muteember** (edit, reference = `gloamforge-f1.png`, 8 steps, CFG 1.0, file `gloamforge-f2.png`)
```
Redraw the same character as the reference image as its second form, a charging young bull. Keep the same big pale-lavender eyes and the same mid-violet obsidian colouring with dull orange cracks, the same dark indigo outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a longer, heavier bull with a big muscular shoulder hump, violet-grey iron plates over its shoulders, long curved horns pointing forward, and dull orange ember cracks across its body. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, charging forward, head lowered, horns forward, one front hoof raised, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Hushkiln** (edit, reference = `gloamforge-f2.png`, 8 steps, CFG 1.0, file `gloamforge-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge furnace-backed bull. Keep the same face, the same big round pale-lavender eyes and the same mid-violet obsidian skin, the same dark indigo outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A huge bull with a dome-shaped furnace on its back with a small dim orange flame visible through a violet-grey iron grate, massive curved horns, and thick violet-grey iron plates over its mid-violet body. Three-quarter view facing left, standing on all four legs, low, wide and powerful, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 38. Hushflow > Nullstream > Riftcurrent (Void/Aqueous)

`id: hushflow` | key: **green #00FF00** | ratio: **structure** | outline: dark indigo | note: Void: green key, mid-violet body.

**Form 1, Hushflow** (text to image, 8 steps, CFG 1.0, file `hushflow-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark indigo outlines and vibrant saturated colours. A small round octopus with a smooth body in rich mid-violet with lighter lavender highlights, marked with pale-blue stripes, big round pale-lavender eyes, a tiny smile and eight short stubby tentacles. Three-quarter view facing left, sitting on the ground, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Nullstream** (edit, reference = `hushflow-f1.png`, 8 steps, CFG 1.0, file `hushflow-f2.png`)
```
Redraw the same character as the reference image as its second form, a tall dancing octopus. Keep the same big pale-lavender eyes and the same mid-violet colouring with pale-blue stripes, the same dark indigo outlines and the same art style. Make it noticeably larger and more complex overall. Now a much bigger octopus with a tall oval head and eight very long tentacles with pale-blue stripes, two of them raised high and curling. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, rising up tall on the tips of its tentacles, two tentacles raised high, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Riftcurrent** (edit, reference = `hushflow-f2.png`, 8 steps, CFG 1.0, file `hushflow-f3.png`)
```
Redraw the same character as the reference image as its final form, a giant rift-current octopus. Keep the same big round pale-lavender eyes and the same calm smile, the same dark indigo outlines and the same art style. A real final evolution: about three times the size of the second form, grander, more intricate and clearly the most impressive form; correct anatomy, no extra limbs. A giant octopus about three times the size of the second form, with a huge tall domed head rising high above its eyes, a crisp flat violet swirl-shaped rift mark on its forehead, and eight very long, thick tentacles streaming down and out beneath it like a flowing river current, with pale-blue stripes and small pale star dots along them. Three-quarter view facing left, rising upright in mid-air, its tall head up and its tentacles streaming down and out beneath it, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 39. Gridrift > Corewire > Lodestar (Void/Voltaic)

`id: gridrift` | key: **green #00FF00** | ratio: **structure** | outline: dark indigo | note: Void: green key, mid-violet body. The endgame Aether-infrastructure creature.

**Form 1, Gridrift** (text to image, 8 steps, CFG 1.0, file `gridrift-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark indigo outlines and vibrant saturated colours. A small floating cube of rich mid-violet with lighter lavender highlights metal with copper wire running along its edges, two big round pale-lavender eyes on its front face, a small yellow lightning mark, and no legs. Three-quarter view facing left, floating in mid-air, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Corewire** (edit, reference = `gridrift-f1.png`, 8 steps, CFG 1.0, file `gridrift-f2.png`)
```
Redraw the same character as the reference image as its second form, a larger lattice creature. Keep the same big pale-lavender eyes and the same mid-violet metal with copper wire, the same dark indigo outlines and the same art style. Make it noticeably larger and more complex overall. Now a larger open lattice of copper wire forming a cage around a mid-violet core cube with the same eyes, with two smaller cubes attached at its corners. Three-quarter view facing left, floating in mid-air, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Lodestar** (edit, reference = `gridrift-f2.png`, 8 steps, CFG 1.0, file `gridrift-f3.png`)
```
Redraw the same character as the reference image as its final form, the great lattice star. Keep the same two big round pale-lavender eyes on the same violet core cube, the same dark indigo outlines and the same art style. A real final evolution: about three times the size of the second form, grander, more intricate and clearly the most impressive form; correct anatomy, no extra limbs. A large floating lattice star: the violet core cube with the same eyes at its centre, surrounded by three big copper wire rings crossing each other like an armillary sphere, eight small violet cubes set at the ring tips, and a yellow four-pointed star piece on top. Three-quarter view facing left, floating in mid-air, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

## Special recipes, Chunk 2 (names provisional)

### 40. Gravelnip > Reefpincer > Boulderclaw (Telluric/Aqueous)

`id: gravelnip` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark-brown

**Form 1, Gravelnip** (two-reference edit, reference 1 = `pebblescoot-f1.png`, reference 2 = `puddlescoop-f1.png`, 8 steps, CFG 1.0, file `gravelnip-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark-brown outlines. It is not either parent: it is a small round crab with a slate-grey shell veined in teal, big round eyes on short stalks, one oversized claw, one small claw and six stubby legs. From the first creature it takes shell plates shaped like a beetle's grey shale carapace and two thin antennae. From the second creature it takes a small wooden bucket full of water sitting on top of its shell like a hat. Three-quarter view facing left, standing on its legs, claws forward, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Reefpincer** (edit, reference = `gravelnip-f1.png`, 8 steps, CFG 1.0, file `gravelnip-f2.png`)
```
Redraw the same character as the reference image as its second form, a tall reef-pincer crab. Keep the same face, the same eyes and the same colouring, the same shale shell plates and the same wooden bucket, the same dark-brown outlines and the same art style. Make it noticeably larger and more complex overall. Now a much bigger crab with a wide layered slate shell veined in teal, one huge ridged claw, long jointed legs lifting it high off the ground, and the wooden bucket on its shell grown bigger. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, standing tall on long legs, the big claw raised high over its head, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Boulderclaw** (edit, reference = `gravelnip-f2.png`, 8 steps, CFG 1.0, file `gravelnip-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge boulder-clawed crab. Keep the same face, the same eyes and the same colouring, the same eyes on short stalks and the wooden bucket on its shell, the same dark-brown outlines and the same art style. A real final evolution: about three times the size of the second form, grander, more intricate and clearly the most impressive form; correct anatomy, no extra limbs. A huge, towering crab raised high on six long armoured legs, with exactly two claws: one enormous boulder claw of grey rock bigger than its body, and one small claw held up in front of its face, both clearly visible; a craggy shale shell veined in teal like a small cliff, and the wooden bucket on its shell grown into a big wooden tub holding a tide pool with a tiny reed. Three-quarter view facing left, raised high on its legs, its boulder claw lifted over its head, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 41. Ripplesnap > Slatesnout > Ridgehide (Telluric/Aqueous)

`id: ripplesnap` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark olive-green

**Form 1, Ripplesnap** (two-reference edit, reference 1 = `quakemaw-f1.png`, reference 2 = `splashfin-f1.png`, 8 steps, CFG 1.0, file `ripplesnap-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark olive-green outlines. It is not either parent: it is a baby crocodile, not a lizard: a long flat body low to the ground, a long flat snout, short sprawled legs, a long thick tail and mottled grey-green skin with a ridged back. From the first creature it takes only a bright orange scarf around its neck. From the second creature it takes blue-and-silver riveted metal plates on its back and a metal fin at its tail tip. Three-quarter view facing left, lying low on its belly, legs sprawled, long tail stretched out behind, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Slatesnout** (edit, reference = `ripplesnap-f1.png`, 8 steps, CFG 1.0, file `ripplesnap-f2.png`)
```
Redraw the same character as the reference image as its second form, a slate-snouted crocodile. Keep the same face, the same eyes and the same colouring, the same orange scarf and the same blue riveted metal plates, the same dark olive-green outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now twice as long, with a broad slate-grey snout and its mouth open showing blunt teeth, straight strong legs, a ridged back where the blue riveted plates have grown into a line of armour, and a long tail with a metal fin at the tip. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, walking with its body raised high off the ground on straight legs, head up, mouth open, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Ridgehide** (edit, reference = `ripplesnap-f2.png`, 8 steps, CFG 1.0, file `ripplesnap-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge ridge-hided crocodile. Keep the same face, the same eyes, the same grey-green colouring, the same orange scarf and the same blue riveted metal plates, the same dark olive-green outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A huge crocodile about twice the size of the second form, with heavy ridged stone-like hide, the orange scarf around its neck, a row of big blue riveted steel plates down its back, a wide snout with a few pale quartz teeth, and a long powerful tail. Three-quarter view facing left, standing on all four legs with its body raised off the ground, jaws open in a wide grin, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 42. Cairnflit > Pumiceglide > Fluxwing (Telluric/Voltaic)

`id: cairnflit` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark-brown

**Form 1, Cairnflit** (two-reference edit, reference 1 = `coilchirp-f1.png`, reference 2 = `geodecore-f1.png`, 8 steps, CFG 1.0, file `cairnflit-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark-brown outlines. It is not either parent: it is a small round bat with dusky brown fur, big round ears, big round eyes and small folded wings. From the first creature it takes loops of copper wire around its body, copper-edged wings and a springy coiled tail. From the second creature it takes a small pale-blue crystal set in its chest like a chime, and pebbly grey stone patches on its shoulders. Three-quarter view facing left, hovering in mid-air with its wings half open, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Pumiceglide** (edit, reference = `cairnflit-f1.png`, 8 steps, CFG 1.0, file `cairnflit-f2.png`)
```
Redraw the same character as the reference image as its second form, a big pumice-winged bat. Keep the same face, the same eyes and the same colouring, the same copper wire and coiled tail and the same chest crystal, the same dark-brown outlines and the same art style. Make it noticeably larger and more complex overall. Now a bigger bat with a longer body and a wingspan twice as wide, wing membranes edged with copper thread and patched with grey pumice stone, a longer coiled copper tail, and a larger quartz crystal at its chest. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, flying with both wings spread wide open, its wingspan much wider than its body, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Fluxwing** (edit, reference = `cairnflit-f2.png`, 8 steps, CFG 1.0, file `cairnflit-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge flux-winged bat. Keep the same face, the same eyes and the same colouring, the same big round ears, the quartz chime pendant and the coiled tail, the same dark-brown outlines and the same art style. A real final evolution: about three times the size of the second form, grander, more intricate and clearly the most impressive form; correct anatomy, no extra limbs. A large bat with huge wings whose membranes are set with grey pumice stones and edged in copper thread with yellow zigzag lines, a thick fur mane with a big quartz chime at its throat, a long coiled copper tail, and strong clawed feet. Three-quarter view facing left, swooping forward with both huge wings spread fully open, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 43. Flintlamb > Ampcurl > Mesahorn (Telluric/Voltaic)

`id: flintlamb` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark-brown

**Form 1, Flintlamb** (two-reference edit, reference 1 = `tuskcub-f1.png`, reference 2 = `voltfluff-f1.png`, 8 steps, CFG 1.0, file `flintlamb-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark-brown outlines. It is not either parent: it is a small round lamb with big round eyes, short sturdy legs and two short spiral horns of banded grey stone. From the first creature it takes a little boar snout, two small pale-blue crystal tusks and a curly tail. From the second creature it takes a huge fluffy cream fleece ruff with small yellow zigzag bolt marks. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Ampcurl** (edit, reference = `flintlamb-f1.png`, 8 steps, CFG 1.0, file `flintlamb-f2.png`)
```
Redraw the same character as the reference image as its second form, a leaping mountain ram. Keep the same face, the same eyes and the same colouring, the same crystal tusks and curly tail and the same cream fleece with bolt marks, the same dark-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a tall, lean ram with long slender legs, a long neck, huge curling spiral horns of banded stone, small crystal tusks, a thick cream fleece on its chest and shoulders with yellow zigzag marks, and a curly tail. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, leaping forward, front legs tucked, back legs pushing off, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Mesahorn** (edit, reference = `flintlamb-f2.png`, 8 steps, CFG 1.0, file `flintlamb-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge mesa-horned ram. Keep the same face, the same eyes and the same colouring, the same dark-brown outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A huge ram with massive horns of layered banded red-and-cream rock, curled a full turn and a half and heavy like mesa cliffs, a thick woolly cream fleece mane around its neck and chest with yellow zigzag marks crackling at the tips, a broad powerful chest, and thick legs with big dark hooves. Three-quarter view facing left, standing square on all four legs with its head lowered, ready to charge, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 44. Coralpeep > Flarewade > Pyreplume (Pyric/Aqueous)

`id: coralpeep` | key: **green #00FF00** | ratio: **animal** | outline: dark red-brown | note: Pink creature: GREEN key (magenta would eat the feathers). Cut out with --bg #00FF00 and without --halo-strict.

**Form 1, Coralpeep** (two-reference edit, reference 1 = `charwhisk-f1.png`, reference 2 = `frothsprite-f1.png`, 8 steps, CFG 1.0, file `coralpeep-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark red-brown outlines. It is not either parent: it is a small round flamingo chick with fluffy rosy-pink feathers shading to orange at the tips, a short bent orange beak and thin legs. From the first creature it takes a small red feather crest on its head and a tail shaped like a little metal kitchen whisk. From the second creature it takes a fluffy collar of white seafoam bubbles around its neck. Three-quarter view facing left, standing on two thin legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Flarewade** (edit, reference = `coralpeep-f1.png`, 8 steps, CFG 1.0, file `coralpeep-f2.png`)
```
Redraw the same character as the reference image as its second form, a wading flamingo. Keep the same face, the same eyes, the same colouring, the same red crest and whisk tail and the same seafoam bubble collar, the same dark red-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now taller, with a long neck, long thin legs, orange-tipped rosy feathers and a bigger ruffle of plumes. Three-quarter view facing left, standing on two long thin legs, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Pyreplume** (edit, reference = `coralpeep-f2.png`, 8 steps, CFG 1.0, file `coralpeep-f3.png`)
```
Redraw the same character as the reference image as its final form, a majestic flamingo. Keep the same face, the same eyes and the same colouring, the same dark red-brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A tall, majestic flamingo with a great fan of plumes in orange and red drawn as crisp flat feather shapes, a long graceful neck and long thin legs. Three-quarter view facing left, standing on two long thin legs, tall and proud, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 45. Drizzlenub > Brooksoak > Lavabask (Pyric/Aqueous)

`id: drizzlenub` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark red-brown

**Form 1, Drizzlenub** (two-reference edit, reference 1 = `dewdrop-f1.png`, reference 2 = `roastbelly-f1.png`, 8 steps, CFG 1.0, file `drizzlenub-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark red-brown outlines. It is not either parent: it is a small round baby capybara with a blunt square snout, small round ears and short legs. From the first creature it takes a glossy sky-blue coat with white shine highlights, as if its fur were made of water. From the second creature it takes sleepy half-closed content eyes and a warm orange-cream belly. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Brooksoak** (edit, reference = `drizzlenub-f1.png`, 8 steps, CFG 1.0, file `drizzlenub-f2.png`)
```
Redraw the same character as the reference image as its second form, a big lounging capybara. Keep the same face, the same eyes and the same colouring, the same glossy sky-blue water coat and the same sleepy eyes, the same dark red-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a much bigger, longer-bodied capybara with a glossy water-blue coat beaded with small droplets, a big round warm orange belly, a small leaf resting on its head, and long back feet. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, sitting up on its haunches like a person, belly out, front paws resting on its belly, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Lavabask** (edit, reference = `drizzlenub-f2.png`, 8 steps, CFG 1.0, file `drizzlenub-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge basking lava capybara. Keep the same face, the same eyes and the same colouring and the same light-blue skin, the same dark red-brown outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A huge, round light-blue capybara with a broad back covered in dark lava-rock plates with orange cracks drawn as crisp flat shapes, like a warm stone, a big orange-red patch on its belly, a tiny white steam curl above its head drawn as a crisp outlined shape, and a sleepy, blissful face. Three-quarter view facing left, lying stretched out on its belly, basking, its chin resting on its front paws, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 46. Coalgrub > Arcflicker > Blazefly (Pyric/Voltaic)

`id: coalgrub` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark brown

**Form 1, Coalgrub** (two-reference edit, reference 1 = `emberfang-f1.png`, reference 2 = `joulebug-f1.png`, 8 steps, CFG 1.0, file `coalgrub-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark brown outlines. It is not either parent: it is a small round firefly with a dark glossy shell, big round eyes, six tiny legs, small folded wings and a round amber lamp-shaped patch on its belly. From the first creature it takes an orange flame-shaped crest on its head drawn as crisp flat shapes. From the second creature it takes yellow-and-black stripes on its shell and two long thin antennae. Three-quarter view facing left, hovering in mid-air, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Arcflicker** (edit, reference = `coalgrub-f1.png`, 8 steps, CFG 1.0, file `coalgrub-f2.png`)
```
Redraw the same character as the reference image as its second form, an arc-winged firefly. Keep the same face, the same eyes, the same colouring, the same flame crest and the same yellow-and-black stripes, the same dark brown outlines and the same art style. Make it noticeably larger and more complex overall. Now bigger, with larger wings patterned with yellow zigzag lines, a bigger amber-orange lamp patch on its belly, and the same face. Three-quarter view facing left, hovering in mid-air, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Blazefly** (edit, reference = `coalgrub-f2.png`, 8 steps, CFG 1.0, file `coalgrub-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge blaze-winged firefly. Keep the same face, the same eyes and the same colouring, the same dark brown outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A large firefly with wide wings patterned in orange and yellow flame shapes drawn as crisp flat shapes, a big amber-orange lamp patch on its belly, and the same friendly face. Three-quarter view facing left, hovering in mid-air, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 47. Boltkit > Brandtail > Scorchfox (Pyric/Voltaic)

`id: boltkit` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark red-brown

**Form 1, Boltkit** (two-reference edit, reference 1 = `cinderpup-f1.png`, reference 2 = `voltfluff-f1.png`, 8 steps, CFG 1.0, file `boltkit-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark red-brown outlines. It is not either parent: it is a small round fox kit with russet fur, big round dark eyes and large pointed ears. From the first creature it takes black-and-tan markings on its face and legs and a bushy tail whose tip is an orange flame drawn as a crisp flat shape. From the second creature it takes a huge fluffy cream ruff around its neck and chest and a few small yellow zigzag bolt marks on its fur. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Brandtail** (edit, reference = `boltkit-f1.png`, 8 steps, CFG 1.0, file `boltkit-f2.png`)
```
Redraw the same character as the reference image as its second form, a young fox. Keep the same face, the same eyes, the same colouring, the same black-and-tan markings and flame-tipped tail and the same fluffy cream ruff and bolt marks, the same dark red-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a sleeker young fox with longer legs, a bushy tail with a flame-shaped orange tip and yellow zigzag marks, and a bigger ruff. Three-quarter view facing left, standing on all four legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Scorchfox** (edit, reference = `boltkit-f2.png`, 8 steps, CFG 1.0, file `boltkit-f3.png`)
```
Redraw the same character as the reference image as its final form, Scorchfox, a great full-grown fire fox. Keep the same face, the same eyes and the same colouring, the same dark red-brown outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A large, lean, full-grown fox with long powerful legs, a long muzzle, tall pointed ears, a thick cream ruff, yellow lightning-bolt markings on its flanks and legs, and a huge tail split into three flowing flame-shaped tails in orange and red, drawn as crisp flat shapes. Three-quarter view facing left, striding forward with one front paw raised, head held high, its three tails raised behind it, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 48. Eddyelver > Kelpeel > Dynamoeel (Aqueous/Voltaic)

`id: eddyelver` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark navy-blue

**Form 1, Eddyelver** (two-reference edit, reference 1 = `dewdrop-f1.png`, reference 2 = `plasmaplug-f1.png`, 8 steps, CFG 1.0, file `eddyelver-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark navy-blue outlines. It is not either parent: it is a long slim eel with one smooth silver body, a rust-orange underside, big round eyes and a small round face. From the first creature it takes a glossy sky-blue sheen with white shine highlights, as if its body were made of water. From the second creature it takes dark bands along its body and a tail that ends in a small two-pronged electric plug. Three-quarter view facing left, stretched out in one long open wave, head raised, the body never looping or crossing itself, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Kelpeel** (edit, reference = `eddyelver-f1.png`, 8 steps, CFG 1.0, file `eddyelver-f2.png`)
```
Redraw the same character as the reference image as its second form, a kelp-maned sea serpent. Keep the same face, the same eyes and the same colouring, the same glossy water sheen and the same plug-tipped tail, the same dark navy-blue outlines and the same art style. Make it noticeably larger and more complex overall. Now a sea serpent twice as long and much thicker, with a flowing mane of kelp-leaf frills down its neck and back, two small finned front legs, a glossy silver-blue body with dark bands, a rust-orange underside and a big two-pronged plug at its tail tip. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, stretched out in one long open wave, head raised, the body never looping or crossing itself, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Dynamoeel** (edit, reference = `eddyelver-f2.png`, 8 steps, CFG 1.0, file `eddyelver-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge electric eel. Keep the same face, the same eyes and the same colouring and the same spiky mane of kelp leaves, the same dark navy-blue outlines and the same art style. A real final evolution: about three times the size of the second form, grander, more intricate and clearly the most impressive form; correct anatomy, no extra limbs. A huge, long eel as thick as a tree trunk, with a big spiky mane of dark kelp leaves around its head, a glossy silver-blue body with dark bands and bright yellow lightning marks between them, a rust-orange underside, a tall kelp-leaf fin down its back, and a large two-pronged plug at its tail tip. Three-quarter view facing left, rising up tall in one big open S-curve, head raised high, the body never crossing itself, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 49. Sprayfledge > Pulsedart > Voltfisher (Aqueous/Voltaic)

`id: sprayfledge` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark navy-blue

**Form 1, Sprayfledge** (two-reference edit, reference 1 = `coilchirp-f1.png`, reference 2 = `splashfin-f1.png`, 8 steps, CFG 1.0, file `sprayfledge-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark navy-blue outlines. It is not either parent: it is a small round kingfisher chick with a cobalt-blue back, an amber chest, big round eyes and a long dark beak. From the first creature it takes loops of copper wire wrapped around its body and a springy coiled tail. From the second creature it takes small riveted metal plates on its wings and tail, like a robot fish's fins. Three-quarter view facing left, perched on two thin legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Pulsedart** (edit, reference = `sprayfledge-f1.png`, 8 steps, CFG 1.0, file `sprayfledge-f2.png`)
```
Redraw the same character as the reference image as its second form, a diving kingfisher. Keep the same face, the same eyes and the same colouring, the same copper wire loops and coiled tail and the same riveted metal wing plates, the same dark navy-blue outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a bigger, sleeker kingfisher with a long dark beak, long wings with riveted metal plates and copper pinstripes, and a longer coiled copper tail. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, flying with both wings spread wide open, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Voltfisher** (edit, reference = `sprayfledge-f2.png`, 8 steps, CFG 1.0, file `sprayfledge-f3.png`)
```
Redraw the same character as the reference image as its final form, a great armoured storm kingfisher. Keep the same face, the same eyes, the same cobalt and amber colouring, the riveted metal feather plates on its wings and the long coiled copper-wire tail, the same dark navy-blue outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A large, powerful kingfisher with a long lance-like dark beak, big wide wings covered in riveted steel-blue metal feather plates with copper pinstripes and small yellow zigzag marks, a broad amber chest, and a long coiled copper-wire tail ending in a spiral. Three-quarter view facing left, diving forward with both wings spread wide and raised, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 50. Sorrelcliff > Fernscarp > Highhorn (Verdant/Telluric)

`id: sorrelcliff` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark brown

**Form 1, Sorrelcliff** (two-reference edit, reference 1 = `sproutlet-f1.png`, reference 2 = `tuskcub-f1.png`, 8 steps, CFG 1.0, file `sorrelcliff-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark brown outlines. It is not either parent: it is a small round baby mountain goat with a fluffy warm brown coat, big round eyes and short legs with dark hooves. From the first creature it takes a small green sapling sprout with two leaves on top of its head and a collar of green leaves around its neck. From the second creature it takes two short horns of pale-blue crystal shaped like little tusks, and a curly tail. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Fernscarp** (edit, reference = `sorrelcliff-f1.png`, 8 steps, CFG 1.0, file `sorrelcliff-f2.png`)
```
Redraw the same character as the reference image as its second form, a tall mountain goat. Keep the same face, the same eyes and the same colouring, the same sapling sprout and leaf collar and the same pale-blue crystal horns and curly tail, the same dark brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a tall, lean mountain goat with long legs and a long neck, long curving pale-blue crystal horns fringed with small fern fronds, and a shaggier sorrel-brown coat. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, leaping upward, front legs tucked, back legs pushing off, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Highhorn** (edit, reference = `sorrelcliff-f2.png`, 8 steps, CFG 1.0, file `sorrelcliff-f3.png`)
```
Redraw the same character as the reference image as its final form, a proud high-horned mountain goat. Keep the same friendly face, the same big round amber eyes, the same sorrel-brown coat and the same collar of green leaves, the same dark brown outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A large, proud mountain goat with enormous sweeping horns curving back over its body, banded with grey stone rings and tipped with fern fronds, a collar of green leaves around its neck, a small fern tuft on its head, a thick shaggy sorrel-brown coat with a long cream beard, and a broad strong chest. Three-quarter view facing left, rearing up on its hind legs with its front hooves raised and its head held high, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 51. Hazelslate > Mossflint > Grovepeak (Verdant/Telluric)

`id: hazelslate` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark brown

**Form 1, Hazelslate** (two-reference edit, reference 1 = `mossgear-f1.png`, reference 2 = `pebblescoot-f1.png`, 8 steps, CFG 1.0, file `hazelslate-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark brown outlines. It is not either parent: it is a small round baby tortoise with olive skin, big round eyes and a domed shell of layered flat grey slate plates. From the first creature it takes soft bright moss growing over its shell and a small brass gear set in its forehead. From the second creature it takes two short thin antennae on its head, and shell plates shaped like a beetle's shale carapace. Three-quarter view facing left, standing on all four stubby legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Mossflint** (edit, reference = `hazelslate-f1.png`, 8 steps, CFG 1.0, file `hazelslate-f2.png`)
```
Redraw the same character as the reference image as its second form, a long-necked flint tortoise. Keep the same face, the same eyes and the same colouring, the same moss and brass forehead gear and the same short antennae, the same dark brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a much bigger tortoise with a long neck, long sturdy legs lifting it high, and a tall domed shell of chipped grey flint plates with thick moss and a few small ferns growing on top. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, walking forward, neck stretched out, one front foot lifted, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Grovepeak** (edit, reference = `hazelslate-f2.png`, 8 steps, CFG 1.0, file `hazelslate-f3.png`)
```
Redraw the same character as the reference image as its final form, an ancient mountain tortoise. Keep the same face, the same eyes and the same colouring, the same dark brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A huge ancient tortoise whose broad slate shell rises into a small rocky peak with a tiny grove of three little trees on top, moss and small ferns along the shell's rim, thick pillar-like legs and a wise calm face. Three-quarter view facing left, standing on all four thick legs, slow and steady, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 52. Brackensear > Thornkiln > Scaldhearth (Verdant/Pyric)

`id: brackensear` | key: **magenta #FF00FF** | ratio: **cute** | outline: dark red-brown

**Form 1, Brackensear** (two-reference edit, reference 1 = `brambletrundle-f1.png`, reference 2 = `cinderpup-f1.png`, 8 steps, CFG 1.0, file `brackensear-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark red-brown outlines. It is not either parent: it is a tiny round hedgehog with a cream face, big round eyes and spines of dry curling russet bracken fronds. From the first creature it takes a few thorny green vines wound around its spines with small yellow zigzag bolt marks on them. From the second creature it takes black-and-tan markings on its face and legs, and a short tail with an orange flame tip drawn as a crisp flat shape. Three-quarter view facing left, sitting curled up on the ground, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Thornkiln** (edit, reference = `brackensear-f1.png`, 8 steps, CFG 1.0, file `brackensear-f2.png`)
```
Redraw the same character as the reference image as its second form, a long-legged ember hedgehog. Keep the same face, the same eyes and the same colouring, the same thorny vines and the same flame-tipped tail, the same dark red-brown outlines and the same art style. Change the body proportions: a clearly bigger, sturdier, young-adult body about twice the size of the head, visibly longer and stronger legs and a fuller chest — a real, obvious size increase from the reference, not a subtle one — while keeping the head large and round so it still reads as cute. Now a much longer body high on four long slim legs, a pointed snout, a mane of bracken-frond spines tipped with small orange ember points drawn as crisp flat shapes, and vines wound around its legs. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, walking on four long legs, body held high, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Scaldhearth** (edit, reference = `brackensear-f2.png`, 8 steps, CFG 1.0, file `brackensear-f3.png`)
```
Redraw the same character as the reference image as its final form, a big sleepy hearth hedgehog. Keep the same face, the same eyes and the same colouring, the same dark red-brown outlines and the same art style. Change the body proportions further: a large, mature body about two and a half times the size of the head, a full broad chest and strong legs, clearly and obviously bigger and more grown-up than the second form, while keeping a big friendly head so it stays cute and warm, not fierce. A big, plump, sleepy hedgehog with a thick coat of long bracken-frond quills tipped with orange ember points drawn as crisp flat shapes, a small ring of warm hearth stones tucked around its front paws, and a cosy content face. Three-quarter view facing left, resting on its belly with its head raised, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 53. Yarrowflare > Bloomember > Petalblaze (Verdant/Pyric)

`id: yarrowflare` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark red-brown

**Form 1, Yarrowflare** (two-reference edit, reference 1 = `buzzbud-f1.png`, reference 2 = `roastbelly-f1.png`, 8 steps, CFG 1.0, file `yarrowflare-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark red-brown outlines. It is not either parent: it is a tiny round sunbird chick with fluffy white feathers, a small thin curved beak and stubby wings. From the first creature it takes fuzzy cream-and-olive patches like a bumblebee's and two small leaf-tipped antennae on its head. From the second creature it takes sleepy half-closed content eyes and a warm orange belly. Three-quarter view facing left, perched on two thin legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Bloomember** (edit, reference = `yarrowflare-f1.png`, 8 steps, CFG 1.0, file `yarrowflare-f2.png`)
```
Redraw the same character as the reference image as its second form, a petal-winged sunbird. Keep the same face, the same eyes and the same colouring, the same leaf-tipped antennae and the same warm orange belly, the same dark red-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a bigger, sleeker sunbird with long petal-shaped white wing feathers edged in pale gold, a bright orange-red throat, and a long tail of flower-petal feathers. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, flying with both wings spread wide open, long tail streaming behind, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Petalblaze** (edit, reference = `yarrowflare-f2.png`, 8 steps, CFG 1.0, file `yarrowflare-f3.png`)
```
Redraw the same character as the reference image as its final form, a blazing petal sunbird. Keep the same face, the same eyes and the same colouring and the two small leaf sprouts on its head, the same dark red-brown outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A large, grand sunbird with long white petal-shaped wings whose outer feathers turn orange and red at the tips like flames, a crest of three tall petal plumes, a bright orange-red throat and chest, and a very long sweeping tail of flower petals turning into flames, all drawn as crisp flat shapes. Three-quarter view facing left, flying upward with its wings raised high above its back and its long tail streaming below, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 54. Sedgestilt > Reedcurrent > Willowmire (Verdant/Aqueous)

`id: sedgestilt` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark navy-blue

**Form 1, Sedgestilt** (two-reference edit, reference 1 = `dewdrop-f1.png`, reference 2 = `mossgear-f1.png`, 8 steps, CFG 1.0, file `sedgestilt-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark navy-blue outlines. It is not either parent: it is a small round heron chick with a long thin yellow beak, big round eyes and very long thin reed-like legs. From the first creature it takes glossy sky-blue feathers with white shine highlights, as if they were made of water. From the second creature it takes a fuzzy crest of bright moss on its head with a small brass gear set in it. Three-quarter view facing left, standing on its two long thin legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Reedcurrent** (edit, reference = `sedgestilt-f1.png`, 8 steps, CFG 1.0, file `sedgestilt-f2.png`)
```
Redraw the same character as the reference image as its second form, a reed-plumed heron. Keep the same face, the same eyes, the same colouring, the same glossy blue feathers and the same mossy crest with the brass gear, the same dark navy-blue outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now taller and slimmer, with a long S-curved neck, long reed-shaped plumes in sage and olive along its back and crest, and long thin legs. Three-quarter view facing left, standing still on its two long thin legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Willowmire** (edit, reference = `sedgestilt-f2.png`, 8 steps, CFG 1.0, file `sedgestilt-f3.png`)
```
Redraw the same character as the reference image as its final form, a great glossy blue heron. Keep the same face, the same eyes and the same colouring and the same mossy crest with its small brass gear, the same dark navy-blue outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A great heron with glossy sky-blue feathers, a big mossy crest with a small brass gear, long trailing willow-leaf plumes draped from its back and wings like a curtain, a long sharp yellow beak, and very long legs. Three-quarter view facing left, wading forward in mid-stride, both wings half spread and one long leg raised, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 55. Rowanboulder > Fernbrook > Alderfalls (Verdant/Aqueous)

`id: rowanboulder` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark brown | note: Kept apart from Brambletide (the teal thorn-vine hybrid otter): glossy rowan-red fur, no vines.

**Form 1, Rowanboulder** (two-reference edit, reference 1 = `frothsprite-f1.png`, reference 2 = `sproutlet-f1.png`, 8 steps, CFG 1.0, file `rowanboulder-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark brown outlines. It is not either parent: it is a small round otter pup with glossy rowan-red fur, a cream belly and muzzle, big round eyes and small webbed paws. From the first creature it takes a fluffy collar of white seafoam bubbles around its neck. From the second creature it takes a small green sapling sprout with two leaves on top of its head and a leaf-tipped tail. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Fernbrook** (edit, reference = `rowanboulder-f1.png`, 8 steps, CFG 1.0, file `rowanboulder-f2.png`)
```
Redraw the same character as the reference image as its second form, a fern-marked river otter. Keep the same face, the same eyes, the same colouring, the same seafoam bubble collar and the same sapling sprout and leaf-tipped tail, the same dark brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now bigger and sleeker, with fern-leaf-shaped markings in olive along its back and tail, a longer thick tail, and strong webbed paws. Three-quarter view facing left, standing on all four legs, tail raised, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Alderfalls** (edit, reference = `rowanboulder-f2.png`, 8 steps, CFG 1.0, file `rowanboulder-f3.png`)
```
Redraw the same character as the reference image as its final form, a big waterfall otter. Keep the same round face, the same big round dark eyes, the same glossy rowan-red fur and the same collar of pale-blue bubbles, the same dark brown outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A big, broad, powerful river otter with thick glossy rowan-red fur, a mane of alder leaves and ferns around its neck under the bubble collar, olive fern markings along its back, a long thick rudder tail, and a small cluster of red rowan berries behind one ear. Three-quarter view facing left, standing upright on its hind legs with its front paws on its belly and its tail behind it, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 56. Ivyflux > Vinespark > Leafcharge (Verdant/Voltaic)

`id: ivyflux` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark-green | note: Wings drawn opaque so the key colour can't show through them.

**Form 1, Ivyflux** (two-reference edit, reference 1 = `buzzbud-f1.png`, reference 2 = `coilchirp-f1.png`, 8 steps, CFG 1.0, file `ivyflux-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark-green outlines. It is not either parent: it is a small round dragonfly with a chubby olive body, big round eyes, two pairs of small opaque pale-sage wings and a short segmented tail. From the first creature it takes fuzzy cream-and-olive bumblebee patches on its body and two small leaf-tipped antennae. From the second creature it takes loops of copper wire wrapped around its body, and a tail that ends in a springy copper coil. Three-quarter view facing left, hovering in mid-air, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Vinespark** (edit, reference = `ivyflux-f1.png`, 8 steps, CFG 1.0, file `ivyflux-f2.png`)
```
Redraw the same character as the reference image as its second form, a big copper-wired bumblebee. Keep the same face, the same eyes and the same colouring, the same leaf-tipped antennae and the same copper wire loops and coiled tail, the same dark-green outlines and the same art style. Make it noticeably larger and more complex overall. Now a much bigger bumblebee with a longer body, four big opaque pale-sage wings shaped like ivy leaves, more copper wire loops around its fuzzy body with small yellow zigzag marks, and a longer coiled copper tail. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, flying forward with all four wings spread wide open, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Leafcharge** (edit, reference = `ivyflux-f2.png`, 8 steps, CFG 1.0, file `ivyflux-f3.png`)
```
Redraw the same character as the reference image as its final form, a great ivy-winged bee. Keep the same face, the same eyes and the same colouring, the same dark-green outlines and the same art style. A real final evolution: about three times the size of the second form, grander, more intricate and clearly the most impressive form; correct anatomy, no extra limbs. A large, grand bumblebee about twice the size of the second form, with four big opaque wings shaped like broad ivy leaves and veined with bright yellow zigzag lines, a thick fuzzy olive-and-cream body wound with copper wire, curling vine tendrils along its legs, and a big coiled copper tail. Three-quarter view facing left, hovering upright with its body tilted forward and all four wings spread wide above it, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 57. Burrbolt > Quillspark > Stormbristle (Verdant/Voltaic)

`id: burrbolt` | key: **magenta #FF00FF** | ratio: **cute** | outline: dark brown

**Form 1, Burrbolt** (two-reference edit, reference 1 = `brambletrundle-f1.png`, reference 2 = `joulebug-f1.png`, 8 steps, CFG 1.0, file `burrbolt-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark brown outlines. It is not either parent: it is a tiny round squirrel with chestnut-brown fur, a cream belly, big round eyes, small pointed ears and a big fluffy tail. From the first creature it takes thorny green vines wound around its tail, with small round burrs and yellow zigzag bolt marks. From the second creature it takes yellow-and-black stripes across its back and two long thin antennae-like tufts on its ears. Three-quarter view facing left, sitting upright on its hind legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Quillspark** (edit, reference = `burrbolt-f1.png`, 8 steps, CFG 1.0, file `burrbolt-f2.png`)
```
Redraw the same character as the reference image as its second form, a gliding burr squirrel. Keep the same face, the same eyes and the same colouring, the same burr vines and the same stripes and ear tufts, the same dark brown outlines and the same art style. Change the body proportions: a clearly bigger, sturdier, young-adult body about twice the size of the head, visibly longer and stronger legs and a fuller chest — a real, obvious size increase from the reference, not a subtle one — while keeping the head large and round so it still reads as cute. Now a slimmer flying squirrel with wide gliding flaps between its legs edged with burr quills and small yellow zigzag marks, taller ear tufts, and a much bigger banded tail. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, gliding through the air, legs spread wide, flaps open, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Stormbristle** (edit, reference = `burrbolt-f2.png`, 8 steps, CFG 1.0, file `burrbolt-f3.png`)
```
Redraw the same character as the reference image as its final form, a storm-bristled squirrel. Keep the same face, the same eyes and the same colouring, the same dark brown outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A big squirrel with strong hind legs, a thick mane of burr-quills around its neck, and an enormous tail bigger than its whole body, its quills standing straight up on end like a storm cloud of olive burrs, with small yellow zigzag bolt marks jumping between the quill tips. Three-quarter view facing left, standing up tall on its hind legs with its forepaws raised and its huge tail fanned out above it, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 58. Cliffscorch > Kilnclaw > Pyrestinger (Telluric/Pyric)

`id: cliffscorch` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark-brown

**Form 1, Cliffscorch** (two-reference edit, reference 1 = `emberfang-f1.png`, reference 2 = `quakemaw-f1.png`, 8 steps, CFG 1.0, file `cliffscorch-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark-brown outlines. It is not either parent: it is a small round baby scorpion covered in chunky grey-brown stone plates, with big round eyes, two small pincers, six stubby legs and a short curled tail. From the first creature it takes a spiky orange flame-shaped crest on its head drawn as crisp flat shapes, and orange pincer tips. From the second creature it takes a bright orange scarf tied around its neck and pebbly bumps on its plates. Three-quarter view facing left, standing on its legs, pincers forward, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Kilnclaw** (edit, reference = `cliffscorch-f1.png`, 8 steps, CFG 1.0, file `cliffscorch-f2.png`)
```
Redraw the same character as the reference image as its second form, a kiln-plated flame lizard-cat. Keep the same face, the same eyes and the same colouring, the same orange flame crest, the same orange scarf and the same segmented tail, the same dark-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a longer, bigger body with long legs and strong claws, heat-cracked grey stone plates on its back and shoulders showing thin orange ember cracks drawn as crisp flat shapes, a taller flame crest, and its segmented tail longer and arched high over its back with an orange tip. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, rearing up on its hind legs, front claws raised, tail arched high over its head, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Pyrestinger** (edit, reference = `cliffscorch-f2.png`, 8 steps, CFG 1.0, file `cliffscorch-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge stone scorch-cat. Keep the same face, the same eyes and the same colouring, the same flame crest, the orange scarf and the segmented tail, the same dark-brown outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A huge, heavy lizard-cat armoured in big heat-cracked grey rock plates with orange ember cracks drawn as crisp flat shapes, a great flame crest down its neck like a mane, big clawed paws, the orange scarf, and a tall segmented stone tail arched over its back like a scorpion's, its tip white-hot yellow and orange. Three-quarter view facing left, crouched low on all four legs, ready to pounce, tail arched high over its back, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 59. Nettlemesa > Spurback > Spinehearth (Telluric/Pyric)

`id: nettlemesa` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark-brown

**Form 1, Nettlemesa** (two-reference edit, reference 1 = `charwhisk-f1.png`, reference 2 = `geodecore-f1.png`, 8 steps, CFG 1.0, file `nettlemesa-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark-brown outlines. It is not either parent: it is a small round baby horned lizard with a flat round body in sun-baked clay orange and tan, big round eyes and short stubby legs. From the first creature it takes a small red feather crest on its head and a tail that ends in a little metal kitchen-whisk shape. From the second creature it takes a crown of short grey stone horns and one pale-blue crystal set in its forehead. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Spurback** (edit, reference = `nettlemesa-f1.png`, 8 steps, CFG 1.0, file `nettlemesa-f2.png`)
```
Redraw the same character as the reference image as its second form, a flat thorny horned lizard. Keep the same face, the same eyes and the same colouring, the same whisk tail and the same stone horns and forehead crystal, the same dark-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a real lizard, not a dinosaur: a long, flat, low body wider than it is tall, sprawled legs, a wide flat head with a crown of long stone horns and the forehead crystal, rows of small rust-red spurs along its back and sides, and a long tapering tail ending in the metal whisk. Slim, not chubby. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, lying low and flat like a basking lizard, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Spinehearth** (edit, reference = `nettlemesa-f2.png`, 8 steps, CFG 1.0, file `nettlemesa-f3.png`)
```
Redraw the same character as the reference image as its final form, a broad hearth-spined lizard. Keep the same face, the same eyes and the same colouring, the same stone horns and the same forehead crystal, the same dark-brown outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A huge, broad, heavy horned lizard with a wide flat body, a big crown of stone horns, a small stone hearth set into the middle of its back with an orange fire inside, rows of thick spines down its back and sides whose tips are orange and red like banked coals drawn as crisp flat shapes, a thick spiked tail, and thick clawed legs. Three-quarter view facing left, standing on all four legs, low, wide and heavy, head raised, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 60. Murkroot > Palevine > Loamgrove (Void/Verdant)

`id: murkroot` | key: **green #00FF00** | ratio: **cute** | outline: dark indigo | note: Void: green key. No green foliage: the saplings are pale ivory with deep-violet leaves.

**Form 1, Murkroot** (two-reference edit, reference 1 = `mossgear-f1.png`, reference 2 = `netherpod-f1.png`, 8 steps, CFG 1.0, file `murkroot-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark indigo outlines. It is not either parent: it is a tiny round mole with soft dark charcoal fur, a small pale snout and big pale digging paws. From the first creature it takes a small brass gear set in its forehead and a round fuzzy cog-shaped ruff of fur around its neck. From the second creature it takes a smooth violet shell-like patch on its back like a chrysalis, with a band of tiny pale star dots. Three-quarter view facing left, sitting on the ground, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Palevine** (edit, reference = `murkroot-f1.png`, 8 steps, CFG 1.0, file `murkroot-f2.png`)
```
Redraw the same character as the reference image as its second form, a big digging mole. Keep the same face, the same eyes and the same colouring, the same brass forehead gear and the same star-banded violet patch, the same dark indigo outlines and the same art style. Change the body proportions: a clearly bigger, sturdier, young-adult body about twice the size of the head, visibly longer and stronger legs and a fuller chest — a real, obvious size increase from the reference, not a subtle one — while keeping the head large and round so it still reads as cute. Now a much longer mole with huge pale digging paws, long pale ivory root-vines for whiskers curling out in front, and the violet star-banded patch grown over its back. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, standing up on its hind legs, huge digging paws held out in front, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Loamgrove** (edit, reference = `murkroot-f2.png`, 8 steps, CFG 1.0, file `murkroot-f3.png`)
```
Redraw the same character as the reference image as its final form, a big old grove mole. Keep the same face, the same eyes and the same colouring, the brass gear on its forehead, the violet star-banded patch on its back and the pale root whiskers, the same dark indigo outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A big, round old mole with a broad heavy body, a big brass gear in its forehead, long pale root whiskers, huge pale digging paws with long claws, and the violet star-banded patch on its back grown into a mound where a small grove of three pale ivory saplings with deep-violet leaves grows. Three-quarter view facing left, sitting up on its haunches with its huge digging paws raised, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 61. Duskbloom > Wanehop > Moonwarren (Void/Verdant)

`id: duskbloom` | key: **green #00FF00** | ratio: **animal** | outline: dark indigo | note: Void: green key. No green foliage: leaves are deep violet.

**Form 1, Duskbloom** (two-reference edit, reference 1 = `buzzbud-f1.png`, reference 2 = `riftsneak-f1.png`, 8 steps, CFG 1.0, file `duskbloom-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark indigo outlines. It is not either parent: it is a small round hare with soft pale lavender-grey fur, long upright ears and big round eyes. From the first creature it takes two small leaf-tipped antennae between its ears and a closed flower bud held in its front paws. From the second creature it takes violet ear tips like a kitten's and a small grey stone ring worn around its neck. Three-quarter view facing left, sitting on its hind legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Wanehop** (edit, reference = `duskbloom-f1.png`, 8 steps, CFG 1.0, file `duskbloom-f2.png`)
```
Redraw the same character as the reference image as its second form, a moon-pale hare. Keep the same face, the same eyes, the same colouring, the same antennae and flower bud and the same grey stone ring, the same dark indigo outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now taller and leaner, with moon-pale silver fur, long legs made for bounding, and a few small half-closed deep-violet flowers tucked behind its ears. Three-quarter view facing left, standing on all four legs, ready to bound, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Moonwarren** (edit, reference = `duskbloom-f2.png`, 8 steps, CFG 1.0, file `duskbloom-f3.png`)
```
Redraw the same character as the reference image as its final form, a tall moon-crowned hare. Keep the same face, the same eyes and the same colouring and the same long ears, the same dark indigo outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A tall, graceful moon hare with long powerful hind legs, silver fur with pale star dots across its back, very long ears with deep-violet insides, a crown of open night-blooming flowers with pale-gold and white petals and deep-violet leaves between its ears, and a mane of the same flowers down its neck. Three-quarter view facing left, bounding forward in mid-leap, front paws reaching out and hind legs stretched behind, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 62. Riftshale > Chasmclaw > Abyssburrow (Void/Telluric)

`id: riftshale` | key: **green #00FF00** | ratio: **animal** | outline: dark indigo | note: Void: green key.

**Form 1, Riftshale** (two-reference edit, reference 1 = `pebblescoot-f1.png`, reference 2 = `riftsneak-f1.png`, 8 steps, CFG 1.0, file `riftshale-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark indigo outlines. It is not either parent: it is a small stocky badger cub with slate-grey fur, a white face stripe, big round eyes and short strong legs. From the first creature it takes grey shale plates across its back like a beetle's shell. From the second creature it takes violet paws and a small grey stone portal ring held in one front paw. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Chasmclaw** (edit, reference = `riftshale-f1.png`, 8 steps, CFG 1.0, file `riftshale-f2.png`)
```
Redraw the same character as the reference image as its second form, a chasm-clawed badger. Keep the same face, the same eyes and the same colouring, the same shale back plates and the same round stone portal ring, the same dark indigo outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a long, broad badger with long dark-violet claws, slate stone plates on its shoulders with thin jagged dark-violet rift lines, and strong legs. It still carries the round grey stone portal ring from the reference, now bigger, held in its front paws. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, standing up on its hind legs, holding the stone ring out in front with both front paws, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Abyssburrow** (edit, reference = `riftshale-f2.png`, 8 steps, CFG 1.0, file `riftshale-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge rift-digging badger. Keep the same face, the same eyes and the same colouring, the same white face stripe and the round grey stone portal ring, the same dark indigo outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A huge, powerful badger with a broad heavy body, thick slate stone plates across its back and shoulders split by jagged dark-violet rift lines with pale star dots inside them, enormous dark-violet digging claws, and the round grey stone portal ring grown big and set upright on its back like a shield. Three-quarter view facing left, standing on all four legs, low and wide, head lowered and claws dug in, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 63. Nethershale > Grimplate > Umbralith (Void/Telluric)

`id: nethershale` | key: **green #00FF00** | ratio: **animal** | outline: dark indigo | note: Void: green key. Kept apart from Nullshale (slate-grey scaled pangolin): broad charcoal-black stone bands.

**Form 1, Nethershale** (two-reference edit, reference 1 = `netherpod-f1.png`, reference 2 = `quakemaw-f1.png`, 8 steps, CFG 1.0, file `nethershale-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark indigo outlines. It is not either parent: it is a small round baby armadillo with broad banded armour plates, a small pointed snout, small upright ears and short legs. From the first creature it takes violet armour plates with a band of tiny pale star dots around its middle, like a chrysalis. From the second creature it takes pebbly grey-brown skin, big round yellow eyes and a bright orange scarf around its neck. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Grimplate** (edit, reference = `nethershale-f1.png`, 8 steps, CFG 1.0, file `nethershale-f2.png`)
```
Redraw the same character as the reference image as its second form, a grim-plated armadillo. Keep the same face, the same eyes and the same colouring, the same star band and the same orange scarf, the same dark indigo outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a long, low armadillo on four short legs with a long snout, thick chiselled violet stone bands across its back, a wider band of pale star dots, and a long armoured tail. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, walking on all four legs, long and low, tail stretched out behind, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Umbralith** (edit, reference = `nethershale-f2.png`, 8 steps, CFG 1.0, file `nethershale-f3.png`)
```
Redraw the same character as the reference image as its final form, a monolith armadillo. Keep the same face, the same eyes and the same colouring, the same dark indigo outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A great armadillo with massive chiselled dark-violet stone bands stacked high like a monolith, pale star dots in the cracks between the bands, a thick armoured tail, and a small calm face under a heavy stone brow. Three-quarter view facing left, standing low on its legs, wide and powerful, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 64. Wraithcoal > Ashgloam > Cinderwraith (Void/Pyric)

`id: wraithcoal` | key: **green #00FF00** | ratio: **animal** | outline: dark indigo | note: Void: green key. Orange coal eyes instead of the usual pale-lavender, from the species description.

**Form 1, Wraithcoal** (two-reference edit, reference 1 = `cinderpup-f1.png`, reference 2 = `eclipsa-f1.png`, 8 steps, CFG 1.0, file `wraithcoal-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark indigo outlines. It is not either parent: it is a small round vulture chick with fluffy ash-grey feathers, a bare pale-grey head, a small hooked beak and big round deep-orange eyes. From the first creature it takes black-and-tan markings and a short tail with an orange flame tip drawn as a crisp flat shape. From the second creature it takes a round flat violet disk-shaped crest behind its head, like a small dark moon with a soft rim. Three-quarter view facing left, perched on two legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Ashgloam** (edit, reference = `wraithcoal-f1.png`, 8 steps, CFG 1.0, file `wraithcoal-f2.png`)
```
Redraw the same character as the reference image as its second form, a big ash vulture. Keep the same face, the same eyes and the same colouring, the same flame-tipped tail and the same violet disk crest, the same dark indigo outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a much bigger, taller vulture with a long neck, huge ash-grey wings, a ruff of charcoal feathers tipped with small orange ember points drawn as crisp flat shapes, the violet disk crest grown bigger behind its head, and a longer flame-tipped tail. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, standing tall with both wings spread wide open, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Cinderwraith** (edit, reference = `wraithcoal-f2.png`, 8 steps, CFG 1.0, file `wraithcoal-f3.png`)
```
Redraw the same character as the reference image as its final form, a great cinder vulture. Keep the same face, the same eyes and the same colouring, the same violet disk crest behind its head and the same flame-tipped tail, the same dark indigo outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A great vulture with a long bare neck, huge ash-grey wings with mid-violet and orange-tipped flight feathers, a large violet disk crest behind its head like a dark moon, a heavy ruff of charcoal feathers with orange ember points, a long flame-tipped tail and big strong talons, every part inside crisp outlines with no loose wisps. Three-quarter view facing left, hunched forward in a low crouch, its huge wings folded around its body like a heavy cloak, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 65. Duskflare > Wanescorch > Gloamfang (Void/Pyric)

`id: duskflare` | key: **green #00FF00** | ratio: **animal** | outline: dark indigo | note: Void: green key.

**Form 1, Duskflare** (two-reference edit, reference 1 = `riftsneak-f1.png`, reference 2 = `roastbelly-f1.png`, 8 steps, CFG 1.0, file `duskflare-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark indigo outlines. It is not either parent: it is a small lean jackal pup with a warm rust-orange coat, tall pointed ears and a bushy tail. From the first creature it takes a violet back, violet ear tips like a kitten's and a small grey stone portal ring around one front leg. From the second creature it takes sleepy half-closed content eyes and a warm cream belly. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Wanescorch** (edit, reference = `duskflare-f1.png`, 8 steps, CFG 1.0, file `duskflare-f2.png`)
```
Redraw the same character as the reference image as its second form, a smouldering dusk jackal. Keep the same face, the same eyes, the same colouring, the same violet back and stone ring and the same sleepy eyes, the same dark indigo outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now taller and leaner, with a rust coat whose back fades into deep violet like the end of dusk, thin orange ember lines drawn as crisp flat shapes along its shoulders, and long legs. Three-quarter view facing left, standing on all four legs, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Gloamfang** (edit, reference = `duskflare-f2.png`, 8 steps, CFG 1.0, file `duskflare-f3.png`)
```
Redraw the same character as the reference image as its final form, a great dusk jackal. Keep the same face, the same eyes and the same colouring, the same tall ears and the small grey stone portal ring around one front leg, the same dark indigo outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A large, powerful jackal with a long muzzle showing two small dark fangs, a coat running from sunset orange at the chest to deep violet on its back, a thick mane of dark-violet flame shapes drawn as crisp flat shapes running down its spine, a long bushy violet-tipped tail, long strong legs, and the small grey stone ring around one front leg. Three-quarter view facing left, standing on all four legs, howling with its head thrown back, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 66. Murkmire > Murkveil > Abyssbloom (Void/Aqueous)

`id: murkmire` | key: **green #00FF00** | ratio: **structure** | outline: dark indigo | note: Void: green key. The species text says translucent; drawn opaque on purpose (a see-through body lets the key colour through and ruins the cut-out).

**Form 1, Murkmire** (two-reference edit, reference 1 = `dewdrop-f1.png`, reference 2 = `netherpod-f1.png`, 8 steps, CFG 1.0, file `murkmire-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark indigo outlines. It is not either parent: it is a small round jellyfish with a soft opaque bell, a tiny smile and a few short wavy tentacles. From the first creature it takes a glossy sky-blue bell with white shine highlights, like a drop of water. From the second creature it takes a violet core shaped like a small chrysalis with a band of tiny pale star dots. Three-quarter view facing left, floating in mid-air, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Murkveil** (edit, reference = `murkmire-f1.png`, 8 steps, CFG 1.0, file `murkmire-f2.png`)
```
Redraw the same character as the reference image as its second form, a veil-trailing jellyfish. Keep the same face, the same eyes, the same colouring, the same glossy blue bell and the same star-banded violet core, the same dark indigo outlines and the same art style. Make it noticeably larger and more complex overall. Now bigger, with a wider bell and long flowing veils of ink-dark violet tentacles trailing beneath it like ribbons. Three-quarter view facing left, floating in mid-air, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Abyssbloom** (edit, reference = `murkmire-f2.png`, 8 steps, CFG 1.0, file `murkmire-f3.png`)
```
Redraw the same character as the reference image as its final form, a vast abyss-blossom jellyfish. Keep the same face, the same eyes and the same colouring, the glossy sky-blue bell with the face on it and the violet star-dotted core, the same dark indigo outlines and the same art style. A real final evolution: about three times the size of the second form, grander, more intricate and clearly the most impressive form; correct anatomy, no extra limbs. A vast jellyfish that keeps its glossy sky-blue bell and face, now crowned by a ring of big dark-violet flower petals opening around the rim of the bell like a blossom, the violet star-dotted core showing through the bell, and long ink-dark ribbon tentacles trailing far below. Three-quarter view facing left, floating in mid-air, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 67. Hollowstream > Stillgill > Palepool (Void/Aqueous)

`id: hollowstream` | key: **green #00FF00** | ratio: **animal** | outline: dark indigo | note: Void: green key. The species text says near-transparent; drawn opaque and pale on purpose (see Murkmire).

**Form 1, Hollowstream** (two-reference edit, reference 1 = `frothsprite-f1.png`, reference 2 = `hushflutter-f1.png`, 8 steps, CFG 1.0, file `hollowstream-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark indigo outlines. It is not either parent: it is a small round newt with smooth pale lavender-white skin, little feathery gill fronds on each side of its head and a flat paddle tail. From the first creature it takes a fluffy collar of white seafoam bubbles around its neck. From the second creature it takes fuzzy violet gill fronds shaped like a moth's feathery antennae and small pale star spots on its tail. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Stillgill** (edit, reference = `hollowstream-f1.png`, 8 steps, CFG 1.0, file `hollowstream-f2.png`)
```
Redraw the same character as the reference image as its second form, a winged newt. Keep the same face, the same eyes and the same colouring, the same seafoam bubble collar and the same moth-antenna gills and star spots, the same dark indigo outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a much longer, sleeker newt with large feathery violet gill fronds, its moth-like wings grown big with pale star spots, long legs, and a long flat finned tail. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, flying with its wings spread wide open, long tail trailing, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Palepool** (edit, reference = `hollowstream-f2.png`, 8 steps, CFG 1.0, file `hollowstream-f3.png`)
```
Redraw the same character as the reference image as its final form, a large pale pool newt. Keep the same face, the same eyes and the same colouring, the seafoam bubble collar and the moth-like wings with star spots, the same dark indigo outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A large, graceful newt with a long body and a very long flat finned tail, big frilled violet gills fanned out like a crown, two pairs of large moth-like wings with pale star spots, the seafoam bubble collar, pale lavender-white skin with faint mid-violet ripple patterns, and wide webbed feet. Three-quarter view facing left, flying with all four wings spread wide open, long tail trailing, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 68. Wraithwire > Wanewire > Shadescythe (Void/Voltaic)

`id: wraithwire` | key: **green #00FF00** | ratio: **structure** | outline: dark indigo | note: Void: green key.

**Form 1, Wraithwire** (two-reference edit, reference 1 = `coilchirp-f1.png`, reference 2 = `riftsneak-f1.png`, 8 steps, CFG 1.0, file `wraithwire-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark indigo outlines. It is not either parent: it is a small round baby mantis with a slender dark violet body, a small triangular head, big round eyes, two folded front arms and thin legs. From the first creature it takes loops of copper wire wrapped around its arms and legs and a springy copper coil at the end of its body. From the second creature it takes pointed kitten ears and a small grey stone portal ring held in its front arms. Three-quarter view facing left, standing on its four back legs, front arms folded, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Wanewire** (edit, reference = `wraithwire-f1.png`, 8 steps, CFG 1.0, file `wraithwire-f2.png`)
```
Redraw the same character as the reference image as its second form, a sleek adult shadow cat. Keep the same face, the same eyes and the same colouring, the same ears, the same copper wire wraps and coiled tail and the same stone portal ring, the same dark indigo outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a long, lean adult cat with long slim legs and a long body, copper wire wound along its legs with small yellow zigzag marks at each wrap, a long coiled copper tail, and a bigger stone portal ring hanging from its tail. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, standing on all four long legs, back arched, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Shadescythe** (edit, reference = `wraithwire-f2.png`, 8 steps, CFG 1.0, file `wraithwire-f3.png`)
```
Redraw the same character as the reference image as its final form, a tall shadow-scythe cat. Keep the same face, the same eyes and the same colouring, the same ears, the copper wire wraps and the stone portal ring on its tail, the same dark indigo outlines and the same art style. A real final evolution: a new pose and a clearly different, fully grown body about twice the size of the second form, the head smaller in proportion to the body; correct anatomy, no extra limbs. A tall, powerful panther-like cat with long slim legs, copper wire wound around its legs with small yellow zigzag marks, a long coiled copper tail carrying the big stone portal ring, and a long crescent-shaped fin of dark violet fur sweeping back from each front leg like a scythe blade, edged with bright yellow zigzag lines. Three-quarter view facing left, prowling on all four legs, low and stalking, head forward, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 69. Duskvolt > Wanecoil > Gloomweaver (Void/Voltaic)

`id: duskvolt` | key: **green #00FF00** | ratio: **structure** | outline: dark indigo | note: Void: green key. No web behind it (scenery would spoil the cut-out): the silk is a ball of thread it holds.

**Form 1, Duskvolt** (two-reference edit, reference 1 = `eclipsa-f1.png`, reference 2 = `joulebug-f1.png`, 8 steps, CFG 1.0, file `duskvolt-f1.png`)
```
Create one brand-new baby creature that is the child of the two creatures in the reference images, drawn in exactly the same art style, the same soft painterly look and the same kind of clean dark indigo outlines. It is not either parent: it is a small round fuzzy spider with two big round eyes, a tiny smile and eight short stubby legs in four matching pairs. From the first creature it takes a round flat violet body shaped like a small dark disk with a soft rim. From the second creature it takes yellow-and-black stripes on its round abdomen and two long thin antennae. Three-quarter view facing left, standing on its eight legs, full body visible and centred, filling about 65 percent of the frame with clear margin on every side. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor and no shadow under it (do not copy the parents' shadows), no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Wanecoil** (edit, reference = `duskvolt-f1.png`, 8 steps, CFG 1.0, file `duskvolt-f2.png`)
```
Redraw the same character as the reference image as its second form, a long-legged coil spider. Keep the same face, the same eyes and the same colouring, the same disk-shaped violet body and the same yellow-and-black stripes and antennae, the same dark indigo outlines and the same art style. Make it noticeably larger and more complex overall. Now much bigger with eight very long jointed legs lifting its body high, a longer striped abdomen behind the round disk-shaped violet body, long antennae, and a coil of pale silk thread with yellow zigzag bolt marks held between its front legs. A real evolution: a new pose and a clearly different, older, bigger body shape; correct anatomy, no extra limbs. Three-quarter view facing left, standing tall on eight long legs, body raised high, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Gloomweaver** (edit, reference = `duskvolt-f2.png`, 8 steps, CFG 1.0, file `duskvolt-f3.png`)
```
Redraw the same character as the reference image as its final form, a great night-web spider. Keep the same face, the same eyes and the same colouring, the round violet body, the yellow-and-black striped abdomen and the ring of silk held in its front legs, the same dark indigo outlines and the same art style. A real final evolution: about three times the size of the second form, grander, more intricate and clearly the most impressive form; correct anatomy, no extra limbs. A huge spider with eight very long jointed legs lifting it high, a big yellow-and-black striped abdomen with pale star dots, long antennae, a large coil of pale silk thread with yellow zigzag bolt marks held in its front legs, and a crown of short violet crystal spikes on its back. Three-quarter view facing left, standing tall on its eight long legs, body raised high, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

## Adding a creature

- **Template for a new creature:** copy any `C(...)` entry in `D:\AI\tools\build_prompts.py`, fill the fields, and rerun.

## Records

- These prompts are the AI-disclosure record for the sprites, together with `docs/art-pipeline.md` (tool: ComfyUI on the designer's machine; model: FLUX.2 [klein] 4B distilled fp8, Apache 2.0). Keep this file with the approved images.
- Sproutlet and Emberfang were generated before this file existed; their exact prompts are in `docs/art-pipeline.md` (Sproutlet) and the session history (Emberfang).
