# New art entries to merge on pull

The designer is working on art locally, so art-tool changes from cloud sessions land here instead of in
`build_icon_prompts.py` and `make_icons.py` (those two files are left exactly as the designer last pushed
them, so a pull never conflicts). After pulling, paste each block where it says, run the tools as usual,
then delete the entries you've merged (or this whole file once it's empty).

The game already works without merging: the placeholder SVGs for everything below are committed in
`assets/icons/`. Merging only lets the prompt builder list them for painting and lets `make_icons.py`
redraw the placeholders.

## 1. `tools/art/build_icon_prompts.py`: five new vessels (tiers 6 to 10)

Paste right after the `I("luminescent-vessel", ...)` line:

```python
I("gloaming-vessel", "item", "Vessels", "m", ORB.format(body="made of deep periwinkle-blue glass in a dark iron frame shaped like crescent moons, with a dark iron cap"))
I("prismatic-vessel", "item", "Vessels", "m", ORB.format(body="made of clear aqua glass cut into flat facets like a gem, in a thin bright silver frame"))
I("emberheart-vessel", "item", "Vessels", "m", ORB.format(body="made of warm orange glass in a black-iron frame, with bright orange crack lines painted on the glass like cooling lava"))
I("stormglass-vessel", "item", "Vessels", "m", ORB.format(body="made of bright yellow glass in a brass frame, with a small zigzag lightning-bolt shape painted across the glass and a brass cap with a tiny lightning rod"))
I("celestial-vessel", "item", "Vessels", "g", ORB.format(body="made of pearly ivory-white glass in a gold frame with small gold wings on either side and a gold cap topped by a tiny star"))
```

## 2. `tools/art/build_icon_prompts.py`: seven new interface icons (the Market)

Paste right before the `I("vessel", "ui", "Markers", ...)` line:

```python
I("market", "ui", "Navigation", "m", "A small wooden market stall with a red-and-cream striped awning and a wooden counter with one gold coin on it.")
I("egg-market", "ui", "Navigation", "m", "A round woven wicker basket holding three eggs side by side: a mint-green one, a pale-peach one and a taller pearly white one in the middle.")
I("boost-incense", "ui", "Market", "g", "A small violet ceramic incense bowl with a wisp of lilac smoke curling up from it.", note="The Aether Incense boost (+Aether for an hour).")
I("boost-tonic", "ui", "Market", "m", "A round glass potion bottle full of bright red liquid, with a cork stopper and a small white plus sign painted on the front.", note="The Battle Tonic boost (+party XP).")
I("boost-lure", "ui", "Market", "m", "A golden teardrop-shaped fishing lure hanging from a short line, with a white four-pointed star shape painted on it.", note="The Glimmer Lure boost (rarer wild Aetherlings).")
I("boost-brew", "ui", "Market", "m", "A chunky tan wooden tankard with a cream foam top and two small curls of steam above it.", note="Tinker's Brew boost (faster work).")
I("work-slot", "ui", "Market", "m", "A rectangular brass plaque with two rivets at the top corners and a green plus sign in its cream centre.", view="facing the viewer", note="Buying an extra work slot for a skill.")
```

## 3. `tools/make_icons.py`: placeholder drawings for those seven icons

Paste these functions right before the line that starts `UI = {'aether': ui_aether,`:

```python
def ui_market():
    # a market stall: striped awning over a counter with a coin
    return f"""<rect x="12" y="30" width="40" height="26" rx="3" fill="#d49a5a" {st()}/>
<path d="M6 30 L10 12 L54 12 L58 30 Z" fill="#fff4e0" {st()}/>
<path d="M16 12 L14 30 M28 12 L27 30 M40 12 L41 30 M50 12 L52 30" stroke="#e05a6a" stroke-width="5"/>
<path d="M6 30 L10 12 L54 12 L58 30 Z" fill="none" {st()}/>
<circle cx="32" cy="43" r="7" fill="#ffd048" {st(2.4)}/>"""


def ui_egg_market():
    # a woven basket holding three eggs
    return f"""<ellipse cx="20" cy="30" rx="9" ry="12" fill="#bff0c8" {st(2.4)}/>
<ellipse cx="44" cy="30" rx="9" ry="12" fill="#ffd8a8" {st(2.4)}/>
<ellipse cx="32" cy="24" rx="10" ry="14" fill="#f3ecff" {st(2.4)}/>
<path d="M6 34 L58 34 L52 58 L12 58 Z" fill="#c98b4a" {st()}/>
<path d="M10 44 L54 44 M14 52 L50 52 M22 34 L22 58 M32 34 L32 58 M42 34 L42 58" stroke="#8f5f2f" stroke-width="2.4"/>"""


def ui_boost_incense():
    return f"""<path d="M26 8 Q20 16 28 22 Q36 28 30 36" stroke="#b89cff" stroke-width="4" fill="none" stroke-linecap="round"/>
<path d="M18 38 L46 38 L42 58 L22 58 Z" fill="#7a5cff" {st()}/>
<rect x="14" y="34" width="36" height="7" rx="3" fill="#b89cff" {st(2.4)}/>
<path d="M32 26 L34 31 L39 32 L34 33 L32 38 L30 33 L25 32 L30 31 Z" fill="#9ff3ff"/>"""


def ui_boost_tonic():
    return f"""<rect x="26" y="4" width="12" height="10" rx="2" fill="#b07a42" {st(2.4)}/>
<path d="M24 14 L40 14 L40 22 Q54 28 52 44 Q50 60 32 60 Q14 60 12 44 Q10 28 24 22 Z" fill="#ff6b6b" {st()}/>
<path d="M18 36 Q32 30 46 36 L46 44 Q44 54 32 54 Q20 54 18 44 Z" fill="#ffb0a0"/>
<path d="M29 38 L35 38 L35 42 L39 42 L39 47 L35 47 L35 51 L29 51 L29 47 L25 47 L25 42 L29 42 Z" fill="#fff"/>"""


def ui_boost_lure():
    return f"""<path d="M32 4 L32 18" stroke="{INK}" stroke-width="3"/>
<path d="M32 18 Q18 22 18 36 Q18 50 32 58 Q46 50 46 36 Q46 22 32 18 Z" fill="#ffd048" {st()}/>
<path d="M32 26 L35 33 L42 34 L35 36 L32 44 L29 36 L22 34 L29 33 Z" fill="#fff"/>
<path d="M50 14 L52 19 L57 20 L52 21 L50 26 L48 21 L43 20 L48 19 Z" fill="#9ff3ff" {st(1.6)}/>"""


def ui_boost_brew():
    return f"""<path d="M12 22 L46 22 L44 56 Q44 58 42 58 L16 58 Q14 58 14 56 Z" fill="#c9a36a" {st()}/>
<path d="M46 28 Q58 30 56 40 Q54 48 44 48" stroke="{INK}" stroke-width="6" fill="none"/>
<path d="M46 28 Q58 30 56 40 Q54 48 44 48" stroke="#c9a36a" stroke-width="2.6" fill="none"/>
<ellipse cx="29" cy="22" rx="17" ry="5" fill="#fff4e0" {st(2.4)}/>
<path d="M22 14 Q20 8 24 4 M32 14 Q30 8 34 4" stroke="#e8ecf8" stroke-width="3" fill="none" stroke-linecap="round"/>
<path d="M22 32 L22 50 M29 32 L29 50 M36 32 L36 50" stroke="#8f6f3a" stroke-width="2.4"/>"""


def ui_work_slot():
    # a brass permit plaque with a plus
    return f"""<rect x="6" y="14" width="52" height="38" rx="6" fill="#e0b84a" {st()}/>
<rect x="12" y="20" width="40" height="26" rx="4" fill="#fff4d0" {st(2)}/>
<path d="M28 25 L36 25 L36 29 L40 29 L40 37 L36 37 L36 41 L28 41 L28 37 L24 37 L24 29 L28 29 Z" fill="#3fbf7f" {st(2)}/>
<circle cx="12" cy="18" r="2" fill="{INK}"/><circle cx="52" cy="18" r="2" fill="{INK}"/>"""
```

Then add these entries to the end of that `UI = {...}` dict (after `'owned': ui_owned`):

```python
'market': ui_market, 'egg-market': ui_egg_market, 'boost-incense': ui_boost_incense, 'boost-tonic': ui_boost_tonic,
'boost-lure': ui_boost_lure, 'boost-brew': ui_boost_brew, 'work-slot': ui_work_slot,
```

The five new vessels need nothing in `make_icons.py`: their placeholders come from `data/items.json`.
