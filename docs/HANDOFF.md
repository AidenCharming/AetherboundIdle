# Handoff: context from the design chat

This project was designed in a long brainstorming chat on claude.ai before any code existed. The repo docs (`design.md`, `content-data.md`, `plan.md`, `PROGRESS.md`) hold the decisions. This file holds what the docs don't: how the designer works, why some decisions were made, and the unfinished work that lives outside the repo. Read it once at the start of a design or review session. Build sessions don't need it.

## The designer
- Loves incremental games and sorting games (a sorting game is a separate later idea). A collector and completionist, which is why collection tracks, hidden recipes, shinies, and Aether-Log completion are core.
- Got tired of brainstorming and wanted a visual product fast. Prefers concrete recommendations, paste-ready prompts, and a short list of what to check, over open-ended options.
- Uses Claude Code in the desktop app (Windows, project at `C:\ClaudeProjects\Aetherbound Idle`). PowerShell blocks `npm`; the fix was `Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned` (already applied), or use `npm.cmd`.
- Uses Gemini (Pro when available, Flash or Flash Lite when out of quota) for naming. Flash tracks rules poorly: expect suffix repetition, dropped constraints, and copied ability names. Pro is better.

## Working pattern
- Design chat: the designer pastes AI outputs (Gemini naming batches, Claude Code summaries) and asks for a review. Review against the rules in `design.md`, list concrete violations, then give a corrected paste-ready prompt.
- When Claude Code asks the designer multiple-choice questions about doc contradictions, give a recommended answer for each, with the reason.
- Build sessions: one model per session (switching mid-session re-reads the whole context and burns usage). Opus for the sim core and offline math (1.4-1.5), Sonnet for scaffolding, data, and UI. Ultracode off unless a single audit justifies the keyword `ultracode`.
- Session names: `Aetherbound P<phase> · <steps> <topic> (<model>)`.

## Why some decisions were made (not in the docs)
- **No prestige:** breeding and collection are the long-term hook. An optional reset can be added later if the late game stalls.
- **Hybrids are decided by parent species, not just type:** default hybrid per type pair (15) plus hidden special recipes (30 planned). Makes breeding a discovery game and gives the Aether-Log something to do.
- **Void is not a shapeshifter:** it keeps its own identity (Aether skills, neutral 1.25 / 0.75 combat, ratio about 1.67, deliberately under a favorable type matchup at 2.0). Void hybrids get half the bonus.
- **Forms give a smaller speed bonus than stats** (+8% / +16% speed vs +20% / +40% stats) so forms never rival rarity, which spans several times more.
- **Rarity has no pity system** (pure luck is the point). Shinies have a separate soft pity.
- **Skills never fail and have no hazards.** Idle game: no failure states, no bonuses for active clicking.
- **Vessel bootstrap:** Vessel Crafting is a Void skill but Void is the last zone, so open Fabrication crafts the lowest tier (the Tinkerer's Vessel) and the tutorial gives 5.
- **Trait structure:** one innate signature trait per species (not rerollable, not inherited) plus up to 3 pool traits (rerollable, inheritable, strength rolled per creature).

## Naming work still outside the repo
Special recipes are being generated in Gemini in 3 chunks of 10:
- **Chunk 1** (Verdant/Telluric, Verdant/Pyric, Verdant/Aqueous, Verdant/Voltaic, Telluric/Pyric) came back and needed fixes: forms must be the SAME animal growing (several swapped animals); every hybrid trait must trigger only while working its PRIMARY skill and not duplicate a parent's trait; three abilities should be support not damage; 10 locked renames (Gladeflint → Sorrelcliff, Willowboulder → Rowanboulder, Acornslate → Hazelslate, Thicketmesa → Nettlemesa, Fernsear → Brackensear, Gladekiln → Yarrowflare, Ferneddy → Sedgestilt, Willowflux → Ivyflux, Lichenamp → Burrbolt, Boulderkiln → Cliffscorch). Status: fix prompt sent; the corrected result has NOT been reviewed yet.
- **Chunk 2 and 3:** the remaining pairs (Telluric/Aqueous, Telluric/Voltaic, Pyric/Aqueous, Pyric/Voltaic, Aqueous/Voltaic, and the 5 Void pairs). Not started.
- **Batch 4 extras:** same-type sibling species (1 per type), the Voltaic zone name and boss, and improved names for the bench/habitat, incubators, and Aether-Log.
- Recipes go in `recipes.json` (`special` list is empty). Each needs a hidden-recipe hint string for the Aether-Log.

**Naming rules to restate in every Gemini prompt:** each type has its own name roots, no suffix more than twice in a batch, unique against everything in `content-data.md` plus the locked renames, no bosses' names, no real-world IP, cosmetic-only descriptions, traits use only the allowed mechanics, every form is a creature with a face and body. Banned/retired: -mite, -weaver, Plasma-, Chasm-, Surge-, Spark-, Matrix, Nexus, Aetheric, Abyssal, Shinsu. Exhausted roots: Ember-, Cinder-, Moss-, Hush-, Brine-, Tide-, Null-, Rift-, Shale-, Smolder-, Crystal-, Grid, -wire, -core, Sprout-, Lumber-, Thicket-, Fern-, Willow-, Glade-, Acorn-, Lichen-. Fresh palettes: Verdant (vine, bark, thistle, pollen, clover, sorrel, bracken, hazel, rowan, yarrow, sedge, ivy, burr, nettle), Telluric (cliff, ridge, flint, cairn, gravel, slate, boulder, obsidian, mesa, pumice), Pyric (flare, kiln, coal, scorch, pyre, sear, lava, brand, blaze, char), Aqueous (ripple, brook, kelp, coral, spray, eddy, reef, gill, drizzle, lagoon), Voltaic (volt, ohm, amp, pulse, flux, bolt, relay, filament, dynamo, arc), Void (gloam, umbra, star, dusk, wisp, murk, veil, astral, hollow, eventide).

## Open design questions (also in PROGRESS.md or design.md section 15)
- Overclocked's "resets on task completion" is ambiguous (needed before Phase 3). Do NOT model it in Phase 1.
- Offline slot-ordering once skills consume resources (before Phase 3).
- Whether Woodcutting tiers (and later skills) scale time, XP, and gold by tier (proposed: oak 3000ms / 10 xp / 2 gold, willow 4000 / 25 / 6, yew 5000 / 50 / 15).
- Fishing expansion (bait, deep-sea zones, treasure system) is a backlog item the designer is excited about.
- Collection milestone reward tables, full gear list, zone wild-species lists, the tutorial script.

## Art plan
Placeholders (emoji on type-colored cards) for everything through Phase 4. Later: about 207 creature sprites (24 base + 15 default hybrids + 30 special, each x 3 forms), plus eggs, icons, and backgrounds. Shinies and rarity tiers are runtime effects (hue shift, frames, glow) and need no extra sprites. Pick one consistent art style first and generate against a reference sheet. Check store disclosure rules for AI-generated art before publishing.
