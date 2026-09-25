# bugtest_benchmark: FAIL

**Why it failed:** 3 invariant breaks

- Played 10:03 real (asked for 10.0 min), seed 1, 733 steps.
- Time compression: 8.00 in-game hours skipped with the bridge `skip` (asked for 8.0).
- Overseer Vance: reached goal 42 of 112 (`bred10`: Lay 10 eggs in the Genesis Pods).
- Screens covered: 45. Stuck: 2. UI gaps: 0.
- fps: min 22, 10th percentile 30, median 30 over 1061 samples.
- Memory: 82 MB at the start, 101 peak, 89 at the end (+9%).

## Goals claimed

| # | Goal | Real time | In-game time |
|---|---|---|---|
| 1 | `work` Put your Sproutlet to work in Woodcutting | 0:03 | 0.0 h |
| 2 | `logs` Gather 10 Oak Logs | 0:30 | 0.0 h |
| 3 | `explore` Send an Aetherling exploring Whisperleaf Hollow | 0:33 | 0.0 h |
| 4 | `bind` Bind a wild Aetherling with a vessel | 1:12 | 0.5 h |
| 5 | `team` Own 3 Aetherlings | 1:13 | 0.5 h |
| 6 | `herb-work` Put an Aetherling to work in Herbalism | 1:16 | 0.5 h |
| 7 | `scav-work` Send an Aetherling Scavenging (any Aetherling can) | 1:17 | 0.5 h |
| 8 | `vessel` Make a Tinker's Vessel in Fabrication (any Aetherling can) | 1:21 | 0.5 h |
| 9 | `mint` Hold 20 Mintleaf | 1:22 | 0.5 h |
| 10 | `kills25` Defeat 25 wild Aetherlings | 1:23 | 0.5 h |
| 11 | `wc10` Reach Woodcutting level 10 | 1:52 | 1.0 h |
| 12 | `breed` Lay your first egg in a Genesis Pod | 1:53 | 1.0 h |
| 13 | `hatch` Hatch an egg | 2:00 | 1.0 h |
| 14 | `captures5` Bind 5 wild Aetherlings | 2:01 | 1.0 h |
| 15 | `boss1` Defeat Old Thicketroll at the end of Whisperleaf Hollow | 3:41 | 2.1 h |
| 16 | `telluric` Bind your first Telluric Aetherling in the Fractured Quarry | 3:50 | 2.1 h |
| 17 | `mine-work` Put a Telluric Aetherling to work in Mining | 3:53 | 2.1 h |
| 18 | `frames` Make 4 Timber Frames in Fabrication (Fabrication level 10) | 4:04 | 2.1 h |
| 19 | `creatures6` Own 6 Aetherlings | 4:07 | 2.1 h |
| 20 | `slot2` Open a second work slot in any skill (skill level 10) | 4:09 | 2.1 h |
| 21 | `works` Build any upgrade in Sanctum Works | 4:11 | 2.1 h |
| 22 | `herb20` Reach Herbalism level 20 | 6:31 | 6.6 h |
| 23 | `boss2` Defeat Granitusk in the Fractured Quarry | 6:32 | 6.6 h |
| 24 | `pyric` Bind your first Pyric Aetherling in the Smoldering Caldera | 6:34 | 6.6 h |
| 25 | `smith-work` Put a Pyric Aetherling to work in Smithing | 6:35 | 6.6 h |
| 26 | `cook-work` Put a Pyric Aetherling to work in Cooking | 6:36 | 6.6 h |
| 27 | `species10` Log 10 species in the Aether-Log | 6:38 | 6.6 h |
| 28 | `form2` Evolve an Aetherling to its second form (level 20) | 6:39 | 6.6 h |
| 29 | `boss3` Defeat Ignis Prime in the Smoldering Caldera | 7:09 | 6.6 h |
| 30 | `aqueous` Bind your first Aqueous Aetherling at Whispering Tides | 7:15 | 6.6 h |
| 31 | `fish-work` Put an Aqueous Aetherling to work in Fishing | 7:19 | 7.1 h |
| 32 | `hybrid` Hatch a hybrid (breed two Aetherlings of different types) | 7:21 | 7.1 h |
| 33 | `total150` Reach a total skill level of 150 | 7:23 | 7.1 h |
| 34 | `captures15` Bind 15 wild Aetherlings | 7:24 | 7.1 h |
| 35 | `rarity3` Own a Steady Aetherling (better eggs or luckier binds) | 7:28 | 7.1 h |
| 36 | `boss4` Defeat Leviathan Core at Whispering Tides | 9:09 | 8.2 h |
| 37 | `voltaic` Bind your first Voltaic Aetherling on the Thunderhum Steppe | 9:18 | 8.2 h |
| 38 | `circ-work` Put a Voltaic Aetherling to work in Circuitry | 9:20 | 8.2 h |
| 39 | `upgrades3` Build 3 upgrades in Sanctum Works | 9:21 | 8.2 h |
| 40 | `species15` Log 15 species in the Aether-Log | 9:22 | 8.2 h |
| 41 | `slot3` Open a third work slot in any skill (skill level 25) | 9:25 | 8.2 h |

Active at the end: goal 42 `bred10` (8/10).

## Errors

None.

## Invariant breaks

- **asked for sanctum , the game shows pods ** (at 4:02). Screenshot: [shots\045_break.png](shots\045_break.png)

<details><summary>the last 30 steps before it</summary>

```
 225.4s #278 click 'Sanctum Works' at 109,821
 225.7s #279 click 'Build' at 452,358
 225.7s #280 built an upgrade (4 levels now)
 230.6s #281 click 'Sanctum' at 109,81
 230.8s #282 click 'Claim' at 1521,189
 230.9s #283 CLAIMED goal 15 telluric
 231.1s #284 click 'Mining' at 109,235
 231.3s #285 click 'Assign an Aetherling' at 387,400
 231.4s #286 click card c22 at 420,360
 232.8s #287 goal 16: mine-work (Put a Telluric Aetherling to work in Mining)
 233.0s #288 click 'Sanctum' at 109,81
 233.3s #289 click 'Claim' at 1521,189
 233.3s #290 CLAIMED goal 16 mine-work
 233.7s #291 click 'Genesis Pods' at 109,669
 234.0s #292 click 'Hatch' at 606,860
 237.9s #293 click 'Click to continue' at 800,450
 238.8s #294 click 'Choose parent A' at 617,79
 239.0s #295 click card c12 at 1047,745
 239.2s #296 click 'Close' at 1232,163
 239.7s #297 click 'Close' at 1232,163
 240.1s #298 click 'Choose parent B' at 1201,79
 240.3s #299 click card c22 at 567,360
 240.5s #300 click 'Close' at 1232,163
 240.9s #301 click 'Close' at 1232,163
 241.4s #302 click 'Tier 1 ·' at 356,300
 241.6s #303 click 'Lay an egg' at 1438,510
 241.6s #304 laid an egg: c12 + c22, tier 1
 242.4s #305 goal 17: frames (Make 4 Timber Frames in Fabrication (Fabrication level 10))
 242.6s #306 click 'Sanctum' at 109,81
 242.6s #307 BREAK asked for sanctum , the game shows pods 
```
</details>

- **goal frames is done but the Sanctum shows no Claim button** (at 4:04). Screenshot: [shots\046_break.png](shots\046_break.png)

<details><summary>the last 30 steps before it</summary>

```
 225.7s #279 click 'Build' at 452,358
 225.7s #280 built an upgrade (4 levels now)
 230.6s #281 click 'Sanctum' at 109,81
 230.8s #282 click 'Claim' at 1521,189
 230.9s #283 CLAIMED goal 15 telluric
 231.1s #284 click 'Mining' at 109,235
 231.3s #285 click 'Assign an Aetherling' at 387,400
 231.4s #286 click card c22 at 420,360
 232.8s #287 goal 16: mine-work (Put a Telluric Aetherling to work in Mining)
 233.0s #288 click 'Sanctum' at 109,81
 233.3s #289 click 'Claim' at 1521,189
 233.3s #290 CLAIMED goal 16 mine-work
 233.7s #291 click 'Genesis Pods' at 109,669
 234.0s #292 click 'Hatch' at 606,860
 237.9s #293 click 'Click to continue' at 800,450
 238.8s #294 click 'Choose parent A' at 617,79
 239.0s #295 click card c12 at 1047,745
 239.2s #296 click 'Close' at 1232,163
 239.7s #297 click 'Close' at 1232,163
 240.1s #298 click 'Choose parent B' at 1201,79
 240.3s #299 click card c22 at 567,360
 240.5s #300 click 'Close' at 1232,163
 240.9s #301 click 'Close' at 1232,163
 241.4s #302 click 'Tier 1 ·' at 356,300
 241.6s #303 click 'Lay an egg' at 1438,510
 241.6s #304 laid an egg: c12 + c22, tier 1
 242.4s #305 goal 17: frames (Make 4 Timber Frames in Fabrication (Fabrication level 10))
 242.6s #306 click 'Sanctum' at 109,81
 242.6s #307 BREAK asked for sanctum , the game shows pods 
 244.0s #308 BREAK goal frames is done but the Sanctum shows no Claim button
```
</details>

- **clicked Build but upgrade levels went 6 -> 6** (at 6:33). Screenshot: [shots\054_break.png](shots\054_break.png)

<details><summary>the last 30 steps before it</summary>

```
 367.7s #451 click 'Choose parent B' at 1201,79
 367.8s #452 click card c56 at 407,360
 367.8s #453 click 'Close' at 1232,163
 368.2s #454 click 'Tier 2 ·' at 521,300
 368.3s #455 click 'Lay an egg' at 1438,510
 368.3s #456 laid an egg: c44 + c56, tier 2
 382.3s #457 skip 0.50h (compress 7/10): {"actions": 5515, "aether": 2675.0, "capped": false, "elapsed": 1800.0, "events": 5, "gained": 14, "gold": 3362.0, "levels": 5, "usedSeconds": 1800.0}
 382.4s #458 click 'Continue' at 1180,787
 382.9s #459 click 'Smithing' at 109,165
 382.9s #460 click 'Iron Bar' at 651,699
 383.1s #461 click 'Woodcutting' at 109,63
 383.1s #462 click 'Maple Tree' at 915,681
 386.3s #463 click 'Aether-Log' at 109,725
 386.4s #464 click 'Milestones' at 559,167
 386.5s #465 click 'Claim' at 422,837
 388.1s #466 click 'Smithing' at 109,263
 388.2s #467 click 'Assign an Aetherling' at 667,430
 388.3s #468 click card c56 at 420,380
 388.3s #469 click 'Close' at 1232,163
 390.2s #470 skip 3.00h (time-away jump): {"actions": 30716, "aether": 11580.0, "capped": false, "elapsed": 10800.0, "events": 9, "gained": 14, "gold": 20207.0, "levels": 5, "usedSeconds": 10800.0}
 390.5s #471 click 'Continue' at 1180,787
 391.8s #472 click 'Sanctum' at 109,81
 391.9s #473 click 'Claim' at 1521,189
 391.9s #474 CLAIMED goal 21 herb20
 392.7s #475 goal 22: boss2 (Defeat Granitusk in the Fractured Quarry)
 392.9s #476 click 'Claim' at 1521,189
 392.9s #477 CLAIMED goal 22 boss2
 393.2s #478 click 'Sanctum Works' at 109,821
 393.3s #479 click 'Build' at 1244,695
 393.3s #480 BREAK clicked Build but upgrade levels went 6 -> 6
```
</details>

## Stuck

- no 'Explore' for Whisperleaf Hollow (at 0:32). Screenshot: [shots\003_stuck.png](shots\003_stuck.png)

<details><summary>the last 25 steps before it</summary>

```
   0.0s #1 new game in slot 2
   1.8s #2 click "Let's start: open Woodcutting" at 800,597
   1.9s #3 key Escape
   2.2s #4 click 'Close' at 962,230
   2.5s #5 goal 0: work (Put your Sproutlet to work in Woodcutting)
   2.6s #6 click 'Assign an Aetherling' at 387,400
   2.6s #7 click card c1 at 420,371
   2.7s #8 click 'Close' at 1232,163
   3.7s #9 click 'Sanctum' at 109,81
   3.8s #10 click 'Claim' at 1521,189
   3.8s #11 CLAIMED goal 0 work
   4.7s #12 goal 1: logs (Gather 10 Oak Logs)
   6.3s #13 click 'Egg Market' at 109,781
  19.5s #14 click 'Sanctum' at 109,81
  19.6s #15 watching goal logs finish on the Sanctum (7/10)
  29.3s #16 Claim showed up on the open Sanctum
  30.5s #17 click 'Claim' at 1521,189
  30.5s #18 CLAIMED goal 1 logs
  30.8s #19 click 'Expeditions' at 109,743
  31.0s #20 click 'Party' at 370,760
  31.2s #21 click 'Add an Aetherling' at 416,847
  31.4s #22 click card c1 at 407,360
  32.0s #23 click 'Whisperleaf Hollow' at 1076,696
  32.0s #24 click 'Explore' failed: no visible button says "Explore"
  32.0s #25 STUCK no 'Explore' for Whisperleaf Hollow
```
</details>

- Sanctum Works: Genesis Pods is affordable but no Build button is enabled (at 3:26). Screenshot: [shots\044_stuck.png](shots\044_stuck.png)

<details><summary>the last 30 steps before it</summary>

```
 169.2s #235 click card c9 at 407,360
 169.2s #236 party: swapped c1 for c9
 169.2s #237 click 'Swap' failed: no visible button says "Swap"
 169.2s #238 click 'Close' at 1232,163
 169.5s #239 click 'Swap' at 996,847
 169.6s #240 click card c7 at 407,360
 169.6s #241 party: swapped c4 for c7
 169.7s #242 click 'Whisperleaf Hollow' at 379,179
 169.7s #243 click 'Explore' at 1076,696
 169.7s #244 expedition running at whisperleaf-hollow with ['c9', 'c2', 'c7']
 173.3s #245 click 'Woodcutting' at 109,155
 173.3s #246 click 'Assign an Aetherling' at 667,400
 173.4s #247 click card c1 at 978,380
 173.4s #248 click 'Close' at 1232,163
 173.8s #249 click 'Scavenging' at 109,315
 173.8s #250 click 'Assign an Aetherling' at 387,400
 173.9s #251 click card c4 at 792,371
 173.9s #252 click 'Close' at 1232,163
 175.0s #253 click 'Broken Carts' at 651,681
 177.1s #254 click 'Sanctum Works' at 109,821
 177.2s #255 click 'Build' at 848,645
 177.2s #256 built an upgrade (2 levels now)
 179.2s #257 click 'Scavenging' at 109,125
 179.3s #258 click 'Assign an Aetherling' at 667,400
 179.3s #259 click card c8 at 978,371
 179.4s #260 click 'Close' at 1232,163
 191.8s #261 click 'Sanctum Works' at 109,821
 191.9s #262 click 'Build' at 848,383
 191.9s #263 built an upgrade (3 levels now)
 206.4s #264 STUCK Sanctum Works: Genesis Pods is affordable but no Build button is enabled
```
</details>

## UI gaps (bridge shortcuts used)

None.

## Screens covered

- aetherlog: [shots\023_aetherlog.png](shots\023_aetherlog.png)
- aetherlog-Creaturedex: [shots\024_aetherlog-Creaturedex.png](shots\024_aetherlog-Creaturedex.png)
- aetherlog-Milestones: [shots\026_aetherlog-Milestones.png](shots\026_aetherlog-Milestones.png)
- aetherlog-Recipes: [shots\025_aetherlog-Recipes.png](shots\025_aetherlog-Recipes.png)
- eggmarket: [shots\035_eggmarket.png](shots\035_eggmarket.png)
- expeditions: [shots\019_expeditions.png](shots\019_expeditions.png)
- expeditions-Auto-bind: [shots\021_expeditions-Auto-bind.png](shots\021_expeditions-Auto-bind.png)
- expeditions-Party: [shots\020_expeditions-Party.png](shots\020_expeditions-Party.png)
- expeditions-Supplies: [shots\022_expeditions-Supplies.png](shots\022_expeditions-Supplies.png)
- hatch-reveal: [shots\043_hatch-reveal.png](shots\043_hatch-reveal.png)
- inventory: [shots\027_inventory.png](shots\027_inventory.png)
- inventory-bulk-sell: [shots\028_inventory-bulk-sell.png](shots\028_inventory-bulk-sell.png)
- market: [shots\029_market.png](shots\029_market.png)
- market-Boosts: [shots\033_market-Boosts.png](shots\033_market-Boosts.png)
- market-Materials: [shots\032_market-Materials.png](shots\032_market-Materials.png)
- market-Today's stock: [shots\030_market-Today-s-stock.png](shots\030_market-Today-s-stock.png)
- market-Vessels: [shots\031_market-Vessels.png](shots\031_market-Vessels.png)
- market-Work slots: [shots\034_market-Work-slots.png](shots\034_market-Work-slots.png)
- menu: [shots\037_menu.png](shots\037_menu.png)
- nexus: [shots\016_nexus.png](shots\016_nexus.png)
- nexus-detail: [shots\017_nexus-detail.png](shots\017_nexus-detail.png)
- notifications: [shots\038_notifications.png](shots\038_notifications.png)
- options-Audio: [shots\048_options-Audio.png](shots\048_options-Audio.png)
- options-Display: [shots\049_options-Display.png](shots\049_options-Display.png)
- options-Gameplay: [shots\050_options-Gameplay.png](shots\050_options-Gameplay.png)
- pods: [shots\018_pods.png](shots\018_pods.png)
- pods-egg: [shots\041_pods-egg.png](shots\041_pods-egg.png)
- sanctum: [shots\004_sanctum.png](shots\004_sanctum.png)
- skill-aether-weaving: [shots\005_skill-aether-weaving.png](shots\005_skill-aether-weaving.png)
- skill-circuitry: [shots\006_skill-circuitry.png](shots\006_skill-circuitry.png)
- skill-cooking: [shots\007_skill-cooking.png](shots\007_skill-cooking.png)
- skill-fabrication: [shots\008_skill-fabrication.png](shots\008_skill-fabrication.png)
- skill-fishing: [shots\009_skill-fishing.png](shots\009_skill-fishing.png)
- skill-herbalism: [shots\010_skill-herbalism.png](shots\010_skill-herbalism.png)
- skill-mining: [shots\011_skill-mining.png](shots\011_skill-mining.png)
- skill-scavenging: [shots\012_skill-scavenging.png](shots\012_skill-scavenging.png)
- skill-smithing: [shots\013_skill-smithing.png](shots\013_skill-smithing.png)
- skill-vessel-crafting: [shots\014_skill-vessel-crafting.png](shots\014_skill-vessel-crafting.png)
- skill-woodcutting: [shots\015_skill-woodcutting.png](shots\015_skill-woodcutting.png)
- title: [shots\051_title.png](shots\051_title.png)
- title-load: [shots\052_title-load.png](shots\052_title-load.png)
- welcome: [shots\001_welcome.png](shots\001_welcome.png)
- welcome-back: [shots\039_welcome-back.png](shots\039_welcome-back.png)
- welcome-back-jump: [shots\053_welcome-back-jump.png](shots\053_welcome-back-jump.png)
- works: [shots\036_works.png](shots\036_works.png)

## Save and load

Everything came back.

| | Before | After |
|---|---|---|
| gold | 13019.0 | 13021.0 |
| aether | 4408.4 | 4409.3 |
| creatures | 44 | 44 |
| goal | 21 | 21 |
| bred | 4 | 4 |
| captures | 41 | 41 |
| species | 8 | 8 |
| skill levels | 82 | 82 |

## Time away

```
{
 "actions": 30716,
 "aether": 11580.0,
 "capped": false,
 "elapsed": 10800.0,
 "events": 9,
 "gained": 14,
 "gold": 20207.0,
 "levels": 5,
 "usedSeconds": 10800.0
}
```

