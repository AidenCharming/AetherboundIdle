# Art brief: app background image

Status: image made (Gemini Pro / Nano Banana, 2026-09-20), saved, and **wired in by step 1.9c checkpoint D**. This file stays the source of truth for the prompt, the specs, and where the files go; see
"How it is wired, as built" at the end for what shipped.

## What it is for
One large, atmospheric backdrop behind the whole game window (sidebar, cards, dialogs sit on top of it). It sets the mood (science-fantasy, twilight, Aether) and must **never fight the text**. It is UI chrome, not creature art, so it does not conflict with CLAUDE.md rule 4 (no per-rarity or per-shiny assets).

## Specs the image must meet
- **Landscape 16:9**, at least 2560 x 1440 asked for (3840 x 2160 is better if the tool offers it). The delivered image is 2048 x 1144, which is fine because it sits behind an overlay and is soft by design; on a very large window it is scaled up slightly. The window can be resized down to 375 px wide, so the important light and shapes must **survive being cropped to the centre and to the edges** (the page uses `cover`).
- **Dark and low contrast.** Most of the image in the lowest third of brightness. Nothing near-white large; small pinpoint glows are fine. Text on cards must stay readable without depending on the image.
- **Calm centre, interest at the edges.** No strong focal point in the middle third, where content sits. Soft depth of field, smooth gradients, minimal fine detail.
- **Palette:** deep midnight blue and indigo base (close to the UI's dark background, `#14171c`), teal and violet Aether glows kept dim, tiny warm gold pinpoints that echo the UI's gold accent. Avoid saturated green, orange, blue or yellow areas: those are the type colors and are reserved for creatures.
- **Contents to avoid:** text, letters, logos, watermarks, UI, frames, characters, creatures, real-world IP.
- Gradients in dark images band easily. If banding shows, add a little film grain or noise in any image editor.

## Prompt (recommended: A, "Aether Sanctuary")
Paste into Gemini image generation, aspect ratio 16:9, highest resolution offered.

**A. Aether Sanctuary (recommended)**
```
A vast twilight sanctuary seen from far away, painted in a soft atmospheric digital-painting style. Distant silhouettes of floating stone islands and ancient ring-shaped ruins drift in a deep midnight-blue and indigo sky, fading into haze. Thin streams of dim teal and violet aether light flow between them like slow rivers, and tiny warm gold points of light float in the air like fireflies and faint stars. Heavy atmospheric perspective, out-of-focus depth of field, gentle volumetric mist. Composition: calm and dark in the centre with soft empty space, gentle glows and shapes gathered toward the left, right and bottom edges, a soft vignette. Very low contrast, moody, the whole image dark (most pixels very dark blue), smooth gradients with no harsh highlights. 16:9 widescreen game background. No text, no letters, no logos, no watermark, no characters, no creatures, no user interface, no borders.
```

**B. Misty Grove (more creature-collector, still dark)**
```
A quiet nocturnal clearing seen from a distance, painted in a soft atmospheric digital-painting style: giant ancient trees and mossy standing stones dissolving into deep blue-indigo mist, drifting bioluminescent spores in dim teal and violet, a few tiny warm gold sparks. Out-of-focus foreground foliage silhouettes frame the left and right edges, the centre is calm, dark and empty. Very low contrast, the whole image dark, smooth gradients, gentle volumetric fog. Avoid bright green and orange. 16:9 widescreen game background. No text, no letters, no logos, no watermark, no characters, no creatures, no user interface, no borders.
```

**C. Abstract Aether Flow (safest for readability)**
```
An abstract dark background: slow flowing ribbons of dim teal and violet light drifting across a deep midnight-blue field, faint concentric ring lines and sacred-geometry arcs barely visible, soft bokeh motes, a few tiny warm gold pinpoints. Soft glow gathered at the corners and edges, calm and dark in the centre, smooth gradients, very low contrast, the whole image dark. 16:9 widescreen game background. No text, no letters, no logos, no watermark, no characters, no creatures, no user interface, no borders.
```

## Follow-up prompts (iterate in the same Gemini chat)
- Too bright or busy: `Make it much darker and lower contrast, keep the composition, remove any bright element in the centre.`
- Banding or flat: `Add very subtle fine film grain so the dark gradients do not band.`
- Phone version: `Create a 9:16 portrait version of this exact scene, same palette and style, keeping the calm dark centre.` (optional, see below)
- Variations: `Give me three variations with the glows shifted further toward the corners.`

## Where the files go
| File | Path | Shipped? |
|---|---|---|
| The finished image (this is what the game uses) | `src/ui/assets/background/app-bg.jpg` (2048 x 1144, 292 KB). Renamed from `.png` in 1.9c: it was always JPEG data. | Yes, bundled by Vite into the exe |
| Optional portrait version for phone widths | `src/ui/assets/background/app-bg-portrait.png` (644 x 1144, a real PNG). **Not used**: `cover` with `--bg-position: 74% 50%` frames well at 375 px, so the landscape file serves every width. Kept in case the art is replaced by something that does crop badly. Unreferenced, so Vite does not bundle it. | No (kept in the repo only) |
| Untouched original from Gemini | `docs/reference/art/background/background-original.png` (identical to app-bg.png) | No (docs are not packaged) |
| The exact prompt used, the tool and model name, and the date | `docs/reference/art/background/background-prompt.txt` | No |

Create the folders if they do not exist. Keep the shipped file to roughly 1 MB or less if you can (in Windows Photos or Paint, "Save as" JPEG is fine); the size only affects load time, since the exe is about 100 MB anyway. **Keep the prompt and tool name**: store rules (Steam and others) can require disclosing AI-generated art, and this record is how the project answers that later.

## Wiring (step 1.9c, the background checkpoint; the exe rebuild at the end of 1.9c carries the image)
The image files above exist. Rename app-bg.png to app-bg.jpg first (it is JPEG data), so the served MIME type is right.
- Reference the image from `src/ui/theme.css` (Vite bundles it and, with `base: './'`, it works from `file://` in the exe). Expose it as a token (for example `--bg-image`) so it is swappable in one place.
- **Guarantee readability regardless of the image:** stack a dark gradient overlay above it (from a `:root` token, no hex outside `:root`, the architecture test enforces that), and keep cards and the sidebar semi-opaque. Check text contrast against the worst-case brightest part of the image.
- `background-size: cover; background-position: center`. Prefer a fixed-position layer (a pseudo-element on the app root) to `background-attachment: fixed`, which can repaint badly. Static only: no animation, no big `backdrop-filter` blur (slow on weak GPUs).
- Use the portrait file below a phone breakpoint if it exists; otherwise the single landscape image is cropped to the centre.
- Keep the window's solid fallback color (`BACKGROUND` in `electron/main.cjs` and `--bg` in the theme, which `test/electron.test.ts` requires to match) so there is no flash before the image loads.
- Add a test that the referenced file exists. Verify at 1280, 1024, 768 and 375 px, screenshot them. The exe rebuild (`npm run electron:pack`) is done by the next step that ships (1.9c), not here.

## How it is wired, as built (step 1.9c checkpoint D)

Four `:root` tokens in `src/ui/theme.css` carry the whole thing, so swapping the art is a one-line change:

| Token | Value | What it does |
|---|---|---|
| `--bg-image` | `url('./assets/background/app-bg.jpg')` | the painting |
| `--bg-scrim` | `linear-gradient(180deg, rgb(13 16 21 / 45%), rgb(13 16 21 / 64%))` | the dark overlay that guarantees readability whatever the image is |
| `--bg-position` | `74% 50%` | off-centre, so a ring island stays in frame down to 375 px (the middle of the painting is deliberately empty) |
| `--panel` / `--panel-raised` | `rgb(20 25 32 / 90%)` / `rgb(26 33 42 / 92%)` | semi-opaque surfaces, so the image shows through without touching text contrast |

Both layers are painted by **one fixed pseudo-element**, `.shell::before` (`z-index: -1`, `pointer-events: none`,
`background-size: cover`), so the sidebar, header, cards, dialogs and toasts all sit over it. Not
`background-attachment: fixed`, which repaints on every scroll frame. Static: no animation, no filter, no backdrop
blur added. `--bg` stays behind it as the solid fallback and still matches `BACKGROUND` in `electron/main.cjs`.

`test/assets.test.ts` guards it: the referenced file exists, the wiring is through the tokens, the layer is static, and
**every file under `src/ui/assets/` really is the format its extension claims** (the trap this image fell into).
