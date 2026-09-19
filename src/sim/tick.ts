// The one step function (plan.md 4.7). The online tick calls it every frame with that frame's dt, and offline
// catch-up calls it once with dt = the elapsed window, so the two paths cannot drift apart: there is no second
// implementation of anything.
import { content, type Content } from '../data'
import type { GameState } from '../types/state'
import { accrueAether } from './aether'
import type { SimResult } from './events'
import { advanceSkills, type AdvanceOptions } from './skills'

/**
 * Advances the game by `dtMs`: every working slot, then bench Aether. A non-positive, NaN or infinite `dt`
 * changes nothing (returns the same state object). `lastSeen` is not touched here; saving stamps it.
 */
export function step(state: GameState, dtMs: number, opts: AdvanceOptions = {}, c: Content = content): SimResult<GameState> {
  const skills = advanceSkills(state, dtMs, opts, c)
  const next = accrueAether(skills.state, dtMs, c)
  return { state: next, events: skills.events }
}
