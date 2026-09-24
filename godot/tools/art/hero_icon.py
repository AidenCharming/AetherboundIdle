"""One-off hero art (the game's app icon) with FLUX.2 [klein] base 4B: the undistilled model, many steps, real CFG and a
negative prompt. The icon pipeline (icon_runner.py) stays on the fast distilled model; this is for single showpiece images.

    python hero_icon.py run --count 5 --steps 30 --cfg 3.75     candidates -> ComfyUI output/hero/app-icon-c<N>_00001_.png
    python hero_icon.py run --count 1 --steps 50                 one image, to time a step count

Seconds per image are printed, so the step count can be tuned to the time budget. Edit PROMPT / NEGATIVE below.
Uses batch_runner.py (D:\\AI\\tools) for the ComfyUI calls and the distilled text-to-image graph as the template.
"""
import argparse
import json
import random
import sys
import time
from pathlib import Path

sys.path.insert(0, r"D:\AI\tools")
import batch_runner as br  # noqa: E402

BASE_MODEL = "flux-2-klein-base-4b-fp8.safetensors"
OUT_PREFIX = "hero/app-icon"

PROMPT = (
    "A game app icon for a cute creature-collecting fantasy idle game, in a soft painterly digital illustration style "
    "with clean thick dark indigo outlines, chunky cartoon proportions and vibrant saturated colours. "
    "A rounded-square badge with a thick polished gold rim and a dark indigo outline fills almost the whole frame. "
    "Inside the badge, a deep twilight sky of indigo and teal with a few tiny pale stars, and a small floating island "
    "of grassy grey rock drifting in the sky, with a few small rocks hanging beneath it. "
    "Sitting on the island is one cute chubby fox-like creature with big round dark-blue eyes, a small smile, soft "
    "cream and pale-cyan fur, large rounded ears and a small faceted pale-cyan crystal on its forehead. It hugs a "
    "round capture orb of cyan glass with a polished silver band around its middle and a bright white core. "
    "The creature and the orb are large and centred and fill most of the badge: a bold, simple silhouette that "
    "still reads clearly at a small size, lit warmly from the upper left. "
    "Outside the badge the background is solid pure magenta (#FF00FF), completely flat, with no shadow."
)
NEGATIVE = (
    "text, letters, words, title, logo lettering, numbers, watermark, signature, "
    "more than one creature, extra limbs, extra eyes, deformed paws, "
    "cropped, cut off, badge touching the edge of the image, drop shadow, floor shadow, "
    "blurry, muddy colours, dull colours, noise, grain, photorealistic, 3d render, "
    "cluttered, busy background, magenta inside the badge"
)

CFG_NODE, NEG_NODE, CLIP_NODE, UNET_NODE = "77:90", "77:91", "77:88", "77:87"


def build(prompt, negative, seed, steps, cfg, prefix):
    g = json.loads((br.WORKFLOWS / br.T2I["file"]).read_text(encoding="utf-8"))
    g[br.T2I["prompt"]]["inputs"]["value"] = prompt
    g[br.T2I["seed"]]["inputs"]["noise_seed"] = seed
    g[br.T2I["steps"]]["inputs"]["steps"] = steps
    g[br.T2I["save"]]["inputs"]["filename_prefix"] = prefix
    g[UNET_NODE]["inputs"]["unet_name"] = BASE_MODEL
    g[CFG_NODE]["inputs"]["cfg"] = cfg
    # the distilled graph zeroes the negative (cfg 1 ignores it); the base model gets a real negative prompt
    g[NEG_NODE] = {"class_type": "CLIPTextEncode", "inputs": {"text": negative, "clip": [CLIP_NODE, 0]}}
    return g


def existing():
    d = br.COMFY_OUT / Path(OUT_PREFIX).parent
    return [int(p.name.split("-c")[1].split("_")[0]) for p in d.glob(Path(OUT_PREFIX).name + "-c*_00001_.png")] if d.exists() else []


def cmd_run(a):
    if not br.comfy_up():
        sys.exit(f"ComfyUI is not answering at {br.HOST}. Start D:\\AI\\ComfyUI\\run_nvidia_gpu.bat first.")
    start = max(existing(), default=0) + 1
    print(f"{a.count} image(s), {a.steps} steps, cfg {a.cfg}, candidates {start}-{start + a.count - 1}")
    for n in range(start, start + a.count):
        seed = random.SystemRandom().randrange(1, 2**50)
        t = time.time()
        img = br.wait_for(br.queue(build(PROMPT, NEGATIVE, seed, a.steps, a.cfg, f"{OUT_PREFIX}-c{n}")))
        print(f"  c{n}: {time.time() - t:.0f} s  seed {seed}  -> {img['subfolder']}/{img['filename']}")


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    r = sub.add_parser("run")
    r.add_argument("--count", type=int, default=5)
    r.add_argument("--steps", type=int, default=30)
    r.add_argument("--cfg", type=float, default=3.75)
    a = p.parse_args()
    {"run": cmd_run}[a.cmd](a)


if __name__ == "__main__":
    main()
