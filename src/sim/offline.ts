// Offline catch-up (plan.md 4.5): bulk, never a tick replay. This file owns only the WINDOW, meaning how much
// time to grant; all the work is `step` with `dt = elapsed`, the same function the online tick uses, so it has
// no maths of its own and cannot drift from the live game.
import { content, type Content } from '../data'
import type { GameState } from '../types/state'
import type { SimEvent } from './events'
import { step } from './tick'

const MS_PER_HOUR = 3_600_000

export interface OfflineSkillSummary {
  skillId: string
  actions: number
  xpGained: number
  levelBefore: number
  levelAfter: number
  slotsUnlocked: number[]
}

/** Everything the "welcome back" screen (step 1.8) shows. */
export interface OfflineSummary {
  /** `now - lastSeen` as measured. Negative when the clock went backwards. */
  requestedMs: number
  /** The window actually simulated: `requestedMs` clamped to [0, cap]. */
  elapsedMs: number
  capMs: number
  /** The player was away longer than the cap, so the excess earned nothing. */
  capped: boolean
  /** `now` was before `lastSeen`. Nothing is granted and the clock is re-anchored. */
  clockSkewed: boolean
  aetherGained: number
  resourcesGained: Record<string, number>
  skills: OfflineSkillSummary[]
}

export interface OfflineResult {
  state: GameState
  events: SimEvent[]
  summary: OfflineSummary
}

/**
 * Catches the game up from `state.lastSeen` to `now`, and re-anchors `lastSeen` to `now`.
 *
 * - The window is `min(now - lastSeen, capHours)`.
 * - A zero window changes nothing but `lastSeen`, and consumes no randomness.
 * - A negative window (clock skew: the system clock moved backwards) is treated as zero rather than as an
 *   error, and `lastSeen` is re-anchored to `now`. Leaving it in the future would freeze progress until the
 *   real clock caught up, and running the sim backwards would be worse.
 * - A non-finite `now` or `lastSeen` is treated as a zero window too.
 *
 * The dev panel's fast-forward (plan 7.1) rewinds `lastSeen` and calls this same function.
 */
export function applyOffline(state: GameState, now: number, c: Content = content): OfflineResult {
  const capMs = c.tuning.offline.capHours * MS_PER_HOUR
  const requestedMs = now - state.lastSeen
  const elapsedMs = Number.isFinite(requestedMs) ? Math.min(Math.max(requestedMs, 0), capMs) : 0

  const stepped = elapsedMs > 0 ? step(state, elapsedMs, { offline: true }, c) : { state, events: [] as SimEvent[] }
  const anchored = Number.isFinite(now) ? { ...stepped.state, lastSeen: now } : stepped.state

  return {
    state: anchored,
    events: stepped.events,
    summary: {
      requestedMs,
      elapsedMs,
      capMs,
      capped: requestedMs > capMs,
      clockSkewed: requestedMs < 0,
      aetherGained: anchored.aether - state.aether,
      ...summarize(state, stepped.events),
    },
  }
}

function summarize(before: GameState, events: readonly SimEvent[]): Pick<OfflineSummary, 'resourcesGained' | 'skills'> {
  const resourcesGained: Record<string, number> = {}
  const bySkill = new Map<string, OfflineSkillSummary>()
  const entry = (skillId: string): OfflineSkillSummary => {
    let e = bySkill.get(skillId)
    if (!e) {
      const level = before.skills[skillId]?.level ?? 1
      e = { skillId, actions: 0, xpGained: 0, levelBefore: level, levelAfter: level, slotsUnlocked: [] }
      bySkill.set(skillId, e)
    }
    return e
  }
  for (const ev of events) {
    if (ev.type === 'action-complete') {
      const e = entry(ev.skillId)
      e.actions += ev.count
      e.xpGained += ev.skillXp
      for (const [id, qty] of Object.entries(ev.outputs)) resourcesGained[id] = (resourcesGained[id] ?? 0) + qty
    } else if (ev.type === 'skill-level-up') {
      entry(ev.skillId).levelAfter = ev.level
    } else if (ev.type === 'slot-unlocked') {
      entry(ev.skillId).slotsUnlocked.push(ev.slotIndex)
    }
  }
  return { resourcesGained, skills: [...bySkill.values()] }
}
