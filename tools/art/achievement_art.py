"""Achievement art for Aetherbound: generates, picks and installs the painted achievement tiles through ComfyUI.

Every painting is made in the style of the island battle backdrops (the island-clear achievements show the backdrops
themselves, so the rest must sit beside them): each scene is painted through the edit graph with its island's
backdrop (godot/assets/zones/<island>.jpg) as the first reference image, and, when an Aetherling is in it, that
creature's approved sprite (godot/assets/creatures/<id>-f<form>.png) as the second, so it stays on-model.
The ComfyUI plumbing (HTTP, upload, queue, wait, graph specs) comes from batch_runner.py in D:\\AI\\tools.

Run with plain `python` from the repo root or tools/art:
    python tools/art/achievement_art.py <command> [options]

Commands
  status   [--category skills|nexus|adventure|breeding|secret|all]   approved, candidates waiting, still to do
  prompts  checks the table against data/achievements.json and writes docs/archive/art/art-prompts-achievements.md
           and D:\\AI\\tools\\achievements.json (the prompts as data)
  run      [--category ...] [--only a,b] [--count 4] [--more] [--dry-run]
           generates candidates (1024x1024). Skips approved paintings and ones that already have --count
           candidates; --more adds another --count. Builds a contact sheet at the end.
  sheet    [--category ...] [--only a,b]   numbered contact sheet, each row starting with its island backdrop so a
           painting that drifts from the backdrops' style stands out. D:\\AI\\achievements\\sheets\\
  pick     KEY N [--force]                  copies candidate N to D:\\AI\\achievements\\approved\\<key>.png
  fix      KEY N --prompt "..." [--count 4] an edit of candidate N ("The same painting as the reference image, ...")
  finish   [--only a,b] [--size 512] [--no-install]
           resizes every approved painting to --size (LANCZOS) and copies it into the game at
           godot/assets/achievements/<key>.png (the game prefers it over the SVG placeholder), then writes a check
           sheet of the finished set in their tier frames at full size and at the page's 176 px.

Every generated image is logged to D:\\AI\\logs\\achievement_generation_log.jsonl (prompt, seed, model, workflow,
references), for the AI-art disclosure. Candidates: ComfyUI output\\cand_achievements\\<key>-c<N>_00001_.png.
Folders can be overridden with AETHERBOUND_AI (default D:\\AI) and AETHERBOUND_GODOT (the repo's root folder).
"""
import argparse
import json
import os
import random
import re
import shutil
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(os.environ.get("AETHERBOUND_AI", r"D:\AI"))
TOOLS = ROOT / "tools"
HERE = Path(__file__).resolve().parent
GODOT = Path(os.environ["AETHERBOUND_GODOT"]) if os.environ.get("AETHERBOUND_GODOT") else HERE.parents[1]
LOG = ROOT / "logs" / "achievement_generation_log.jsonl"
COMFY_OUT = ROOT / "ComfyUI" / "ComfyUI" / "output"
ART_DIR = ROOT / "achievements"
APPROVED = ART_DIR / "approved"
SHEETS = ART_DIR / "sheets"
REFS = ART_DIR / "_refs"
COMFY_PYTHON = ROOT / "ComfyUI" / "python_embeded" / "python.exe"
PROMPTS_MD = GODOT / "docs" / "archive" / "art" / "art-prompts-achievements.md"
PROMPTS_JSON = TOOLS / "achievements.json"
SECONDS_PER_IMAGE = 18.0
TIER_COLORS = {0: "#a07ef0", 1: "#c98a4b", 2: "#c9d3e0", 3: "#f2c14e"}   # secret, bronze, silver, gold (AchievementTile)
PLATE = "#171a38"

sys.path.insert(0, str(TOOLS))

# ----------------------------------------------------------------------------- the paintings
# A(key, island, scene, ref=None): island is the backdrop the scene is painted in (a data/zones.json id); scene says
# what happens, in plain words, as one or two sentences; ref "<species>-f<form>" puts that Aetherling's approved
# sprite in as the second reference (then say "the Aetherling" in the scene).
ART = []


def A(key, island, scene, ref=None):
    ART.append(dict(key=key, island=island, scene=scene, ref=ref))


# skills
A("skill-woodcutting", "whisperleaf-hollow", "The Aetherling proudly stands on a freshly cut tree stump beside a neat stack of logs, wood chips in the moss.", "sproutlet-f1")
A("skill-herbalism", "whisperleaf-hollow", "The Aetherling tends a lush little herb garden of bright leaves and flowers, a small basket of picked herbs beside it.", "mossgear-f1")
A("skill-mining", "fractured-quarry", "The Aetherling stands by a cracked boulder full of glittering ore, a small cart of ore chunks next to it.", "quakemaw-f1")
A("skill-fishing", "whispering-tides", "The Aetherling sits on a small wooden jetty with a fishing line in the water and a bucket of fish beside it.", "splashfin-f1")
A("skill-scavenging", "fractured-quarry", "The Aetherling digs through a heap of old gears, bolts and trinkets, holding up a small shiny find.", "pebblescoot-f1")
A("skill-smithing", "smoldering-caldera", "The Aetherling hammers a glowing orange bar on a sturdy anvil, bright sparks flying.", "emberfang-f1")
A("skill-cooking", "smoldering-caldera", "The Aetherling stirs a bubbling pot over a small campfire, with skewers of grilled fish and a warm pie beside it.", "roastbelly-f1")
A("skill-circuitry", "thunderhum-steppe", "The Aetherling connects copper coils and a small brass machine, a little spark jumping between two wires.", "voltfluff-f1")
A("skill-aether-weaving", "null-horizon", "The Aetherling works a small wooden loom, weaving a shimmering thread that looks like a strip of the night sky.", "hushflutter-f1")
A("skill-vessel-crafting", "null-horizon", "The Aetherling shapes a round crystal vessel on a small workbench, finished vessels lined up beside it.", "riftsneak-f1")
A("skill-fabrication", "thunderhum-steppe", "A tidy tinker's workbench with a vice, gears, springs and a half-built brass gadget, tools hanging above it.")
A("skill-total", "verdigris-canopy", "Eleven small tool symbols, an axe, a pickaxe, a fishing rod, a hammer, a pan and more, hang from branches like a mobile.")
A("skill-first99", "zenith-spire", "A single golden trophy cup stands on a stone pedestal at the top of a staircase, catching the light.")
A("skill-grandmaster", "zenith-spire", "A tall golden trophy crowned with a star stands on a high pedestal, surrounded by the tools of every craft laid out in a circle.")
A("skill-actions", "whisperleaf-hollow", "The Aetherling hurries along carrying a tall wobbling stack of logs, fish and ore.", "joulebug-f1")
# Aetherlings & Nexus
A("nexus-own", "whisperleaf-hollow", "A cosy clearing crowded with many small round cute creatures of different colours sitting together.")
A("nexus-species", "verdigris-canopy", "An open leather field journal on a tree root, its pages filled with little drawings of creatures and notes.")
A("nexus-form2", "whisperleaf-hollow", "The Aetherling stands tall and proud in a swirl of soft light, looking a little bigger and stronger than before.", "sproutlet-f2")
A("nexus-form3", "verdigris-canopy", "The Aetherling in its mightiest form stands on a high branch, towering and majestic.", "sproutlet-f3")
A("nexus-level", "fractured-quarry", "The Aetherling flexes on a rocky ledge, a row of small medals pinned to a sash across it.", "tuskcub-f2")
A("nexus-luminous", "null-horizon", "The Aetherling shines with a soft golden light that fills the dark scene around it.", "eclipsa-f1")
A("nexus-zenith", "zenith-spire", "The Aetherling stands on a white marble pedestal, bathed in ivory and gold light like a statue come alive.", "coilchirp-f2")
A("nexus-aetheric", "zenith-spire", "The Aetherling floats above the spire surrounded by a ring of pure pale aether light and floating crystal shards.", "hushflutter-f3")
A("nexus-shiny", "whispering-tides", "The Aetherling, with unusual bright colours, sparkles on a sunny beach while seashells glint around it.", "dewdrop-f1")
A("nexus-types", "verdigris-canopy", "Six small round creatures sit in a ring: green and leafy, stony brown, fiery red, watery blue, electric yellow and dark violet.")
A("nexus-perches", "whisperleaf-hollow", "A row of wooden perches on a branch, every one taken by a small sleeping creature.")
A("nexus-works", "fractured-quarry", "A charming little stone workshop building with scaffolding, a crane lifting a beam and a fresh coat of paint.")
A("nexus-pearl", "whispering-tides", "A single large pearl with a pale violet sheen rests in an open clam shell on a rock.")
A("nexus-gold", "magmaglass-rift", "A tall heap of gold coins spills out of an open treasure chest.")
# adventure
A("adv-bind", "whisperleaf-hollow", "A round crystal capture vessel lies in the moss, wobbling, with a small bright creature silhouette inside it.")
A("adv-kills", "thunderhum-steppe", "The Aetherling stands in a heroic pose on a small hill, a crowd of dazed wild creatures lying around it with little stars over their heads.", "emberfang-f2")
A("adv-bosses", "magmaglass-rift", "A row of five huge defeated monster silhouettes lies in the distance under a banner planted in the ground.")
A("adv-solo", "stormsea-expanse", "The Aetherling stands alone and brave facing a gigantic storm creature towering over the waves.", "splashfin-f2")
A("adv-shinyseen", "whisperleaf-hollow", "A wild creature with unusual sparkling colours peeks out from behind a tree, while a startled traveller's hat lies on the ground.")
A("adv-shinybind", "whispering-tides", "A crystal capture vessel glows with a rainbow-coloured sparkling creature inside it, resting in the sand.")
# breeding
A("breed-eggs", "whisperleaf-hollow", "A nest of soft moss holding a speckled egg, gently glowing, under a small glass dome.")
A("breed-hybrid", "verdigris-canopy", "Two different little creatures, one leafy green and one watery blue, look proudly at a newly hatched baby that mixes both of them.")
A("breed-special", "null-horizon", "An open old recipe book glowing on a stone table, with a strange rare egg beside it marked with a swirl.")
A("breed-mutation", "smoldering-caldera", "A cracked egg with a bright light shining out of the crack, the shell patterns shifting to brighter colours.")
A("breed-shinyhatch", "whispering-tides", "An egg hatching on the beach, a sparkling unusually coloured baby creature popping out of the shell.")
A("breed-zenith", "zenith-spire", "A tall ivory and gold egg rests on a marble plinth, radiant light around it.")
A("breed-aetheric", "zenith-spire", "A translucent-looking pale egg made of aether light hovers above an altar at the top of the spire.")
# secret
A("secret-runaway", "whisperleaf-hollow", "The Aetherling dashes away across the moss with a puff of dust behind it, looking back over its shoulder annoyed.", "sproutlet-f1")
A("secret-headpats", "whisperleaf-hollow", "The Aetherling closes its eyes happily as a big gentle hand pats its head, little hearts floating up.", "buzzbud-f1")
A("secret-cold-shoulder", "verdigris-canopy", "The Aetherling sits on a perch with its back turned to the viewer, arms folded, clearly sulking.", "cinderpup-f1")
A("secret-wish", "null-horizon", "A small sparkling creature drifts across a night sky, a shooting star trailing behind it.")
A("secret-hop-scotch", "whisperleaf-hollow", "Five small round creatures jump in the air at the same time, mid-hop, with happy faces.")
A("secret-letter-bounce", "thunderhum-steppe", "Big chunky wooden alphabet blocks bouncing in the air above the grass, caught mid-bounce.")
A("secret-konami", "null-horizon", "An old retro game controller with a cross-shaped pad and two round buttons floats in space, glowing in rainbow colours.")
A("secret-patience", "smoldering-caldera", "An egg in a warm nest with a small cross face drawn by its shape, a tiny knuckle knocking on its shell.")
A("secret-bell", "fractured-quarry", "A small brass bell on a stand rings on its own in an empty quarry, one lonely tumbleweed rolling by.")
A("secret-stare-down", "thunderhum-steppe", "Two creatures glare at each other nose to nose, eyes narrowed, a tense wind blowing the grass.")
A("secret-night-owl", "null-horizon", "The Aetherling sits awake by a small lantern under a big moon, eyes wide, a clock nearby showing three o'clock.", "eclipsa-f1")
A("secret-catch-release", "whispering-tides", "An open crystal vessel on the shore, a sparkling creature hopping out of it towards the sea, waving goodbye.")
A("secret-try-again", "fractured-quarry", "The Aetherling picks itself up from the dust with a bandage on its head, determined, a little flag in its paw.", "tuskcub-f1")
A("secret-bargain-bin", "magmaglass-rift", "A wooden crate labelled with only a drawn coin symbol, a single copper coin on top of a pile of odd junk.")
A("secret-riches-to-rags", "stormsea-expanse", "An empty treasure chest on a rock with one lonely coin at the bottom, a single moth fluttering out of it.")

STYLE = ("A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same "
         "soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place "
         "as the first reference image. {scene}{ref} The scene fills the whole square, with one clear subject near the centre "
         "that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no "
         "numbers, no user interface, no border, no frame, no watermark.")
REF_LINE = (" The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, "
            "painted in the same style as the scene.")
BAD = ["text that says", "logo", "signature", "photo", "photorealistic", "3d render", "realistic"]


def prompt(a):
    return STYLE.format(scene=a["scene"], ref=REF_LINE if a["ref"] else "")


def load_data():
    ach = json.loads((GODOT / "data" / "achievements.json").read_text(encoding="utf-8"))
    zones = {z["id"] for z in json.loads((GODOT / "data" / "zones.json").read_text(encoding="utf-8"))}
    return ach, zones


def validate():
    ach, zones = load_data()
    errs = []
    keys = [a["key"] for a in ART]
    for k in {k for k in keys if keys.count(k) > 1}:
        errs.append(f"{k} is in the table twice")
    game = {x["art"] for x in ach if not x["art"].startswith("zone:")}
    for k in sorted(game - set(keys)):
        errs.append(f"achievement art {k} (data/achievements.json) has no prompt")
    for k in sorted(set(keys) - game):
        errs.append(f"{k} has a prompt but no achievement uses it")
    for a in ART:
        p = prompt(a)
        if a["island"] not in zones:
            errs.append(f"{a['key']}: island {a['island']} is not in data/zones.json")
        if a["ref"]:
            if "Aetherling" not in a["scene"]:
                errs.append(f"{a['key']}: has a sprite ref but the scene doesn't say 'the Aetherling'")
            if not (GODOT / "assets" / "creatures" / f"{a['ref']}.png").exists():
                errs.append(f"{a['key']}: no sprite assets/creatures/{a['ref']}.png")
        for w in BAD:
            if re.search(r"\b" + re.escape(w) + r"\b", p, re.I):
                errs.append(f"{a['key']}: avoid '{w}'")
        if len(p.split()) > 150:
            errs.append(f"{a['key']}: prompt is {len(p.split())} words (150 at most)")
    return errs


def by_key():
    ach, _ = load_data()
    info = {}
    for x in ach:
        if x["art"].startswith("zone:"):
            continue
        i = info.setdefault(x["art"], {"category": x["category"], "tier": 0 if x.get("secret") else int(x["tier"]), "names": []})
        i["names"].append(x["name"])
        i["tier"] = max(i["tier"], 0 if x.get("secret") else int(x["tier"]))
    return info


# ----------------------------------------------------------------------------- helpers

def _br():
    try:
        import batch_runner
    except ImportError:
        sys.exit(f"Needs batch_runner.py from {TOOLS} (the creature pipeline).")
    return batch_runner


def _use_comfy_python_if_needed():
    """run (it flattens the sprite references), sheet and finish need Pillow: relaunch under ComfyUI's Python."""
    try:
        import PIL  # noqa: F401
        return
    except ImportError:
        pass
    if Path(sys.executable).resolve() == COMFY_PYTHON.resolve() or not COMFY_PYTHON.exists():
        sys.exit("Needs Pillow (pip install pillow), or ComfyUI's bundled Python.")
    os.execv(str(COMFY_PYTHON), [str(COMFY_PYTHON), str(Path(__file__).resolve())] + sys.argv[1:])


def read_log():
    if not LOG.exists():
        return []
    return [json.loads(line) for line in LOG.read_text(encoding="utf-8").splitlines() if line.strip()]


def append_log(entry):
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def candidates(log, key):
    return sorted((e["cand"], COMFY_OUT / e["file"]) for e in log if e["key"] == key and e.get("ok"))


def approved_path(key):
    return APPROVED / f"{key}.png"


def backdrop(island):
    return GODOT / "assets" / "zones" / f"{island}.jpg"


def select(args):
    only = set(args.only.split(",")) if getattr(args, "only", None) else None
    info = by_key()
    cat = getattr(args, "category", "all")
    for a in ART:
        if only and a["key"] not in only:
            continue
        if cat != "all" and info.get(a["key"], {}).get("category") != cat:
            continue
        yield a


def find(key):
    for a in ART:
        if a["key"] == key:
            return a
    sys.exit(f"unknown painting {key}")


def now():
    return datetime.now().isoformat(timespec="seconds")


def _font(px):
    from PIL import ImageFont
    for p in (r"C:\Windows\Fonts\segoeui.ttf", r"C:\Windows\Fonts\arial.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        if Path(p).exists():
            return ImageFont.truetype(p, px)
    return ImageFont.load_default()


def _upload_refs(br, a):
    """Uploads the island backdrop and (flattened onto white, since LoadImage drops the alpha) the sprite reference.
    Returns (ref_name, ref2_name or None)."""
    from PIL import Image
    ref = f"ach-zone-{a['island']}.jpg"
    br.upload_image(backdrop(a["island"]), ref)
    if not a["ref"]:
        return ref, None
    REFS.mkdir(parents=True, exist_ok=True)
    flat = REFS / f"{a['ref']}-flat.png"
    sprite = Image.open(GODOT / "assets" / "creatures" / f"{a['ref']}.png").convert("RGBA")
    bg = Image.new("RGBA", sprite.size, "white")
    bg.alpha_composite(sprite)
    bg.convert("RGB").save(flat)
    ref2 = f"ach-sprite-{a['ref']}.png"
    br.upload_image(flat, ref2)
    return ref, ref2


# ----------------------------------------------------------------------------- commands

def cmd_status(args):
    log = read_log()
    info = by_key()
    done = waiting = todo = 0
    print(f"{'painting':24}{'category':11}{'island':22}status")
    for a in select(args):
        if approved_path(a["key"]).exists():
            st, done = "APPROVED", done + 1
        else:
            n = len(candidates(log, a["key"]))
            st = f"{n} cand" if n else "todo"
            waiting, todo = waiting + (1 if n else 0), todo + (0 if n else 1)
        print(f"{a['key']:24}{info.get(a['key'], {}).get('category', '?'):11}{a['island']:22}{st}")
    print(f"\n{done} approved, {waiting} with candidates waiting for a pick, {todo} not started.")


def cmd_prompts(args):
    errs = validate()
    if errs:
        print("\n".join("  " + e for e in errs))
        sys.exit(f"{len(errs)} problem(s); nothing written.")
    info = by_key()
    rows = [dict(key=a["key"], island=a["island"], ref=a["ref"], category=info[a["key"]]["category"],
                 achievements=info[a["key"]]["names"], prompt=prompt(a)) for a in ART]
    if TOOLS.exists():
        PROMPTS_JSON.write_text(json.dumps(rows, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print(f"wrote {PROMPTS_JSON}")
    out = ["# Achievement art prompts", "",
           "Written by `tools/art/achievement_art.py prompts`; edit the `ART` table there, not this file. Each painting is "
           "painted through the edit graph with its island's battle backdrop as the first reference (so the set matches the "
           "backdrops the island-clear achievements show) and, when an Aetherling is in it, its approved sprite as the second.", "",
           "Run: `python tools/art/achievement_art.py run --category skills` (or `--only key,key`), look at the sheet, "
           "`pick KEY N`, then `finish` to install at 512 px.", "",
           "| # | Painting | Category | Island | Sprite | Used by | Status |", "|---|---|---|---|---|---|---|"]
    for i, r in enumerate(rows, 1):
        st = "[x] approved" if approved_path(r["key"]).exists() else "[ ]"
        out.append(f"| {i} | `{r['key']}` | {r['category']} | {r['island']} | {r['ref'] or '-'} | {', '.join(r['achievements'])} | {st} |")
    for i, r in enumerate(rows, 1):
        out += ["", f"### {i}. `{r['key']}`", "",
                f"island: **{r['island']}** | sprite: {r['ref'] or 'none'} | file: D:\\AI\\achievements\\approved\\{r['key']}.png "
                f"-> godot/assets/achievements/{r['key']}.png", "", "```", r["prompt"], "```"]
    PROMPTS_MD.parent.mkdir(parents=True, exist_ok=True)
    PROMPTS_MD.write_text("\n".join(out) + "\n", encoding="utf-8")
    print(f"wrote {PROMPTS_MD} ({len(rows)} paintings)")


def cmd_run(args):
    errs = validate()
    if errs:
        sys.exit("Fix the table first:\n" + "\n".join("  " + e for e in errs))
    log = read_log()
    jobs, skipped = [], []
    for a in select(args):
        if approved_path(a["key"]).exists():
            skipped.append((a["key"], "approved"))
            continue
        have = candidates(log, a["key"])
        nxt = (max(n for n, _ in have) if have else 0) + 1
        need = args.count if args.more else args.count - len(have)
        if need <= 0:
            skipped.append((a["key"], f"has {len(have)} candidates (use --more for another {args.count})"))
        else:
            jobs.append((a, nxt, need))
    total = sum(n for _, _, n in jobs)
    print(f"{len(jobs)} paintings, {total} images, about {total * SECONDS_PER_IMAGE / 60:.1f} min.")
    for key, why in skipped:
        print(f"  skip {key}: {why}")
    if args.dry_run or not jobs:
        for a, first, n in jobs:
            print(f"  would run {a['key']}: candidates {first}-{first + n - 1}  island {a['island']}  sprite {a['ref'] or '-'}")
        return
    _use_comfy_python_if_needed()
    br = _br()
    if not br.comfy_up():
        sys.exit(f"ComfyUI is not answering at {br.HOST}. Start D:\\AI\\ComfyUI\\run_nvidia_gpu.bat first.")
    done = 0
    for a, first, n in jobs:
        ref, ref2 = _upload_refs(br, a)
        spec = br.EDIT_DUAL if ref2 else br.EDIT
        text = prompt(a)
        pending = []
        for k in range(first, first + n):
            seed = random.SystemRandom().randrange(1, 2**50)
            pending.append((k, seed, br.queue(br.build_graph(spec, text, seed, f"cand_achievements/{a['key']}-c{k}", ref, ref2))))
        for k, seed, pid in pending:
            try:
                img = br.wait_for(pid)
            except (RuntimeError, TimeoutError) as e:
                print(f"  FAILED {a['key']} c{k}: {e}")
                append_log(dict(time=now(), key=a["key"], cand=k, ok=False, error=str(e)))
                continue
            rel = (Path(img.get("subfolder", "")) / img["filename"]).as_posix()
            append_log(dict(time=now(), key=a["key"], cand=k, ok=True, file=rel, seed=seed, steps=spec["steps_n"], cfg=1.0,
                            model=br.MODEL, workflow=spec["file"], reference=ref, reference2=ref2, prompt=text))
            done += 1
        print(f"  {a['key']}: candidates {first}-{first + n - 1} done ({done}/{total})")
    args.only = ",".join(a["key"] for a, _, _ in jobs)
    cmd_sheet(args)


def cmd_sheet(args):
    _use_comfy_python_if_needed()
    from PIL import Image, ImageDraw
    log = read_log()
    rows = [(a, [c for c in candidates(log, a["key"]) if c[1].exists()]) for a in select(args)]
    rows = [r for r in rows if r[1]]
    if not rows:
        print("No candidates to show.")
        return
    tile, gap, label_w = 240, 10, 250
    cols = 1 + max(len(cs) for _, cs in rows)
    W = label_w + cols * (tile + gap) + gap
    H = gap + len(rows) * (tile + 28 + gap)
    sheet = Image.new("RGB", (W, H), "#14171c")
    d = ImageDraw.Draw(sheet)
    f_big, f_small = _font(20), _font(16)
    for r, (a, cs) in enumerate(rows):
        y = gap + r * (tile + 28 + gap)
        d.text((12, y + tile // 2 - 24), a["key"], fill="#f0e6d2", font=f_big)
        d.text((12, y + tile // 2 + 4), a["island"], fill="#8a8a99", font=f_small)
        if approved_path(a["key"]).exists():
            d.text((12, y + tile // 2 + 26), "APPROVED", fill="#8fd6a0", font=f_small)
        # the island backdrop first, for style
        bd = Image.open(backdrop(a["island"])).convert("RGB").resize((tile, tile), Image.LANCZOS)
        sheet.paste(bd, (label_w, y))
        d.text((label_w + 6, y + tile + 4), "backdrop", fill="#8a8a99", font=f_small)
        for i, (n, path) in enumerate(cs, 1):
            x = label_w + i * (tile + gap)
            sheet.paste(Image.open(path).convert("RGB").resize((tile, tile), Image.LANCZOS), (x, y))
            d.text((x + 6, y + tile + 4), f"#{n}", fill="#c9c2b3", font=f_small)
    SHEETS.mkdir(parents=True, exist_ok=True)
    out = SHEETS / f"candidates-{datetime.now().strftime('%Y%m%d-%H%M%S')}.png"
    sheet.save(out)
    print(f"contact sheet: {len(rows)} paintings -> {out}")


def cmd_pick(args):
    a = find(args.key)
    have = dict(candidates(read_log(), a["key"]))
    if args.n not in have:
        sys.exit(f"No candidate {args.n} logged for {a['key']}. Known: {sorted(have)}")
    dst = approved_path(a["key"])
    if dst.exists() and not args.force:
        sys.exit(f"{dst} exists; use --force to overwrite.")
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(have[args.n], dst)
    print(f"copied {have[args.n].name} -> {dst}")


def cmd_fix(args):
    _use_comfy_python_if_needed()
    a = find(args.key)
    have = dict(candidates(read_log(), a["key"]))
    if args.n not in have:
        sys.exit(f"No candidate {args.n} logged for {a['key']}. Known: {sorted(have)}")
    br = _br()
    if not br.comfy_up():
        sys.exit(f"ComfyUI is not answering at {br.HOST}.")
    ref = f"ach-{a['key']}-fixref-c{args.n}.png"
    br.upload_image(have[args.n], ref)
    nxt = max(have) + 1
    pending = []
    for k in range(nxt, nxt + args.count):
        seed = random.SystemRandom().randrange(1, 2**50)
        pending.append((k, seed, br.queue(br.build_graph(br.EDIT, args.prompt, seed, f"cand_achievements/{a['key']}-c{k}", ref))))
    for k, seed, pid in pending:
        try:
            img = br.wait_for(pid)
        except (RuntimeError, TimeoutError) as e:
            print(f"  FAILED {a['key']} c{k}: {e}")
            append_log(dict(time=now(), key=a["key"], cand=k, ok=False, error=str(e)))
            continue
        rel = (Path(img.get("subfolder", "")) / img["filename"]).as_posix()
        append_log(dict(time=now(), key=a["key"], cand=k, ok=True, file=rel, seed=seed, steps=br.EDIT["steps_n"], cfg=1.0,
                        model=br.MODEL, workflow=br.EDIT["file"], reference=ref, fix_of=args.n, prompt=args.prompt))
    print(f"{a['key']}: candidates {nxt}-{nxt + args.count - 1}")
    args.only, args.category = a["key"], "all"
    cmd_sheet(args)


def cmd_finish(args):
    _use_comfy_python_if_needed()
    from PIL import Image, ImageDraw
    info = by_key()
    dest = GODOT / "assets" / "achievements"
    done = []
    for a in select(args):
        src = approved_path(a["key"])
        if not src.exists():
            continue
        im = Image.open(src).convert("RGB")
        side = min(im.size)
        im = im.crop(((im.width - side) // 2, (im.height - side) // 2, (im.width + side) // 2, (im.height + side) // 2))
        im = im.resize((args.size, args.size), Image.LANCZOS)
        out = ART_DIR / "finished" / f"{a['key']}.png"
        out.parent.mkdir(parents=True, exist_ok=True)
        im.save(out, optimize=True)
        if not args.no_install:
            dest.mkdir(parents=True, exist_ok=True)
            shutil.copy2(out, dest / f"{a['key']}.png")
        done.append((a, im))
    if not done:
        print("Nothing approved yet.")
        return
    print(f"finished {len(done)} paintings" + ("" if args.no_install else f" -> {dest}"))
    # check sheet: each painting in its tier frame at the page's 176 px, beside a larger copy
    small, big, gap = 176, 352, 16
    W = gap + 4 * (big + small + 3 * gap)
    rows = (len(done) + 3) // 4
    sheet = Image.new("RGB", (W, gap + rows * (big + 40 + gap)), PLATE)
    d = ImageDraw.Draw(sheet)
    f = _font(16)
    for i, (a, im) in enumerate(done):
        x = gap + (i % 4) * (big + small + 3 * gap)
        y = gap + (i // 4) * (big + 40 + gap)
        col = TIER_COLORS[info.get(a["key"], {}).get("tier", 1)]
        for size, dx in ((big, 0), (small, big + gap)):
            sheet.paste(im.resize((size, size), Image.LANCZOS), (x + dx, y))
            w = max(3, round(size * 0.022))
            d.rectangle([x + dx, y, x + dx + size - 1, y + size - 1], outline=col, width=w)
        d.text((x, y + big + 8), a["key"], fill="#eef0ff", font=f)
    SHEETS.mkdir(parents=True, exist_ok=True)
    out = SHEETS / f"finished-{datetime.now().strftime('%Y%m%d-%H%M%S')}.png"
    sheet.save(out)
    print(f"check sheet -> {out}")


def main():
    ap = argparse.ArgumentParser(description="Achievement art through ComfyUI (see the module docstring).")
    sub = ap.add_subparsers(dest="cmd", required=True)
    cats = ["skills", "nexus", "adventure", "breeding", "secret", "all"]
    p = sub.add_parser("status")
    p.add_argument("--category", choices=cats, default="all")
    p.add_argument("--only")
    sub.add_parser("prompts")
    p = sub.add_parser("run")
    p.add_argument("--category", choices=cats, default="all")
    p.add_argument("--only")
    p.add_argument("--count", type=int, default=4)
    p.add_argument("--more", action="store_true")
    p.add_argument("--dry-run", action="store_true")
    p = sub.add_parser("sheet")
    p.add_argument("--category", choices=cats, default="all")
    p.add_argument("--only")
    p = sub.add_parser("pick")
    p.add_argument("key")
    p.add_argument("n", type=int)
    p.add_argument("--force", action="store_true")
    p = sub.add_parser("fix")
    p.add_argument("key")
    p.add_argument("n", type=int)
    p.add_argument("--prompt", required=True)
    p.add_argument("--count", type=int, default=4)
    p = sub.add_parser("finish")
    p.add_argument("--only")
    p.add_argument("--category", choices=cats, default="all")
    p.add_argument("--size", type=int, default=512)
    p.add_argument("--no-install", action="store_true")
    args = ap.parse_args()
    {"status": cmd_status, "prompts": cmd_prompts, "run": cmd_run, "sheet": cmd_sheet, "pick": cmd_pick,
     "fix": cmd_fix, "finish": cmd_finish}[args.cmd](args)


if __name__ == "__main__":
    main()
