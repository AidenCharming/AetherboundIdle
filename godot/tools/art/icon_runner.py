"""Icon runner for Aetherbound: generates, picks and installs the game's icons and island battle backdrops through
ComfyUI (--group item, ui or zone).

The icon counterpart of batch_runner.py. Icons have one stage (no forms), so this is a small wrapper: the ComfyUI
calls and the text-to-image graph come from batch_runner.py, the cutout from sprite_tools.py (both in D:\\AI\\tools).
Prompts come from icons.json, written by build_icon_prompts.py.

Run with plain `python` from any prompt (keep it in D:\\AI\\tools next to batch_runner.py, or anywhere else: it looks
for batch_runner.py and sprite_tools.py in D:\\AI\\tools either way):
    python icon_runner.py <command> [options]

Commands
  status  [--group item|ui|zone|all]                what is approved, how many candidates exist, what is still to do
  run     [--group item|ui|zone|all] [--only a,b] [--count 4] [--more] [--dry-run]
          generates candidates with the text-to-image graph. Skips approved icons and icons that already have --count
          candidates. Resumable: rerun and it tops up. --more adds another --count. Builds a contact sheet at the end.
  sheet   [--group item|ui|zone|all] [--only a,b]    contact sheet of every candidate (numbered), D:\\AI\\icons\\sheets\\
  pick    ID N [--group item|ui|zone] [--force]      copies candidate N to D:\\AI\\icons\\approved\\items|ui\\<id>.png
  fix     ID N --prompt "..." [--count 4] [--group item|ui|zone]
          a targeted edit of candidate N through the edit graph, like batch_runner fix. Start the prompt with
          "The same icon as the reference image, with exactly the same ..., change only ...".
  finish  [--group item|ui|zone|all] [--only a,b] [--size 256] [--no-install]
          cuts out every approved icon (background measured from the border), writes it to D:\\AI\\icons\\cutouts\\, and
          copies it into the game at godot/assets/icons/items|ui/<id>.png (the game prefers a PNG over its SVG
          placeholder). Also writes the copy-only icons (same_as) and a sheet of the finished set over the game's dark
          plate. Island backdrops (group zone) are not cut out: square-cropped to 1024 px, saved as JPEG and copied to
          godot/assets/zones/<id>.jpg. Needs Pillow/numpy/scipy: relaunches under ComfyUI's Python if they are missing.

Every generated image is logged to D:\\AI\\logs\\icon_generation_log.jsonl (prompt, seed, model, workflow), for the
AI-art disclosure. Candidates: ComfyUI output\\cand_icons\\<group>\\<id>-c<N>_00001_.png.

Folders can be overridden with AETHERBOUND_AI (default D:\\AI) and AETHERBOUND_GODOT (the repo's godot folder).
"""
import argparse
import json
import os
import random
import shutil
import sys
from datetime import datetime
from pathlib import Path

ROOT = Path(os.environ.get("AETHERBOUND_AI", r"D:\AI"))
TOOLS = ROOT / "tools"
GODOT = Path(os.environ.get("AETHERBOUND_GODOT", r"C:\ClaudeProjects\Aetherbound Idle\godot"))
HERE = Path(__file__).resolve().parent
if not GODOT.exists() and (HERE.parents[1] / "project.godot").exists():
    GODOT = HERE.parents[1]  # running from godot/tools/art inside the repo
ICONS_JSON = TOOLS / "icons.json" if (TOOLS / "icons.json").exists() else HERE / "icons.json"
LOG = ROOT / "logs" / "icon_generation_log.jsonl"
COMFY_OUT = ROOT / "ComfyUI" / "ComfyUI" / "output"
ICON_DIR = ROOT / "icons"
APPROVED = ICON_DIR / "approved"
CUTOUTS = ICON_DIR / "cutouts"
SHEETS = ICON_DIR / "sheets"
PREVIEW = ICON_DIR / "_preview"
COMFY_PYTHON = ROOT / "ComfyUI" / "python_embeded" / "python.exe"
SECONDS_PER_IMAGE = 8.8
PLATE = "#171a38"  # the game's panel colour, so the finished sheet shows the icons as they will look

sys.path.insert(0, str(TOOLS))
sys.path.insert(1, str(HERE))


def _br():
    """batch_runner.py holds the ComfyUI plumbing (HTTP, upload, queue, wait, graph specs). Imported lazily so
    `status` works even where it is not installed."""
    try:
        import batch_runner
    except ImportError:
        sys.exit(f"Needs batch_runner.py from {TOOLS} (the creature pipeline).")
    return batch_runner


def _use_comfy_python_if_needed():
    """`finish` and `sheet` need Pillow (and finish needs numpy/scipy for sprite_tools). If this Python lacks them,
    relaunch this script under ComfyUI's bundled Python and take over this console window."""
    try:
        import PIL, numpy, scipy  # noqa: F401
        return
    except ImportError:
        pass
    if Path(sys.executable).resolve() == COMFY_PYTHON.resolve():
        sys.exit("Pillow/numpy/scipy missing even under ComfyUI's own Python; check the ComfyUI install.")
    if not COMFY_PYTHON.exists():
        sys.exit(f"Needs Pillow/numpy/scipy, and {COMFY_PYTHON} doesn't exist.")
    os.execv(str(COMFY_PYTHON), [str(COMFY_PYTHON), str(Path(__file__).resolve())] + sys.argv[1:])


# ---------- data ----------

def load_icons():
    if not ICONS_JSON.exists():
        sys.exit(f"{ICONS_JSON} not found: run build_icon_prompts.py first.")
    return json.loads(ICONS_JSON.read_text(encoding="utf-8"))


def folder(group):
    """The game's folder names: assets/icons/items, assets/icons/ui and assets/zones (same names under approved and
    cutouts)."""
    return {"item": "items", "ui": "ui", "zone": "zones"}[group]


def approved_path(icon):
    return APPROVED / folder(icon["group"]) / f"{icon['id']}.png"


def read_log():
    if not LOG.exists():
        return []
    return [json.loads(line) for line in LOG.read_text(encoding="utf-8").splitlines() if line.strip()]


def append_log(entry):
    LOG.parent.mkdir(parents=True, exist_ok=True)
    with LOG.open("a", encoding="utf-8") as f:
        f.write(json.dumps(entry, ensure_ascii=False) + "\n")


def candidates(log, icon):
    """Successful candidates for one icon, oldest first, as (number, absolute path)."""
    out = [(e["cand"], COMFY_OUT / e["file"]) for e in log
           if e["id"] == icon["id"] and e.get("group") == icon["group"] and e.get("ok")]
    return sorted(out)


def select(icons, args, generated_only=True):
    only = set(args.only.split(",")) if getattr(args, "only", None) else None
    for c in icons:
        if generated_only and c.get("same_as"):
            continue
        if only and c["id"] not in only:
            continue
        if args.group != "all" and c["group"] != args.group:
            continue
        yield c


def find(icons, icon_id, group):
    hits = [c for c in icons if c["id"] == icon_id and (group in (None, "all") or c["group"] == group)]
    if not hits:
        sys.exit(f"unknown icon {icon_id}")
    if len(hits) > 1:
        sys.exit(f"{icon_id} exists in more than one group; add --group item or --group ui")
    return hits[0]


def now():
    return datetime.now().isoformat(timespec="seconds")


# ---------- status ----------

def cmd_status(args):
    icons, log = load_icons(), read_log()
    todo = cand = done = 0
    print(f"{'icon':22}{'group':7}{'key':10}status")
    for c in select(icons, args, generated_only=False):
        if c.get("same_as"):
            st = f"copy of {c['same_as']}"
        elif approved_path(c).exists():
            st, done = "APPROVED", done + 1
        else:
            n = len(candidates(log, c))
            st = f"{n} cand" if n else "todo"
            cand, todo = cand + (1 if n else 0), todo + (0 if n else 1)
        print(f"{c['id']:22}{c['group']:7}{(c['key'] or '-'):10}{st}")
    print(f"\n{done} approved, {cand} with candidates waiting for a pick, {todo} not started.")


# ---------- run ----------

def cmd_run(args):
    icons, log = load_icons(), read_log()
    jobs, skipped = [], []
    for c in select(icons, args):
        if approved_path(c).exists():
            skipped.append((c["id"], "approved"))
            continue
        have = candidates(log, c)
        nxt = (max(n for n, _ in have) if have else 0) + 1
        need = args.count if args.more else args.count - len(have)
        if need <= 0:
            skipped.append((c["id"], f"has {len(have)} candidates (use --more for another {args.count})"))
        else:
            jobs.append((c, nxt, need))
    total = sum(n for _, _, n in jobs)
    print(f"{len(jobs)} icons, {total} images, about {total * SECONDS_PER_IMAGE / 60:.1f} min.")
    for cid, why in skipped:
        print(f"  skip {cid}: {why}")
    if args.dry_run or not jobs:
        for c, first, n in jobs:
            print(f"  would run {c['group']}/{c['id']}: candidates {first}-{first + n - 1}  key {c['key'] or '-'}")
        return
    br = _br()
    if not br.comfy_up():
        sys.exit(f"ComfyUI is not answering at {br.HOST}. Start D:\\AI\\ComfyUI\\run_nvidia_gpu.bat and wait for 'To see the GUI go to'.")
    done = 0
    for c, first, n in jobs:
        pending = []
        for k in range(first, first + n):
            seed = random.SystemRandom().randrange(1, 2**50)
            prefix = f"cand_icons/{c['group']}/{c['id']}-c{k}"
            pending.append((k, seed, br.queue(br.build_graph(br.T2I, c["prompt"], seed, prefix))))
        for k, seed, pid in pending:
            try:
                img = br.wait_for(pid)
            except (RuntimeError, TimeoutError) as e:
                print(f"  FAILED {c['id']} c{k}: {e}")
                append_log(dict(time=now(), id=c["id"], group=c["group"], cand=k, ok=False, error=str(e)))
                continue
            rel = (Path(img.get("subfolder", "")) / img["filename"]).as_posix()
            append_log(dict(time=now(), id=c["id"], group=c["group"], cand=k, ok=True, file=rel, seed=seed, key=c["key"],
                            steps=br.T2I["steps_n"], cfg=1.0, model=br.MODEL, workflow=br.T2I["file"], prompt=c["prompt"]))
            done += 1
        print(f"  {c['group']}/{c['id']}: candidates {first}-{first + n - 1} done ({done}/{total})")
    print("Building contact sheet...")
    args.only = ",".join(c["id"] for c, _, _ in jobs)
    _sheet_subprocess(args)


def _sheet_subprocess(args):
    """The sheet needs Pillow, which may mean relaunching under ComfyUI's Python, so it runs as its own process
    (same reason batch_runner builds its contact sheet in a subprocess)."""
    import subprocess
    cmd = [sys.executable, str(Path(__file__).resolve()), "sheet", "--group", args.group]
    if args.only:
        cmd += ["--only", args.only]
    r = subprocess.run(cmd, capture_output=True, text=True, timeout=300)
    print(r.stdout.strip())
    if r.returncode != 0:
        print(f"(contact sheet failed; run: python icon_runner.py sheet --group {args.group})")
        print(r.stderr.strip()[-600:])


# ---------- sheet ----------

def _font(px):
    from PIL import ImageFont
    for p in (r"C:\Windows\Fonts\segoeui.ttf", r"C:\Windows\Fonts\arial.ttf", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"):
        if Path(p).exists():
            return ImageFont.truetype(p, px)
    return ImageFont.load_default()


def cmd_sheet(args):
    _use_comfy_python_if_needed()
    from PIL import Image, ImageDraw
    icons, log = load_icons(), read_log()
    rows = [(c, candidates(log, c)) for c in select(icons, args)]
    rows = [(c, [x for x in cs if x[1].exists()]) for c, cs in rows]
    rows = [r for r in rows if r[1]]
    if not rows:
        print("No candidates to show.")
        return
    tile, gap, label_w = 200, 10, 230
    cols = max(len(cs) for _, cs in rows)
    W = label_w + cols * (tile + gap) + gap
    H = gap + len(rows) * (tile + 28 + gap)
    sheet = Image.new("RGB", (W, H), "#14171c")
    d = ImageDraw.Draw(sheet)
    f_big, f_small = _font(20), _font(16)
    for r, (c, cs) in enumerate(rows):
        y = gap + r * (tile + 28 + gap)
        d.text((12, y + tile // 2 - 12), c["id"], fill="#f0e6d2", font=f_big)
        d.text((12, y + tile // 2 + 14), "APPROVED" if approved_path(c).exists() else c["group"], fill="#8fd6a0" if approved_path(c).exists() else "#8a8a99", font=f_small)
        for i, (n, path) in enumerate(cs):
            x = label_w + i * (tile + gap)
            im = Image.open(path).convert("RGB").resize((tile, tile), Image.LANCZOS)
            sheet.paste(im, (x, y))
            d.text((x + 6, y + tile + 4), f"#{n}", fill="#c9c2b3", font=f_small)
    SHEETS.mkdir(parents=True, exist_ok=True)
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    out = SHEETS / f"candidates-{args.group}-{stamp}.png"
    k = 2
    while out.exists():
        out = SHEETS / f"candidates-{args.group}-{stamp}-{k}.png"
        k += 1
    sheet.save(out)
    print(f"contact sheet: {len(rows)} icons -> {out}")


# ---------- pick ----------

def cmd_pick(args):
    icons, log = load_icons(), read_log()
    c = find(icons, args.id, args.group)
    have = dict(candidates(log, c))
    if args.n not in have:
        sys.exit(f"No candidate {args.n} logged for {c['id']}. Known: {sorted(have)}")
    dst = approved_path(c)
    if dst.exists() and not args.force:
        sys.exit(f"{dst} exists; use --force to overwrite.")
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(have[args.n], dst)
    print(f"copied {have[args.n].name} -> {dst}")


# ---------- fix ----------

def cmd_fix(args):
    icons, log = load_icons(), read_log()
    c = find(icons, args.id, args.group)
    have = dict(candidates(log, c))
    if args.n not in have:
        sys.exit(f"No candidate {args.n} logged for {c['id']}. Known: {sorted(have)}")
    br = _br()
    if not br.comfy_up():
        sys.exit(f"ComfyUI is not answering at {br.HOST}.")
    ref = f"icon-{c['group']}-{c['id']}-fixref-c{args.n}.png"
    br.upload_image(have[args.n], ref)
    nxt = max(have) + 1
    print(f"Fixing {c['id']} from candidate {args.n}: candidates {nxt}-{nxt + args.count - 1}.")
    pending = []
    for k in range(nxt, nxt + args.count):
        seed = random.SystemRandom().randrange(1, 2**50)
        prefix = f"cand_icons/{c['group']}/{c['id']}-c{k}"
        pending.append((k, seed, br.queue(br.build_graph(br.EDIT, args.prompt, seed, prefix, ref))))
    for k, seed, pid in pending:
        try:
            img = br.wait_for(pid)
        except (RuntimeError, TimeoutError) as e:
            print(f"  FAILED {c['id']} c{k}: {e}")
            append_log(dict(time=now(), id=c["id"], group=c["group"], cand=k, ok=False, error=str(e)))
            continue
        rel = (Path(img.get("subfolder", "")) / img["filename"]).as_posix()
        append_log(dict(time=now(), id=c["id"], group=c["group"], cand=k, ok=True, file=rel, seed=seed, key=c["key"],
                        steps=br.EDIT["steps_n"], cfg=1.0, reference=ref, fix_of=args.n, model=br.MODEL,
                        workflow=br.EDIT["file"], prompt=args.prompt))
    args.only = c["id"]
    args.group = c["group"]
    _sheet_subprocess(args)


# ---------- finish ----------

def cmd_finish(args):
    _use_comfy_python_if_needed()
    import sprite_tools as st
    from PIL import Image, ImageDraw
    icons = load_icons()
    made = []
    zones = _finish_zones(icons, args)
    for c in select(icons, args):
        src = approved_path(c)
        if not src.exists() or c["group"] == "zone":
            continue
        # bg_hex=None: measure the background from the border (the rendered key drifts per image, see batch_runner);
        # halo off (the prompts forbid glow); margin 0.04 so the icon fills its square
        out = st.cutout_file(str(src), str(CUTOUTS / folder(c["group"])), args.size, 0.04, None, True, False, False, None)
        made.append((c, Path(out)))
    # copy-only icons take the finished file of the icon they reuse
    by_key = {f"{folder(c['group'])}/{c['id']}": p for c, p in made}
    for c in select(icons, args, generated_only=False):
        if c.get("same_as"):
            src = by_key.get(c["same_as"]) or (CUTOUTS / f"{c['same_as']}.png")
            if Path(src).exists():
                dst = CUTOUTS / folder(c["group"]) / f"{c['id']}.png"
                dst.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(src, dst)
                made.append((c, dst))
    if not made:
        if not zones:
            print("Nothing approved yet.")
        return
    if not args.no_install:
        if not (GODOT / "project.godot").exists():
            print(f"(not installing: {GODOT} is not the godot folder; set AETHERBOUND_GODOT)")
        else:
            for c, p in made:
                dst = GODOT / "assets" / "icons" / folder(c["group"]) / f"{c['id']}.png"
                shutil.copy2(p, dst)
            print(f"installed {len(made)} icons into {GODOT / 'assets' / 'icons'} (open the project in Godot to import them)")
    # a sheet of the finished set over the game's panel colour, at the sizes the game uses
    cols = 10
    cell = 120
    rows = (len(made) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell, rows * (cell + 22)), PLATE)
    d = ImageDraw.Draw(sheet)
    f = _font(13)
    for i, (c, p) in enumerate(made):
        x, y = (i % cols) * cell, (i // cols) * (cell + 22)
        im = Image.open(p).convert("RGBA")
        big = im.resize((72, 72), Image.LANCZOS)
        small = im.resize((24, 24), Image.LANCZOS)
        sheet.paste(big, (x + 8, y + 10), big)
        sheet.paste(small, (x + 86, y + 34), small)
        d.text((x + 6, y + cell), c["id"][:17], fill="#a9aed6", font=f)
    SHEETS.mkdir(parents=True, exist_ok=True)
    out = SHEETS / "finished-icons.png"
    sheet.save(out)
    print(f"finished sheet (72 px and 24 px, as in the game) -> {out}")
    print(f"QA images (icon over cyan) are next to the cutouts in {CUTOUTS}.")


def _finish_zones(icons, args):
    """Island backdrops are not cut out: centre-crop to a square, 1024 px, JPEG, straight into godot/assets/zones/."""
    from PIL import Image
    done = []
    for c in select(icons, args):
        src = approved_path(c)
        if c["group"] != "zone" or not src.exists():
            continue
        im = Image.open(src).convert("RGB")
        side = min(im.size)
        left, top = (im.width - side) // 2, (im.height - side) // 2
        im = im.crop((left, top, left + side, top + side)).resize((1024, 1024), Image.LANCZOS)
        out = CUTOUTS / "zones" / f"{c['id']}.jpg"
        out.parent.mkdir(parents=True, exist_ok=True)
        im.save(out, quality=90)
        done.append((c, out))
    if done and not args.no_install:
        if not (GODOT / "project.godot").exists():
            print(f"(not installing backdrops: {GODOT} is not the godot folder; set AETHERBOUND_GODOT)")
        else:
            dst_dir = GODOT / "assets" / "zones"
            dst_dir.mkdir(parents=True, exist_ok=True)
            for c, p in done:
                shutil.copy2(p, dst_dir / p.name)
            print(f"installed {len(done)} island backdrops into {dst_dir} (open the project in Godot to import them)")
    return done


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)
    groups = ("item", "ui", "zone", "all")
    s = sub.add_parser("status"); s.add_argument("--group", choices=groups, default="all"); s.add_argument("--only")
    s = sub.add_parser("run"); s.add_argument("--group", choices=groups, default="all"); s.add_argument("--only")
    s.add_argument("--count", type=int, default=4); s.add_argument("--more", action="store_true"); s.add_argument("--dry-run", action="store_true")
    s = sub.add_parser("sheet"); s.add_argument("--group", choices=groups, default="all"); s.add_argument("--only")
    s = sub.add_parser("pick"); s.add_argument("id"); s.add_argument("n", type=int); s.add_argument("--group", choices=("item", "ui", "zone")); s.add_argument("--force", action="store_true")
    s = sub.add_parser("fix"); s.add_argument("id"); s.add_argument("n", type=int); s.add_argument("--prompt", required=True)
    s.add_argument("--count", type=int, default=4); s.add_argument("--group", choices=("item", "ui", "zone"))
    s = sub.add_parser("finish"); s.add_argument("--group", choices=groups, default="all"); s.add_argument("--only")
    s.add_argument("--size", type=int, default=256); s.add_argument("--no-install", action="store_true")
    a = p.parse_args()
    {"status": cmd_status, "run": cmd_run, "sheet": cmd_sheet, "pick": cmd_pick, "fix": cmd_fix, "finish": cmd_finish}[a.cmd](a)


if __name__ == "__main__":
    main()
