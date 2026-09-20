# Art brief: app background image

Status: image made (Gemini Pro / Nano Banana, 2026-09-20) and saved; not wired in yet. It is wired in by step 1.9c, checkpoint C (see "Wiring" below). This file is the source of truth for the prompt, the specs, and where the files go.

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
| The finished image (this is what the game uses) | `src/ui/assets/background/app-bg.png` (2048 x 1144). **It is really JPEG data with a .png name: rename it to app-bg.jpg when wiring.** | Yes, bundled by Vite into the exe |
| Optional portrait version for phone widths | `src/ui/assets/background/app-bg-portrait.png` (644 x 1144, a real PNG). It is a plain 9:16 crop of the landscape scene, not a separate painting: try CSS `cover` with a `background-position` first and use this file only if that crops badly. | Yes |
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
