# Creature sprite prompts (ready to paste)

Generated 2026-09-21 from `D:\AI\tools\build_prompts.py` (edit the table there, rerun, and this file and `D:\AI\tools\creatures.json` are rebuilt). Recipe and lessons: `docs/art-pipeline.md`. Nothing here is wired into the game.

## Status of the source material (read this first)

- **24 base species:** names, types and form lines come from `docs/content-data.md`. The four done lines (Sproutlet, Emberfang, Brambletrundle, Riftsneak) are approved. The other 20 are written here from the design's placeholder descriptions, reworded to be art-safe (no "glowing" or "aura"; transparent things made opaque; pink kept away from the key colour).
- **15 default hybrids:** the design only gives names, types and skills, never a look. The animals and designs here are **my invention** (an assistant proposal) and need the designer's review before any of them are generated. Cheap to change: edit the table, rerun.
- **10 special recipes (Chunk 2):** from `docs/naming/chunk2-claude.md` (names and cosmetic lines). **Provisional**: that batch has not been reviewed yet, so the names may still change.
- **20 special recipes are missing:** the corrected Chunk 1 (10 recipes) was never pasted into any session, and Chunk 3 (the 5 Void pairs) has not been written. They get sections here once the names are final.
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
| 3 | Mossgear | Verdant | Mossgear > Mosscrank > Mossbastion | base | magenta | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 4 | Petalsprocket | Verdant | Petalsprocket > Bloomwheel > Blossomcrank | base | magenta | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 5 | Quakemaw | Telluric | Quakemaw > Faultjaw > Craterchomp | base | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 6 | Geodecore | Telluric | Geodecore > Crystalheart > Prismpulse | base | magenta | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 7 | Pebblescoot | Telluric | Pebblescoot > Shalestride > Bedrockbound | base | magenta | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 8 | Tuskcub | Telluric | Tuskcub > Ridgecrest > Summitspike | base | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 9 | Emberfang | Pyric | Emberfang > Smolderbite > Emberroar | base | magenta | animal | DONE |
| 10 | Cinderpup | Pyric | Cinderpup > Cinderbark > Cinderhowl | base | magenta | cute | F1 [ ]  F2 [ ]  F3 [ ] |
| 11 | Roastbelly | Pyric | Roastbelly > Oventummy > Smolderplump | base | magenta | cute | F1 [ ]  F2 [ ]  F3 [ ] |
| 12 | Charwhisk | Pyric | Charwhisk > Coalstir > Hearthblend | base | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 13 | Dewdrop | Aqueous | Dewdrop > Rillstream > Tideflow | base | magenta | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 14 | Puddlescoop | Aqueous | Puddlescoop > Basincatch > Lakehaul | base | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 15 | Frothsprite | Aqueous | Frothsprite > Foamspirit > Brinesoul | base | magenta | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 16 | Splashfin | Aqueous | Splashfin > Wavegill > Tidetail | base | magenta | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 17 | Voltfluff | Voltaic | Voltfluff > Staticfleece > Arcwool | base | magenta | cute | F1 [ ]  F2 [ ]  F3 [ ] |
| 18 | Joulebug | Voltaic | Joulebug > Ohmroach > Wattbeetle | base | magenta | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 19 | Plasmaplug | Voltaic | Plasmaplug > Ionjack > Surgeport | base | magenta | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 20 | Coilchirp | Voltaic | Coilchirp > Wirebeak > Gridtrill | base | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 21 | Eclipsa | Void | Eclipsa > Umbrax > Penumbrum | base | green | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 22 | Riftsneak | Void | Riftsneak > Nullprowl > Gloamstalk | base | green | structure | DONE |
| 23 | Hushflutter | Void | Hushflutter > Hushglide > Silentwing | base | green | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 24 | Netherpod | Void | Netherpod > Chasmshell > Astralcarapace | base | green | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 25 | Ashwood | Verdant/Pyric | Ashwood > Emberbark > Hearthtrunk | hybrid | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 26 | Brambletide | Verdant/Aqueous | Brambletide > Briarripple > Thicketwave | hybrid | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 27 | Sproutfault | Verdant/Telluric | Sproutfault > Timbershale > Lumbercrag | hybrid | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 28 | Mosscoil | Verdant/Voltaic | Mosscoil > Mossfuse > Canopygrid | hybrid | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 29 | Mudskulker | Telluric/Aqueous | Mudskulker > Shaleflow > Bedrocktide | hybrid | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 30 | Quakeforge | Telluric/Pyric | Quakeforge > Slagfist > Craterhearth | hybrid | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 31 | Geodegrid | Telluric/Voltaic | Geodegrid > Crystalwire > Prismvolt | hybrid | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 32 | Cinderbasin | Pyric/Aqueous | Cinderbasin > Steamrill > Kettlebrine | hybrid | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 33 | Embersurge | Pyric/Voltaic | Embersurge > Blazearc > Infernodynamo | hybrid | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 34 | Brinecore | Aqueous/Voltaic | Brinecore > Rillarc > Tidebolt | hybrid | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 35 | Eclipseed | Void/Verdant | Eclipseed > Starsap > Nightbloom | hybrid | green | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 36 | Nullshale | Void/Telluric | Nullshale > Riftrock > Abysscrag | hybrid | green | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 37 | Gloamforge | Void/Pyric | Gloamforge > Muteember > Hushkiln | hybrid | green | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 38 | Hushflow | Void/Aqueous | Hushflow > Nullstream > Riftcurrent | hybrid | green | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 39 | Gridrift | Void/Voltaic | Gridrift > Corewire > Lodestar | hybrid | green | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 40 | Gravelnip | Telluric/Aqueous | Gravelnip > Reefpincer > Boulderclaw | special | magenta | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 41 | Ripplesnap | Telluric/Aqueous | Ripplesnap > Slatesnout > Ridgehide | special | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 42 | Cairnflit | Telluric/Voltaic | Cairnflit > Pumiceglide > Fluxwing | special | magenta | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 43 | Flintlamb | Telluric/Voltaic | Flintlamb > Ampcurl > Mesahorn | special | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 44 | Coralpeep | Pyric/Aqueous | Coralpeep > Flarewade > Pyreplume | special | green | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 45 | Drizzlenub | Pyric/Aqueous | Drizzlenub > Brooksoak > Lavabask | special | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 46 | Coalgrub | Pyric/Voltaic | Coalgrub > Arcflicker > Blazefly | special | magenta | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 47 | Boltkit | Pyric/Voltaic | Boltkit > Brandtail > Scorchfox | special | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |
| 48 | Eddyelver | Aqueous/Voltaic | Eddyelver > Kelpeel > Dynamoeel | special | magenta | structure | F1 [ ]  F2 [ ]  F3 [ ] |
| 49 | Sprayfledge | Aqueous/Voltaic | Sprayfledge > Pulsedart > Voltfisher | special | magenta | animal | F1 [ ]  F2 [ ]  F3 [ ] |

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

### 4. Petalsprocket > Bloomwheel > Blossomcrank (Verdant)

`id: petalsprocket` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark-green | note: Keep the petals cream, yellow and orange, never pink (pink is near the magenta key).

**Form 1, Petalsprocket** (text to image, 8 steps, CFG 1.0, file `petalsprocket-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-green outlines and vibrant saturated colours. A small flower creature hovering in the air: a round soft-yellow face at the centre with two big round dark-green eyes and a tiny smile, ringed by six pale-yellow and white petals each trimmed with a thin silver metal edge, a short green stem body with two small leaf hands, and a small brass sprocket gear on its back. Three-quarter view facing left, hovering in mid-air, floating upright, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Bloomwheel** (edit, reference = `petalsprocket-f1.png`, 8 steps, CFG 1.0, file `petalsprocket-f2.png`)
```
Redraw the same character as the reference image as its second form, a larger rotor-flower. Keep the same round yellow face, the same big dark-green eyes and the same cream, yellow and white petals with silver metal edges, the same dark-green outlines and the same art style. Make it noticeably larger and more complex overall. Now bigger, with two rings of petals shaped like propeller blades on silver hubs, a longer green stem with more leaves, and a larger brass sprocket gear on its back. Three-quarter view facing left, hovering in mid-air, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Blossomcrank** (edit, reference = `petalsprocket-f2.png`, 8 steps, CFG 1.0, file `petalsprocket-f3.png`)
```
Redraw the same character as the reference image as its final form, an intricate many-layered blossom of petals and gears. Keep the same round yellow face, the same big round dark-green eyes and the same tiny smile, the same dark-green outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A large, grand, intricate blossom with three concentric rings of petals in cream, pale yellow and soft orange with small pale-gold highlights painted on them, brass gears and cogs of different sizes nestled between the petal rings, a small crank handle, and a thick green stem with many leaves. Three-quarter view facing left, hovering in mid-air, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 5. Quakemaw > Faultjaw > Craterchomp (Telluric)

`id: quakemaw` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark-brown

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
Redraw the same character as the reference image as its final form, a friendly earth-dragon. Keep the same friendly face, the same big round golden-yellow eyes and the same grey-brown colouring, the same dark-brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A large, friendly earth-dragon with a stone-plated back, small blunt horn ridges over its brow, a row of large clear pale-blue crystal teeth along its wide jaw and short pale-blue crystal spikes along its spine and tail, calm and kind. Three-quarter view facing left, standing on all four legs, low, wide and powerful, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 6. Geodecore > Crystalheart > Prismpulse (Telluric)

`id: geodecore` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark-brown

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
Redraw the same character as the reference image as its final form, a bright crystal nucleus with orbiting stones. Keep the same two big round dark eyes, the same dark-brown outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A large bright faceted amber and pale-blue crystal core with the same eyes, surrounded by five grey-brown stones of different sizes floating close around it in a ring, each stone with its own crisp outline. Three-quarter view facing left, floating in mid-air with the stones circling around it, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 7. Pebblescoot > Shalestride > Bedrockbound (Telluric)

`id: pebblescoot` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark-brown | note: Many legs and long body: needs a wide frame, and may need the fit-to-frame margin raised.

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
Redraw the same character as the reference image as its final form, a gentle plated centipede giant. Keep the same two big round dark eyes, the same dark-brown outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A very long, gentle giant with a segmented centipede-like body of thick bedrock plates in grey and brown, many pairs of sturdy legs, small pale-blue crystal spots along its back, and a kind face with the same eyes. Three-quarter view facing left, long body curving in a gentle S-shape, many legs on the ground, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
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

`id: cinderpup` | key: **magenta #FF00FF** | ratio: **cute** | outline: dark red-brown | note: Design says "stays cute": milder ratio ladder.

**Form 1, Cinderpup** (text to image, 8 steps, CFG 1.0, file `cinderpup-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark red-brown outlines and vibrant saturated colours. A small hyperactive round puppy with charcoal-grey fur, an orange belly and paws, big round dark eyes, floppy ears, a happy open mouth with its tongue out, and a short tail ending in a tiny orange flame-shaped tuft drawn as a crisp flat shape. Three-quarter view facing left, standing on all four legs with its tail up, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Cinderbark** (edit, reference = `cinderpup-f1.png`, 8 steps, CFG 1.0, file `cinderpup-f2.png`)
```
Redraw the same character as the reference image as its second form, a bouncy fiery dog. Keep the same round face, the same big dark eyes, the same floppy ears and the same charcoal-grey and orange colouring, the same dark red-brown outlines and the same art style. Make it a little bigger and sturdier: a body about twice the size of the head and longer legs, but keep the head big and round so it stays cute. Now a bigger, bouncier dog with a few small orange ember spots painted on its fur and a longer tail with a larger flame-shaped tuft. Three-quarter view facing left, trotting on all four legs, one front paw lifted, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Cinderhowl** (edit, reference = `cinderpup-f2.png`, 8 steps, CFG 1.0, file `cinderpup-f3.png`)
```
Redraw the same character as the reference image as its final form, a majestic hound. Keep the same friendly face, the same big round dark eyes and the same floppy ears, the same dark red-brown outlines and the same art style. Make it noticeably larger and more mature: a body about two and a half times the size of the head, a fuller chest and strong legs, still with a big friendly head so it stays cute and friendly. A majestic, elegant hound with its head raised in a howl, a thick mane of ash-grey fur marked with orange ember spots, and a long flowing tail with a big flame-shaped tuft drawn as crisp flat shapes. Still friendly, not fierce. Three-quarter view facing left, standing on all four legs with its head raised, howling, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 11. Roastbelly > Oventummy > Smolderplump (Pyric)

`id: roastbelly` | key: **magenta #FF00FF** | ratio: **cute** | outline: dark red-brown | note: Chubby species: milder ratio ladder.

**Form 1, Roastbelly** (text to image, 8 steps, CFG 1.0, file `roastbelly-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark red-brown outlines and vibrant saturated colours. A round, sleepy little salamander with plump orange-red skin, half-closed sleepy eyes with a contented smile, a warm cream-orange belly, four stubby legs and a short thick tail. Three-quarter view facing left, sitting on its belly on the ground, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Oventummy** (edit, reference = `roastbelly-f1.png`, 8 steps, CFG 1.0, file `roastbelly-f2.png`)
```
Redraw the same character as the reference image as its second form, a chubby waddler with a belly window. Keep the same sleepy half-closed eyes, the same round face and the same orange-red skin with the cream-orange belly, the same dark red-brown outlines and the same art style. Make it a little bigger and sturdier: a body about twice the size of the head and longer legs, but keep the head big and round so it stays cute. Now bigger and chubbier, with a small round oven-style window set into its belly, framed in dark metal and showing a small flame drawn as a crisp flat shape inside. Three-quarter view facing left, waddling on all four legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Smolderplump** (edit, reference = `roastbelly-f2.png`, 8 steps, CFG 1.0, file `roastbelly-f3.png`)
```
Redraw the same character as the reference image as its final form, a massive affectionate salamander. Keep the same sleepy half-closed eyes, the same friendly face and the same orange-red skin, the same dark red-brown outlines and the same art style. Make it noticeably larger and more mature: a body about two and a half times the size of the head, a fuller chest and strong legs, still with a big friendly head so it stays cute and friendly. A huge, plump, affectionate salamander with a deep content smile, a big round oven window on its belly showing a cosy flame drawn as a crisp flat shape, and a row of small rounded ridges along its back like chimney tops. Three-quarter view facing left, sitting on the ground, big and round, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 12. Charwhisk > Coalstir > Hearthblend (Pyric)

`id: charwhisk` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark red-brown

**Form 1, Charwhisk** (text to image, 8 steps, CFG 1.0, file `charwhisk-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark red-brown outlines and vibrant saturated colours. A small round bird with charcoal-black and orange feathers, a small red crest tuft, big round amber eyes, a small orange beak, thin legs, and a tail shaped like a wire kitchen whisk with a few small orange embers caught in its loops. Three-quarter view facing left, standing on two thin legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Coalstir** (edit, reference = `charwhisk-f1.png`, 8 steps, CFG 1.0, file `charwhisk-f2.png`)
```
Redraw the same character as the reference image as its second form, a crane-like bird with metallic legs. Keep the same round face, the same big amber eyes, the same small beak and the same charcoal-black and orange feathers, the same dark red-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now taller, with a longer neck, long thin steel-grey metallic legs and a longer whisk-shaped tail. Three-quarter view facing left, standing on two long legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Hearthblend** (edit, reference = `charwhisk-f2.png`, 8 steps, CFG 1.0, file `charwhisk-f3.png`)
```
Redraw the same character as the reference image as its final form, a fire-peacock with kitchen-tool feathers. Keep the same friendly face, the same big round amber eyes, the same small orange beak and the same charcoal-black body feathers, the same dark red-brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A magnificent peacock-like bird with a huge fanned tail of feathers each shaped like a kitchen tool, whisks, ladles, spatulas and spoons, in orange, copper and red with small pale-gold highlights, on long steel-grey legs. Three-quarter view facing left, standing on two long legs with its tail fanned out behind it, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 13. Dewdrop > Rillstream > Tideflow (Aqueous)

`id: dewdrop` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark navy-blue | note: Keep it opaque. Anything see-through lets the key colour bleed in and ruins the cut-out.

**Form 1, Dewdrop** (text to image, 8 steps, CFG 1.0, file `dewdrop-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark navy-blue outlines and vibrant saturated colours. A round bead-shaped blob of glossy light-blue jelly, drawn as a solid opaque body with a few white highlight shapes painted on it, two big round dark-blue eyes and a tiny smile. Three-quarter view facing left, resting on the ground, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Rillstream** (edit, reference = `dewdrop-f1.png`, 8 steps, CFG 1.0, file `dewdrop-f2.png`)
```
Redraw the same character as the reference image as its second form, a serpentine water elemental. Keep the same round face, the same big dark-blue eyes and the same light-blue colouring, the same dark navy-blue outlines and the same art style. Make it noticeably larger and more complex overall. Now a long serpentine body of glossy blue jelly with silver bands wrapped around it, coiled in loose curves, with a small head and the same face; the body stays solid and opaque. Three-quarter view facing left, coiled loosely on the ground with its head raised, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Tideflow** (edit, reference = `dewdrop-f2.png`, 8 steps, CFG 1.0, file `dewdrop-f3.png`)
```
Redraw the same character as the reference image as its final form, a serene looping water spirit. Keep the same friendly face and the same big round dark-blue eyes, the same dark navy-blue outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A large, graceful, long body of glossy blue jelly with silver bands, looping in one big smooth ring in the air, with a calm, serene expression; solid and opaque, with crisp outlines. Three-quarter view facing left, floating in a large graceful loop, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
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

`id: voltfluff` | key: **magenta #FF00FF** | ratio: **cute** | outline: dark brown | note: Design says "stays cute": milder ratio ladder. Lightning is painted on the wool, never floating around it.

**Form 1, Voltfluff** (text to image, 8 steps, CFG 1.0, file `voltfluff-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark brown outlines and vibrant saturated colours. A small Pomeranian-like ball of fluffy cream and yellow fur in spiky tufts, big round dark eyes, a small black nose, small pointed ears, a curled fluffy tail and a few small yellow zigzag lightning marks painted in the fur. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Staticfleece** (edit, reference = `voltfluff-f1.png`, 8 steps, CFG 1.0, file `voltfluff-f2.png`)
```
Redraw the same character as the reference image as its second form, an electrified sheepdog in crackling wool. Keep the same round face, the same big dark eyes, the same small black nose and the same cream and yellow fluffy fur, the same dark brown outlines and the same art style. Make it a little bigger and sturdier: a body about twice the size of the head and longer legs, but keep the head big and round so it stays cute. Now a bigger sheepdog with long shaggy cream and yellow wool, a big fluffy tail plume, and yellow zigzag lightning patterns painted across its wool. Three-quarter view facing left, standing on all four legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Arcwool** (edit, reference = `voltfluff-f2.png`, 8 steps, CFG 1.0, file `voltfluff-f3.png`)
```
Redraw the same character as the reference image as its final form, a majestic fluffy canine. Keep the same friendly face, the same big round dark eyes and the same small black nose, the same dark brown outlines and the same art style. Make it noticeably larger and more mature: a body about two and a half times the size of the head, a fuller chest and strong legs, still with a big friendly head so it stays cute and friendly. A majestic, large, very fluffy canine with a huge mane of cream and yellow wool and a plume tail, with a few thin yellow lightning-bolt shapes drawn as crisp flat shapes attached to the wool, gentle and friendly. Three-quarter view facing left, standing on all four legs, head held high, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
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

`id: plasmaplug` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark brown | note: Mechanical: a candidate to retest with the base model (see art-pipeline.md).

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
Redraw the same character as the reference image as its final form, a gentle cobra. Keep the same big round curious eyes and the same yellow-and-black colouring, the same dark brown outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A large, gentle cobra with a wide hood shaped like a power-socket hub with several round socket holes set in it, a thick copper-ringed body and a calm kind face. Three-quarter view facing left, coiled with its hooded head raised high, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 20. Coilchirp > Wirebeak > Gridtrill (Voltaic)

`id: coilchirp` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark brown

**Form 1, Coilchirp** (text to image, 8 steps, CFG 1.0, file `coilchirp-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark brown outlines and vibrant saturated colours. A small round songbird with a body wrapped in coppery wire coils, a yellow chest, big round dark eyes, a small dark beak open mid-chirp, and a coiled wire tail. Three-quarter view facing left, perched on two thin legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Wirebeak** (edit, reference = `coilchirp-f1.png`, 8 steps, CFG 1.0, file `coilchirp-f2.png`)
```
Redraw the same character as the reference image as its second form, a conductive singing bird. Keep the same round face, the same big dark eyes and the same copper-wire and yellow colouring, the same dark brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a larger, longer-bodied bird with a crest of copper wire, a sharper beak and longer tail feathers wrapped in wire. Three-quarter view facing left, perched on two thin legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Gridtrill** (edit, reference = `coilchirp-f2.png`, 8 steps, CFG 1.0, file `coilchirp-f3.png`)
```
Redraw the same character as the reference image as its final form, an electric eagle. Keep the same big round dark eyes and the same copper-wire and yellow colouring, the same dark brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A large, noble eagle with broad feathers edged in copper wire and tipped in yellow, a strong hooked beak, a copper wire crest, and powerful talons. Three-quarter view facing left, perched upright with its wings folded, proud, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 21. Eclipsa > Umbrax > Penumbrum (Void)

`id: eclipsa` | key: **green #00FF00** | ratio: **structure** | outline: dark indigo | note: Void: green key, mid-violet body (reads on the dark plate). Keep the rim and rings crisp, not soft.

**Form 1, Eclipsa** (text to image, 8 steps, CFG 1.0, file `eclipsa-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark indigo outlines and vibrant saturated colours. A silent floating flat round disc in rich mid-violet with lighter lavender highlights, seen at a three-quarter angle, with a thin crisp pale-lavender rim, two calm round pale-lavender eyes on its face and a small gentle mouth. Three-quarter view facing left, floating in mid-air, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Umbrax** (edit, reference = `eclipsa-f1.png`, 8 steps, CFG 1.0, file `eclipsa-f2.png`)
```
Redraw the same character as the reference image as its second form, a crescent shadow entity. Keep the same two calm round pale-lavender eyes and the same rich mid-violet with lighter lavender highlights, the same dark indigo outlines and the same art style. Make it noticeably larger and more complex overall. Now a larger crescent-shaped body in rich mid-violet with lighter lavender highlights, with smooth crisp edges and a thin pale-lavender rim, with the same calm eyes. Three-quarter view facing left, floating in mid-air, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Penumbrum** (edit, reference = `eclipsa-f2.png`, 8 steps, CFG 1.0, file `eclipsa-f3.png`)
```
Redraw the same character as the reference image as its final form, a multi-ringed dark body. Keep the same two calm round pale-lavender eyes and the same gentle face, the same dark indigo outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A large body in rich mid-violet with lighter lavender highlights like a planet with several concentric pale-lavender rings around it, drawn as crisp flat bands, with the same calm eyes on its face. Three-quarter view facing left, floating in mid-air, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
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

`id: hushflutter` | key: **green #00FF00** | ratio: **structure** | outline: dark indigo | note: Void: green key, mid-violet body.

**Form 1, Hushflutter** (text to image, 8 steps, CFG 1.0, file `hushflutter-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark indigo outlines and vibrant saturated colours. A small round fuzzy moth in rich mid-violet with lighter lavender highlights, with two feathery antennae, big round pale-lavender eyes, small rounded wings marked with pale star spots at the tips, and tiny dangling legs. Three-quarter view facing left, hovering in mid-air, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Hushglide** (edit, reference = `hushflutter-f1.png`, 8 steps, CFG 1.0, file `hushflutter-f2.png`)
```
Redraw the same character as the reference image as its second form, a floating manta ray of twilight. Keep the same big pale-lavender eyes and the same soft mid-violet fur with lighter lavender highlights, the same dark indigo outlines and the same art style. Make it noticeably larger and more complex overall. Now a larger, wide manta-ray-shaped body in rich mid-violet fading to lighter lavender at the edges, gliding, with pale star dots along its wings and the same face. Three-quarter view facing left, gliding in mid-air, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Silentwing** (edit, reference = `hushflutter-f2.png`, 8 steps, CFG 1.0, file `hushflutter-f3.png`)
```
Redraw the same character as the reference image as its final form, a four-winged phantom glider. Keep the same face and the same big round pale-lavender eyes, the same dark indigo outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A large, elegant glider with four long tapered wings in two pairs, rich mid-violet with lighter lavender highlights and pale star dots along the edges, and a long slim tail. Three-quarter view facing left, gliding in mid-air, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 24. Netherpod > Chasmshell > Astralcarapace (Void)

`id: netherpod` | key: **green #00FF00** | ratio: **structure** | outline: dark indigo | note: Void: green key, mid-violet body.

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
Redraw the same character as the reference image as its final form, a slow void-tortoise. Keep the same big round pale-lavender eyes and the same kind face, the same dark indigo outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A huge, slow, gentle tortoise with a domed shell of rich mid-violet plates that carries a small swirling nebula painted in lavender and pale blue inside a crisp outline, thick stubby legs and the same eyes. Three-quarter view facing left, standing on four thick legs, big and low, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
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
Redraw the same character as the reference image as its second form, a young charred-bark bear. Keep the same round face, the same big warm-brown eyes and the same ash-grey bark colouring with orange cracks, the same dark brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now bigger, with charred black bark plates across its shoulders and back with orange ember cracks between them, small leafy sprigs on its shoulders, and thick strong legs. Three-quarter view facing left, standing on all four legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
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
Redraw the same character as the reference image as its second form, a thorny river otter. Keep the same round face, the same big dark-teal eyes and the same teal-blue fur, the same dark-green outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now bigger and sleeker, with armour-like plates of woven thorny vines over its back and shoulders, small leaf-shaped fins along its flanks, and a longer rippling tail. Three-quarter view facing left, standing on all four legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Thicketwave** (edit, reference = `brambletide-f2.png`, 8 steps, CFG 1.0, file `brambletide-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge wave-crested otter. Keep the same friendly face, the same big round dark-teal eyes, the same small round ears and the same teal-blue fur, the same dark-green outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A large, powerful otter whose back carries a tall crest of vines and broad leaves shaped like a curling wave, thorny vine armour on its shoulders, and a long thick tail with wave-shaped leaf frills. Three-quarter view facing left, standing on all four legs, low, wide and powerful, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 27. Sproutfault > Timbershale > Lumbercrag (Verdant/Telluric)

`id: sproutfault` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark-brown

**Form 1, Sproutfault** (text to image, 8 steps, CFG 1.0, file `sproutfault-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-brown outlines and vibrant saturated colours. A small round mountain goat kid with a grey-brown coat, a cream chin tuft, big round golden eyes, two tiny stone horns, a small green sapling sprouting between the horns, and small hooves. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Timbershale** (edit, reference = `sproutfault-f1.png`, 8 steps, CFG 1.0, file `sproutfault-f2.png`)
```
Redraw the same character as the reference image as its second form, a shale-plated goat. Keep the same round face, the same big golden eyes and the same grey-brown coat, the same dark-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now bigger and sturdier, with layered shale plates over its shoulders and back, longer curved horns of bark and stone with small leaves, and strong legs. Three-quarter view facing left, standing on all four legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Lumbercrag** (edit, reference = `sproutfault-f2.png`, 8 steps, CFG 1.0, file `sproutfault-f3.png`)
```
Redraw the same character as the reference image as its final form, a majestic crag-goat. Keep the same friendly face, the same big round golden eyes and the same cream chin tuft, the same dark-brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A huge, majestic crag-goat with heavy curved stone horns that have small trees growing on them, a body of grey rock plates with moss patches, and thick strong legs. Three-quarter view facing left, standing on all four legs, low, wide and powerful, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 28. Mosscoil > Mossfuse > Canopygrid (Verdant/Voltaic)

`id: mosscoil` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark-green

**Form 1, Mosscoil** (text to image, 8 steps, CFG 1.0, file `mosscoil-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-green outlines and vibrant saturated colours. A small round baby sloth with mossy bright-green fur, a cream face patch, big round dark eyes with a sleepy smile, long arms with small claws, and a small copper wire coil wound around one arm with a tiny yellow zigzag mark on it. Three-quarter view facing left, sitting on the ground, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Mossfuse** (edit, reference = `mosscoil-f1.png`, 8 steps, CFG 1.0, file `mosscoil-f2.png`)
```
Redraw the same character as the reference image as its second form, a wire-woven mossy sloth. Keep the same round sleepy face, the same big dark eyes and the same mossy green fur, the same dark-green outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now bigger, with thick moss on its back and copper wire coils woven through its long fur and around both arms, with small yellow zigzag marks on the coils. Three-quarter view facing left, on all four limbs, slow and heavy, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
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
Redraw the same character as the reference image as its second form, a shale-plated mudskipper. Keep the same big bulging eyes on top of the head and the same brown-blue skin, the same dark navy-blue outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now longer and bigger, with slate-grey shale plates along its back, strong front fins like arms, and a taller dorsal fin. Three-quarter view facing left, propped up on its front fins, low and long, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Bedrocktide** (edit, reference = `mudskulker-f2.png`, 8 steps, CFG 1.0, file `mudskulker-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge bedrock mudskipper. Keep the same big bulging eyes on top of the head, the same wide friendly mouth and the same brown-blue skin, the same dark navy-blue outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A huge, heavy mudskipper with thick bedrock plates over its back, a tall sail-like dorsal fin edged with wave-shaped ripples, and powerful front fins, still with the same friendly eyes. Three-quarter view facing left, propped up on its front fins, low and long, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
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
Redraw the same character as the reference image as its second form, a crystal-quilled porcupine. Keep the same round face, the same big dark eyes and the same grey-brown body, the same dark-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now larger, with long pale-blue crystal quills connected by strands of copper wire, and sturdy legs. Three-quarter view facing left, standing on all four legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Prismvolt** (edit, reference = `geodegrid-f2.png`, 8 steps, CFG 1.0, file `geodegrid-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge prism porcupine. Keep the same friendly face, the same big round dark eyes and the same small dark nose, the same dark-brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A large, majestic porcupine with a great fan of big faceted crystal quills in pale blue and amber connected by copper wire, and thick strong legs. Three-quarter view facing left, standing on all four legs, low, wide and powerful, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 32. Cinderbasin > Steamrill > Kettlebrine (Pyric/Aqueous)

`id: cinderbasin` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark red-brown

**Form 1, Cinderbasin** (text to image, 8 steps, CFG 1.0, file `cinderbasin-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark red-brown outlines and vibrant saturated colours. A small round hippo calf with soft blue-grey skin, an orange-red belly, big round dark eyes, a wide round snout, tiny round ears, stubby legs, and a small shallow basin-shaped dip on its back holding a tiny puddle of water. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Steamrill** (edit, reference = `cinderbasin-f1.png`, 8 steps, CFG 1.0, file `cinderbasin-f2.png`)
```
Redraw the same character as the reference image as its second form, a steaming hippo. Keep the same round face, the same big dark eyes and the same blue-grey skin with an orange belly, the same dark red-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now bigger and heavier, with a wider basin on its back holding a small pool with a thin white steam curl drawn as a crisp outlined shape, and orange-red cinder speckles across its blue-grey skin. Three-quarter view facing left, standing on all four legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
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
Redraw the same character as the reference image as its second form, a young stallion. Keep the same round face, the same big amber eyes and the same orange-red coat with the yellow blaze, the same dark red-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a longer, taller young stallion with a mane and tail of orange flame shapes, yellow lightning-bolt patterns on its flanks and strong legs. Three-quarter view facing left, standing on all four legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
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
Redraw the same character as the reference image as its second form, a sleek sea lion. Keep the same round face, the same big dark eyes and the same blue-grey pelt, the same dark navy-blue outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a longer, sleeker sea lion with strong front flippers, curved yellow lightning stripes across its blue-grey coat, and a larger core gem in its chest. Three-quarter view facing left, resting on its front flippers with its head high, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
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
Redraw the same character as the reference image as its second form, a young star-marked owl. Keep the same big pale-lavender eyes and the same mid-violet feathers with lighter lavender highlights, the same dark indigo outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now bigger, with a crest of branch-like feathers on its head carrying several small pale-gold buds, tiny pale star dots across its wings, and longer wings folded at its sides. Three-quarter view facing left, perched on two legs, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
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
Redraw the same character as the reference image as its second form, a young pangolin with fissured plates. Keep the same big pale-lavender eyes and the same mid-violet and slate-grey colouring, the same dark indigo outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now longer and larger, with big overlapping stone plates in slate-grey and mid-violet with thin pale-lavender crack lines painted between them, and a long thick tail. Three-quarter view facing left, standing on all four legs, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Abysscrag** (edit, reference = `nullshale-f2.png`, 8 steps, CFG 1.0, file `nullshale-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge cragged pangolin. Keep the same big round pale-lavender eyes and the same small pointed snout, the same dark indigo outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A huge, heavy pangolin with jagged crag-like rock plates in slate-grey and mid-violet, pale-lavender crack lines painted between them, strong claws and a long heavy tail. Three-quarter view facing left, standing on all four legs, low, wide and powerful, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 37. Gloamforge > Muteember > Hushkiln (Void/Pyric)

`id: gloamforge` | key: **green #00FF00** | ratio: **animal** | outline: dark indigo | note: Void: green key, mid-violet body (not black: black vanishes on the dark plate).

**Form 1, Gloamforge** (text to image, 8 steps, CFG 1.0, file `gloamforge-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark indigo outlines and vibrant saturated colours. A small round bull calf with glossy obsidian-like skin in rich mid-violet with lighter lavender highlights, thin dull orange ember cracks painted on its shoulders, big round pale-lavender eyes, small blunt horns and small hooves. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Muteember** (edit, reference = `gloamforge-f1.png`, 8 steps, CFG 1.0, file `gloamforge-f2.png`)
```
Redraw the same character as the reference image as its second form, a young bull. Keep the same big pale-lavender eyes and the same mid-violet obsidian colouring with dull orange cracks, the same dark indigo outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now bigger and heavier, with violet-grey iron plates over its shoulders, longer curved horns, and dull orange ember cracks across its body. Three-quarter view facing left, standing on all four legs, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
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
Redraw the same character as the reference image as its second form, a bigger octopus with flowing tentacles. Keep the same big pale-lavender eyes and the same mid-violet colouring with pale-blue stripes, the same dark indigo outlines and the same art style. Make it noticeably larger and more complex overall. Now bigger, with eight long tentacles curling in flowing stream-like shapes, pale-blue stripes along each tentacle, and the same face. Three-quarter view facing left, floating in mid-air with its tentacles curling, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Riftcurrent** (edit, reference = `hushflow-f2.png`, 8 steps, CFG 1.0, file `hushflow-f3.png`)
```
Redraw the same character as the reference image as its final form, a giant elegant octopus. Keep the same big round pale-lavender eyes and the same calm smile, the same dark indigo outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A giant, elegant octopus with a large domed head, long tentacles spiralling in smooth curves, pale-blue stripes and small pale star dots along them, and a calm expression. Three-quarter view facing left, floating in mid-air with its tentacles curling, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
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
Redraw the same character as the reference image as its final form, the great lattice star. Keep the same two big round pale-lavender eyes, the same dark indigo outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A large, intricate star-shaped lattice of copper wire rings and mid-violet metal struts around a deeper-violet core with the same eyes, and a small yellow star-shaped centre piece, grand and complex. Three-quarter view facing left, floating in mid-air, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

## Special recipes, Chunk 2 (names provisional)

### 40. Gravelnip > Reefpincer > Boulderclaw (Telluric/Aqueous)

`id: gravelnip` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark-brown

**Form 1, Gravelnip** (text to image, 8 steps, CFG 1.0, file `gravelnip-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-brown outlines and vibrant saturated colours. A small round crab with a slate-grey shell veined in teal, big round dark eyes on short stalks, one oversized claw and one small claw, six stubby legs, and a tiny blue puddle painted in a hollow of its shell. Three-quarter view facing left, standing on its legs, claws forward, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Reefpincer** (edit, reference = `gravelnip-f1.png`, 8 steps, CFG 1.0, file `gravelnip-f2.png`)
```
Redraw the same character as the reference image as its second form, a reef-pincer crab. Keep the same face, the same big dark eyes and the same slate-grey and teal colouring, the same dark-brown outlines and the same art style. Make it noticeably larger and more complex overall. Now bigger, with a wide layered slate shell veined in teal, a larger oversized claw with ridges, and stronger legs. Three-quarter view facing left, standing on its legs, claws forward, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Boulderclaw** (edit, reference = `gravelnip-f2.png`, 8 steps, CFG 1.0, file `gravelnip-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge boulder-clawed crab. Keep the same big round dark eyes on short stalks, the same dark-brown outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A huge crab with a boulder-like oversized claw of grey rock, a broad heavy shell with teal veins and a small tide pool with a tiny reed set in a hollow of the shell, drawn inside crisp outlines. Three-quarter view facing left, standing on its legs, claws forward, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 41. Ripplesnap > Slatesnout > Ridgehide (Telluric/Aqueous)

`id: ripplesnap` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark olive-green

**Form 1, Ripplesnap** (text to image, 8 steps, CFG 1.0, file `ripplesnap-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark olive-green outlines and vibrant saturated colours. A small round baby crocodile with a broad snout, mottled stone-grey and marsh-green skin, a short ridged back, big round golden eyes, a friendly closed-mouth smile with one tiny quartz-coloured tooth showing, and short stubby legs. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Slatesnout** (edit, reference = `ripplesnap-f1.png`, 8 steps, CFG 1.0, file `ripplesnap-f2.png`)
```
Redraw the same character as the reference image as its second form, a slate-snouted crocodile. Keep the same broad face, the same big golden eyes and the same mottled stone-grey and marsh-green skin, the same dark olive-green outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now longer and bigger, with a broad slate-grey snout, a ridged back of stone plates, and strong short legs. Three-quarter view facing left, standing on all four legs, low and long, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Ridgehide** (edit, reference = `ripplesnap-f2.png`, 8 steps, CFG 1.0, file `ripplesnap-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge ridge-hided crocodile. Keep the same broad friendly face, the same big round golden eyes and the same marsh-green colouring, the same dark olive-green outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A huge crocodile with heavy ridged stone-like hide, a wide snout with a few pale quartz teeth, thick strong legs and a long powerful tail. Three-quarter view facing left, standing on all four legs, low and long, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 42. Cairnflit > Pumiceglide > Fluxwing (Telluric/Voltaic)

`id: cairnflit` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark-brown

**Form 1, Cairnflit** (text to image, 8 steps, CFG 1.0, file `cairnflit-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-brown outlines and vibrant saturated colours. A small round bat with dusky brown fur, big round ears, big round dark eyes, small wings edged in thin copper thread, and a small quartz chime hanging at its throat. Three-quarter view facing left, hovering in mid-air with its wings half open, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Pumiceglide** (edit, reference = `cairnflit-f1.png`, 8 steps, CFG 1.0, file `cairnflit-f2.png`)
```
Redraw the same character as the reference image as its second form, a pumice-winged bat. Keep the same big round ears, the same big dark eyes and the same dusky brown fur with copper-edged wings, the same dark-brown outlines and the same art style. Make it noticeably larger and more complex overall. Now bigger, with larger wings edged in copper thread, stone-grey patches like pumice on its shoulders, and a larger quartz chime at its throat. Three-quarter view facing left, hovering in mid-air with its wings half open, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Fluxwing** (edit, reference = `cairnflit-f2.png`, 8 steps, CFG 1.0, file `cairnflit-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge flux-winged bat. Keep the same big round ears, the same big round dark eyes and the same dusky brown fur, the same dark-brown outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A large bat with big broad wings edged in copper thread and marked with yellow zigzag lines, thick fur, and a big quartz chime at its throat. Three-quarter view facing left, hovering in mid-air with its wings half open, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 43. Flintlamb > Ampcurl > Mesahorn (Telluric/Voltaic)

`id: flintlamb` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark-brown

**Form 1, Flintlamb** (text to image, 8 steps, CFG 1.0, file `flintlamb-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-brown outlines and vibrant saturated colours. A small round lamb with a curly cream fleece, big round dark eyes, tiny spiral horns of banded stone, small hooves, and a few tiny yellow zigzag marks at the tips of its fleece. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Ampcurl** (edit, reference = `flintlamb-f1.png`, 8 steps, CFG 1.0, file `flintlamb-f2.png`)
```
Redraw the same character as the reference image as its second form, a young ram. Keep the same round face, the same big dark eyes and the same cream curly fleece, the same dark-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a sturdy young ram with larger spiral horns of banded stone, a thick cream fleece with yellow zigzag marks at the tips, and strong legs. Three-quarter view facing left, standing on all four legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Mesahorn** (edit, reference = `flintlamb-f2.png`, 8 steps, CFG 1.0, file `flintlamb-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge mesa-horned ram. Keep the same friendly face and the same big round dark eyes, the same dark-brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A huge ram with massive spiral horns of layered banded rock like mesa cliffs, a thick cream fleece with yellow zigzag marks, and a broad powerful chest. Three-quarter view facing left, standing on all four legs, low, wide and powerful, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 44. Coralpeep > Flarewade > Pyreplume (Pyric/Aqueous)

`id: coralpeep` | key: **green #00FF00** | ratio: **animal** | outline: dark red-brown | note: Pink creature: GREEN key (magenta would eat the feathers). Cut out with --bg #00FF00 and without --halo-strict.

**Form 1, Coralpeep** (text to image, 8 steps, CFG 1.0, file `coralpeep-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark red-brown outlines and vibrant saturated colours. A small round flamingo chick with fluffy rosy-pink feathers shading to orange at the tips, big round dark eyes, a short bent orange beak, thin legs, and a small ruffle of orange feathers on its tail. Three-quarter view facing left, standing on two thin legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure green background (#00FF00), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Flarewade** (edit, reference = `coralpeep-f1.png`, 8 steps, CFG 1.0, file `coralpeep-f2.png`)
```
Redraw the same character as the reference image as its second form, a wading flamingo. Keep the same round face, the same big dark eyes and the same rosy-pink and orange colouring, the same dark red-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now taller, with a long neck, long thin legs, orange-tipped rosy feathers and a bigger ruffle of plumes. Three-quarter view facing left, standing on two long thin legs, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Pyreplume** (edit, reference = `coralpeep-f2.png`, 8 steps, CFG 1.0, file `coralpeep-f3.png`)
```
Redraw the same character as the reference image as its final form, a majestic flamingo. Keep the same friendly face, the same big round dark eyes and the same rosy-pink feathers, the same dark red-brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A tall, majestic flamingo with a great fan of plumes in orange and red drawn as crisp flat feather shapes, a long graceful neck and long thin legs. Three-quarter view facing left, standing on two long thin legs, tall and proud, full body, centred, on a solid bright saturated pure green background (#00FF00), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 45. Drizzlenub > Brooksoak > Lavabask (Pyric/Aqueous)

`id: drizzlenub` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark red-brown

**Form 1, Drizzlenub** (text to image, 8 steps, CFG 1.0, file `drizzlenub-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark red-brown outlines and vibrant saturated colours. A small round capybara pup with damp chestnut-brown fur, big round unbothered dark eyes, a blunt round snout, tiny round ears, short stubby legs, an orange-red patch on its belly, and a tiny white steam curl above its head drawn as a crisp outlined shape. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Brooksoak** (edit, reference = `drizzlenub-f1.png`, 8 steps, CFG 1.0, file `drizzlenub-f2.png`)
```
Redraw the same character as the reference image as its second form, a larger capybara. Keep the same round face, the same big unbothered dark eyes and the same chestnut fur, the same dark red-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now bigger and rounder, with water-beaded chestnut fur, a small green leaf resting on its head, and the orange-red patch on its belly. Three-quarter view facing left, standing on all four legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Lavabask** (edit, reference = `drizzlenub-f2.png`, 8 steps, CFG 1.0, file `drizzlenub-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge basking capybara. Keep the same friendly face, the same big unbothered dark eyes and the same chestnut fur, the same dark red-brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A huge, relaxed capybara with a big orange-red patch on its belly, small orange-red lava-rock patches on its back, a tiny white steam curl above its head drawn as a crisp outlined shape, and a sleepy content face. Three-quarter view facing left, sitting on the ground, huge and round, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 46. Coalgrub > Arcflicker > Blazefly (Pyric/Voltaic)

`id: coalgrub` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark brown

**Form 1, Coalgrub** (text to image, 8 steps, CFG 1.0, file `coalgrub-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark brown outlines and vibrant saturated colours. A small round firefly with a dark glossy shell, big round friendly dark eyes, two short antennae, six tiny legs, small folded wings, and a round amber-orange lamp-shaped patch on its belly with a thin blue line across it. Three-quarter view facing left, hovering in mid-air, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Arcflicker** (edit, reference = `coalgrub-f1.png`, 8 steps, CFG 1.0, file `coalgrub-f2.png`)
```
Redraw the same character as the reference image as its second form, an arc-winged firefly. Keep the same big round dark eyes and the same dark-shelled body with the amber lamp, the same dark brown outlines and the same art style. Make it noticeably larger and more complex overall. Now bigger, with larger wings patterned with yellow zigzag lines, a bigger amber-orange lamp patch on its belly, and the same face. Three-quarter view facing left, hovering in mid-air, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Blazefly** (edit, reference = `coalgrub-f2.png`, 8 steps, CFG 1.0, file `coalgrub-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge blaze-winged firefly. Keep the same big round friendly dark eyes and the same dark glossy shell, the same dark brown outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A large firefly with wide wings patterned in orange and yellow flame shapes drawn as crisp flat shapes, a big amber-orange lamp patch on its belly, and the same friendly face. Three-quarter view facing left, hovering in mid-air, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 47. Boltkit > Brandtail > Scorchfox (Pyric/Voltaic)

`id: boltkit` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark red-brown

**Form 1, Boltkit** (text to image, 8 steps, CFG 1.0, file `boltkit-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark red-brown outlines and vibrant saturated colours. A small round fox kit with russet fur, a cream chest, big round dark eyes, pointed ears, a bushy tail tipped in bright orange, and a thick puffy ruff around its neck. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Brandtail** (edit, reference = `boltkit-f1.png`, 8 steps, CFG 1.0, file `boltkit-f2.png`)
```
Redraw the same character as the reference image as its second form, a young fox. Keep the same round face, the same big dark eyes and the same russet fur with the orange-tipped tail, the same dark red-brown outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a sleeker young fox with longer legs, a bushy tail with a flame-shaped orange tip and yellow zigzag marks, and a bigger ruff. Three-quarter view facing left, standing on all four legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Scorchfox** (edit, reference = `boltkit-f2.png`, 8 steps, CFG 1.0, file `boltkit-f3.png`)
```
Redraw the same character as the reference image as its final form, a majestic fox. Keep the same friendly face, the same big round dark eyes, the same pointed ears and the same russet fur, the same dark red-brown outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A large, elegant fox with a big ruff, a huge bushy tail with a flame-shaped orange tip, and yellow lightning-bolt markings on its flanks. Three-quarter view facing left, standing on all four legs, tall and elegant, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 48. Eddyelver > Kelpeel > Dynamoeel (Aqueous/Voltaic)

`id: eddyelver` | key: **magenta #FF00FF** | ratio: **structure** | outline: dark navy-blue

**Form 1, Eddyelver** (text to image, 8 steps, CFG 1.0, file `eddyelver-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark navy-blue outlines and vibrant saturated colours. A small eel with a smooth silver body, a rust-orange underside and pale-blue bands along it, big round friendly dark eyes, a small round face and a tiny tail fin. Three-quarter view facing left, curled in a loose S-shape with its head raised, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Kelpeel** (edit, reference = `eddyelver-f1.png`, 8 steps, CFG 1.0, file `eddyelver-f2.png`)
```
Redraw the same character as the reference image as its second form, a kelp-frilled eel. Keep the same small round face, the same big dark eyes and the same silver body with pale-blue bands, the same dark navy-blue outlines and the same art style. Make it noticeably larger and more complex overall. Now a longer, thicker eel with frilled fins like kelp leaves along its back, the same silver body and pale-blue bands, and the same face. Three-quarter view facing left, curled in a loose S-shape with its head raised, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Dynamoeel** (edit, reference = `eddyelver-f2.png`, 8 steps, CFG 1.0, file `eddyelver-f3.png`)
```
Redraw the same character as the reference image as its final form, a huge electric eel. Keep the same small round face and the same big round friendly dark eyes, the same dark navy-blue outlines and the same art style. Make it much larger, grander and more intricate overall, clearly the biggest and most impressive form. A very long, thick eel curled in a big loop, silver with pale-blue bands and small yellow lightning marks along its body, a rust-orange underside, and a calm face. Three-quarter view facing left, curled in a big loop with its head raised, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

### 49. Sprayfledge > Pulsedart > Voltfisher (Aqueous/Voltaic)

`id: sprayfledge` | key: **magenta #FF00FF** | ratio: **animal** | outline: dark navy-blue

**Form 1, Sprayfledge** (text to image, 8 steps, CFG 1.0, file `sprayfledge-f1.png`)
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark navy-blue outlines and vibrant saturated colours. A small round kingfisher chick with a cobalt-blue back, an amber chest, big round dark eyes, a long dark beak, and thin copper pinstripes on its wings. Three-quarter view facing left, perched on two thin legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, no light rays, no sparkles, no scenery, no text, no watermark.
```
**Form 2, Pulsedart** (edit, reference = `sprayfledge-f1.png`, 8 steps, CFG 1.0, file `sprayfledge-f2.png`)
```
Redraw the same character as the reference image as its second form, a young kingfisher. Keep the same round face, the same big dark eyes and the same cobalt and amber colouring, the same dark navy-blue outlines and the same art style. Change the body proportions: a longer, sturdier body about three times the size of the head, longer stronger limbs, and a head noticeably smaller in proportion to the body. Now a sleeker young kingfisher with a longer dark beak, brighter copper pinstripes on its wings and a longer tail. Three-quarter view facing left, perched on two thin legs, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```
**Form 3, Voltfisher** (edit, reference = `sprayfledge-f2.png`, 8 steps, CFG 1.0, file `sprayfledge-f3.png`)
```
Redraw the same character as the reference image as its final form, a majestic kingfisher. Keep the same friendly face and the same big round dark eyes, the same dark navy-blue outlines and the same art style. Change the body proportions dramatically: a large, powerful, broad-chested body about four times the size of the head, thick strong limbs, noticeably larger and more massive overall, and a head much smaller in proportion to the body. A large, poised kingfisher with a long lance-like dark beak, a cobalt back with copper pinstripes and small yellow zigzag marks, and an amber chest. Three-quarter view facing left, perched upright, poised, looking forward, full body, centred, on a solid bright saturated pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow effect, no halo.
```

## Still to write (once the names are final)

- **Chunk 1 specials (10):** the corrected result was never pasted. The renames locked earlier were Sorrelcliff, Rowanboulder, Hazelslate, Nettlemesa, Brackensear, Yarrowflare, Sedgestilt, Ivyflux, Burrbolt and Cliffscorch (for the Verdant/Telluric, Verdant/Pyric, Verdant/Aqueous, Verdant/Voltaic and Telluric/Pyric pairs). Their animals and later forms are unknown here.
- **Chunk 3 specials (10):** the five Void pairs, not written yet.
- **Template for a new creature:** copy any `C(...)` entry in `D:\AI\tools\build_prompts.py`, fill the fields, and rerun.

## Records

- These prompts are the AI-disclosure record for the sprites, together with `docs/art-pipeline.md` (tool: ComfyUI on the designer's machine; model: FLUX.2 [klein] 4B distilled fp8, Apache 2.0). Keep this file with the approved images.
- Sproutlet and Emberfang were generated before this file existed; their exact prompts are in `docs/art-pipeline.md` (Sproutlet) and the session history (Emberfang).
