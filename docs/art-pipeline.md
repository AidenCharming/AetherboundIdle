# Art pipeline: creature sprites (local AI generation)

Status (2026-09-21): pipeline proven end to end on ONE line (Sproutlet, forms 1 to 3). Nothing is wired into the game yet; the game still uses emoji placeholders. The tools and files live OUTSIDE the repo, under `D:\AI\`. This file is the record of what was decided and how to repeat it.

## Why local
The designer ran out of Gemini quota and wanted unlimited free generation. The machine can do it: RTX 4060 Laptop (8 GB dedicated VRAM, 47.6 GB shared = system RAM), 64 GB RAM, D: is a 2 TB NVMe drive.

## What is installed (all under `D:\AI\`, nothing in the repo)
| Item | Where | Notes |
|---|---|---|
| ComfyUI v0.36.0 portable (nvidia) | `D:\AI\ComfyUI\` | Start with `run_nvidia_gpu.bat`; UI at http://127.0.0.1:8188. The `.7z` it came from is still in `D:\AI\` and can be deleted. |
| `flux-2-klein-4b-fp8.safetensors` (4.07 GB) | `...\models\diffusion_models\` | **The model in use.** FLUX.2 [klein] 4B distilled, fp8. Apache 2.0 (model card and the repo's LICENSE.md). From `black-forest-labs/FLUX.2-klein-4b-fp8`. |
| `qwen_3_4b.safetensors` (8.04 GB) | `...\models\text_encoders\` | Text encoder for klein. From `Comfy-Org/flux2-klein-4B`. |
| `flux2-vae.safetensors` (336 MB) | `...\models\vae\` | From `Comfy-Org/flux2-klein-4B`. |
| `sd_xl_base_1.0.safetensors`, `flux1-schnell-fp8.safetensors` | `...\models\checkpoints\` | Early experiments, superseded. Can be deleted. |
| Approved sprites | `D:\AI\sprites\approved\` | `sproutlet-f1.png`, `-f2.png`, `-f3.png` (final, the heavy redraw) and `-f3v1.png` (the lighter antler-canopy version, kept as an alternate) |

**Not downloaded, on purpose:** `flux-2-klein-base-4b-fp8.safetensors` (4.09 GB, same Apache repo family), the 9B klein models (licence not verified, believed non-commercial), and anything from the FLUX.1 [dev] family (Redux, Kontext): their licence lets you use OUTPUTS commercially but restricts using the model itself to non-commercial purposes, which is a grey area for a pipeline that feeds a commercial game. Prefer Apache-licensed components for anything that ships. If a background-removal model is ever used, avoid BRIA RMBG-2.0 (non-commercial); BiRefNet (MIT) or `rembg` are fine. A plain hue-based chroma key should be enough and needs no model.

## The workflow (three stages, all with the same model)
1. **Form 1: text to image.** ComfyUI template "Flux.2 [Klein] 4B: Text to Image", the Distilled graph (bypass the other). **4 steps, CFG 1.0**, 1024x1024. About **4.4 s per image**. Five candidates, pick one.
2. **Form 2: image edit.** Template "Flux.2 [Klein] 9B: Image Edit" with the 9B model files swapped for the 4B ones (`flux-2-klein-4b-fp8`, `qwen_3_4b`, `flux2-vae`). Inside the subgraph: Flux2Scheduler steps **8**, CFG Guider **cfg 1.0** (the template default is 20 steps and cfg 5.0, which took about 90 s per image; 4 steps takes about 9 s; **8 steps about 18 s** and gave the crispest bark). Reference image = the approved Form 1.
3. **Form 3: image edit**, same graph, reference = the approved Form 2.
Each stage: run 5 candidates (set the number beside the Run button to 5), pick the best, copy it to the approved folder as `<species-id>-f<n>.png`.

## Prompts that worked (Sproutlet)
Style block, reused for every creature: *soft painterly digital illustration with clean dark-green outlines and vibrant saturated colours* (the outline colour should follow the creature's type), ending with *three-quarter view facing left, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow, no scenery, no text, no watermark.* Klein's text encoder reads plain sentences; do not use weight syntax like `(word:1.4)`, and never paste citation tags such as `[cite: 1]`. The distilled model ignores negative prompts, so phrase everything positively.

**Form 1 (text to image), the slim quadruped that was approved (`sproutlet-f1.png`):**
```
A cute creature design for a mobile idle game, in a soft painterly digital illustration style with clean dark-green outlines and vibrant saturated colours. A tiny leafy four-legged creature with slim young-animal proportions: a small compact round green body about the same size as its head, on four slender but sturdy legs with small clawed feet, a big round head with a smooth rounded face, huge glossy dark-blue eyes with white highlights, a tiny smile and no snout, and a small leaf-shaped tail. A small sapling with five bright leaves sprouts from the top of its head, and a collar of broad green leaves wraps around its neck. Three-quarter view facing left, standing on all four legs, full body visible and centred, filling about 70 percent of the frame with clear margin. Solid pure magenta background (#FF00FF), evenly lit and completely flat, with no floor, no shadow, no glow, no scenery, no text, no watermark.
```

**Form 2 (edit, 8 steps, cfg 1.0), approved as `sproutlet-f2.png`:**
```
The same character as the reference image, grown up into its second form. Keep the same round head, the same huge glossy dark-blue eyes, the same green skin, the same dark-green outlines and the same art style. Now larger and sturdier, with longer, stronger legs wrapped in brown bark plating, a bark-armor shell across its back and shoulders, and two small wooden antler buds with tiny leaves growing beside the sapling. Keep the leaf collar and the leaf tail. Three-quarter view facing left, full body, centred, on a solid pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow.
```

**Form 3, first version (edit, 8 steps, cfg 1.0; reference = Form 2), kept as `sproutlet-f3v1.png` (the lighter antler-canopy version):**
```
The same character as the reference image, grown into its final majestic form. Keep the same round head, the same huge glossy dark-blue eyes, the same blush and gentle smile, the same green skin, the same dark-green outlines and the same art style. Now much larger and taller, a noble stag-like forest beast standing on all four legs, not upright: thick bark armor across its shoulders and back, strong bark-wrapped legs, and a grand symmetrical canopy of branching wooden antlers covered in bright green leaves, growing only from the top of its head with no loose or stray branches, with a few leaves glowing softly from within. Keep the sapling at the centre of its head, the leaf collar, and the bark tail. Three-quarter view facing left, full body, centred, on a solid pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow outside the silhouette.
```

**Form 3, final (a "redraw" of the first Form 3, 8 steps, cfg 1.0; reference = `sproutlet-f3v1.png`), approved as `sproutlet-f3.png` (it is `sproutlet-f3ref_00010_.png`, chosen from candidates 6 to 10):**
```
Redraw the same character as the reference image as an ancient, hulking guardian form. Keep the same face, the same huge glossy dark-blue eyes, the same gentle smile, the same green skin, the same dark-green outlines and the same art style. Change the body proportions dramatically: a massive broad chest and body about three times the size of the head, thick trunk-like legs, heavy stacked bark-plate armor across the shoulders and back, and the head much smaller in proportion to the body. Keep the grand canopy of leafy antlers with a few leaves glowing softly from within, the sapling, the leaf collar and the bark tail. Standing on all four legs, low, wide and powerful. Three-quarter view facing left, full body, centred, on a solid pure magenta background (#FF00FF), evenly lit and completely flat, no shadow, no glow outside the silhouette.
```
So the approved chain is: F1 (text to image) -> F2 (edit of F1) -> F3v1 (edit of F2) -> F3 (redraw of F3v1).

## Lessons learned
- Klein follows prompts far better than FLUX.1 schnell (a "biped" is drawn as a biped), and its edit mode keeps the face and style of the reference almost perfectly. Chaining forms (each form's reference is the previous approved form) works.
- Ask for the **stance explicitly** in edit prompts ("standing on all four legs, not upright"); otherwise some candidates stand upright. Upright bipeds can look good and may suit a later evolution.
- The **body barely grows** in the edit: klein preserves proportions. If a form should be visibly bigger or leggier, say so in words ("noticeably longer legs, a larger broader body, a head smaller in proportion to the body").
- Glow words make a halo around the silhouette that ruins cut-outs. Keep glow inside the silhouette ("leaves glowing softly from within").
- Counts (leaves on the sapling) are only roughly followed. The magenta background comes out as slightly different shades and a faint contact shadow remains; a **hue-based chroma key** removes both because the shadow is the same hue.
- Void creatures are purple, close to magenta: use a different key colour (green or cyan) for them. Choose the key colour per type when the batch script is written.
- Stray artefacts to reject when picking: extra twigs or floating leaves, a second head-like blob, one-eyed faces, a stray signature in a corner.

## Bulk test (2026-09-21): how far can an edit change the body?
Two reference images, five candidates each, 8 steps, cfg 1.0 (about 18 s per image):
- **"Edit" wording, reference = Form 2** ("redrawn as a much bulkier, heavier form", `sproutlet-f3alt_*`): failed to bulk up; the body stayed at Form 2's chibi size and only gained a bark cape.
- **"Edit" wording, reference = approved Form 3** (`sproutlet-f3ref_00001` to `_00005`): added heavy bark plates and pauldrons but the proportions barely moved.
- **"Redraw" wording, same prompt with the sentence starting "redraw the same character as the reference image…"** (`sproutlet-f3ref_00006` to `_00010`): this DID change proportions. Body clearly larger and heavier, thick trunk legs, head smaller relative to the body, face and antler canopy preserved. Designer's picks: 7, 9 and 10 good; 8 good but with a small dark hollow next to the neck; 7 is the most dramatic (barrel shell with rivets).
- **Lesson: start the prompt with "redraw" and give a proportion ratio ("body about three times the size of the head", "head about one third of the total height") when a form must change shape. "Keep the same…" phrasing anchors the reference's proportions.** Use it for any form that should look visibly bigger, taller or bulkier, and keep "keep the same face, eyes, colours, outlines and style" for identity.
- The designer then approved candidate 10 as the final Form 3 (`sproutlet-f3.png`); the lighter antler-canopy version is kept as `sproutlet-f3v1.png` (a possible variant or a shiny/alternate look).

## Base model test (2026-09-21): is `flux-2-klein-base-4b-fp8` worth it?
- **Base at the distilled settings (8 steps, cfg 1.0): unusable.** Mushy, half-finished images, the face and anatomy drifted (`sproutlet-f3baseref_00001` to `_00005`). A base model needs many steps and real guidance; it is not a drop-in swap.
- **Base at proper settings (about 28 steps, cfg about 4, a negative prompt), one image (`sproutlet-f3baseref_00006`):** crisp, clean lines, the face and the glowing antler canopy preserved exactly. But it reinterpreted "bark-plate armor" as carved wooden barrel staves with hoop bands and gave the character humanoid hands, a crafted look rather than the organic bark of Forms 1 and 2, and it costs roughly 2 minutes per image versus 18 s. The approved distilled redraw is more organic and consistent with the rest of the line.
- **Verdict: keep the distilled model (4 steps to explore, 8 steps for finals).** Keep the base file installed; the one case where it may pay off is a mechanical or geometry-heavy species (cogs, wires, robots such as Mossgear, Splashfin, Plasmaplug), where crisp structure matters more than organic style. Retest it on one of those before adopting it.

## Emberfang test (2026-09-21): a second species, a different colour range
Emberfang (Pyric) went through the same three stages to check the style generalises. It does: crisp dark red-brown outlines, flat stylised flames with no halo, amber eyes, cream belly, and the magenta background is fine for an orange creature.
- **Stage 2, first attempt** ("about twice the size of the head", "grown up"): almost no growth; the kitten kept its upright pose and only turned grey with ember cracks. Only one candidate dropped onto four legs.
- **Stage 2, second attempt** ("redraw", **"body about three times the size of the head"**, "head noticeably smaller in proportion to the body", **"prowling on all four legs in a low, stalking walk, not standing upright"**, "a long flaming tail"): a real evolution, every candidate a long, low, four-legged predator with the same face, amber eyes and flame tuft. **Use this recipe.**
- **Proportion ladder (default for animal-shaped creatures):** Form 1 chibi (body about 1x the head), Form 2 about 3x, Form 3 about 4x plus "noticeably larger and more massive overall". State the stance explicitly at every stage.
- **Exceptions to plan per species, not per batch:** creatures that "stay cute" (Cinderpup, Voltfluff) need a milder ladder (about 2x then 2.5x, head kept large); orbs, blobs, floating crystals, machines and insects have no meaningful body-to-head ratio, so describe the structural change in words (more parts, bigger rotor, more rings). Put a per-species growth profile (ratio, stance, what is added) next to the form descriptions when they are written, so the batch script can fill it in.

## The sprite tools script (`D:\AI\tools\sprite_tools.py`)
Runs with ComfyUI's Python (`D:\AI\ComfyUI\python_embeded\python.exe`; Pillow, numpy and scipy are already there). Commands: `cutout` (background removal to transparent, cropped, square PNGs, `--qa` adds a check image over bright cyan), `line` (cut out a set of images and build a side-by-side comparison sheet on a dark plate), `sheet` (same, from images already cut out). Previews and check images go to `D:\AI\sprites\preview\`.
- **The first prototype punched holes in the wood** (dark reddish-brown pixels have a hue near magenta, and it also removed by hue band everywhere). The real script fixes that: the background colour is measured from the border; a pixel is background by colour DIRECTION and chroma, not brightness (so the flat colour, its vignette and the soft shadow all match); only background CONNECTED TO THE BORDER is removed, plus enclosed pockets that are big and unmistakably background, so creature pixels that merely resemble the background can never be punched out; edge pixels get soft alpha and un-mixed colour (no fringe). A `--qa` image over bright cyan is how to spot damage.
- **`--halo` (halo clean):** glowing parts (the Sproutlet Form 3 antler canopy) blend with the magenta and leave a light pink haze. With `--halo` the script removes light, low-chroma tints of the key colour, but ONLY blobs that touch already-transparent area, and only if they are light (so dark outlines and brown wood never qualify). A pink ear or blush cheek enclosed by the creature's own outline is never touched. Checked: it cleans the Sproutlet Form 3 canopy (about 1,800 px) and changes nothing on the Emberfang sprites (0 px) or Sproutlet Forms 1 and 2. Use it for anything with glowing parts. Thresholds are the `HALO_*` constants at the top of the script.
- **`--halo-strict` (opt-in, for sprites with a glowing canopy):** `--halo` deliberately ignores pink pockets that are fully enclosed by foliage, because an enclosed pink pocket looks exactly like a pink ear. In the Sproutlet Form 3 those pockets are background seen through the canopy, tinted by the glow, so `--halo-strict` also removes (1) enclosed dusty-pink pockets, and (2) a salmon-pink fringe within 3 px of transparent area (leaf outlines are dark green and wood has blue well below green, so they do not match). It would also remove a pink ear, so it is chosen per species, never globally. The batch script should read a per-species `glow` flag from the description table and pass `--halo-strict` when it is set. Both Sproutlet Form 3 files (`sproutlet-f3.png`, `sproutlet-f3v1.png`) were cut with it (about 4,000 and 3,400 pixels of haze).
- **Stricter prompting to avoid haze in the first place:** do not ask for "glowing" leaves or light. Ask for painted highlights instead, for example "a few leaves with small pale yellow-green highlights painted on them, no glow effect, no halo, no light rays, no sparkles", and keep any flame or light effect inside crisp outlines. Fewer gaps in a dense canopy also means fewer background pockets to clean.
- If a cut-out fails to save with "Invalid argument", an image viewer has that file open (Windows locks it); close the viewer and rerun.
- Void creatures need `--bg` set to a green or cyan key colour.
- **Approved sprites** (originals in `D:\AI\sprites\approved\`, cut-outs at 512 px in `D:\AI\sprites\cutouts\`, comparison sheets in `D:\AI\sprites\preview\`): Sproutlet f1, f2, f3 (+ f3v1 alternate); Emberfang f1, f2, f3 (Form 3 = the tiger candidate with the realistic tiger face, chosen by the designer over the chibi-faced candidate).
- Pass `--bg #RRGGBB` to override the measured colour; the script prints the measured colour per image.

## Design consequence to reconcile later (do not edit yet)
`docs/content-data.md` describes the Sproutlet as a biped (Form 1) then a quadruped (Form 2). The approved art is a quadruped throughout, with bark armor from Form 2 and a leaf-and-antler canopy at Form 3. Those description lines are placeholders for art prompts, but `test/content.test.ts` checks the JSON against them, so change the doc line and the JSON together in one small build-session step once the designer has settled the forms.

## AI disclosure record (keep this current)
Tool: ComfyUI v0.36.0 on the designer's own machine. Model: FLUX.2 [klein] 4B distilled fp8 (Apache 2.0), text encoder Qwen3 4B, VAE flux2-vae. Prompts: above. Steam (from its January 2026 rules) requires disclosing pre-generated AI art that ships in the game; this record is the answer. Save the two workflow files (ComfyUI, Save, and Export as API format) next to it.

## Not done yet
1. **Save the workflows** (ComfyUI: Ctrl+S on each tab; Export (API) for the batch script). They were still unsaved tabs when this was written. Suggested: `D:\AI\workflows\`.
2. **Test a non-Verdant creature by hand** (suggested: Emberfang, Pyric) through all three stages, to check the style holds across colour ranges and the magenta background works for an orange creature.
3. **Write form descriptions** for the 15 default hybrids and, once they are named, the 30 special recipes. `content-data.md` only has descriptions for the 24 base species.
4. **Batch runner** (a Claude window, outside the repo): reads the descriptions, fills the prompt templates, drives ComfyUI through its local API with the exported API workflows, runs the three stages with five candidates each, makes a contact sheet per stage for the designer to pick from, and names files by id. Resumable.
5. **Post-processing:** hue chroma key per type, crop to the creature, pad to a square, downscale to about 512 px, keep the 1024 px originals in `D:\AI\`.
6. **Wire into the game** (a build session): a `sprite` path per form in the species data, the card and Nexus show it with the emoji as fallback, type-coloured plate behind it (a green creature on a green Verdant tile will blend in: use a darker neutral plate with the type colour as a rim). Sprites go under `src/ui/assets/creatures/`.
7. Eggs, resource and skill icons, vessel icons and zone backgrounds are separate later tasks with the same tools.
