"""Generates the item icons in assets/icons/items/ from data/items.json.

Each item names a shape template and a base colour (`"icon": {"shape": "ore", "color": "#d27a3c"}`); this script
draws the shape with a thick dark outline, a shaded base and a highlight, to match the outlined creature sprites.
Adding an item: give it an icon entry in items.json and run `python3 tools/make_icons.py` from the godot/ folder.
Standard library only.
"""
import colorsys
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
OUT = os.path.join(ROOT, 'assets', 'icons', 'items')
INK = '#231a35'
SW = 3.2  # outline width


def _rgb(hexc):
    hexc = hexc.lstrip('#')
    return tuple(int(hexc[i:i + 2], 16) / 255 for i in (0, 2, 4))


def _hex(rgb):
    return '#' + ''.join(f'{max(0, min(255, round(c * 255))):02x}' for c in rgb)


def shade(hexc, dl, ds=0.0):
    h, l, s = colorsys.rgb_to_hls(*_rgb(hexc))
    return _hex(colorsys.hls_to_rgb(h, max(0, min(1, l + dl)), max(0, min(1, s + ds))))


def st(width=SW):
    return f'stroke="{INK}" stroke-width="{width}" stroke-linejoin="round" stroke-linecap="round"'


# Every template takes (base, light, dark) and returns SVG body markup for a 64x64 canvas.
def log(b, l, d):
    return f'''<path d="M12 22 L46 16 Q56 15 57 29 Q58 43 48 45 L14 51 Z" fill="{b}" {st()}/>
<path d="M16 26 L44 21" stroke="{d}" stroke-width="2.5" stroke-linecap="round" fill="none"/>
<path d="M18 40 L42 36" stroke="{d}" stroke-width="2.5" stroke-linecap="round" fill="none"/>
<ellipse cx="13" cy="36.5" rx="8" ry="14.5" fill="{l}" {st()}/>
<ellipse cx="13" cy="36.5" rx="4" ry="8" fill="none" stroke="{d}" stroke-width="2"/>
<circle cx="13" cy="36.5" r="1.6" fill="{d}"/>'''


def leaf(b, l, d):
    return f'''<path d="M10 54 Q8 20 50 10 Q58 40 26 52 Q18 55 10 54 Z" fill="{b}" {st()}/>
<path d="M12 52 Q28 34 46 16" stroke="{d}" stroke-width="2.6" fill="none" stroke-linecap="round"/>
<path d="M22 40 L18 30 M30 32 L28 22 M28 36 L38 36 M36 26 L44 26" stroke="{d}" stroke-width="2" fill="none" stroke-linecap="round"/>
<path d="M16 42 Q16 26 34 18" stroke="{l}" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.8"/>'''


def flower(b, l, d):
    petals = ''.join(
        f'<ellipse cx="32" cy="17" rx="8.5" ry="12" fill="{b}" {st()} transform="rotate({a} 32 32)"/>' for a in (0, 72, 144, 216, 288))
    return petals + f'''<circle cx="32" cy="32" r="8" fill="{shade(b, 0.25, 0.2)}" {st()}/>
<circle cx="29.5" cy="29.5" r="2.4" fill="#fff" opacity="0.8"/>'''


def mushroom(b, l, d):
    return f'''<path d="M26 34 L24 54 Q32 58 40 54 L38 34 Z" fill="#efe3cf" {st()}/>
<path d="M8 36 Q8 10 32 10 Q56 10 56 36 Q32 42 8 36 Z" fill="{b}" {st()}/>
<circle cx="22" cy="24" r="4" fill="{l}"/><circle cx="38" cy="19" r="3" fill="{l}"/><circle cx="44" cy="29" r="3.4" fill="{l}"/>
<path d="M14 30 Q16 18 26 14" stroke="#fff" stroke-width="2.6" fill="none" stroke-linecap="round" opacity="0.55"/>'''


def sprout(b, l, d):
    return f'''<path d="M32 58 Q30 44 32 30" stroke="{INK}" stroke-width="7" fill="none" stroke-linecap="round"/>
<path d="M32 58 Q30 44 32 30" stroke="{d}" stroke-width="3.2" fill="none" stroke-linecap="round"/>
<path d="M32 32 Q10 34 8 14 Q30 12 32 32 Z" fill="{b}" {st()}/>
<path d="M32 30 Q54 30 56 10 Q34 8 32 30 Z" fill="{l}" {st()}/>
<ellipse cx="32" cy="56" rx="14" ry="4" fill="{d}" {st()}/>'''


def clover(b, l, d):
    leaves = ''.join(f'<path d="M32 32 Q20 26 20 16 Q20 8 28 10 Q32 12 32 18 Q32 12 36 10 Q44 8 44 16 Q44 26 32 32 Z" fill="{b}" {st()} transform="rotate({a} 32 32)"/>'
                     for a in (0, 90, 180, 270))
    return leaves + f'<circle cx="32" cy="32" r="3" fill="{d}"/>'


def seed(b, l, d):
    return f'''<path d="M18 30 Q18 58 32 58 Q46 58 46 30 Z" fill="{b}" {st()}/>
<path d="M12 30 Q12 16 32 14 Q52 16 52 30 Z" fill="{d}" {st()}/>
<path d="M32 14 L34 6" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>
<path d="M24 36 Q23 48 29 52" stroke="{l}" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.8"/>'''


def ore(b, l, d):
    return f'''<path d="M8 42 L14 20 L30 10 L48 16 L57 34 L48 52 L22 55 Z" fill="#7d7890" {st()}/>
<path d="M14 20 L30 10 L48 16 L40 28 L22 30 Z" fill="#9993ad"/>
<path d="M22 30 L40 28 L57 34 L48 52 L22 55 L8 42 Z" fill="#65607a" opacity="0.6"/>
<path d="M8 42 L14 20 L30 10 L48 16 L57 34 L48 52 L22 55 Z" fill="none" {st()}/>
<path d="M20 36 L28 32 L32 40 L24 44 Z" fill="{b}" {st(2)}/>
<path d="M38 22 L46 26 L42 32 L35 29 Z" fill="{l}" {st(2)}/>
<path d="M36 42 L44 40 L44 47 L37 48 Z" fill="{b}" {st(2)}/>'''


def gem(b, l, d):
    return f'''<path d="M14 24 L24 10 L40 10 L50 24 L32 56 Z" fill="{b}" {st()}/>
<path d="M14 24 L50 24 M24 10 L28 24 L32 56 M40 10 L36 24 L32 56" stroke="{INK}" stroke-width="2" fill="none" stroke-linejoin="round"/>
<path d="M24 10 L28 24 L14 24 Z" fill="{l}"/><path d="M36 24 L50 24 L32 56 Z" fill="{d}" opacity="0.7"/>
<path d="M14 24 L24 10 L40 10 L50 24 L32 56 Z" fill="none" {st()}/>
<path d="M20 20 L25 13" stroke="#fff" stroke-width="2.4" stroke-linecap="round" opacity="0.9"/>'''


def geode(b, l, d):
    return f'''<path d="M8 34 Q8 12 32 10 Q56 12 56 34 Q56 56 32 56 Q8 56 8 34 Z" fill="#8b8499" {st()}/>
<path d="M16 34 Q16 18 32 18 Q48 18 48 34 Q48 48 32 48 Q16 48 16 34 Z" fill="{d}" {st(2.4)}/>
<path d="M32 22 L38 32 L32 44 L26 32 Z M22 30 L28 26 L26 38 Z M42 30 L36 26 L38 38 Z" fill="{b}" stroke="{INK}" stroke-width="1.6" stroke-linejoin="round"/>
<path d="M30 26 L32 30" stroke="#fff" stroke-width="2" stroke-linecap="round"/>'''


def pearl(b, l, d):
    return f'''<path d="M6 44 Q14 26 32 26 Q50 26 58 44 Q44 54 32 54 Q20 54 6 44 Z" fill="#cdb8e8" {st()}/>
<circle cx="32" cy="30" r="14" fill="{b}" {st()}/>
<circle cx="27" cy="25" r="4.5" fill="#fff" opacity="0.9"/>
<path d="M20 36 Q32 44 44 36" stroke="{d}" stroke-width="2" fill="none" opacity="0.6"/>'''


def fish(b, l, d):
    return f'''<path d="M44 32 L60 18 L58 32 L60 46 Z" fill="{d}" {st()}/>
<path d="M6 32 Q18 12 36 14 Q50 18 50 32 Q50 46 36 50 Q18 52 6 32 Z" fill="{b}" {st()}/>
<path d="M24 16 Q30 8 38 14" fill="{d}" {st()}/>
<path d="M14 36 Q28 46 44 38" stroke="{l}" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.8"/>
<circle cx="17" cy="28" r="4" fill="#fff" {st(2)}/><circle cx="17.6" cy="28.4" r="1.8" fill="{INK}"/>
<path d="M28 24 Q32 32 28 40" stroke="{d}" stroke-width="2.2" fill="none" stroke-linecap="round"/>'''


def puffer(b, l, d):
    thin = st(2)
    spikes = ''.join(f'<path d="M32 10 L35 4 L38 11" fill="{l}" {thin} transform="rotate({a} 32 32)"/>' for a in range(-80, 200, 40))
    return spikes + f'''<path d="M48 32 L60 22 L60 42 Z" fill="{d}" {st()}/>
<circle cx="30" cy="33" r="20" fill="{b}" {st()}/>
<circle cx="22" cy="28" r="4.2" fill="#fff" {st(2)}/><circle cx="22.5" cy="28.4" r="2" fill="{INK}"/>
<circle cx="24" cy="40" r="2.2" fill="{d}"/><circle cx="32" cy="44" r="2" fill="{d}"/><circle cx="36" cy="38" r="2" fill="{d}"/>
<path d="M16 38 Q18 46 26 49" stroke="{l}" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.7"/>'''


def gear(b, l, d):
    teeth = ''.join(f'<rect x="28" y="4" width="8" height="12" rx="2" fill="{b}" {st()} transform="rotate({a} 32 32)"/>' for a in range(0, 360, 45))
    return teeth + f'''<circle cx="32" cy="32" r="19" fill="{b}" {st()}/>
<circle cx="32" cy="32" r="7" fill="{d}" {st()}/>
<path d="M19 26 Q22 18 30 15" stroke="{l}" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.9"/>'''


def spring(b, l, d):
    loops = ''.join(f'<ellipse cx="32" cy="{14 + i * 8}" rx="16" ry="5.5" fill="none" stroke="{INK}" stroke-width="7"/>' for i in range(5))
    loops2 = ''.join(f'<ellipse cx="32" cy="{14 + i * 8}" rx="16" ry="5.5" fill="none" stroke="{b}" stroke-width="3.4"/>' for i in range(5))
    return loops + loops2 + f'<path d="M20 12 Q24 9 30 9" stroke="#fff" stroke-width="2" fill="none" stroke-linecap="round" opacity="0.8"/>'


def lens(b, l, d):
    return f'''<rect x="36" y="38" width="10" height="22" rx="4" fill="#8a6a4a" {st()} transform="rotate(-45 41 49)"/>
<circle cx="28" cy="28" r="20" fill="#d9dde6" {st()}/>
<circle cx="28" cy="28" r="14" fill="{b}" {st(2.4)}/>
<path d="M19 24 Q21 17 28 16" stroke="#fff" stroke-width="3" fill="none" stroke-linecap="round"/>'''


def shard(b, l, d):
    return f'''<path d="M30 4 L44 22 L40 56 L22 60 L18 26 Z" fill="{b}" {st()}/>
<path d="M30 4 L30 40 L22 60 M30 40 L40 56 M18 26 L30 40 L44 22" stroke="{INK}" stroke-width="1.8" fill="none" stroke-linejoin="round"/>
<path d="M30 4 L30 40 L18 26 Z" fill="{l}"/><path d="M30 40 L40 56 L44 22 Z" fill="{d}" opacity="0.6"/>
<path d="M30 4 L44 22 L40 56 L22 60 L18 26 Z" fill="none" {st()}/>
<circle cx="50" cy="12" r="2.4" fill="{l}"/><circle cx="12" cy="46" r="2" fill="{l}"/>'''


def crystal(b, l, d):
    return shard(b, l, d) + f'<circle cx="31" cy="30" r="5" fill="#fff" opacity="0.55"/>'


def ingot(b, l, d):
    return f'''<path d="M6 44 L16 26 L50 26 L58 44 Z" fill="{d}" {st()}/>
<path d="M16 26 L22 16 L52 16 L50 26 Z" fill="{l}" {st()}/>
<path d="M6 44 L16 26 L50 26 L58 44 Z" fill="{b}" {st()}/>
<path d="M50 26 L52 16 L60 34 L58 44 Z" fill="{d}" {st()}/>
<path d="M16 34 L44 34" stroke="{l}" stroke-width="3" stroke-linecap="round" opacity="0.8"/>'''


def meal(b, l, d):
    return f'''<path d="M22 12 Q18 6 24 2 M32 12 Q28 6 34 2 M42 12 Q38 6 44 2" stroke="#e8e8f0" stroke-width="2.6" fill="none" stroke-linecap="round" opacity="0.8"/>
<ellipse cx="32" cy="30" rx="25" ry="10" fill="{b}" {st()}/>
<circle cx="24" cy="27" r="4" fill="{l}" {st(1.8)}/><circle cx="36" cy="25" r="3.4" fill="{d}" {st(1.8)}/><circle cx="41" cy="31" r="3" fill="#8fdc7a" {st(1.6)}/>
<path d="M7 32 Q8 56 32 56 Q56 56 57 32 Q32 42 7 32 Z" fill="#f2e6d6" {st()}/>
<path d="M12 38 Q20 50 32 50" stroke="#fff" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.8"/>
<path d="M14 44 L50 44" stroke="#d27a52" stroke-width="3" stroke-linecap="round"/>'''


def coil(b, l, d):
    wraps = ''.join(f'<path d="M{18 + i * 7} 14 L{18 + i * 7} 50" stroke="{INK}" stroke-width="6.5" stroke-linecap="round"/><path d="M{18 + i * 7} 14 L{18 + i * 7} 50" stroke="{b}" stroke-width="3" stroke-linecap="round"/>' for i in range(5))
    return f'''<rect x="10" y="22" width="44" height="20" rx="6" fill="#4d4a63" {st()}/>''' + wraps + f'''
<path d="M4 32 L12 32 M52 32 L60 32" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>
<path d="M18 16 L18 24" stroke="#fff" stroke-width="1.6" stroke-linecap="round" opacity="0.8"/>'''


def capacitor(b, l, d):
    return f'''<path d="M24 46 L24 60 M40 46 L40 60" stroke="{INK}" stroke-width="5" stroke-linecap="round"/>
<path d="M24 46 L24 60 M40 46 L40 60" stroke="#c8c8d4" stroke-width="2" stroke-linecap="round"/>
<rect x="14" y="8" width="36" height="40" rx="9" fill="{b}" {st()}/>
<ellipse cx="32" cy="12" rx="17" ry="4" fill="{l}" {st(2)}/>
<rect x="18" y="20" width="6" height="22" rx="3" fill="{d}"/>
<path d="M38 26 L34 32 L40 32 L36 38" stroke="#ffe066" stroke-width="2.6" fill="none" stroke-linecap="round" stroke-linejoin="round"/>'''


def chip(b, l, d):
    pins = ''.join(f'<path d="M{18 + i * 9} 4 L{18 + i * 9} 14 M{18 + i * 9} 50 L{18 + i * 9} 60 M4 {18 + i * 9} L14 {18 + i * 9} M50 {18 + i * 9} L60 {18 + i * 9}" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>' for i in range(4))
    return pins + f'''<rect x="12" y="12" width="40" height="40" rx="7" fill="#3b3852" {st()}/>
<rect x="20" y="20" width="24" height="24" rx="4" fill="{b}" {st(2)}/>
<circle cx="32" cy="32" r="5" fill="{l}"/><path d="M24 24 L28 24" stroke="#fff" stroke-width="2" stroke-linecap="round"/>'''


def dynamo(b, l, d):
    return chip(b, l, d) + f'<path d="M34 22 L28 33 L35 33 L30 43" stroke="#fff" stroke-width="2.4" fill="none" stroke-linejoin="round" stroke-linecap="round"/>'


def spool(b, l, d):
    return f'''<rect x="12" y="6" width="40" height="9" rx="3" fill="#b88a5c" {st()}/>
<rect x="12" y="49" width="40" height="9" rx="3" fill="#b88a5c" {st()}/>
<rect x="17" y="15" width="30" height="34" fill="{b}" {st()}/>
<path d="M17 22 L47 20 M17 29 L47 27 M17 36 L47 34 M17 43 L47 41" stroke="{d}" stroke-width="2" opacity="0.8"/>
<path d="M21 18 L21 46" stroke="{l}" stroke-width="3" stroke-linecap="round" opacity="0.8"/>
<path d="M47 40 Q58 44 54 56" stroke="{b}" stroke-width="2.6" fill="none" stroke-linecap="round"/>'''


def vessel(b, l, d):
    return f'''<circle cx="32" cy="38" r="20" fill="{b}" {st()}/>
<circle cx="32" cy="38" r="11" fill="#fff" opacity="0.35"/>
<circle cx="32" cy="38" r="6" fill="#ffffff" opacity="0.85"/>
<rect x="22" y="10" width="20" height="12" rx="4" fill="#5e5873" {st()}/>
<rect x="18" y="6" width="28" height="7" rx="3" fill="#8a84a0" {st()}/>
<path d="M17 32 Q19 24 26 21" stroke="#fff" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.85"/>
<path d="M14 44 Q32 52 50 44" stroke="{d}" stroke-width="2.4" fill="none" opacity="0.7"/>'''


def chest(b, l, d):
    return f'''<rect x="8" y="28" width="48" height="28" rx="4" fill="{b}" {st()}/>
<path d="M8 28 Q8 10 32 10 Q56 10 56 28 Z" fill="{l}" {st()}/>
<path d="M8 28 L56 28" stroke="{INK}" stroke-width="{SW}"/>
<path d="M20 12 L20 56 M44 12 L44 56" stroke="{d}" stroke-width="4"/>
<rect x="27" y="24" width="10" height="12" rx="2" fill="#ffe27a" {st(2.4)}/>
<path d="M14 18 Q20 13 28 12" stroke="#fff" stroke-width="2.4" fill="none" stroke-linecap="round" opacity="0.7"/>'''


def crate(b, l, d):
    return f'''<rect x="8" y="10" width="48" height="44" rx="3" fill="{b}" {st()}/>
<path d="M8 22 L56 22 M8 42 L56 42" stroke="{INK}" stroke-width="2.6"/>
<path d="M12 22 L52 42 M52 22 L12 42" stroke="{d}" stroke-width="4" stroke-linecap="round"/>
<path d="M12 14 L50 14" stroke="{l}" stroke-width="2.6" stroke-linecap="round"/>
<circle cx="13" cy="16" r="1.6" fill="{INK}"/><circle cx="51" cy="16" r="1.6" fill="{INK}"/>'''


def frame(b, l, d):
    return f'''<path d="M32 4 L58 32 L32 60 L6 32 Z" fill="{b}" {st()}/>
<path d="M32 16 L46 32 L32 48 L18 32 Z" fill="#2c2742" {st(2.4)}/>
<circle cx="32" cy="32" r="5" fill="#9ff3ff"/>
<path d="M14 30 L30 12" stroke="{l}" stroke-width="3" stroke-linecap="round" opacity="0.9"/>'''


def lantern(b, l, d):
    return f'''<path d="M32 2 L32 8" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>
<rect x="18" y="8" width="28" height="7" rx="3" fill="#8a84a0" {st()}/>
<rect x="18" y="49" width="28" height="7" rx="3" fill="#8a84a0" {st()}/>
<rect x="20" y="15" width="24" height="34" rx="4" fill="{b}" {st()}/>
<circle cx="32" cy="32" r="8" fill="#ffffff" opacity="0.9"/>
<path d="M26 18 L26 46 M38 18 L38 46" stroke="{INK}" stroke-width="2" opacity="0.6"/>'''


SHAPES = {f.__name__: f for f in (log, leaf, flower, mushroom, sprout, clover, seed, ore, gem, geode, pearl, fish, puffer, gear, spring,
                                   lens, shard, crystal, ingot, meal, coil, capacitor, chip, dynamo, spool, vessel, chest, crate, frame, lantern)}


# ---------------------------------------------------------------- interface icons (currencies, skills, navigation)
def ui_aether():
    return f"""<circle cx="32" cy="32" r="22" fill="#6ee7ff" opacity="0.18"/>
<path d="M32 4 L38 26 L60 32 L38 38 L32 60 L26 38 L4 32 L26 26 Z" fill="#9ff3ff" {st()}/>
<path d="M32 14 L35 29 L50 32 L35 35 L32 50 L29 35 L14 32 L29 29 Z" fill="#ffffff"/>
<circle cx="32" cy="32" r="3.5" fill="#6c5cff"/>"""


def ui_gold():
    return f"""<circle cx="32" cy="34" r="22" fill="#d99a1e" {st()}/>
<circle cx="32" cy="30" r="22" fill="#ffd048" {st()}/>
<circle cx="32" cy="30" r="15" fill="none" stroke="#d99a1e" stroke-width="3"/>
<path d="M32 20 L35 27 L42 28 L37 33 L38 40 L32 36 L26 40 L27 33 L22 28 L29 27 Z" fill="#fff3c4"/>
<path d="M16 22 Q20 13 30 11" stroke="#fff" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.8"/>"""


def ui_axe():
    return f"""<path d="M18 58 L42 14" stroke="{INK}" stroke-width="9" stroke-linecap="round"/>
<path d="M18 58 L42 14" stroke="#b9854f" stroke-width="4.5" stroke-linecap="round"/>
<path d="M34 8 Q56 6 58 26 Q48 22 40 28 Z" fill="#c9d3df" {st()}/>
<path d="M40 12 Q52 12 54 20" stroke="#fff" stroke-width="2.4" fill="none" stroke-linecap="round"/>"""


def ui_pick():
    return f"""<path d="M16 58 L42 20" stroke="{INK}" stroke-width="9" stroke-linecap="round"/>
<path d="M16 58 L42 20" stroke="#b9854f" stroke-width="4.5" stroke-linecap="round"/>
<path d="M12 18 Q34 2 58 22 Q46 16 36 18 Q24 16 12 18 Z" fill="#aab4c2" {st()}/>
<path d="M20 14 Q32 8 44 12" stroke="#fff" stroke-width="2.2" fill="none" stroke-linecap="round"/>"""


def ui_rod():
    return f"""<path d="M10 58 L50 8" stroke="{INK}" stroke-width="7" stroke-linecap="round"/>
<path d="M10 58 L50 8" stroke="#8a5a3a" stroke-width="3" stroke-linecap="round"/>
<path d="M50 8 Q58 24 54 40" stroke="{INK}" stroke-width="1.8" fill="none"/>
<circle cx="54" cy="44" r="5" fill="#ff5d5d" {st(2.4)}/>
<circle cx="18" cy="48" r="5" fill="#6d6a80" {st(2.4)}/>"""


def ui_magnifier():
    return lens('#9fe6ff', '#c9f3ff', '#5fb6d6')


def ui_hammer():
    return f"""<path d="M20 58 L38 26" stroke="{INK}" stroke-width="9" stroke-linecap="round"/>
<path d="M20 58 L38 26" stroke="#b9854f" stroke-width="4.5" stroke-linecap="round"/>
<rect x="22" y="8" width="34" height="16" rx="4" fill="#8f98a6" {st()} transform="rotate(30 39 16)"/>
<path d="M28 10 L46 20" stroke="#fff" stroke-width="2.4" stroke-linecap="round" opacity="0.8"/>"""


def ui_pan():
    return f"""<path d="M40 40 L60 56" stroke="{INK}" stroke-width="9" stroke-linecap="round"/>
<path d="M40 40 L60 56" stroke="#5a4a3a" stroke-width="4.5" stroke-linecap="round"/>
<ellipse cx="28" cy="30" rx="24" ry="20" fill="#4d4a63" {st()}/>
<ellipse cx="28" cy="30" rx="15" ry="12" fill="#fff7e0" {st(2)}/>
<circle cx="30" cy="31" r="6" fill="#ffc53d" {st(2)}/>"""


def ui_bolt():
    return f"""<path d="M36 4 L12 36 L28 36 L22 60 L52 24 L34 24 Z" fill="#ffd43b" {st()}/>
<path d="M32 12 L20 30" stroke="#fff" stroke-width="2.6" stroke-linecap="round" opacity="0.8"/>"""


def ui_wrench():
    return f"""<path d="M14 54 L38 30" stroke="{INK}" stroke-width="11" stroke-linecap="round"/>
<path d="M14 54 L38 30" stroke="#aab4c2" stroke-width="6" stroke-linecap="round"/>
<path d="M36 18 Q40 6 54 8 L46 16 L48 22 L54 24 L60 16 Q62 30 48 32 Q40 32 36 18 Z" fill="#aab4c2" {st()}/>"""


def ui_egg():
    return f"""<path d="M32 4 Q52 6 54 36 Q54 60 32 60 Q10 60 10 36 Q12 6 32 4 Z" fill="#f3ecff" {st()}/>
<circle cx="24" cy="30" r="5" fill="#b89cff"/><circle cx="40" cy="42" r="6" fill="#9ff3ff"/><circle cx="38" cy="20" r="3.5" fill="#ffb8e0"/>
<path d="M18 22 Q20 12 28 9" stroke="#fff" stroke-width="3" fill="none" stroke-linecap="round"/>"""


def ui_compass():
    return f"""<circle cx="32" cy="32" r="26" fill="#e9dcc0" {st()}/>
<circle cx="32" cy="32" r="19" fill="#fff8e8" {st(2)}/>
<path d="M32 12 L38 32 L32 52 L26 32 Z" fill="#ff6b6b" {st(2)}/>
<path d="M32 32 L38 32 L32 52 L26 32 Z" fill="#6c7a99"/>
<circle cx="32" cy="32" r="3" fill="{INK}"/>"""


def ui_book():
    return f"""<path d="M6 12 Q20 8 32 16 L32 58 Q20 50 6 54 Z" fill="#7a5cff" {st()}/>
<path d="M58 12 Q44 8 32 16 L32 58 Q44 50 58 54 Z" fill="#9a82ff" {st()}/>
<path d="M12 22 Q20 20 27 24 M12 30 Q20 28 27 32 M37 24 Q44 20 52 22" stroke="#e8e0ff" stroke-width="2.2" fill="none" stroke-linecap="round"/>
<path d="M44 34 L46 40 L52 40 L47 44 L49 50 L44 46 L39 50 L41 44 L36 40 L42 40 Z" fill="#ffe27a" {st(1.6)}/>"""


def ui_bag():
    return f"""<path d="M22 20 Q22 6 32 6 Q42 6 42 20" stroke="{INK}" stroke-width="7" fill="none"/>
<path d="M22 20 Q22 6 32 6 Q42 6 42 20" stroke="#b9854f" stroke-width="3" fill="none"/>
<path d="M10 24 Q10 18 16 18 L48 18 Q54 18 54 24 L56 52 Q56 58 50 58 L14 58 Q8 58 8 52 Z" fill="#d49a5a" {st()}/>
<rect x="24" y="30" width="16" height="10" rx="3" fill="#ffe27a" {st(2.4)}/>
<path d="M14 26 L14 48" stroke="#f0c28a" stroke-width="3" stroke-linecap="round"/>"""


def ui_cog():
    return gear('#aab4c2', '#dfe6ee', '#6f7a8a')


def ui_home():
    return f"""<ellipse cx="32" cy="50" rx="26" ry="9" fill="#5b4f7a" {st()}/>
<path d="M14 48 L14 28 L32 12 L50 28 L50 48 Z" fill="#9ff3ff" {st()}/>
<path d="M8 30 L32 8 L56 30" stroke="{INK}" stroke-width="7" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M8 30 L32 8 L56 30" stroke="#7a5cff" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
<path d="M32 26 L35 33 L42 34 L35 36 L32 44 L29 36 L22 34 L29 33 Z" fill="#fff"/>"""


def ui_paw():
    return f"""<ellipse cx="32" cy="42" rx="14" ry="12" fill="#ffb8d9" {st()}/>
<ellipse cx="14" cy="28" rx="6" ry="8" fill="#ffb8d9" {st()}/><ellipse cx="50" cy="28" rx="6" ry="8" fill="#ffb8d9" {st()}/>
<ellipse cx="24" cy="14" rx="6" ry="8" fill="#ffb8d9" {st()}/><ellipse cx="40" cy="14" rx="6" ry="8" fill="#ffb8d9" {st()}/>"""


def ui_bell():
    return f"""<path d="M14 46 Q18 40 18 28 Q18 12 32 12 Q46 12 46 28 Q46 40 50 46 Z" fill="#ffd048" {st()}/>
<circle cx="32" cy="52" r="5" fill="#ffd048" {st()}/><circle cx="32" cy="8" r="3" fill="#ffd048" {st(2.4)}/>
<path d="M24 20 Q26 16 30 15" stroke="#fff" stroke-width="2.6" fill="none" stroke-linecap="round"/>"""


def ui_close():
    return f"""<circle cx="32" cy="32" r="24" fill="#c94f5e" {st()}/>
<path d="M22 22 L42 42 M42 22 L22 42" stroke="{INK}" stroke-width="10" stroke-linecap="round"/>
<path d="M22 22 L42 42 M42 22 L22 42" stroke="#fff4e8" stroke-width="5" stroke-linecap="round"/>"""


def ui_lock():
    return f"""<path d="M20 28 L20 20 Q20 8 32 8 Q44 8 44 20 L44 28" stroke="{INK}" stroke-width="8" fill="none"/>
<path d="M20 28 L20 20 Q20 8 32 8 Q44 8 44 20 L44 28" stroke="#aab4c2" stroke-width="4" fill="none"/>
<rect x="12" y="26" width="40" height="32" rx="6" fill="#ffd048" {st()}/>
<circle cx="32" cy="40" r="4" fill="{INK}"/><path d="M32 42 L32 50" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>"""


def ui_heart():
    return f"""<path d="M32 56 Q6 40 6 22 Q6 8 19 8 Q28 8 32 18 Q36 8 45 8 Q58 8 58 22 Q58 40 32 56 Z" fill="#ff6b8a" {st()}/>
<path d="M14 18 Q16 12 22 12" stroke="#fff" stroke-width="3" fill="none" stroke-linecap="round"/>"""


def ui_sword():
    return f"""<path d="M12 52 L46 10 L54 8 L52 16 L18 50 Z" fill="#dfe6ee" {st()}/>
<path d="M8 44 L20 56" stroke="{INK}" stroke-width="9" stroke-linecap="round"/><path d="M8 44 L20 56" stroke="#b9854f" stroke-width="4.5" stroke-linecap="round"/>
<path d="M6 58 L12 52" stroke="{INK}" stroke-width="7" stroke-linecap="round"/>
<path d="M24 38 L46 12" stroke="#fff" stroke-width="2" stroke-linecap="round" opacity="0.8"/>"""


def ui_shield():
    return f"""<path d="M32 4 L54 12 Q56 42 32 60 Q8 42 10 12 Z" fill="#62b6ff" {st()}/>
<path d="M32 12 L46 17 Q46 38 32 50 Z" fill="#9fd6ff"/>
<path d="M32 4 L54 12 Q56 42 32 60 Q8 42 10 12 Z" fill="none" {st()}/>"""


def ui_clock():
    return f"""<circle cx="32" cy="32" r="26" fill="#e8ecf8" {st()}/>
<path d="M32 16 L32 32 L44 38" stroke="{INK}" stroke-width="4" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
<circle cx="32" cy="32" r="3" fill="#7a5cff"/>"""


def ui_star():
    return f"""<path d="M32 4 L40 22 L60 24 L45 37 L50 58 L32 47 L14 58 L19 37 L4 24 L24 22 Z" fill="#ffd048" {st()}/>
<path d="M22 26 L28 24" stroke="#fff" stroke-width="3" stroke-linecap="round"/>"""


def ui_up():
    return f"""<path d="M32 6 L56 32 L42 32 L42 58 L22 58 L22 32 L8 32 Z" fill="#66e3a0" {st()}/>
<path d="M28 34 L28 52" stroke="#c9ffe0" stroke-width="3" stroke-linecap="round"/>"""


def ui_sparkle():
    return f"""<path d="M24 6 L29 22 L44 27 L29 32 L24 48 L19 32 L4 27 L19 22 Z" fill="#fff6c2" {st()}/>
<path d="M46 34 L49 43 L58 46 L49 49 L46 58 L43 49 L34 46 L43 43 Z" fill="#ffd8f5" {st(2.4)}/>"""


def ui_owned():
    # a green badge with a paw print: "this species is already in your Nexus"
    return f"""<circle cx="32" cy="32" r="26" fill="#3fbf7f" {st()}/>
<circle cx="32" cy="32" r="20" fill="none" stroke="#fff6e0" stroke-width="3"/>
<ellipse cx="32" cy="38" rx="8" ry="7" fill="#fff6e0"/>
<ellipse cx="21" cy="29" rx="3.6" ry="4.6" fill="#fff6e0"/><ellipse cx="43" cy="29" rx="3.6" ry="4.6" fill="#fff6e0"/>
<ellipse cx="27" cy="21" rx="3.6" ry="4.6" fill="#fff6e0"/><ellipse cx="37" cy="21" rx="3.6" ry="4.6" fill="#fff6e0"/>"""


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


def ui_trophy():
    return f'''<path d="M20 12 L44 12 L44 26 Q44 40 32 42 Q20 40 20 26 Z" fill="#f2c14e" {st()}/>
<path d="M20 16 Q10 16 11 25 Q12 32 21 32" fill="none" {st(3.6)}/>
<path d="M44 16 Q54 16 53 25 Q52 32 43 32" fill="none" {st(3.6)}/>
<path d="M20 16 Q10 16 11 25 Q12 32 21 32" fill="none" stroke="#f2c14e" stroke-width="1.6"/>
<path d="M44 16 Q54 16 53 25 Q52 32 43 32" fill="none" stroke="#f2c14e" stroke-width="1.6"/>
<rect x="28" y="41" width="8" height="8" fill="#d9a032" {st()}/>
<rect x="20" y="49" width="24" height="7" rx="2" fill="#8a5a3a" {st()}/>
<path d="M25 16 Q25 30 30 36" stroke="#fff3c4" stroke-width="3" fill="none" stroke-linecap="round" opacity="0.85"/>'''


UI = {'aether': ui_aether, 'gold': ui_gold, 'woodcutting': ui_axe, 'herbalism': lambda: leaf('#57cf8e', '#8fe8b4', '#2f9a62'),
      'mining': ui_pick, 'fishing': ui_rod, 'scavenging': ui_magnifier, 'smithing': ui_hammer, 'cooking': ui_pan,
      'circuitry': ui_bolt, 'aether-weaving': lambda: spool('#9d6bff', '#c5a8ff', '#6a3fd0'),
      'vessel-crafting': lambda: vessel('#b98bff', '#d8c0ff', '#7a50d0'), 'fabrication': ui_wrench,
      'sanctum': ui_home, 'nexus': ui_paw, 'pods': ui_egg, 'expeditions': ui_compass, 'aetherlog': ui_book,
      'inventory': ui_bag, 'works': ui_cog, 'settings': lambda: gear('#8f98a6', '#c9d0da', '#5d6675'), 'bell': ui_bell, 'close': ui_close,
      'lock': ui_lock, 'health': ui_heart, 'power': ui_sword, 'guard': ui_shield, 'time': ui_clock, 'xp': ui_star,
      'upgrade': ui_up, 'shiny': ui_sparkle, 'vessel': lambda: vessel('#c9a36a', '#e0c58f', '#8f6f3a'),
      'meal': lambda: meal('#e0a36a', '#f0c49a', '#b07a42'), 'owned': ui_owned,
      'market': ui_market, 'egg-market': ui_egg_market, 'boost-incense': ui_boost_incense, 'boost-tonic': ui_boost_tonic,
      'boost-lure': ui_boost_lure, 'boost-brew': ui_boost_brew, 'work-slot': ui_work_slot, 'achievements': ui_trophy}


# ----------------------------------------------------------------------------- achievement placeholders
# Stand-ins for the painted achievement scenes (tools/art/achievement_art.py): a tinted square with the
# category's (or the skill's) glyph, so the page works before the art is in. A painted PNG with the same name wins.
ACH_TINT = {'skills': '#3f6fb0', 'nexus': '#3f9a6a', 'adventure': '#b0703f', 'breeding': '#b04f8a', 'secret': '#6a4fc0'}
ACH_GLYPH = {'skills': ui_star, 'nexus': ui_paw, 'adventure': ui_compass, 'breeding': ui_egg}


def ui_question():
    return f'''<circle cx="32" cy="32" r="24" fill="#8f7fe0" {st()}/>
<path d="M24 25 Q24 16 32 16 Q41 16 41 24 Q41 30 34 32 L33 38" fill="none" stroke="{INK}" stroke-width="5.5" stroke-linecap="round"/>
<path d="M24 25 Q24 16 32 16 Q41 16 41 24 Q41 30 34 32 L33 38" fill="none" stroke="#fff" stroke-width="2.4" stroke-linecap="round"/>
<circle cx="33" cy="46" r="3.4" fill="#fff" {st(2)}/>'''


def achievement_placeholder(a):
    cat = a['category']
    tint = ACH_TINT[cat]
    glyph = ui_question if cat == 'secret' else ACH_GLYPH[cat]
    if a['check'].get('kind') == 'skill_level' and a['check']['skill'] in UI:
        glyph = UI[a['check']['skill']]
    return (f'<svg xmlns="http://www.w3.org/2000/svg" width="256" height="256" viewBox="0 0 64 64">\n'
            f'<defs><linearGradient id="g" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="{shade(tint, 0.12)}"/>'
            f'<stop offset="1" stop-color="{shade(tint, -0.18)}"/></linearGradient></defs>\n'
            f'<rect width="64" height="64" fill="url(#g)"/>\n'
            f'<ellipse cx="32" cy="54" rx="22" ry="5" fill="{shade(tint, -0.28)}"/>\n'
            f'<g transform="translate(14 12) scale(0.56)">{glyph()}</g>\n</svg>\n')


def write_achievement_placeholders():
    out = os.path.join(ROOT, 'assets', 'achievements')
    os.makedirs(out, exist_ok=True)
    done = set()
    for a in json.load(open(os.path.join(ROOT, 'data', 'achievements.json'), encoding='utf8')):
        if a['art'].startswith('zone:') or a['art'] in done:
            continue
        done.add(a['art'])
        with open(os.path.join(out, a['art'] + '.svg'), 'w', newline='\n') as f:
            f.write(achievement_placeholder(a))
    return len(done)


def svg(body):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="128" height="128" viewBox="0 0 64 64">\n{body}\n</svg>\n'


def main():
    os.makedirs(OUT, exist_ok=True)
    items = json.load(open(os.path.join(ROOT, 'data', 'items.json')))
    for it in items:
        ic = it['icon']
        base = ic['color']
        body = SHAPES[ic['shape']](base, shade(base, 0.18, 0.05), shade(base, -0.2))
        with open(os.path.join(OUT, it['id'] + '.svg'), 'w', newline='\n') as f:
            f.write(svg(body))
    ui_out = os.path.join(ROOT, 'assets', 'icons', 'ui')
    os.makedirs(ui_out, exist_ok=True)
    for name, fn in UI.items():
        with open(os.path.join(ui_out, name + '.svg'), 'w', newline='\n') as f:
            f.write(svg(fn()))
    n_ach = write_achievement_placeholders()
    print(f'wrote {len(items)} item icons, {len(UI)} interface icons and {n_ach} achievement placeholders')


if __name__ == '__main__':
    main()
