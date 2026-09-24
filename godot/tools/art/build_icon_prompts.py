"""Builds godot/docs/art-prompts-icons.md and D:/AI/tools/icons.json from one data table: the prompts for every icon
the game uses (60 item icons and 32 interface icons), for FLUX.2 [klein] in ComfyUI.

The icon counterpart of build_prompts.py (the creature sprites). Run with any Python 3:
    python build_icon_prompts.py
Edit the ICONS table below, rerun, and both outputs are regenerated. icon_runner.py reads icons.json.

Where things go (override with environment variables if your folders differ):
    AETHERBOUND_GODOT  the repo's godot folder   (default C:\\ClaudeProjects\\Aetherbound Idle\\godot)
    AETHERBOUND_AI     the AI pipeline root       (default D:\\AI)
If a folder does not exist the file is written next to this script instead, so the script also runs from the repo.
"""
import json
import os
import re
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
GODOT = Path(os.environ.get("AETHERBOUND_GODOT", r"C:\ClaudeProjects\Aetherbound Idle\godot"))
AI_ROOT = Path(os.environ.get("AETHERBOUND_AI", r"D:\AI"))
if not GODOT.exists():
    GODOT = HERE.parents[1]  # running from godot/tools/art inside the repo
DOC_OUT = GODOT / "docs" / "art-prompts-icons.md"
JSON_OUT = (AI_ROOT / "tools" / "icons.json") if (AI_ROOT / "tools").exists() else HERE / "icons.json"
APPROVED_DIR = AI_ROOT / "icons" / "approved"

KEYS = {"m": ("magenta", "#FF00FF"), "g": ("green", "#00FF00")}
OUTLINE = "dark indigo"  # every icon uses the same outline, matching the game's generated SVG icons and UI ink colour

ICONS = []


def I(id, group, category, key, subject, view="seen from a slight three-quarter angle", same_as=None, note=""):
    """group: item (-> assets/icons/items/<id>.png) or ui (-> assets/icons/ui/<id>.png).
    key: m = magenta background (default), g = green background for anything pink, purple, violet, lilac or rose.
    subject: the object itself, in plain concrete words. No item names (the model doesn't know them), no glow words.
    same_as: "items/<id>" when this interface icon should simply be a copy of an item icon (not generated)."""
    ICONS.append(dict(id=id, group=group, category=category, key=key, subject=subject, view=view, same_as=same_as, note=note))


# ----------------------------------------------------------------------------- items: logs (Woodcutting)
I("oak-log", "item", "Logs", "m", "A short chunky cut log of warm tan-brown oak with rough brown bark, one flat cut end facing the viewer showing pale cream growth rings.")
I("willow-log", "item", "Logs", "m", "A short chunky cut log of pale olive-green willow wood with smooth grey-green bark and two thin trailing green leaves, one flat cut end showing pale growth rings.")
I("maple-log", "item", "Logs", "m", "A short chunky cut log of red-brown maple wood with reddish bark and one small orange maple leaf still attached, one flat cut end showing pale orange growth rings.")
I("yew-log", "item", "Logs", "g", "A short chunky cut log of deep plum-purple yew wood with dark purple bark, one flat cut end showing pale lilac growth rings.")
I("starbark-log", "item", "Logs", "m", "A short chunky cut log of deep blue wood with dark navy bark dotted with small pale-yellow star shapes, one flat cut end showing pale-blue growth rings.")
I("seedcache", "item", "Rare finds", "m", "A plump golden-brown acorn-shaped seed pouch with a rough bark cap, a few tiny golden seeds peeking out of a small opening in its side.")

# ----------------------------------------------------------------------------- herbs (Herbalism)
I("mintleaf", "item", "Herbs", "m", "A small sprig of three bright mint-green leaves with pale veins on a short green stem.")
I("sunpetal", "item", "Herbs", "m", "A single bright-yellow daisy-like flower with five rounded petals and an orange centre, on a short green stem with one leaf.")
I("glowcap", "item", "Herbs", "m", "A cute toadstool mushroom with a rounded teal cap covered in pale-cyan spots and a short cream stem.")
I("dreamroot", "item", "Herbs", "g", "A small twisting root bulb in soft lavender and lilac, with a few curling root tendrils underneath and two small deep-violet leaves on top.")
I("aetherbloom", "item", "Herbs", "g", "A single large flower with layered violet and pale-lilac petals around a pale-gold centre, on a short deep-violet stem.")
I("lucky-clover", "item", "Rare finds", "m", "A bright green four-leaf clover with four heart-shaped leaves and a short stem.")

# ----------------------------------------------------------------------------- ores and gems (Mining)
I("copper-ore", "item", "Ores & gems", "m", "A rough chunk of grey stone with bright orange-copper metal nuggets embedded in it.")
I("iron-ore", "item", "Ores & gems", "m", "A rough chunk of dark grey rock with silvery metallic flecks and a few rust-brown spots.")
I("sunstone", "item", "Ores & gems", "m", "A faceted orange-amber gemstone cut like a classic jewel, with a few white highlight shapes painted on its facets.")
I("skyquartz", "item", "Ores & gems", "m", "A faceted sky-blue gemstone cut like a classic jewel, with a few white highlight shapes painted on its facets.")
I("aetherite", "item", "Ores & gems", "g", "A faceted violet gemstone cut like a classic jewel, with a few pale-lilac highlight shapes painted on its facets.")
I("heartgeode", "item", "Rare finds", "g", "A round grey geode split open, its hollow lined with small rose-pink crystals around a heart-shaped pink gem in the middle.")

# ----------------------------------------------------------------------------- fish (Fishing)
I("minnow", "item", "Fish", "m", "A small silver-grey fish with a pale blue-grey back, a big round eye and a small forked tail.", view="side view")
I("sunfish", "item", "Fish", "m", "A round golden-yellow fish with orange stripes, a big round eye and rounded fins.", view="side view")
I("bubblepuff", "item", "Fish", "m", "A round puffed-up pufferfish, pale yellow with small soft spikes all over, big round eyes and tiny fins.", view="side view")
I("lanternfish", "item", "Fish", "m", "A teal fish with a big round eye and a small round pale-yellow lamp bulb dangling on a thin stalk from its forehead.", view="side view")
I("starfin", "item", "Fish", "m", "An elegant indigo-blue fish with long flowing fins dotted with small pale-yellow star shapes.", view="side view")
I("moonpearl", "item", "Rare finds", "g", "A single large round pearl, lavender-white with soft lilac shading and one white highlight shape, resting in a small open grey-blue clam shell.")
I("sunken-trinket", "item", "Treasure", "m", "A small wooden treasure chest with gold trim, weathered by the sea, a few small barnacles on its lid and a strand of dark-green seaweed draped over one corner.")

# ----------------------------------------------------------------------------- salvage (Scavenging)
I("scrap", "item", "Salvage", "m", "A small pile of scrap metal: a bent grey metal plate, a loose steel bolt and a small cog.")
I("spring", "item", "Salvage", "m", "A single chunky coiled metal spring in polished silver-grey.")
I("glass-lens", "item", "Salvage", "m", "A loose round thick glass lens disc in a thin brass rim, the lens drawn opaque pale blue with white highlight shapes, no handle.")
I("clockwork-heart", "item", "Salvage", "m", "A heart-shaped brass clockwork device with small visible gears in its face and a little wind-up key on top.")
I("starglass", "item", "Salvage", "g", "A jagged shard of opaque pale-lilac crystal with tiny pale-gold star flecks painted across it.")
I("tinkers-cache", "item", "Rare finds", "m", "A small battered steel lockbox with rivets and a brass padlock, a few loose cogs spilling out from under the lid.")

# ----------------------------------------------------------------------------- bars (Smithing)
BAR = "A single metal ingot bar with a trapezoid shape and a flat top, {c}, with white highlight shapes painted on the top face."
I("copper-bar", "item", "Bars", "m", BAR.format(c="shiny orange copper"))
I("iron-bar", "item", "Bars", "m", BAR.format(c="polished steel grey"))
I("sunsteel-bar", "item", "Bars", "m", BAR.format(c="bright golden-orange metal"))
I("skysteel-bar", "item", "Bars", "m", BAR.format(c="pale sky-blue metal"))
I("aether-ingot", "item", "Bars", "g", BAR.format(c="deep violet metal with pale-lilac edges"))

# ----------------------------------------------------------------------------- meals (Cooking)
I("grilled-minnow", "item", "Meals", "m", "A small grilled fish on a wooden skewer, golden-brown with dark grill marks.")
I("herb-sunfish", "item", "Meals", "m", "A golden roasted fish on a small round cream plate, garnished with a sprig of green mint leaves.")
I("bubble-stew", "item", "Meals", "m", "A round wooden bowl of hearty orange-red stew with chunks of fish and one yellow flower petal on top, a wisp of white steam above it drawn as a crisp outlined shape.")
I("lantern-roll", "item", "Meals", "m", "Three plump rice rolls wrapped in dark seaweed on a small wooden board, cut to show a teal fish filling, each topped with a slice of teal mushroom.")
I("starfin-feast", "item", "Meals", "m", "A grand oval platter with a whole roasted blue-and-gold fish surrounded by small roasted root vegetables and green herbs.")

# ----------------------------------------------------------------------------- components (Circuitry)
I("copper-coil", "item", "Components", "m", "A small cylindrical electrical coil of shiny copper wire wound tightly around a dark core, with two short metal leads sticking out.")
I("iron-capacitor", "item", "Components", "m", "A small upright cylindrical steel-grey capacitor with two thin metal legs and a yellow lightning-bolt symbol painted on its side.")
CHIP = "A small square dark-grey circuit chip with short metal pins along all four sides and a {c} set in its centre."
I("sun-resonator", "item", "Components", "m", CHIP.format(c="round amber-orange crystal"))
I("sky-relay", "item", "Components", "m", CHIP.format(c="round sky-blue crystal"))
I("aether-dynamo", "item", "Components", "g", CHIP.format(c="round violet crystal with a pale-gold lightning mark painted on it"))

# ----------------------------------------------------------------------------- threads (Aether-Weaving)
SPOOL = "A wooden sewing spool wound with thick soft {c} thread, one loose end curling away from it."
I("dusk-thread", "item", "Threads", "g", SPOOL.format(c="indigo-violet"))
I("gloam-thread", "item", "Threads", "g", SPOOL.format(c="deep midnight-violet"))
I("star-thread", "item", "Threads", "m", SPOOL.format(c="periwinkle-blue") + " Tiny pale-yellow star specks are painted on the thread.")
I("veil-thread", "item", "Threads", "g", SPOOL.format(c="bright violet"))
I("eventide-thread", "item", "Threads", "g", SPOOL.format(c="rose-pink"))

# ----------------------------------------------------------------------------- vessels (binding Aetherlings)
ORB = "A round capture orb, {body}, with a bright white core shape painted in its centre."
I("tinkerers-vessel", "item", "Vessels", "m", ORB.format(body="made of thick amber-tinted glass held in a simple bent copper-wire cage, with a small cork-and-brass stopper on top"))
I("sturdy-vessel", "item", "Vessels", "m", ORB.format(body="made of thick pale-blue glass in a sturdy riveted steel frame with a heavy steel cap"))
I("polished-vessel", "item", "Vessels", "m", ORB.format(body="made of cyan glass with a polished silver cap and a silver band around its middle"))
I("resonant-vessel", "item", "Vessels", "g", ORB.format(body="made of violet glass in an ornate silver frame, with two small tuning-fork prongs on its cap"))
I("luminescent-vessel", "item", "Vessels", "m", ORB.format(body="made of pale-gold glass in an ornate gold filigree frame with a small crown-like cap") + " A small white star shape is painted in the centre.")

# ----------------------------------------------------------------------------- parts (Fabrication) and Aether
I("timber-frame", "item", "Parts", "m", "A small square wooden crate frame made of planks with crossed braces and dark iron corner brackets.")
I("resonance-frame", "item", "Parts", "m", "A diamond-shaped brass frame with small rivets, holding a round pale-blue crystal in its centre.")
I("aether-lantern", "item", "Parts", "m", "An elegant brass lantern with a ring handle on top and opaque frosted panes, a small pale-cyan crystal flame inside drawn as a crisp flat shape.")
I("aether-crystal", "item", "Rare finds", "m", "A cluster of three pale-cyan crystal shards growing from a small grey rock base, with white highlight shapes on the facets.")

# ----------------------------------------------------------------------------- interface: currencies and skills
I("aether", "ui", "Currencies", "m", "A four-pointed star-shaped crystal, faceted, pale cyan and white, with a small round indigo gem in its centre.", view="facing the viewer")
I("gold", "ui", "Currencies", "m", "A single thick gold coin with a raised star emblem and a beaded rim, with white highlight shapes.")
I("woodcutting", "ui", "Skills", "m", "A small wood-chopping axe with a curved wooden handle and a steel head, pointing up diagonally.")
I("herbalism", "ui", "Skills", "m", "A small woven wicker basket overflowing with fresh green leaves and one yellow flower.")
I("mining", "ui", "Skills", "m", "A miner's pickaxe with a wooden handle and a double-pointed steel head, pointing up diagonally.")
I("fishing", "ui", "Skills", "m", "A wooden fishing rod, pointing up diagonally, with a curved line and a round red-and-white float at the end of it.")
I("scavenging", "ui", "Skills", "m", "A magnifying glass with a brass rim and a short wooden handle, the lens drawn opaque pale blue with white highlight shapes.")
I("smithing", "ui", "Skills", "m", "A blacksmith's hammer with a wooden handle and a heavy steel head, pointing up diagonally.")
I("cooking", "ui", "Skills", "m", "A black frying pan with a short handle and a sunny-side-up egg in it.")
I("circuitry", "ui", "Skills", "m", "A chunky yellow lightning-bolt shape with a thin copper wire curling around it.", view="facing the viewer")
I("aether-weaving", "ui", "Skills", "g", "A wooden spool of violet thread with a silver sewing needle pushed through the thread.")
I("vessel-crafting", "ui", "Skills", "g", "A round violet glass capture orb with a silver cap, drawn solid and opaque, resting on a small three-legged brass crafting stand.")
I("fabrication", "ui", "Skills", "m", "A steel wrench and a screwdriver with a yellow handle, crossed in an X.")

# ----------------------------------------------------------------------------- interface: navigation
I("sanctum", "ui", "Navigation", "m", "A small floating island of grey rock with grass on top, a tiny round stone tower with a teal-blue roof on it, and a few small rocks hanging beneath the island.")
I("nexus", "ui", "Navigation", "g", "A plump cartoon creature paw in cream fur, facing the viewer, with four rose-pink toe pads and one large rose-pink pad.", view="facing the viewer")
I("pods", "ui", "Navigation", "g", "A single large egg standing upright, with a pearly white shell dotted with lilac and pale-cyan spots.")
I("expeditions", "ui", "Navigation", "m", "An open brass pocket compass with a cream face, a red-and-grey needle and small dark tick marks.", view="facing the viewer")
I("aetherlog", "ui", "Navigation", "g", "A thick closed book with a violet leather cover, gold metal corner caps and a gold star emblem on the front.")
I("inventory", "ui", "Navigation", "m", "A brown leather satchel backpack with a buckled flap and a small gold clasp.")
I("works", "ui", "Navigation", "m", "A large steel cog wheel with a smaller brass cog meshed beside it.", view="facing the viewer")
I("settings", "ui", "Navigation", "m", "A single steel-grey cog wheel with a round hole in its centre.", view="facing the viewer")

# ----------------------------------------------------------------------------- interface: markers and stats
I("bell", "ui", "Markers", "m", "A golden notification bell with a small round clapper at the bottom and a little loop on top.")
I("lock", "ui", "Markers", "m", "A chunky golden padlock with a steel shackle and a dark keyhole.", view="facing the viewer")
I("health", "ui", "Stats", "g", "A plump glossy red heart shape with a white highlight shape near the top.", view="facing the viewer")
I("power", "ui", "Stats", "m", "A short steel sword with a brass crossguard and a brown leather grip, pointing up diagonally.")
I("guard", "ui", "Stats", "m", "A kite-shaped shield in sky blue with a silver rim and a small silver boss in the middle.", view="facing the viewer")
I("time", "ui", "Stats", "m", "A small wooden hourglass with opaque frosted glass bulbs and pale golden sand.", view="facing the viewer")
I("xp", "ui", "Stats", "m", "A plump five-pointed golden star with rounded points and a white highlight shape.", view="facing the viewer")
I("upgrade", "ui", "Markers", "m", "A chunky mint-green arrow pointing straight up.", view="facing the viewer")
I("shiny", "ui", "Markers", "m", "Two chunky four-pointed star shapes side by side, a large pale-gold one and a small pale-cyan one.", view="facing the viewer")
I("vessel", "ui", "Markers", "m", "", same_as="items/tinkerers-vessel", note="The top bar's vessel counter uses the Tinker's Vessel icon.")
I("meal", "ui", "Markers", "m", "", same_as="items/bubble-stew", note="The top bar's meal counter uses the stew icon.")


# ----------------------------------------------------------------------------- prompt builder
def prompt(c):
    n, h = KEYS[c["key"]]
    return (f"A single game icon for a cute creature-collecting idle game, in a soft painterly digital illustration style with clean thick "
            f"{OUTLINE} outlines, chunky cartoon proportions and vibrant saturated colours. {c['subject']} "
            f"One object alone, {c['view']}, centred, filling about 75 percent of the frame with clear margin, a bold simple silhouette "
            f"that reads clearly at a small size. Everything drawn solid and opaque, nothing see-through. "
            f"Solid pure {n} background ({h}), evenly lit and completely flat, with no floor, no shadow, no glow effect, no halo, "
            f"no light rays, no sparkles, no scenery, no text, no letters, no numbers, no border, no frame, no watermark.")


# ----------------------------------------------------------------------------- validation (same rules as build_prompts.py)
BAD = re.compile(r"glow|aura|shimmer|sparkl|radian|luminous|luminesc|magic|\bmist|gleam|transparen|translucen|\(word|\[cite", re.I)
NEAR_MAGENTA = re.compile(r"\bpink|magenta|purple|violet|lilac|lavender|\bplum\b|\bplum-|\brose\b|\brose-|mauve|fuchsia", re.I)


def validate():
    errs = []
    ids = set()
    for c in ICONS:
        key = (c["group"], c["id"])
        if key in ids:
            errs.append(f"duplicate {c['group']}/{c['id']}")
        ids.add(key)
        if c["same_as"]:
            continue
        body = c["subject"]
        if BAD.search(body):
            errs.append(f"{c['id']}: banned word: {BAD.search(body).group(0)}")
        if c["key"] == "m" and NEAR_MAGENTA.search(body):
            errs.append(f"{c['id']}: '{NEAR_MAGENTA.search(body).group(0)}' on a magenta key (use key g)")
        if c["key"] == "g" and re.search(r"\bgreen\b", body, re.I):
            errs.append(f"{c['id']}: green in a green-key icon")
        p = prompt(c)
        if KEYS[c["key"]][1] not in p:
            errs.append(f"{c['id']}: missing key colour")
        if len(p.split()) > 150:
            errs.append(f"{c['id']}: {len(p.split())} words (too long)")
    for c in ICONS:
        if c["same_as"]:
            g, i = c["same_as"].split("/")
            if not any(x["id"] == i and folder(x["group"]) == g for x in ICONS):
                errs.append(f"{c['id']}: same_as {c['same_as']} not found")
    # every item in the game's data has an icon here, and nothing here is unknown to the game
    items_json = GODOT / "data" / "items.json"
    if items_json.exists():
        game_items = {it["id"] for it in json.loads(items_json.read_text(encoding="utf-8"))}
        mine = {c["id"] for c in ICONS if c["group"] == "item"}
        for missing in sorted(game_items - mine):
            errs.append(f"item {missing} is in data/items.json but has no icon prompt")
        for extra in sorted(mine - game_items):
            errs.append(f"item {extra} has a prompt but is not in data/items.json")
    ui_dir = GODOT / "assets" / "icons" / "ui"
    if ui_dir.exists():
        game_ui = {p.stem for p in ui_dir.glob("*.svg")}
        mine = {c["id"] for c in ICONS if c["group"] == "ui"}
        for missing in sorted(game_ui - mine):
            errs.append(f"interface icon {missing} is in the game but has no prompt")
    return errs


def folder(group):
    return "items" if group == "item" else "ui"


def approved(c):
    return (APPROVED_DIR / folder(c["group"]) / f"{c['id']}.png").exists()


# ----------------------------------------------------------------------------- outputs
def md():
    L = []
    a = L.append
    gen = [c for c in ICONS if not c["same_as"]]
    a("# Icon prompts (ready to paste)\n")
    a("Generated by `godot/tools/art/build_icon_prompts.py` (edit the table there, rerun, and this file and `D:\\AI\\tools\\icons.json` "
      "are rebuilt). The creature sprite prompts are the separate `docs/art-prompts.md` on `main`.\n")
    a("## What this covers\n")
    a(f"- **{len([c for c in gen if c['group'] == 'item'])} item icons**: every item in `godot/data/items.json` (logs, herbs, ores, fish, salvage, "
      "bars, meals, components, threads, vessels, parts, rare finds). Game file: `godot/assets/icons/items/<id>.png`.")
    a(f"- **{len([c for c in ICONS if c['group'] == 'ui'])} interface icons**: currencies, the 11 skills, navigation, stats and markers. "
      f"{len([c for c in ICONS if c['same_as']])} of them reuse an item icon (no generation). Game file: `godot/assets/icons/ui/<id>.png`.")
    a(f"- **{len(gen)} images to generate in total.**")
    a("- The game already has generated SVG placeholders for all of these, drawn in the same outlined style. **A PNG with the same name "
      "replaces the SVG automatically** (the game prefers `.png` when it exists), so icons can be swapped in one at a time.")
    a("- **Not covered:** eggs (drawn by a shader in the game), zone backgrounds, and the hybrid creature sprites (those belong in the "
      "creature pipeline, `build_prompts.py`).\n")
    a("## How to use these\n")
    a("One stage only (icons have no forms), with the **Flux.2 [Klein] 4B text-to-image** graph, **8 steps, CFG 1.0**, 1024x1024, "
      "the same graph the creature Form 1s use.\n")
    a("The fast way is `icon_runner.py` (in `godot/tools/art/`; it uses your `batch_runner.py` and `sprite_tools.py` from `D:\\AI\\tools`):")
    a("```\npython icon_runner.py status                          what is approved, generated, still to do\n"
      "python icon_runner.py run --group item --count 4       4 candidates per item icon (resumable; --only a,b; --more)\n"
      "python icon_runner.py run --group ui --count 4\n"
      "python icon_runner.py sheet --group item               contact sheet of the candidates, numbered\n"
      "python icon_runner.py pick oak-log 3                   approve candidate 3 (copies it to D:\\AI\\icons\\approved\\items\\)\n"
      "python icon_runner.py fix oak-log 3 --prompt \"...\"      targeted edit of one candidate, like batch_runner fix\n"
      "python icon_runner.py finish                           cut out every approved icon to 256 px and copy it into the game\n```")
    a("Or by hand: paste a prompt below into the text-to-image graph, pick the best, and save it as "
      "`D:\\AI\\icons\\approved\\items\\<id>.png` (or `...\\ui\\<id>.png`), then run `icon_runner.py finish`.\n")
    a("**Estimated time:** about 9 s per image, so 4 candidates for all "
      f"{len(gen)} icons is about {len(gen) * 4 * 9 / 60:.0f} minutes of generation.\n")
    a("**Key colour:** magenta `#FF00FF`, except **green `#00FF00` for anything pink, purple, violet, lilac or rose** (same rule as the "
      "creatures: those colours sit too close to magenta for a clean cut). Each prompt already has the right one; `finish` measures the "
      "background from the image border either way.\n")
    a("**Picking checklist:**")
    a("- One object only: reject extra copies, a second smaller object, or scattered crumbs and specks around it.")
    a("- Reads at 24 px: squint or zoom out. Thin details vanish; a bold silhouette and two or three strong colours win.")
    a("- No text, letters or numbers anywhere (models like to write on coins, books and chips).")
    a("- No floor shadow, no glow or haze around the outline, nothing see-through (the key colour shows through glass and ruins the cut).")
    a("- Same family: outline weight and saturation should match the icons you already approved. Put the new pick next to the others on "
      "the contact sheet before approving it.")
    a("- Sizes: the game shows icons from 18 to 84 px. Framing is centred with a small margin; `finish` crops to the object anyway.\n")
    a("**The style line** at the start of every prompt matches the creature sprites (soft painterly, clean outlines, vibrant, chunky), "
      "so the icons sit next to the Aetherlings. All icons use the same dark indigo outline, the game's ink colour.\n")
    a("## Checklist\n")
    a("| # | Icon | Group | Category | Key | Status |")
    a("|---|---|---|---|---|---|")
    for i, c in enumerate(ICONS, 1):
        if c["same_as"]:
            st = f"copy of `{c['same_as']}`"
        else:
            st = "[x] approved" if approved(c) else "[ ]"
        a(f"| {i} | `{c['id']}` | {c['group']} | {c['category']} | {KEYS[c['key']][0]} | {st} |")
    a("")
    cats = []
    for c in ICONS:
        if (c["group"], c["category"]) not in cats:
            cats.append((c["group"], c["category"]))
    for grp, cat in cats:
        title = f"{'Item' if grp == 'item' else 'Interface'} icons: {cat}"
        a(f"## {title}\n")
        for i, c in enumerate(ICONS, 1):
            if c["group"] != grp or c["category"] != cat:
                continue
            n, h = KEYS[c["key"]]
            if c["same_as"]:
                a(f"### {i}. `{c['id']}`\n")
                a(f"Not generated: `finish` copies `{c['same_as']}`. {c['note']}\n")
                continue
            a(f"### {i}. `{c['id']}`\n")
            a(f"key: **{n} {h}** | file: `D:\\AI\\icons\\approved\\{folder(grp)}\\{c['id']}.png` -> `godot/assets/icons/{folder(grp)}/{c['id']}.png`"
              + (f" | note: {c['note']}" if c["note"] else "") + "\n")
            a(f"```\n{prompt(c)}\n```\n")
    a("## Records\n")
    a("- These prompts are the AI-disclosure record for the icons, together with `D:\\AI\\logs\\icon_generation_log.jsonl` (every generated "
      "image with its prompt, seed and model, written by `icon_runner.py`). Tool: ComfyUI on the designer's machine; model: FLUX.2 [klein] 4B "
      "distilled fp8 (Apache 2.0).")
    a("- The SVG placeholders in `godot/assets/icons/` were drawn by code (`godot/tools/make_icons.py`), not by an AI image model.")
    return "\n".join(L) + "\n"


def main():
    errs = validate()
    if errs:
        print("VALIDATION FAILED")
        for e in errs:
            print(" -", e)
        sys.exit(1)
    DOC_OUT.parent.mkdir(parents=True, exist_ok=True)
    DOC_OUT.write_text(md(), encoding="utf-8")
    data = []
    for c in ICONS:
        d = dict(id=c["id"], group=c["group"], category=c["category"], key=KEYS[c["key"]][1], same_as=c["same_as"], note=c["note"])
        if not c["same_as"]:
            d["prompt"] = prompt(c)
        data.append(d)
    JSON_OUT.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
    gen = [c for c in ICONS if not c["same_as"]]
    print(f"OK: {len(ICONS)} icons ({len(gen)} to generate, {len(ICONS) - len(gen)} copies)")
    print("wrote", DOC_OUT)
    print("wrote", JSON_OUT)


if __name__ == "__main__":
    main()
