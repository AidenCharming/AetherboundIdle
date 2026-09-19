import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { canWork, creatureCooldown, creatureStats, grantCreatureXp, makeCreature } from '../src/sim/creature'
import { xpForLevel } from '../src/sim/formulas'
import { createInitialState } from '../src/sim/state'
import { pool } from './helpers'

const cooldownMs = (creature: ReturnType<typeof makeCreature>, skill: string, base = 3000) => creatureCooldown(creature, skill, base, []).cooldownMs

describe('canWork', () => {
  it('a base species works its own type\'s locked skills and every open skill', () => {
    const sprout = makeCreature('a', 'sproutlet')
    expect(canWork(sprout, 'woodcutting')).toBe(true)
    expect(canWork(sprout, 'herbalism')).toBe(true)
    expect(canWork(sprout, 'scavenging')).toBe(true)
    expect(canWork(sprout, 'fabrication')).toBe(true)
    expect(canWork(sprout, 'mining')).toBe(false)
    expect(canWork(sprout, 'nonsense')).toBe(false)
  })

  it('a hybrid works the locked skills of both parent types, and the open skills', () => {
    const ashwood = makeCreature('a', 'ashwood') // Verdant + Pyric
    for (const s of ['woodcutting', 'herbalism', 'cooking', 'smithing', 'scavenging']) expect(canWork(ashwood, s), s).toBe(true)
    for (const s of ['mining', 'fishing', 'circuitry']) expect(canWork(ashwood, s), s).toBe(false)
  })
})

describe('stats', () => {
  it('a Dim Form 1 Sproutlet (Guard lean) has the base stats times the lean', () => {
    const s = creatureStats(makeCreature('a', 'sproutlet'))
    expect(s.health).toBeCloseTo(50 * 0.9)
    expect(s.power).toBeCloseTo(10 * 0.9)
    expect(s.guard).toBeCloseTo(10 * 1.25)
  })

  it('scales with level, rarity and form', () => {
    const s = creatureStats(makeCreature('a', 'sproutlet', { level: 31, rarityTier: 3, form: 2 }))
    expect(s.guard).toBeCloseTo(10 * 1.25 * (1 + 0.04 * 30) * 2.8 * 1.2)
  })

  it('trait bonuses are a percentage of the stat: Vitality moderate is +10% Health only', () => {
    const plain = creatureStats(makeCreature('a', 'sproutlet'))
    const vit = creatureStats(makeCreature('a', 'sproutlet', { poolTraits: [pool('vitality', 'moderate')] }))
    expect(vit.health / plain.health).toBeCloseTo(1.1)
    expect(vit.power).toBeCloseTo(plain.power)
    expect(vit.guard).toBeCloseTo(plain.guard)
  })

  it('bonus stat traits share their registry cap', () => {
    const plain = creatureStats(makeCreature('a', 'sproutlet'))
    const stacked = creatureStats(makeCreature('a', 'sproutlet', { poolTraits: [pool('vitality', 'major'), pool('vitality', 'major'), pool('vitality', 'major')] }))
    expect(stacked.health / plain.health).toBeCloseTo(1.5) // 0.6 total, capped at 0.5
  })

  it('Champion is a small upgrade over Brawn: about 60% of it on Power, and Guard as well', () => {
    const plain = creatureStats(makeCreature('a', 'sproutlet'))
    const brawn = creatureStats(makeCreature('a', 'sproutlet', { poolTraits: [pool('brawn', 'moderate')] }))
    const champ = creatureStats(makeCreature('a', 'sproutlet', { poolTraits: [pool('champion', 'moderate')] }))
    expect(brawn.power / plain.power).toBeCloseTo(1.1)
    expect(champ.power / plain.power).toBeCloseTo(1.06)
    expect(champ.guard / plain.guard).toBeCloseTo(1.06)
    expect(champ.health).toBeCloseTo(plain.health)
    expect(champ.power).toBeLessThan(brawn.power) // strictly weaker per stat...
    expect(champ.power * champ.guard).toBeGreaterThan(plain.power * plain.guard) // ...but still an upgrade
  })

  it('throws on an unknown species rather than returning NaN', () => {
    expect(() => creatureStats({ ...makeCreature('a', 'sproutlet'), speciesId: 'nope' })).toThrow(/unknown species/)
  })
})

describe('creature cooldown', () => {
  it('a base creature on its own skill takes the base time', () => {
    expect(cooldownMs(makeCreature('a', 'sproutlet'), 'woodcutting')).toBe(3000)
  })

  it('level, rarity and form all speed it up', () => {
    const base = cooldownMs(makeCreature('a', 'sproutlet'), 'woodcutting')
    expect(cooldownMs(makeCreature('a', 'sproutlet', { level: 30 }), 'woodcutting')).toBeLessThan(base)
    expect(cooldownMs(makeCreature('a', 'sproutlet', { rarityTier: 5 }), 'woodcutting')).toBeLessThan(base)
    expect(cooldownMs(makeCreature('a', 'sproutlet', { form: 2 }), 'woodcutting')).toBeLessThan(base)
    expect(cooldownMs(makeCreature('a', 'sproutlet', { level: 31, rarityTier: 3, form: 2 }), 'woodcutting')).toBeCloseTo(3000 / 1.32)
  })

  it('a hybrid on a covered skill that is not its primary takes base / 0.60', () => {
    const ashwood = makeCreature('a', 'ashwood') // primary Woodcutting
    expect(cooldownMs(ashwood, 'woodcutting')).toBeCloseTo(3000)
    expect(cooldownMs(ashwood, 'herbalism')).toBeCloseTo(3000 / 0.6)
    expect(cooldownMs(ashwood, 'cooking')).toBeCloseTo(3000 / 0.6)
  })

  it('open skills are nobody\'s off-primary: a hybrid there takes no efficiency penalty', () => {
    const ashwood = makeCreature('a', 'ashwood') // secondary aptitude Fabrication
    expect(cooldownMs(ashwood, 'scavenging')).toBeCloseTo(3000)
    expect(cooldownMs(ashwood, 'fabrication')).toBeCloseTo(3000 / 1.15)
  })

  it('a matching secondary aptitude on an open skill takes base / 1.15; a non-matching open skill does not', () => {
    const sprout = makeCreature('a', 'sproutlet') // secondary aptitude Scavenging
    expect(cooldownMs(sprout, 'scavenging')).toBeCloseTo(3000 / 1.15)
    expect(cooldownMs(sprout, 'fabrication')).toBeCloseTo(3000)
  })

  it('trait reduction feeds the cooldown, capped', () => {
    const one = makeCreature('a', 'sproutlet', { poolTraits: [pool('swift-worker', 'moderate')] })
    expect(cooldownMs(one, 'woodcutting')).toBeCloseTo(3000 * 0.9)
    const lots = makeCreature('a', 'sproutlet', { poolTraits: [pool('swift-worker', 'major'), pool('swift-worker', 'major'), pool('swift-worker', 'major')] })
    expect(cooldownMs(lots, 'woodcutting')).toBeCloseTo(3000 * 0.5)
  })

  it('the breakdown says what it did', () => {
    const b = creatureCooldown(makeCreature('a', 'ashwood'), 'herbalism', 3000, [])
    expect(b.efficiency).toBeCloseTo(0.6)
    expect(b.adjustedBase).toBeCloseTo(5000)
    expect(b.floor).toBeCloseTo(1000)
    expect(b.floored).toBe(false)
  })
})

describe('creature XP, levels and forms', () => {
  const curve = content.tuning.xp.creatureCurve
  const at = (level: number) => xpForLevel(curve, level, content.tuning.creature.maxLevel)

  it('emits a level-up per level crossed', () => {
    const { state, events } = grantCreatureXp(makeCreature('a', 'sproutlet'), at(4))
    expect(state.level).toBe(4)
    expect(events.filter((e) => e.type === 'creature-level-up').map((e) => (e as { level: number }).level)).toEqual([2, 3, 4])
    expect(events.some((e) => e.type === 'form-evolved')).toBe(false)
  })

  it('evolves at level 30 and 60 (automatic), in order with the level-ups', () => {
    const { state, events } = grantCreatureXp(makeCreature('a', 'sproutlet', { level: 28, xp: at(28), form: 1 }), at(61))
    expect(state.form).toBe(3)
    expect(state.level).toBe(61)
    const form = events.filter((e) => e.type === 'form-evolved')
    expect(form.map((e) => (e as { form: number }).form)).toEqual([2, 3])
    const idx = (l: number) => events.findIndex((e) => e.type === 'creature-level-up' && e.level === l)
    expect(events.indexOf(form[0]!)).toBe(idx(30) + 1)
    expect(events.indexOf(form[1]!)).toBe(idx(60) + 1)
  })

  it('never de-levels or de-evolves, ignores negative XP, and stops at max level', () => {
    const start = makeCreature('a', 'sproutlet', { level: 40, xp: at(40), form: 2 })
    expect(grantCreatureXp(start, -1000).state).toMatchObject({ level: 40, form: 2, xp: at(40) })
    expect(grantCreatureXp(start, 1e12).state.level).toBe(content.tuning.creature.maxLevel)
  })

  it('does not mutate its input', () => {
    const start = makeCreature('a', 'sproutlet')
    grantCreatureXp(start, 1e6)
    expect(start).toMatchObject({ level: 1, xp: 0, form: 1 })
  })
})

describe('initial state', () => {
  const state = createInitialState(777, 1000)
  it('starts with one benched Dim Sproutlet and nothing else', () => {
    expect(state.creatures).toHaveLength(1)
    expect(state.creatures[0]).toMatchObject({ speciesId: 'sproutlet', rarityTier: 1, level: 1, form: 1, shiny: false, assignment: null, poolTraits: [] })
    expect(state).toMatchObject({ aether: 0, gold: 0, resources: {}, lastSeen: 1000, rngState: 777, version: content.tuning.save.version })
  })
  it('has every skill at level 1 with exactly one open slot', () => {
    for (const skill of content.skills) expect(state.skills[skill.id]).toEqual({ level: 1, xp: 0, slots: [null] })
  })
})
