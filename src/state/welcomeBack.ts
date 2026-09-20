// The pending "welcome back" summary: which offline catch-ups the player is told about, and what happens when a
// second one arrives before the first has been read. This is presentation policy, not simulation, so it lives in
// the state layer; `sim/offline.ts` produces the summary and never decides whether it is shown.
//
// A catch-up ALWAYS happens. `settings.offlineSummary` only decides whether the player sees the report of it.
import { content, type Content } from '../data'
import type { OfflineSummary, OfflineSkillSummary } from '../sim/offline'
import type { Settings } from '../types/state'

/**
 * What to hold as the pending summary after `summary` was produced. Returns `current` unchanged when the new
 * summary is not worth showing:
 *
 * - a new game has no "away" to report,
 * - the player turned the summary off in Settings,
 * - the window earned was no longer than `offline.awayThresholdMs`, which is the same gap the tick driver treats
 *   as "away" in the first place, so a reload or a short tab switch never opens a dialog.
 *
 * When one is already pending (the player has not read it yet), the two are combined rather than one dropped.
 */
export function queueWelcomeBack(
  current: OfflineSummary | null,
  summary: OfflineSummary | null,
  opts: { isNewGame: boolean; settings: Settings },
  c: Content = content,
): OfflineSummary | null {
  if (!summary || opts.isNewGame || !opts.settings.offlineSummary) return current
  if (summary.elapsedMs <= c.tuning.offline.awayThresholdMs) return current
  return current ? combineSummaries(current, summary) : summary
}

/**
 * Two away windows read as one. Additive fields add up (time, Aether, resources, actions, XP); a skill's level span
 * runs from the earliest `levelBefore` to the latest `levelAfter`; unlocked slots are the union. Fields that are
 * facts about a single window (`capMs`) keep the later value, and the flags are true if either window had them.
 */
export function combineSummaries(a: OfflineSummary, b: OfflineSummary): OfflineSummary {
  const resourcesGained = { ...a.resourcesGained }
  for (const [id, qty] of Object.entries(b.resourcesGained)) resourcesGained[id] = (resourcesGained[id] ?? 0) + qty

  const skills = new Map<string, OfflineSkillSummary>()
  for (const s of [...a.skills, ...b.skills]) {
    const prev = skills.get(s.skillId)
    if (!prev) {
      skills.set(s.skillId, { ...s, slotsUnlocked: [...s.slotsUnlocked] })
      continue
    }
    prev.actions += s.actions
    prev.xpGained += s.xpGained
    prev.levelBefore = Math.min(prev.levelBefore, s.levelBefore)
    prev.levelAfter = Math.max(prev.levelAfter, s.levelAfter)
    for (const i of s.slotsUnlocked) if (!prev.slotsUnlocked.includes(i)) prev.slotsUnlocked.push(i)
    prev.slotsUnlocked.sort((x, y) => x - y)
  }

  return {
    // A clock-skewed window has a negative requestedMs and grants nothing; counting it would subtract time away.
    requestedMs: Math.max(0, a.requestedMs) + Math.max(0, b.requestedMs),
    elapsedMs: a.elapsedMs + b.elapsedMs,
    capMs: b.capMs,
    capped: a.capped || b.capped,
    clockSkewed: a.clockSkewed || b.clockSkewed,
    aetherGained: a.aetherGained + b.aetherGained,
    resourcesGained,
    skills: [...skills.values()],
  }
}
