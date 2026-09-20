// A brand-new game. Phase 1 starts the player with one Sproutlet and nothing else (plan.md 7).
import { content, type Content } from '../data'
import type { GameState } from '../types/state'
import { makeCreature } from './creature'
import { slotCount } from './skills'

/**
 * The seed and the clock come in as arguments because the sim never calls Math.random or Date.now. The
 * caller picks the seed (once, when the save is first created); after that `rngState` is the live state.
 */
export function createInitialState(seed: number, now: number, c: Content = content): GameState {
  const starter = makeCreature('creature-1', 'sproutlet', {}, c)
  return {
    version: c.tuning.save.version,
    lastSeen: now,
    rngState: seed >>> 0,
    aether: 0,
    gold: 0,
    resources: {},
    creatures: [starter],
    nextCreatureSeq: 2,
    skills: Object.fromEntries(
      c.skills.map((skill) => [skill.id, { level: 1, xp: 0, slots: Array.from({ length: slotCount(skill, 1) }, () => null) }]),
    ),
    collection: {
      speciesSeen: [starter.speciesId],
      rarityTiersSeen: { [starter.speciesId]: [starter.rarityTier] },
      recipesFound: [],
      shiniesFound: [],
      formsUnlocked: { [starter.speciesId]: starter.form },
    },
    settings: { offlineSummary: true, devPanelEnabled: false },
    stats: { onlineMs: 0, awayMs: 0, devMs: 0 },
  }
}
