// Bench Aether (plan.md 4.4). Emission is a continuous rate accrued fractionally from `dt`: there is no
// once-a-minute lump, online or offline, and the same function serves a 200 ms frame and a 12-hour window.
// `tuning.aether.benchEmissionTickMs` is a save/display cadence only and is deliberately not read here, so
// changing it can never change how much a player earns.
import { content, type Content } from '../data'
import type { Creature, GameState } from '../types/state'
import { sanitizeDt } from './formulas'
import { cappedModifier } from './modifiers'

const MS_PER_MIN = 60000

/** Creatures in no work slot (and, later, on no expedition) are the ones that emit. */
export function benchedCreatures(state: GameState): Creature[] {
  return state.creatures.filter((cr) => cr.assignment === null)
}

/** One creature's emission: its rarity's rate scaled by its capped `bench_aether_emission` modifiers. */
export function creatureEmissionPerMin(creature: Creature, c: Content = content): number {
  const rarity = c.rarities[creature.rarityTier - 1]
  if (!rarity) return 0
  return rarity.benchEmissionPerMin * (1 + cappedModifier('bench_aether_emission', creature, null, [], c))
}

export function emissionPerMin(state: GameState, c: Content = content): number {
  let total = 0
  for (const cr of benchedCreatures(state)) total += creatureEmissionPerMin(cr, c)
  return total
}

/**
 * Adds `emissionPerMin * dt / 60000` to `state.aether`. Stored as a float and never rounded, so a short
 * session or a small bench is not silently worth zero. Returns the same state object when nothing accrues.
 */
export function accrueAether(state: GameState, dtMs: number, c: Content = content): GameState {
  const dt = sanitizeDt(dtMs)
  if (dt === 0) return state
  const gained = emissionPerMin(state, c) * (dt / MS_PER_MIN)
  return gained === 0 ? state : { ...state, aether: state.aether + gained }
}
