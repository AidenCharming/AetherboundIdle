# Achievement art prompts

Written by `tools/art/achievement_art.py prompts`; edit the `ART` table there, not this file. Each painting is painted through the edit graph with its island's battle backdrop as the first reference (so the set matches the backdrops the island-clear achievements show) and, when an Aetherling is in it, its approved sprite as the second.

Run: `python tools/art/achievement_art.py run --category skills` (or `--only key,key`), look at the sheet, `pick KEY N`, then `finish` to install at 512 px.

| # | Painting | Category | Island | Sprite | Used by | Status |
|---|---|---|---|---|---|---|
| 1 | `skill-woodcutting` | skills | whisperleaf-hollow | sproutlet-f1 | Splinter, Lumberjack, Heart of the Forest | [ ] |
| 2 | `skill-herbalism` | skills | whisperleaf-hollow | mossgear-f1 | Green Thumb, Herb Whisperer, Garden of Wonders | [ ] |
| 3 | `skill-mining` | skills | fractured-quarry | quakemaw-f1 | Pebble Picker, Deep Delver, Heart of the Mountain | [ ] |
| 4 | `skill-fishing` | skills | whispering-tides | splashfin-f1 | First Nibble, Reel Deal, Lord of the Tides | [ ] |
| 5 | `skill-scavenging` | skills | fractured-quarry | pebblescoot-f1 | Finders Keepers, Treasure Nose, Nothing Goes to Waste | [ ] |
| 6 | `skill-smithing` | skills | smoldering-caldera | emberfang-f1 | Hot Iron, Anvil Rhythm, Master of the Forge | [ ] |
| 7 | `skill-cooking` | skills | smoldering-caldera | roastbelly-f1 | Snack Time, Sous Chef, Feast Maker | [ ] |
| 8 | `skill-circuitry` | skills | thunderhum-steppe | voltfluff-f1 | Spark Starter, Live Wire, Clockwork Genius | [ ] |
| 9 | `skill-aether-weaving` | skills | null-horizon | hushflutter-f1 | Loose Threads, Loom Keeper, Weaver of Stars | [ ] |
| 10 | `skill-vessel-crafting` | skills | null-horizon | riftsneak-f1 | Cracked Pot, Steady Hands, Vesselsmith Supreme | [ ] |
| 11 | `skill-fabrication` | skills | thunderhum-steppe | - | Tinkerer, Workshop Regular, Master Fabricator | [ ] |
| 12 | `skill-total` | skills | verdigris-canopy | - | Well Rounded, Jack of All Trades, Pillar of the Sanctum | [ ] |
| 13 | `skill-first99` | skills | zenith-spire | - | Peak Performance | [ ] |
| 14 | `skill-grandmaster` | skills | zenith-spire | - | Grand Master | [ ] |
| 15 | `skill-actions` | skills | whisperleaf-hollow | joulebug-f1 | Busy Paws, Hard Workers, Tireless | [ ] |
| 16 | `nexus-own` | nexus | whisperleaf-hollow | - | Small Flock, Full House, Menagerie | [ ] |
| 17 | `nexus-species` | nexus | verdigris-canopy | - | Curious, Naturalist, Living Encyclopedia | [ ] |
| 18 | `nexus-form2` | nexus | whisperleaf-hollow | sproutlet-f2 | Growing Up | [ ] |
| 19 | `nexus-form3` | nexus | verdigris-canopy | sproutlet-f3 | Final Form | [ ] |
| 20 | `nexus-level` | nexus | fractured-quarry | tuskcub-f2 | Trained, Veteran, Living Legend | [ ] |
| 21 | `nexus-luminous` | nexus | null-horizon | eclipsa-f1 | It Glows! | [ ] |
| 22 | `nexus-zenith` | nexus | zenith-spire | coilchirp-f2 | Zenith Reached | [ ] |
| 23 | `nexus-aetheric` | nexus | zenith-spire | hushflutter-f3 | Pure Aether | [ ] |
| 24 | `nexus-shiny` | nexus | whispering-tides | dewdrop-f1 | Something Shiny, Shiny Hunter | [ ] |
| 25 | `nexus-types` | nexus | verdigris-canopy | - | Full Spectrum | [ ] |
| 26 | `nexus-perches` | nexus | whisperleaf-hollow | - | Full Roost | [ ] |
| 27 | `nexus-works` | nexus | fractured-quarry | - | Renovator, Sanctum Architect | [ ] |
| 28 | `nexus-pearl` | nexus | whispering-tides | - | Pearl of Wisdom | [ ] |
| 29 | `nexus-gold` | nexus | magmaglass-rift | - | Pocket Money, Millionaire | [ ] |
| 30 | `adv-bind` | adventure | whisperleaf-hollow | - | Gotcha!, Collector, Binder Supreme | [ ] |
| 31 | `adv-kills` | adventure | thunderhum-steppe | emberfang-f2 | Scrapper, Brawler, Unstoppable | [ ] |
| 32 | `adv-bosses` | adventure | magmaglass-rift | - | Boss Rush | [ ] |
| 33 | `adv-solo` | adventure | stormsea-expanse | splashfin-f2 | One-Aetherling Army | [ ] |
| 34 | `adv-shinyseen` | adventure | whisperleaf-hollow | - | Did You See That? | [ ] |
| 35 | `adv-shinybind` | adventure | whispering-tides | - | Shiny Catch | [ ] |
| 36 | `breed-eggs` | breeding | whisperleaf-hollow | - | First Egg, Egg Enthusiast, Egg Empire | [ ] |
| 37 | `breed-hybrid` | breeding | verdigris-canopy | - | Mix and Match, Every Blend | [ ] |
| 38 | `breed-special` | breeding | null-horizon | - | Secret Recipe, Recipe Keeper, Keeper of Secrets | [ ] |
| 39 | `breed-mutation` | breeding | smoldering-caldera | - | Mutation! | [ ] |
| 40 | `breed-shinyhatch` | breeding | whispering-tides | - | Shiny Surprise | [ ] |
| 41 | `breed-zenith` | breeding | zenith-spire | - | Bred for Greatness | [ ] |
| 42 | `breed-aetheric` | breeding | zenith-spire | - | Born of Aether | [ ] |
| 43 | `secret-runaway` | secret | whisperleaf-hollow | sproutlet-f1 | Leave Me Alone! | [ ] |
| 44 | `secret-headpats` | secret | whisperleaf-hollow | buzzbud-f1 | Headpats | [ ] |
| 45 | `secret-cold-shoulder` | secret | verdigris-canopy | cinderpup-f1 | Cold Shoulder | [ ] |
| 46 | `secret-wish` | secret | null-horizon | - | Wish Upon a Star | [ ] |
| 47 | `secret-hop-scotch` | secret | whisperleaf-hollow | - | Hop Scotch | [ ] |
| 48 | `secret-letter-bounce` | secret | thunderhum-steppe | - | Letter Bounce | [ ] |
| 49 | `secret-konami` | secret | null-horizon | - | Up, Up, Down, Down | [ ] |
| 50 | `secret-patience` | secret | smoldering-caldera | - | Patience! | [ ] |
| 51 | `secret-bell` | secret | fractured-quarry | - | Is Anyone There? | [ ] |
| 52 | `secret-stare-down` | secret | thunderhum-steppe | - | Stare Down | [ ] |
| 53 | `secret-night-owl` | secret | null-horizon | eclipsa-f1 | Night Owl | [ ] |
| 54 | `secret-catch-release` | secret | whispering-tides | - | Catch and Release | [ ] |
| 55 | `secret-try-again` | secret | fractured-quarry | tuskcub-f1 | Try, Try Again | [ ] |
| 56 | `secret-bargain-bin` | secret | magmaglass-rift | - | Bargain Bin | [ ] |
| 57 | `secret-riches-to-rags` | secret | stormsea-expanse | - | Riches to Rags | [ ] |

### 1. `skill-woodcutting`

island: **whisperleaf-hollow** | sprite: sproutlet-f1 | file: D:\AI\achievements\approved\skill-woodcutting.png -> godot/assets/achievements/skill-woodcutting.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling proudly stands on a freshly cut tree stump beside a neat stack of logs, wood chips in the moss. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 2. `skill-herbalism`

island: **whisperleaf-hollow** | sprite: mossgear-f1 | file: D:\AI\achievements\approved\skill-herbalism.png -> godot/assets/achievements/skill-herbalism.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling tends a lush little herb garden of bright leaves and flowers, a small basket of picked herbs beside it. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 3. `skill-mining`

island: **fractured-quarry** | sprite: quakemaw-f1 | file: D:\AI\achievements\approved\skill-mining.png -> godot/assets/achievements/skill-mining.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling stands by a cracked boulder full of glittering ore, a small cart of ore chunks next to it. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 4. `skill-fishing`

island: **whispering-tides** | sprite: splashfin-f1 | file: D:\AI\achievements\approved\skill-fishing.png -> godot/assets/achievements/skill-fishing.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling sits on a small wooden jetty with a fishing line in the water and a bucket of fish beside it. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 5. `skill-scavenging`

island: **fractured-quarry** | sprite: pebblescoot-f1 | file: D:\AI\achievements\approved\skill-scavenging.png -> godot/assets/achievements/skill-scavenging.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling digs through a heap of old gears, bolts and trinkets, holding up a small shiny find. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 6. `skill-smithing`

island: **smoldering-caldera** | sprite: emberfang-f1 | file: D:\AI\achievements\approved\skill-smithing.png -> godot/assets/achievements/skill-smithing.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling hammers a glowing orange bar on a sturdy anvil, bright sparks flying. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 7. `skill-cooking`

island: **smoldering-caldera** | sprite: roastbelly-f1 | file: D:\AI\achievements\approved\skill-cooking.png -> godot/assets/achievements/skill-cooking.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling stirs a bubbling pot over a small campfire, with skewers of grilled fish and a warm pie beside it. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 8. `skill-circuitry`

island: **thunderhum-steppe** | sprite: voltfluff-f1 | file: D:\AI\achievements\approved\skill-circuitry.png -> godot/assets/achievements/skill-circuitry.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling connects copper coils and a small brass machine, a little spark jumping between two wires. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 9. `skill-aether-weaving`

island: **null-horizon** | sprite: hushflutter-f1 | file: D:\AI\achievements\approved\skill-aether-weaving.png -> godot/assets/achievements/skill-aether-weaving.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling works a small wooden loom, weaving a shimmering thread that looks like a strip of the night sky. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 10. `skill-vessel-crafting`

island: **null-horizon** | sprite: riftsneak-f1 | file: D:\AI\achievements\approved\skill-vessel-crafting.png -> godot/assets/achievements/skill-vessel-crafting.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling shapes a round crystal vessel on a small workbench, finished vessels lined up beside it. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 11. `skill-fabrication`

island: **thunderhum-steppe** | sprite: none | file: D:\AI\achievements\approved\skill-fabrication.png -> godot/assets/achievements/skill-fabrication.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A tidy tinker's workbench with a vice, gears, springs and a half-built brass gadget, tools hanging above it. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 12. `skill-total`

island: **verdigris-canopy** | sprite: none | file: D:\AI\achievements\approved\skill-total.png -> godot/assets/achievements/skill-total.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. Eleven small tool symbols, an axe, a pickaxe, a fishing rod, a hammer, a pan and more, hang from branches like a mobile. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 13. `skill-first99`

island: **zenith-spire** | sprite: none | file: D:\AI\achievements\approved\skill-first99.png -> godot/assets/achievements/skill-first99.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A single golden trophy cup stands on a stone pedestal at the top of a staircase, catching the light. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 14. `skill-grandmaster`

island: **zenith-spire** | sprite: none | file: D:\AI\achievements\approved\skill-grandmaster.png -> godot/assets/achievements/skill-grandmaster.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A tall golden trophy crowned with a star stands on a high pedestal, surrounded by the tools of every craft laid out in a circle. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 15. `skill-actions`

island: **whisperleaf-hollow** | sprite: joulebug-f1 | file: D:\AI\achievements\approved\skill-actions.png -> godot/assets/achievements/skill-actions.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling hurries along carrying a tall wobbling stack of logs, fish and ore. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 16. `nexus-own`

island: **whisperleaf-hollow** | sprite: none | file: D:\AI\achievements\approved\nexus-own.png -> godot/assets/achievements/nexus-own.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A cosy clearing crowded with many small round cute creatures of different colours sitting together. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 17. `nexus-species`

island: **verdigris-canopy** | sprite: none | file: D:\AI\achievements\approved\nexus-species.png -> godot/assets/achievements/nexus-species.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. An open leather field journal on a tree root, its pages filled with little drawings of creatures and notes. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 18. `nexus-form2`

island: **whisperleaf-hollow** | sprite: sproutlet-f2 | file: D:\AI\achievements\approved\nexus-form2.png -> godot/assets/achievements/nexus-form2.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling stands tall and proud in a swirl of soft light, looking a little bigger and stronger than before. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 19. `nexus-form3`

island: **verdigris-canopy** | sprite: sproutlet-f3 | file: D:\AI\achievements\approved\nexus-form3.png -> godot/assets/achievements/nexus-form3.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling in its mightiest form stands on a high branch, towering and majestic. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 20. `nexus-level`

island: **fractured-quarry** | sprite: tuskcub-f2 | file: D:\AI\achievements\approved\nexus-level.png -> godot/assets/achievements/nexus-level.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling flexes on a rocky ledge, a row of small medals pinned to a sash across it. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 21. `nexus-luminous`

island: **null-horizon** | sprite: eclipsa-f1 | file: D:\AI\achievements\approved\nexus-luminous.png -> godot/assets/achievements/nexus-luminous.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling shines with a soft golden light that fills the dark scene around it. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 22. `nexus-zenith`

island: **zenith-spire** | sprite: coilchirp-f2 | file: D:\AI\achievements\approved\nexus-zenith.png -> godot/assets/achievements/nexus-zenith.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling stands on a white marble pedestal, bathed in ivory and gold light like a statue come alive. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 23. `nexus-aetheric`

island: **zenith-spire** | sprite: hushflutter-f3 | file: D:\AI\achievements\approved\nexus-aetheric.png -> godot/assets/achievements/nexus-aetheric.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling floats above the spire surrounded by a ring of pure pale aether light and floating crystal shards. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 24. `nexus-shiny`

island: **whispering-tides** | sprite: dewdrop-f1 | file: D:\AI\achievements\approved\nexus-shiny.png -> godot/assets/achievements/nexus-shiny.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling, with unusual bright colours, sparkles on a sunny beach while seashells glint around it. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 25. `nexus-types`

island: **verdigris-canopy** | sprite: none | file: D:\AI\achievements\approved\nexus-types.png -> godot/assets/achievements/nexus-types.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. Six small round creatures sit in a ring: green and leafy, stony brown, fiery red, watery blue, electric yellow and dark violet. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 26. `nexus-perches`

island: **whisperleaf-hollow** | sprite: none | file: D:\AI\achievements\approved\nexus-perches.png -> godot/assets/achievements/nexus-perches.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A row of wooden perches on a branch, every one taken by a small sleeping creature. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 27. `nexus-works`

island: **fractured-quarry** | sprite: none | file: D:\AI\achievements\approved\nexus-works.png -> godot/assets/achievements/nexus-works.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A charming little stone workshop building with scaffolding, a crane lifting a beam and a fresh coat of paint. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 28. `nexus-pearl`

island: **whispering-tides** | sprite: none | file: D:\AI\achievements\approved\nexus-pearl.png -> godot/assets/achievements/nexus-pearl.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A single large pearl with a pale violet sheen rests in an open clam shell on a rock. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 29. `nexus-gold`

island: **magmaglass-rift** | sprite: none | file: D:\AI\achievements\approved\nexus-gold.png -> godot/assets/achievements/nexus-gold.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A tall heap of gold coins spills out of an open treasure chest. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 30. `adv-bind`

island: **whisperleaf-hollow** | sprite: none | file: D:\AI\achievements\approved\adv-bind.png -> godot/assets/achievements/adv-bind.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A round crystal capture vessel lies in the moss, wobbling, with a small bright creature silhouette inside it. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 31. `adv-kills`

island: **thunderhum-steppe** | sprite: emberfang-f2 | file: D:\AI\achievements\approved\adv-kills.png -> godot/assets/achievements/adv-kills.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling stands in a heroic pose on a small hill, a crowd of dazed wild creatures lying around it with little stars over their heads. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 32. `adv-bosses`

island: **magmaglass-rift** | sprite: none | file: D:\AI\achievements\approved\adv-bosses.png -> godot/assets/achievements/adv-bosses.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A row of five huge defeated monster silhouettes lies in the distance under a banner planted in the ground. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 33. `adv-solo`

island: **stormsea-expanse** | sprite: splashfin-f2 | file: D:\AI\achievements\approved\adv-solo.png -> godot/assets/achievements/adv-solo.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling stands alone and brave facing a gigantic storm creature towering over the waves. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 34. `adv-shinyseen`

island: **whisperleaf-hollow** | sprite: none | file: D:\AI\achievements\approved\adv-shinyseen.png -> godot/assets/achievements/adv-shinyseen.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A wild creature with unusual sparkling colours peeks out from behind a tree, while a startled traveller's hat lies on the ground. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 35. `adv-shinybind`

island: **whispering-tides** | sprite: none | file: D:\AI\achievements\approved\adv-shinybind.png -> godot/assets/achievements/adv-shinybind.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A crystal capture vessel glows with a rainbow-coloured sparkling creature inside it, resting in the sand. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 36. `breed-eggs`

island: **whisperleaf-hollow** | sprite: none | file: D:\AI\achievements\approved\breed-eggs.png -> godot/assets/achievements/breed-eggs.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A nest of soft moss holding a speckled egg, gently glowing, under a small glass dome. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 37. `breed-hybrid`

island: **verdigris-canopy** | sprite: none | file: D:\AI\achievements\approved\breed-hybrid.png -> godot/assets/achievements/breed-hybrid.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. Two different little creatures, one leafy green and one watery blue, look proudly at a newly hatched baby that mixes both of them. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 38. `breed-special`

island: **null-horizon** | sprite: none | file: D:\AI\achievements\approved\breed-special.png -> godot/assets/achievements/breed-special.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. An open old recipe book glowing on a stone table, with a strange rare egg beside it marked with a swirl. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 39. `breed-mutation`

island: **smoldering-caldera** | sprite: none | file: D:\AI\achievements\approved\breed-mutation.png -> godot/assets/achievements/breed-mutation.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A cracked egg with a bright light shining out of the crack, the shell patterns shifting to brighter colours. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 40. `breed-shinyhatch`

island: **whispering-tides** | sprite: none | file: D:\AI\achievements\approved\breed-shinyhatch.png -> godot/assets/achievements/breed-shinyhatch.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. An egg hatching on the beach, a sparkling unusually coloured baby creature popping out of the shell. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 41. `breed-zenith`

island: **zenith-spire** | sprite: none | file: D:\AI\achievements\approved\breed-zenith.png -> godot/assets/achievements/breed-zenith.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A tall ivory and gold egg rests on a marble plinth, radiant light around it. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 42. `breed-aetheric`

island: **zenith-spire** | sprite: none | file: D:\AI\achievements\approved\breed-aetheric.png -> godot/assets/achievements/breed-aetheric.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A translucent-looking pale egg made of aether light hovers above an altar at the top of the spire. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 43. `secret-runaway`

island: **whisperleaf-hollow** | sprite: sproutlet-f1 | file: D:\AI\achievements\approved\secret-runaway.png -> godot/assets/achievements/secret-runaway.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling dashes away across the moss with a puff of dust behind it, looking back over its shoulder annoyed. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 44. `secret-headpats`

island: **whisperleaf-hollow** | sprite: buzzbud-f1 | file: D:\AI\achievements\approved\secret-headpats.png -> godot/assets/achievements/secret-headpats.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling closes its eyes happily as a big gentle hand pats its head, little hearts floating up. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 45. `secret-cold-shoulder`

island: **verdigris-canopy** | sprite: cinderpup-f1 | file: D:\AI\achievements\approved\secret-cold-shoulder.png -> godot/assets/achievements/secret-cold-shoulder.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling sits on a perch with its back turned to the viewer, arms folded, clearly sulking. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 46. `secret-wish`

island: **null-horizon** | sprite: none | file: D:\AI\achievements\approved\secret-wish.png -> godot/assets/achievements/secret-wish.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A small sparkling creature drifts across a night sky, a shooting star trailing behind it. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 47. `secret-hop-scotch`

island: **whisperleaf-hollow** | sprite: none | file: D:\AI\achievements\approved\secret-hop-scotch.png -> godot/assets/achievements/secret-hop-scotch.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. Five small round creatures jump in the air at the same time, mid-hop, with happy faces. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 48. `secret-letter-bounce`

island: **thunderhum-steppe** | sprite: none | file: D:\AI\achievements\approved\secret-letter-bounce.png -> godot/assets/achievements/secret-letter-bounce.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. Big chunky wooden alphabet blocks bouncing in the air above the grass, caught mid-bounce. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 49. `secret-konami`

island: **null-horizon** | sprite: none | file: D:\AI\achievements\approved\secret-konami.png -> godot/assets/achievements/secret-konami.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. An old retro game controller with a cross-shaped pad and two round buttons floats in space, glowing in rainbow colours. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 50. `secret-patience`

island: **smoldering-caldera** | sprite: none | file: D:\AI\achievements\approved\secret-patience.png -> godot/assets/achievements/secret-patience.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. An egg in a warm nest with a small cross face drawn by its shape, a tiny knuckle knocking on its shell. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 51. `secret-bell`

island: **fractured-quarry** | sprite: none | file: D:\AI\achievements\approved\secret-bell.png -> godot/assets/achievements/secret-bell.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A small brass bell on a stand rings on its own in an empty quarry, one lonely tumbleweed rolling by. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 52. `secret-stare-down`

island: **thunderhum-steppe** | sprite: none | file: D:\AI\achievements\approved\secret-stare-down.png -> godot/assets/achievements/secret-stare-down.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. Two creatures glare at each other nose to nose, eyes narrowed, a tense wind blowing the grass. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 53. `secret-night-owl`

island: **null-horizon** | sprite: eclipsa-f1 | file: D:\AI\achievements\approved\secret-night-owl.png -> godot/assets/achievements/secret-night-owl.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling sits awake by a small lantern under a big moon, eyes wide, a clock nearby showing three o'clock. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 54. `secret-catch-release`

island: **whispering-tides** | sprite: none | file: D:\AI\achievements\approved\secret-catch-release.png -> godot/assets/achievements/secret-catch-release.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. An open crystal vessel on the shore, a sparkling creature hopping out of it towards the sea, waving goodbye. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 55. `secret-try-again`

island: **fractured-quarry** | sprite: tuskcub-f1 | file: D:\AI\achievements\approved\secret-try-again.png -> godot/assets/achievements/secret-try-again.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. The Aetherling picks itself up from the dust with a bandage on its head, determined, a little flag in its paw. The Aetherling is exactly the creature in the second reference image: the same shape, colours and markings, painted in the same style as the scene. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 56. `secret-bargain-bin`

island: **magmaglass-rift** | sprite: none | file: D:\AI\achievements\approved\secret-bargain-bin.png -> godot/assets/achievements/secret-bargain-bin.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. A wooden crate labelled with only a drawn coin symbol, a single copper coin on top of a pile of odd junk. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```

### 57. `secret-riches-to-rags`

island: **stormsea-expanse** | sprite: none | file: D:\AI\achievements\approved\secret-riches-to-rags.png -> godot/assets/achievements/secret-riches-to-rags.png

```
A square painted illustration for an achievement in a cute creature-collecting idle game, painted in exactly the same soft painterly digital illustration style, rich colour and light as the first reference image, and set in the same place as the first reference image. An empty treasure chest on a rock with one lonely coin at the bottom, a single moth fluttering out of it. The scene fills the whole square, with one clear subject near the centre that reads well at a small size, and the colours slightly deep and rich like the reference. No text, no letters, no numbers, no user interface, no border, no frame, no watermark.
```
