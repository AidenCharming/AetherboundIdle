import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { emissionPerMin } from '../src/sim/aether'
import type { SimEvent } from '../src/sim/events'
import { applyOffline } from '../src/sim/offline'
import { step } from '../src/sim/tick'
import type { GameState } from '../src/types/state'
import { addCreature, assignmentProblems, HOUR, newGame, NOW, pool, quietContent, sproutletAtWork, variant, work } from './helpers'

const q = quietContent()
const MIN = 60_000

/** A working Sproutlet plus one benched Steady creature (4 Aether/min), on the given content. */
function busy(c = content): GameState {
  const s = addCreature(sproutletAtWork(c), 'sproutlet', { rarityTier: 3 }, c).state
  return s
}

/** Independent re-derivation of the level for a cumulative XP total. */
function expectedLevel(xp: number): number {
  let level = 1
  let need = 0
  for (;;) {
    need += Math.round(100 * 1.1 ** (level - 1))
    if (xp < need || level >= 99) return level
    level++
  }
}

describe('step (the shared online/offline function)', () => {
  it('advances slots and bench Aether together', () => {
    const r = step(busy(q), 3000 * 5, {}, q)
    expect(r.state.resources['oak-log']).toBe(5)
    expect(r.state.aether).toBeCloseTo(4 * (15_000 / MIN))
    expect(r.events).toHaveLength(1)
  })

  for (const dt of [0, -1, -1e9, NaN, Infinity]) {
    it(`a non-positive or non-finite dt (${dt}) returns the very same state`, () => {
      const s = busy()
      const r = step(s, dt)
      expect(r.state).toBe(s)
      expect(r.events).toEqual([])
    })
  }
})

describe('zero window', () => {
  it('changes nothing but lastSeen, consumes no randomness, and reports a zero window', () => {
    const s = busy()
    const r = applyOffline(s, s.lastSeen)
    expect(r.state).toEqual(s)
    expect(r.state.rngState).toBe(s.rngState)
    expect(r.events).toEqual([])
    expect(r.summary).toMatchObject({ requestedMs: 0, elapsedMs: 0, capped: false, clockSkewed: false, aetherGained: 0, resourcesGained: {}, skills: [] })
  })
})

describe('clock-skewed (negative) window', () => {
  const s = busy()
  for (const [label, delta] of [['a few minutes', -5 * MIN], ['a day', -24 * HOUR], ['a decade', -3650 * 24 * HOUR]] as const) {
    it(`now ${label} before lastSeen grants nothing, flags the skew, and re-anchors the clock`, () => {
      const now = s.lastSeen + delta
      const r = applyOffline(s, now)
      expect(r.state).toEqual({ ...s, lastSeen: now })
      expect(r.state.rngState).toBe(s.rngState)
      expect(r.events).toEqual([])
      expect(r.summary).toMatchObject({ requestedMs: delta, elapsedMs: 0, capped: false, clockSkewed: true, aetherGained: 0 })
    })
  }

  it('re-anchoring means progress resumes normally afterwards instead of freezing until the old time returns', () => {
    const skewed = applyOffline(s, s.lastSeen - 6 * HOUR)
    const later = applyOffline(skewed.state, skewed.state.lastSeen + HOUR)
    expect(later.summary.elapsedMs).toBe(HOUR)
    expect(later.summary.skills[0]!.actions).toBe(1200)
  })

  it('a non-finite clock is treated as a zero window rather than corrupting the save', () => {
    for (const now of [NaN, Infinity, -Infinity]) {
      const r = applyOffline(s, now)
      expect(r.state).toBe(s)
      expect(r.summary.elapsedMs).toBe(0)
    }
    expect(applyOffline({ ...s, lastSeen: NaN }, NOW).state.resources).toEqual({})
  })
})

describe('a window that crosses a level-up', () => {
  // 1 hour = 1200 oak actions = 12,000 XP: level 27, so it crosses the level-20 slot unlock.
  const start = busy(q)
  const r = applyOffline(start, start.lastSeen + HOUR, q)
  const level = expectedLevel(12_000)

  it('is worked out in bulk to the right totals', () => {
    expect(level).toBeGreaterThan(20)
    expect(r.state.resources['oak-log']).toBe(1200)
    expect(r.state.skills.woodcutting).toMatchObject({ xp: 12_000, level })
    expect(r.state.skills.woodcutting!.slots).toHaveLength(2)
    expect(r.state.lastSeen).toBe(start.lastSeen + HOUR)
    expect(assignmentProblems(r.state)).toEqual([])
  })

  it('emits every level-up and the slot unlock, and summarises them for the welcome-back screen', () => {
    const levels = r.events.filter((e): e is Extract<SimEvent, { type: 'skill-level-up' }> => e.type === 'skill-level-up').map((e) => e.level)
    expect(levels).toEqual(Array.from({ length: level - 1 }, (_, i) => i + 2))
    expect(r.summary.skills).toEqual([{ skillId: 'woodcutting', actions: 1200, xpGained: 12_000, levelBefore: 1, levelAfter: level, slotsUnlocked: [1] }])
    expect(r.summary).toMatchObject({ requestedMs: HOUR, elapsedMs: HOUR, capped: false, clockSkewed: false })
    expect(r.summary.resourcesGained).toEqual({ 'oak-log': 1200 })
  })

  it('also banks the bench Aether for the same window: 4/min for an hour', () => {
    expect(r.summary.aetherGained).toBeCloseTo(240)
    expect(r.state.aether).toBeCloseTo(240)
  })

  it('keeps the action in progress when the window ends mid-action', () => {
    const mid = applyOffline(start, start.lastSeen + 3000 * 1200 + 1500, q)
    expect(mid.state.skills.woodcutting!.slots[0]!.progressMs).toBe(1500)
  })

  it('does not mutate the state it was given', () => {
    const s = busy(q)
    const snapshot = structuredClone(s)
    applyOffline(s, s.lastSeen + 5 * HOUR, q)
    expect(s).toEqual(snapshot)
  })
})

describe('a window longer than capHours', () => {
  const s = busy(q)
  const capped = applyOffline(s, s.lastSeen + 100 * HOUR, q)
  const exactly = applyOffline(s, s.lastSeen + 12 * HOUR, q)

  it('grants exactly the cap (12 h), not the 100 h that passed', () => {
    expect(capped.summary).toMatchObject({ requestedMs: 100 * HOUR, elapsedMs: 12 * HOUR, capMs: 12 * HOUR, capped: true })
    expect(capped.state.resources['oak-log']).toBe(14_400)
    expect(capped.state.skills.woodcutting!.xp).toBe(144_000)
    expect(capped.state.aether).toBeCloseTo(4 * 720)
  })

  it('gives the same progress as being away exactly the cap, but still moves lastSeen to now', () => {
    expect({ ...capped.state, lastSeen: 0 }).toEqual({ ...exactly.state, lastSeen: 0 })
    expect(capped.state.lastSeen).toBe(s.lastSeen + 100 * HOUR)
    expect(exactly.summary.capped).toBe(false)
  })

  it('reads the cap from tuning.json, so it can be extended without code', () => {
    const c = variant((raw) => {
      raw.tuning.offline.capHours = 1
      for (const r of raw.resources) if (r.rareDrop) r.rareDrop.chance = 0
      raw.traits.find((t: any) => t.id === 'overgrowth').effects[0].valueByStrength = { moderate: 0 }
    })
    const r = applyOffline(work(newGame(c), 'creature-1', 'woodcutting', 0, 'oak-log', c), NOW + 3 * HOUR, c)
    expect(r.summary).toMatchObject({ elapsedMs: HOUR, capMs: HOUR, capped: true })
    expect(r.state.resources['oak-log']).toBe(1200)
  })

  it('the dev panel fast-forward path (rewind lastSeen, call applyOffline) is clamped the same way', () => {
    const rewound = { ...s, lastSeen: NOW - 100 * HOUR }
    expect(applyOffline(rewound, NOW, q).summary).toMatchObject({ elapsedMs: 12 * HOUR, capped: true })
  })
})

describe('offline and online are the same maths', () => {
  const elapsed = 2 * HOUR

  it('offline Aether for a window equals online Aether for the same elapsed time', () => {
    const start = busy()
    const offline = applyOffline(start, start.lastSeen + elapsed).state.aether
    let online = start
    for (let i = 0; i < elapsed / 1000; i++) online = step(online, 1000).state
    expect(online.aether).toBeCloseTo(offline, 6)
    expect(offline).toBeCloseTo(emissionPerMin(start) * (elapsed / MIN), 8)
  })

  it('with a ragged frame pattern (including a dropped-tab 40 s frame) it still matches', () => {
    const start = busy()
    const frames = [16, 17, 250, 40_000, 3, 999, 1_800_000, 1_000_000, 4_000_000, 397_965]
    const total = frames.reduce((a, b) => a + b, 0)
    let online = start
    for (const dt of frames) online = step(online, dt).state
    expect(online.aether).toBeCloseTo(applyOffline(start, start.lastSeen + total).state.aether, 6)
  })

  it('offline XP, actions, level and slots equal stepping the same time online (deterministic content)', () => {
    const start = busy(q)
    const offline = applyOffline(start, start.lastSeen + elapsed, q).state
    let online = start
    for (let i = 0; i < elapsed / 250; i++) online = step(online, 250, {}, q).state
    expect(online.resources).toEqual(offline.resources)
    expect(online.skills).toEqual(offline.skills)
    expect(online.aether).toBeCloseTo(offline.aether, 6)
  })
})

describe('offline output rolls and the RNG', () => {
  it('advances the saved RNG state when it rolls, and is deterministic for a given (state, now)', () => {
    const s = sproutletAtWork()
    const a = applyOffline(s, s.lastSeen + 6 * HOUR)
    expect(a.state.rngState).not.toBe(s.rngState)
    expect(applyOffline(s, s.lastSeen + 6 * HOUR)).toEqual(a)
  })

  it('a second offline window continues the stream rather than replaying the first', () => {
    const s = sproutletAtWork()
    const first = applyOffline(s, s.lastSeen + 6 * HOUR)
    const second = applyOffline(first.state, first.state.lastSeen + 6 * HOUR)
    const extras = (r: ReturnType<typeof applyOffline>) => r.summary.resourcesGained['oak-log']! - 7200
    expect(extras(second)).not.toBe(extras(first))
  })

  it("Night Owl's offline_extra_output_chance applies here and only here", () => {
    let s = addCreature(newGame(), 'sproutlet', { poolTraits: [pool('night-owl', 'major')] }).state
    s = work(s, 'creature-2')
    const offline = applyOffline(s, s.lastSeen + 12 * HOUR).summary.resourcesGained['oak-log']! - 14_400
    let online = s
    for (let i = 0; i < 12 * 3600; i++) online = step(online, 1000).state
    const onlineExtra = online.resources['oak-log']! - 14_400
    // Overgrowth gives 0.10 always; Night Owl Major adds 0.20 on the offline path only. So offline is ~0.30 * n
    // and online ~0.10 * n (n = 14,400, sd about 55 and 36; the +-250 bands are 4+ sd wide).
    expect(offline).toBeGreaterThan(14_400 * 0.3 - 250)
    expect(offline).toBeLessThan(14_400 * 0.3 + 250)
    expect(onlineExtra).toBeGreaterThan(14_400 * 0.1 - 250)
    expect(onlineExtra).toBeLessThan(14_400 * 0.1 + 250)
  })

  it('the summary agrees with the state it produced', () => {
    const s = busy()
    const r = applyOffline(s, s.lastSeen + 9 * HOUR)
    for (const [id, qty] of Object.entries(r.summary.resourcesGained)) expect(r.state.resources[id]! - (s.resources[id] ?? 0)).toBe(qty)
    expect(r.summary.aetherGained).toBeCloseTo(r.state.aether - s.aether, 9)
  })
})
