// The one step function (plan.md 4.7). The online tick calls it every frame with that frame's dt, and offline
// catch-up calls it once with dt = the elapsed window, so the two paths cannot drift apart: there is no second
// implementation of anything.
import { content, type Content } from '../data'
import type { GameState, PlayTimeCredit } from '../types/state'
import { accrueAether } from './aether'
import type { SimResult } from './events'
import { sanitizeDt } from './formulas'
import { advanceSkills, type AdvanceOptions } from './skills'

export interface StepOptions extends AdvanceOptions {
  /**
   * Which play-time counter this `dt` belongs to (step 1.9c). The default is ordinary online play. `applyOffline`
   * passes 'awayMs' for a real away window and 'devMs' for the dev panel's fast-forward, and what it passes is the
   * window it GRANTED (already capped), because that is the `dt` it hands to this function. 'none' credits nothing.
   */
  credit?: PlayTimeCredit
}

/**
 * Advances the game by `dtMs`: every working slot, then bench Aether, then the play-time counter. A non-positive,
 * NaN or infinite `dt` changes nothing (returns the same state object). `lastSeen` is not touched here; saving
 * stamps it.
 */
export function step(state: GameState, dtMs: number, opts: StepOptions = {}, c: Content = content): SimResult<GameState> {
  const skills = advanceSkills(state, dtMs, opts, c)
  const next = accrueAether(skills.state, dtMs, c)
  return { state: creditPlayTime(next, dtMs, opts.credit ?? 'onlineMs'), events: skills.events }
}

/**
 * The ONE place `stats` is written, so no path can count twice and none can be forgotten. It adds the same
 * sanitized `dt` the rest of the step used, which is why the counters can never disagree with what was earned:
 * a clamped, skewed or non-finite window earns nothing and counts nothing.
 */
function creditPlayTime(state: GameState, dtMs: number, credit: PlayTimeCredit): GameState {
  const dt = sanitizeDt(dtMs)
  if (dt === 0 || credit === 'none') return state
  return { ...state, stats: { ...state.stats, [credit]: state.stats[credit] + dt } }
}
