import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import type { SimEvent } from '../src/sim/events'
import { xpForLevel } from '../src/sim/formulas'
import { createRng } from '../src/sim/rng'
import { addSkillXp, advanceSkills, assignCreature, setSlotResource, slotCount, unassignCreature } from '../src/sim/skills'
import { addCreature, assignmentProblems, newGame, pool, quietContent, setSkillLevel, sproutletAtWork, variant, work } from './helpers'

const q = quietContent()
const woodcutting = content.skillById.get('woodcutting')!
const curve = content.tuning.xp.skillCurve
/** The level each work slot opens at, read from skills.json so a retune moves these tests with it. */
const [, SLOT2] = woodcutting.slotUnlockLevels as [number, number, ...number[]]

/**
 * Independent re-derivation of the level for a cumulative XP total: a plain running sum of
 * round(base * growth^(L-1)), against formulas.ts's memoized table and binary search. The curve's numbers come
 * from tuning.json, so this checks the code agrees with the formula, not with a remembered balance pass.
 */
function expectedLevel(xp: number): number {
  let level = 1
  let need = 0
  for (;;) {
    need += Math.round(curve.base * curve.growth ** (level - 1))
    if (xp < need || level >= woodcutting.maxLevel) return level
    level++
  }
}

const ofType = <T extends SimEvent['type']>(events: SimEvent[], type: T) => events.filter((e): e is Extract<SimEvent, { type: T }> => e.type === type)

describe('addSkillXp and slot unlocks', () => {
  const start = { level: 1, xp: 0, slots: [null] as null[], reached: {} }

  it('grows the slot count at exactly each tuned unlock level and emits slot-unlocked for each', () => {
    const at = (level: number) => setSkillLevel(newGame(), 'woodcutting', level).skills.woodcutting!
    woodcutting.slotUnlockLevels.forEach((unlock, i) => {
      expect(at(unlock).slots.length, `at level ${unlock}`).toBe(i + 1)
      if (unlock > 1) expect(at(unlock - 1).slots.length, `at level ${unlock - 1}`).toBe(i)
    })

    const all = addSkillXp(start, woodcutting, xpForLevel(curve, woodcutting.maxLevel, woodcutting.maxLevel))
    expect(all.state.level).toBe(woodcutting.maxLevel)
    expect(all.state.slots).toHaveLength(woodcutting.slotUnlockLevels.length)
    expect(ofType(all.events, 'slot-unlocked').map((e) => e.slotIndex)).toEqual(woodcutting.slotUnlockLevels.map((_, i) => i).slice(1))
  })

  it('emits one skill-level-up per level, in order, with slot-unlocked right after its level-up', () => {
    const { events } = addSkillXp(start, woodcutting, xpForLevel(curve, woodcutting.maxLevel, woodcutting.maxLevel))
    expect(ofType(events, 'skill-level-up').map((e) => e.level)).toEqual(Array.from({ length: woodcutting.maxLevel - 1 }, (_, i) => i + 2))
    const atSlot2 = events.findIndex((e) => e.type === 'skill-level-up' && e.level === SLOT2)
    expect(events[atSlot2 + 1]).toEqual({ type: 'slot-unlocked', skillId: 'woodcutting', slotIndex: 1 })
  })

  it('never shrinks the slots and never lowers the level', () => {
    const xp40 = xpForLevel(curve, 40, woodcutting.maxLevel)
    const roomy = { level: 40, xp: xp40, slots: [null, null, null, null, null] as null[], reached: {} }
    expect(addSkillXp(roomy, woodcutting, 0).state.slots).toHaveLength(5)
    expect(addSkillXp(roomy, woodcutting, -500).state).toEqual(roomy)
    const lowClaim = { level: 40, xp: 0, slots: [null, null, null] as null[], reached: {} } // xp says level 1; the higher level stands
    expect(addSkillXp(lowClaim, woodcutting, 10).state.level).toBe(40)
  })

  it('keeps level consistent with xp', () => {
    for (const xp of [0, 99, 100, 1234, 88_888, 5e6, 5e8]) expect(addSkillXp(start, woodcutting, xp).state.level).toBe(expectedLevel(xp))
  })

  it('slotCount agrees', () => {
    const levels = [1, SLOT2, woodcutting.maxLevel]
    expect(levels.map((l) => slotCount(woodcutting, l))).toEqual([1, 2, woodcutting.slotUnlockLevels.length])
  })
})

describe('assignCreature', () => {
  it('fills the slot and marks the creature, and the two views agree', () => {
    const r = assignCreature(newGame(), 'creature-1', 'woodcutting', 0, 'oak-log')
    expect(r.ok).toBe(true)
    if (!r.ok) return
    expect(r.state.skills.woodcutting!.slots[0]).toEqual({ creatureId: 'creature-1', resourceId: 'oak-log', progressMs: 0 })
    expect(r.state.creatures[0]!.assignment).toEqual({ skillId: 'woodcutting', slotIndex: 0 })
    expect(assignmentProblems(r.state)).toEqual([])
  })

  it('does not mutate the state it was given', () => {
    const before = newGame()
    const snapshot = structuredClone(before)
    assignCreature(before, 'creature-1', 'woodcutting', 0, 'oak-log')
    expect(before).toEqual(snapshot)
  })

  const refuses = (result: ReturnType<typeof assignCreature>, reason: RegExp) => {
    expect(result.ok).toBe(false)
    if (!result.ok) expect(result.reason).toMatch(reason)
  }

  it('refuses a creature the skill is locked against, an unknown id, and a locked slot', () => {
    refuses(assignCreature(newGame(), 'creature-1', 'mining', 0, 'oak-log'), /cannot work mining/)
    refuses(assignCreature(newGame(), 'creature-9', 'woodcutting', 0, 'oak-log'), /unknown creature/)
    refuses(assignCreature(newGame(), 'creature-1', 'woodcutting', 1, 'oak-log'), /slot 1 is locked/)
    refuses(assignCreature(newGame(), 'creature-1', 'woodcutting', -1, 'oak-log'), /locked/)
    refuses(assignCreature(newGame(), 'creature-1', 'woodcutting', 0.5, 'oak-log'), /locked/)
    refuses(assignCreature(newGame(), 'creature-1', 'made-up', 0, 'oak-log'), /unknown skill/)
  })

  it('gates resource tiers on skill level: willow at 15, yew at 30', () => {
    refuses(assignCreature(newGame(), 'creature-1', 'woodcutting', 0, 'willow-log'), /needs woodcutting level 15/)
    refuses(assignCreature(newGame(), 'creature-1', 'woodcutting', 0, 'unicorn-log'), /unknown resource/)
    refuses(assignCreature(newGame(), 'creature-1', 'woodcutting', 0, 'verdant-seedcache'), /cannot be gathered/)
    expect(assignCreature(setSkillLevel(newGame(), 'woodcutting', 15), 'creature-1', 'woodcutting', 0, 'willow-log').ok).toBe(true)
    refuses(assignCreature(setSkillLevel(newGame(), 'woodcutting', 29), 'creature-1', 'woodcutting', 0, 'yew-log'), /level 30/)
    expect(assignCreature(setSkillLevel(newGame(), 'woodcutting', 30), 'creature-1', 'woodcutting', 0, 'yew-log').ok).toBe(true)
  })

  it('moving a working creature empties its old slot; benching whoever held the target', () => {
    let s = setSkillLevel(newGame(), 'woodcutting', SLOT2) // high enough for a second slot
    s = addCreature(s, 'sproutlet').state // creature-2
    s = work(s, 'creature-1', 'woodcutting', 0)
    s = work(s, 'creature-1', 'woodcutting', 1) // move
    expect(s.skills.woodcutting!.slots.map((x) => x?.creatureId ?? null)).toEqual([null, 'creature-1'])
    expect(assignmentProblems(s)).toEqual([])

    s = work(s, 'creature-2', 'woodcutting', 1) // displaces creature-1
    expect(s.creatures.find((c) => c.id === 'creature-1')!.assignment).toBeNull()
    expect(s.skills.woodcutting!.slots.map((x) => x?.creatureId ?? null)).toEqual([null, 'creature-2'])
    expect(assignmentProblems(s)).toEqual([])
  })

  it('re-assigning the same creature to the same slot and resource keeps its progress', () => {
    let s = sproutletAtWork()
    s = advanceSkills(s, 1000).state
    expect(s.skills.woodcutting!.slots[0]!.progressMs).toBe(1000)
    s = work(s, 'creature-1')
    expect(s.skills.woodcutting!.slots[0]!.progressMs).toBe(1000)
  })

  it('unassign benches the creature and empties the slot', () => {
    const s = unassignCreature(sproutletAtWork(), 'creature-1')
    expect(s.creatures[0]!.assignment).toBeNull()
    expect(s.skills.woodcutting!.slots).toEqual([null])
    expect(unassignCreature(s, 'creature-1')).toBe(s) // already benched: no-op
    expect(unassignCreature(s, 'nobody')).toBe(s)
  })

  it('setSlotResource swaps the resource and resets progress', () => {
    let s = setSkillLevel(newGame(), 'woodcutting', 15)
    s = work(s, 'creature-1')
    s = advanceSkills(s, 1000).state
    const r = setSlotResource(s, 'woodcutting', 0, 'willow-log')
    expect(r.ok && r.state.skills.woodcutting!.slots[0]).toEqual({ creatureId: 'creature-1', resourceId: 'willow-log', progressMs: 0 })
    expect(setSlotResource(s, 'woodcutting', 0, 'yew-log').ok).toBe(false)
    expect(setSlotResource(newGame(), 'woodcutting', 0, 'oak-log').ok).toBe(false) // empty slot
  })
})

describe('advanceSkills: action resolution', () => {
  it('one full cooldown is one action: 1 log and 10 xp, and the progress resets', () => {
    const { state, events } = advanceSkills(sproutletAtWork(q), 3000, {}, q)
    expect(state.resources).toEqual({ 'oak-log': 1 })
    expect(state.skills.woodcutting).toMatchObject({ xp: 10, level: 1 })
    expect(state.skills.woodcutting!.slots[0]!.progressMs).toBe(0)
    expect(events).toEqual([
      { type: 'action-complete', skillId: 'woodcutting', slotIndex: 0, creatureId: 'creature-1', resourceId: 'oak-log', count: 1, outputs: { 'oak-log': 1 }, skillXp: 10 },
    ])
  })

  it('carries partial progress between steps instead of dropping it', () => {
    let s = sproutletAtWork(q)
    s = advanceSkills(s, 2999, {}, q).state
    expect(s.resources).toEqual({})
    expect(s.skills.woodcutting!.slots[0]!.progressMs).toBe(2999)
    s = advanceSkills(s, 1, {}, q).state
    expect(s.resources).toEqual({ 'oak-log': 1 })
    expect(s.skills.woodcutting!.slots[0]!.progressMs).toBe(0)
  })

  it('a window of several cooldowns completes them all and keeps the remainder', () => {
    const { state, events } = advanceSkills(sproutletAtWork(q), 3000 * 7 + 1234, {}, q)
    expect(state.resources['oak-log']).toBe(7)
    expect(state.skills.woodcutting!.xp).toBe(70)
    expect(state.skills.woodcutting!.slots[0]!.progressMs).toBe(1234)
    expect(events).toHaveLength(1) // aggregated, not seven events
    expect(ofType(events, 'action-complete')[0]!.count).toBe(7)
  })

  it('uses the creature\'s real cooldown: level, rarity and form make it faster', () => {
    let s = newGame(q)
    s = addCreature(s, 'sproutlet', { level: 31, rarityTier: 3, form: 2 }, q).state
    s = work(s, 'creature-2', 'woodcutting', 0, 'oak-log', q)
    const r = advanceSkills(s, 100_000, {}, q)
    expect(ofType(r.events, 'action-complete')[0]!.count).toBe(Math.floor(100_000 / (3000 / 1.32))) // 44
  })

  it('scales resource tiers: a willow takes 4 s for 25 xp and a yew 5 s for 50', () => {
    let s = setSkillLevel(newGame(q), 'woodcutting', 30, q)
    s = work(s, 'creature-1', 'woodcutting', 0, 'willow-log', q)
    const willow = advanceSkills(s, 40_000, {}, q).state
    expect(willow.resources['willow-log']).toBe(10)
    expect(willow.skills.woodcutting!.xp - s.skills.woodcutting!.xp).toBe(250)
    const yew = advanceSkills(work(s, 'creature-1', 'woodcutting', 0, 'yew-log', q), 50_000, {}, q).state
    expect(yew.resources['yew-log']).toBe(10)
    expect(yew.skills.woodcutting!.xp - s.skills.woodcutting!.xp).toBe(500)
  })

  it('runs every occupied slot with its own progress and cooldown', () => {
    let s = setSkillLevel(newGame(q), 'woodcutting', SLOT2, q) // high enough for a second slot
    s = addCreature(s, 'sproutlet', { rarityTier: 4 }, q).state // Gleaming: term 0.18 -> 3000/1.18
    s = work(work(s, 'creature-1', 'woodcutting', 0, 'oak-log', q), 'creature-2', 'woodcutting', 1, 'oak-log', q)
    const { state, events } = advanceSkills(s, 30_000, {}, q)
    const [a, b] = ofType(events, 'action-complete')
    expect([a!.slotIndex, a!.count]).toEqual([0, 10])
    expect([b!.slotIndex, b!.count]).toEqual([1, Math.floor(30_000 / (3000 / 1.18))])
    expect(state.skills.woodcutting!.xp).toBe(s.skills.woodcutting!.xp + (a!.count + b!.count) * 10)
  })

  it('idles instead of throwing when a slot no longer makes sense (level too low, resource or creature gone)', () => {
    const s = sproutletAtWork(q)
    const stale = (slot: object) => ({ ...s, skills: { ...s.skills, woodcutting: { ...s.skills.woodcutting!, slots: [slot as never] } } })
    for (const slot of [
      { creatureId: 'creature-1', resourceId: 'willow-log', progressMs: 5 }, // needs level 15
      { creatureId: 'creature-1', resourceId: 'deleted-log', progressMs: 5 },
      { creatureId: 'ghost', resourceId: 'oak-log', progressMs: 5 },
      { creatureId: 'creature-1', resourceId: 'verdant-seedcache', progressMs: 5 }, // not gatherable
    ]) {
      const r = advanceSkills(stale(slot), 100_000, {}, q)
      expect(r.events).toEqual([])
      expect(r.state.resources).toEqual({})
      expect(r.state.skills.woodcutting!.slots[0]).toEqual(slot)
    }
  })

  it('does not mutate its input', () => {
    const s = sproutletAtWork(q)
    const snapshot = structuredClone(s)
    advanceSkills(s, 10 * 3600_000, {}, q)
    expect(s).toEqual(snapshot)
  })

  it('a benched creature does nothing here', () => {
    const r = advanceSkills(newGame(q), 1e9, {}, q)
    expect(r.events).toEqual([])
    expect(r.state.resources).toEqual({})
  })
})

describe('advanceSkills: a window that crosses level-ups', () => {
  // 1 hour = 1200 oak actions = 12,000 XP. Which level that is depends on the tuned curve, so it is re-derived.
  const HOUR = 3_600_000
  const OAK_MS = 3000
  const OAK_XP = 10
  const result = advanceSkills(sproutletAtWork(q), HOUR, {}, q)
  const level = expectedLevel(12_000)

  // Long enough to cross the second slot unlock, whatever level that is tuned to: the XP that level needs,
  // rounded up to a whole oak action. A slot unlock is much further out than an hour on the shipped curve.
  const slot2Window = Math.ceil(xpForLevel(curve, SLOT2, woodcutting.maxLevel) / OAK_XP) * OAK_MS
  const slot2 = advanceSkills(sproutletAtWork(q), slot2Window, {}, q)

  it('lands on the right total XP and level', () => {
    expect(level).toBeGreaterThan(1)
    expect(result.state.skills.woodcutting).toMatchObject({ xp: 12_000, level })
    expect(result.state.resources['oak-log']).toBe(1200)
  })

  it('emits a level-up for every level crossed, in order, after the actions that earned them', () => {
    expect(ofType(result.events, 'skill-level-up').map((e) => e.level)).toEqual(Array.from({ length: level - 1 }, (_, i) => i + 2))
    expect(result.events.map((e) => e.type)[0]).toBe('action-complete')
    expect(result.state.skills.woodcutting!.slots).toHaveLength(slotCount(woodcutting, level))
  })

  it('emits the slot unlock right after the level-up that earned it', () => {
    expect(slot2.state.skills.woodcutting!.level).toBe(SLOT2)
    expect(ofType(slot2.events, 'slot-unlocked')).toEqual([{ type: 'slot-unlocked', skillId: 'woodcutting', slotIndex: 1 }])
    const order = slot2.events.map((e) => e.type)
    expect(order[0]).toBe('action-complete')
    // The level-ups run 2..SLOT2, so the unlock sits (SLOT2 - 1) events after the first one.
    expect(order.indexOf('slot-unlocked')).toBe(order.indexOf('skill-level-up') + (SLOT2 - 1))
  })

  it('opens the new slot, empty, without disturbing the working one', () => {
    const slots = slot2.state.skills.woodcutting!.slots
    expect(slots).toHaveLength(2)
    expect(slots[0]).toMatchObject({ creatureId: 'creature-1', resourceId: 'oak-log' })
    expect(slots[1]).toBeNull()
    expect(assignmentProblems(slot2.state)).toEqual([])
  })

  it('a single big step and thousands of small steps agree exactly (online and offline cannot drift)', () => {
    let s = sproutletAtWork(q)
    const stepped: SimEvent[] = []
    for (let i = 0; i < HOUR / 250; i++) {
      const r = advanceSkills(s, 250, {}, q)
      s = r.state
      stepped.push(...r.events)
    }
    expect(s.resources).toEqual(result.state.resources)
    expect(s.skills.woodcutting).toEqual(result.state.skills.woodcutting)
    expect(ofType(stepped, 'skill-level-up').map((e) => e.level)).toEqual(ofType(result.events, 'skill-level-up').map((e) => e.level))
    expect(ofType(stepped, 'action-complete').reduce((n, e) => n + e.count, 0)).toBe(1200)
  })

  it('a window that ends mid-action keeps the partial progress', () => {
    const r = advanceSkills(sproutletAtWork(q), 3000 * 1200 + 1500, {}, q)
    expect(r.state.skills.woodcutting!.slots[0]!.progressMs).toBe(1500)
    expect(r.state.skills.woodcutting!.xp).toBe(12_000)
  })
})

describe('advanceSkills: zero and clock-skewed (negative) windows', () => {
  const s = sproutletAtWork()
  for (const [label, dt] of [['zero', 0], ['negative', -5000], ['a huge negative', -1e12], ['NaN', NaN], ['-Infinity', -Infinity], ['+Infinity', Infinity]] as const) {
    it(`a ${label} window changes nothing and consumes no randomness`, () => {
      const r = advanceSkills(s, dt)
      expect(r.state).toBe(s)
      expect(r.events).toEqual([])
      expect(r.state.rngState).toBe(s.rngState)
    })
  }
})

describe('advanceSkills: the RNG', () => {
  const HOURS = 3_600_000
  const s = sproutletAtWork()

  it('advances the saved state when it rolls, and leaves it alone when no action finished', () => {
    const rolled = advanceSkills(s, 3000 * 50)
    expect(rolled.state.rngState).not.toBe(s.rngState)
    expect(advanceSkills(s, 2999).state.rngState).toBe(s.rngState)
  })

  it('is a pure function of (state, dt): the same inputs give the same result', () => {
    expect(advanceSkills(s, 5 * HOURS)).toEqual(advanceSkills(s, 5 * HOURS))
  })

  it('draws extra-output before rare-drop from the persisted state, and writes the advanced state back', () => {
    const n = 4000
    const r = advanceSkills(s, 3000 * n)
    const rng = createRng(s.rngState)
    const extra = rng.binomial(n, 0.1) // Overgrowth, Moderate
    const rare = rng.binomial(n, 0.01) // oak's Verdant Seedcache
    expect(r.state.resources['oak-log']).toBe(n + extra)
    expect(r.state.resources['verdant-seedcache'] ?? 0).toBe(rare)
    expect(r.state.rngState).toBe(rng.state)
  })

  it('continuing from the returned state does not replay the previous window', () => {
    const first = advanceSkills(s, 3000 * 100_000)
    const second = advanceSkills(first.state, 3000 * 100_000)
    const extras = (r: ReturnType<typeof advanceSkills>) => r.state.resources['oak-log']! - 100_000 * (r === first ? 1 : 2)
    expect(extras(second)).not.toBe(extras(first))
    expect(second.state.rngState).not.toBe(first.state.rngState)
  })

  it('a reload between windows (only rngState carried over) continues the stream', () => {
    const first = advanceSkills(s, 3000 * 4000)
    const reloaded = { ...s, rngState: first.state.rngState } // as a save/load round-trip would restore
    const viaReload = advanceSkills(reloaded, 3000 * 4000)
    const direct = advanceSkills({ ...first.state, skills: s.skills, resources: {} }, 3000 * 4000)
    expect(viaReload.state.resources).toEqual(direct.state.resources)
  })
})

describe('advanceSkills: modifiers on output and XP', () => {
  const n = 100_000
  const window = 3000 * n
  const within = (actual: number, expected: number, p: number, trials = n) => {
    const sd = Math.sqrt(trials * p * (1 - p))
    expect(Math.abs(actual - expected), `${actual} vs ${expected} (sd ${sd.toFixed(1)})`).toBeLessThan(5 * sd)
  }

  it("Sproutlet's Overgrowth adds about 10% extra output and oak drops the rare cache about 1%", () => {
    const r = advanceSkills(sproutletAtWork(), window)
    within(r.state.resources['oak-log']! - n, n * 0.1, 0.1)
    within(r.state.resources['verdant-seedcache']!, n * 0.01, 0.01)
    expect(ofType(r.events, 'action-complete')[0]!.outputs).toEqual(r.state.resources)
  })

  it('extra output is capped by the shared registry cap (0.5), not summed without limit', () => {
    let s = addCreature(newGame(), 'sproutlet', { poolTraits: [pool('bountiful', 'major'), pool('bountiful', 'major'), pool('bountiful', 'major')] }).state
    s = work(s, 'creature-2')
    within(advanceSkills(s, window).state.resources['oak-log']! - n, n * 0.5, 0.5) // 0.1 + 0.6 -> 0.5
  })

  it('night-owl adds extra output on the offline path only', () => {
    let s = addCreature(newGame(), 'sproutlet', { poolTraits: [pool('night-owl', 'moderate')] }).state
    s = work(s, 'creature-2')
    within(advanceSkills(s, window, { offline: false }).state.resources['oak-log']! - n, n * 0.1, 0.1)
    within(advanceSkills(s, window, { offline: true }).state.resources['oak-log']! - n, n * 0.2, 0.2)
  })

  it('bonus_xp multiplies the XP per action, not the action count', () => {
    let s = addCreature(newGame(q), 'sproutlet', { poolTraits: [pool('scholar', 'major')] }, q).state
    s = work(s, 'creature-2', 'woodcutting', 0, 'oak-log', q)
    const r = advanceSkills(s, 3000 * 100, {}, q)
    expect(r.state.resources['oak-log']).toBe(100)
    expect(r.state.skills.woodcutting!.xp).toBeCloseTo(100 * 10 * 1.2)
    expect(ofType(r.events, 'action-complete')[0]!.skillXp).toBeCloseTo(1200)
  })

  it('rare_drop_chance scales the drop\'s own chance rather than adding points to it', () => {
    const c = variant((raw) => {
      for (const r of raw.resources) if (r.rareDrop) r.rareDrop.chance = 0.5
      raw.traits.find((t: any) => t.id === 'overgrowth').effects[0].valueByStrength = { moderate: 0 }
    })
    let plain = work(newGame(c), 'creature-1', 'woodcutting', 0, 'oak-log', c)
    within(advanceSkills(plain, window, {}, c).state.resources['verdant-seedcache']!, n * 0.5, 0.5)
    plain = addCreature(newGame(c), 'sproutlet', { poolTraits: [pool('lucky', 'major')] }, c).state
    const lucky = work(plain, 'creature-2', 'woodcutting', 0, 'oak-log', c)
    within(advanceSkills(lucky, window, {}, c).state.resources['verdant-seedcache']!, n * 0.6, 0.6) // 0.5 * 1.2
  })

  it('a resource with no rare drop never rolls one', () => {
    const c = variant((raw) => {
      raw.resources.find((r: any) => r.id === 'oak-log').rareDrop = null
    })
    const r = advanceSkills(work(newGame(c), 'creature-1', 'woodcutting', 0, 'oak-log', c), window, {}, c)
    expect(r.state.resources['verdant-seedcache']).toBeUndefined()
  })
})
