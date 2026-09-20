// The shipped pacing, asserted against the REAL tuning.json and skills.json (no variant, no fixture). Every
// number the sim uses comes from the data; the milestone times below are the designer's brief for step 1.8t,
// and this file exists so a later retune that quietly breaks that feel fails a test instead of shipping.
//
// The model is the one the brief is written against: ONE unupgraded starter Sproutlet (level 1, rarity tier 1,
// Form 1, alone, no auras) cutting wood, always on the best Woodcutting tier its skill level has unlocked.
// Creature level is held at 1 because working never grants creature XP in phase 1.
import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { creatureCooldown, makeCreature } from '../src/sim/creature'
import { cooldown, levelForXp, xpForLevel, xpToNext } from '../src/sim/formulas'
import { parseSave, serializeSave } from '../src/sim/save'
import { slotCount } from '../src/sim/skills'
import { newGame, setSkillLevel, variant } from './helpers'

const SECOND = 1000
const MINUTE = 60 * SECOND
const HOUR = 60 * MINUTE
const DAY = 24 * HOUR
const MONTH = (365.25 / 12) * DAY

const woodcutting = content.skillById.get('woodcutting')!
const curve = content.tuning.xp.skillCurve

/** The Woodcutting tiers as shipped, lowest unlock level first. */
const tiers = content.resources
  .filter((r) => r.kind === 'raw' && r.skill === 'woodcutting' && r.baseActionMs !== null && r.requiredSkillLevel !== null)
  .sort((a, b) => a.requiredSkillLevel! - b.requiredSkillLevel!)

/** The starter Sproutlet, exactly as a new game makes it. */
const sproutlet = makeCreature('creature-1', 'sproutlet')

/** XP per millisecond at this skill level: the best unlocked tier, through the real cooldown formula. */
function xpPerMs(level: number): number {
  const tier = [...tiers].reverse().find((r) => r.requiredSkillLevel! <= level)!
  const { cooldownMs } = creatureCooldown(sproutlet, 'woodcutting', tier.baseActionMs!, [])
  return tier.xpPerAction! / cooldownMs
}

/** Milliseconds of unbroken work to reach `target` from a fresh save, tier by tier and level by level. */
function timeToLevel(target: number): number {
  let ms = 0
  for (let level = 1; level < target; level++) ms += xpToNext(curve, level) / xpPerMs(level)
  return ms
}

/**
 * The tolerance. The targets are the designer's round numbers, so it has to absorb their rounding (level 100 is
 * "about 8 h" against a real 8.7 h, the widest gap at 8%). It is nowhere near wide enough to survive a real
 * retune: on the pre-1.8t curve the first level-up took 30 s, not 75, and there was no level 100 at all.
 */
const TOLERANCE = 0.15
const within = (actual: number, target: number) => Math.abs(actual - target) / target

describe('the shipped pacing for one unupgraded Sproutlet on Woodcutting', () => {
  it('uses the Woodcutting tiers as shipped: oak from level 1, then willow, then yew', () => {
    expect(tiers.map((r) => r.id)).toEqual(['oak-log', 'willow-log', 'yew-log'])
    expect(tiers.map((r) => r.requiredSkillLevel)).toEqual([1, 15, 30])
    // An unupgraded starter is not sped up or slowed down by anything, so a tier's cooldown is its base time.
    for (const tier of tiers) expect(creatureCooldown(sproutlet, 'woodcutting', tier.baseActionMs!, []).cooldownMs).toBe(tier.baseActionMs)
  })

  // Step 1.9c raised the growth from 1.04 to 1.045. The first level-up is unchanged (the first level costs `base`
  // whatever the growth is) and the early game barely moves; the late game is where the retune lands.
  const milestones: ReadonlyArray<readonly [string, number, number]> = [
    ['the first level-up, about 75 s', 2, 75 * SECOND],
    ['level 30, about 50 min', 30, 50 * MINUTE],
    ['level 100, about 12.5 h', 100, 12.5 * HOUR],
    ['level 250 (the cap), about 12 months', woodcutting.maxLevel, 12 * MONTH],
  ]

  for (const [label, level, target] of milestones) {
    it(`reaches ${label}`, () => {
      const actual = timeToLevel(level)
      expect(within(actual, target), `level ${level} takes ${(actual / MINUTE).toFixed(1)} min, target ${(target / MINUTE).toFixed(1)} min`).toBeLessThan(TOLERANCE)
    })
  }

  it('the cap is the last milestone: 250 levels, and every milestone is further out than the last', () => {
    expect(woodcutting.maxLevel).toBe(milestones[milestones.length - 1]![1])
    const times = milestones.map(([, level]) => timeToLevel(level))
    expect(times).toEqual([...times].sort((a, b) => a - b))
    expect(new Set(times).size).toBe(times.length)
  })

  it('every skill shares the cap and the slot unlock levels, so this pacing is the whole game', () => {
    for (const skill of content.skills) {
      expect(skill.maxLevel, skill.id).toBe(woodcutting.maxLevel)
      expect(skill.slotUnlockLevels, skill.id).toEqual(woodcutting.slotUnlockLevels)
    }
  })

  it('the work slots open well after the first hour, not all within it', () => {
    const [first, second] = woodcutting.slotUnlockLevels as [number, number, ...number[]]
    expect(first).toBe(1)
    expect(timeToLevel(second)).toBeGreaterThan(HOUR)
    expect(timeToLevel(woodcutting.slotUnlockLevels[woodcutting.slotUnlockLevels.length - 1]!)).toBeGreaterThan(7 * DAY)
  })
})

// ---------- the floor: the fastest account the data allows ----------

/**
 * The number the retune was actually aimed at (designer, 2026-09-20). The lone-starter milestones above say how the
 * game opens; this says how fast it can possibly be finished, which is what a fast-forwarded run made impossible to
 * judge by eye.
 *
 * The model is a DELIBERATELY GENEROUS upper bound on the real best case, so the assertion below is a true floor.
 * Everything in it comes from the shipped data and the real formulas:
 *  - every work slot is filled the moment `slotUnlockLevels` opens it (five of them, at 1 / 50 / 100 / 165 / 225);
 *  - every creature is the best the game can make: the top rarity tier, Form 3, the creature cap, primary skill;
 *  - both relevant modifier caps from modifiers.json are fully applied, to every creature at once: the whole shared
 *    `cooldown_reduction` cap, and the whole `bonus_xp` cap;
 *  - every creature is always on the best Woodcutting tier its skill level has unlocked.
 * Nothing in the game can beat that, so the real fastest account takes AT LEAST as long.
 *
 * REVISIT THIS TEST when tiers 4 and 5 are authored, when new trait mechanics land, or when a faster creature is
 * added: each of those raises the best-case rate, so the floor has to be recomputed against the designer's target
 * rather than quietly failing.
 */
describe('the floor: the fastest possible account still needs weeks for level 250', () => {
  const bestRarity = content.rarities[content.rarities.length - 1]!
  const cap = (key: string): number => content.modifierByKey.get(key)!.cap

  /** One best-case creature's cooldown on a tier, through the real cooldown formula. */
  const bestCooldownMs = (baseActionMs: number): number =>
    cooldown(
      {
        baseActionMs,
        offPrimary: false, // Woodcutting is the Sproutlet line's primary skill
        secondaryAptitude: false, // Woodcutting is a locked skill, so no aptitude bonus applies
        level: content.tuning.creature.maxLevel,
        rarityTier: bestRarity.tier,
        form: 3,
        traitReduction: cap('cooldown_reduction'),
      },
      content.tuning,
    ).cooldownMs

  /** XP per millisecond for ONE best-case creature at this skill level. */
  const bestXpPerMs = (level: number): number => {
    const tier = [...tiers].reverse().find((r) => r.requiredSkillLevel! <= level)!
    return (tier.xpPerAction! * (1 + cap('bonus_xp'))) / bestCooldownMs(tier.baseActionMs!)
  }

  /** Milliseconds to reach `target` with every unlocked slot filled by such a creature. */
  function floorTimeToLevel(target: number): number {
    let ms = 0
    for (let level = 1; level < target; level++) ms += xpToNext(curve, level) / (slotCount(woodcutting, level) * bestXpPerMs(level))
    return ms
  }

  it('models the best case from the real data: top rarity, Form 3, creature cap, both modifier caps', () => {
    expect(bestRarity.id).toBe('zenith')
    expect(content.tuning.creature.maxLevel).toBe(99)
    expect(cap('cooldown_reduction')).toBeGreaterThan(0)
    expect(cap('bonus_xp')).toBeGreaterThan(0)
    // It really is faster than the lone starter this file opens with, and by a lot.
    expect(bestCooldownMs(3000)).toBeLessThan(3000)
    expect(bestXpPerMs(1)).toBeGreaterThan(5 * (10 / 3000))
    expect(slotCount(woodcutting, woodcutting.maxLevel)).toBe(woodcutting.slotUnlockLevels.length)
  })

  it('cannot reach level 250 in under 12 days', () => {
    const days = floorTimeToLevel(woodcutting.maxLevel) / DAY
    expect(days, `the best possible account reaches level 250 in ${days.toFixed(1)} days`).toBeGreaterThanOrEqual(12)
  })

  it('is not absurdly slow either: the target is about two weeks, not months', () => {
    expect(floorTimeToLevel(woodcutting.maxLevel) / DAY).toBeLessThan(30)
  })

  it('the old 1.04 curve fails this floor, which is why the growth was raised', () => {
    const old = variant((raw) => {
      raw.tuning.xp.skillCurve.growth = 1.04
    })
    let ms = 0
    for (let level = 1; level < woodcutting.maxLevel; level++) {
      ms += xpToNext(old.tuning.xp.skillCurve, level) / (slotCount(woodcutting, level) * bestXpPerMs(level))
    }
    expect(ms / DAY).toBeLessThan(12) // it took about 4.6 days
  })
})

// ---------- what the retune does to saves written under the old curve ----------

describe('a save written on the old 1.04 curve keeps its XP and re-levels', () => {
  const OLD = variant((raw) => {
    raw.tuning.xp.skillCurve.growth = 1.04
  })

  /** old level -> the level the same XP is worth now. Recomputed from the data, and pinned so a later retune shows up here. */
  const TABLE: ReadonlyArray<readonly [number, number]> = [
    [1, 1],
    [2, 2],
    [15, 14],
    [30, 28],
    [50, 46],
    [100, 91],
    [150, 136],
    [165, 149],
    [200, 180],
    [217, 196],
    [225, 203],
    [250, 225],
  ]

  it('drops each old level to the one its XP now buys, and never by more than a tenth', () => {
    for (const [oldLevel, newLevel] of TABLE) {
      const xp = xpForLevel(OLD.tuning.xp.skillCurve, oldLevel, woodcutting.maxLevel)
      expect(levelForXp(curve, xp, woodcutting.maxLevel), `old level ${oldLevel}`).toBe(newLevel)
      expect(newLevel).toBeLessThanOrEqual(oldLevel)
      expect(oldLevel - newLevel, `old level ${oldLevel} lost too much`).toBeLessThanOrEqual(Math.ceil(oldLevel * 0.1))
    }
  })

  it('loads such a save without losing XP, a creature or a slot', () => {
    for (const [oldLevel, newLevel] of TABLE) {
      const before = setSkillLevel(newGame(OLD), 'woodcutting', oldLevel, OLD)
      const loaded = parseSave(serializeSave(before))
      if (!loaded.ok) throw new Error(`old level ${oldLevel}: ${loaded.message}`)
      const sk = loaded.state.skills.woodcutting!
      expect(sk.xp, `old level ${oldLevel}`).toBe(before.skills.woodcutting!.xp) // XP is never taken away
      expect(sk.level, `old level ${oldLevel}`).toBe(newLevel)
      expect(loaded.state.creatures).toHaveLength(before.creatures.length)
      // 1.8t's grandfathering still holds: a slot the new level no longer earns is kept.
      expect(sk.slots.length, `old level ${oldLevel}`).toBeGreaterThanOrEqual(before.skills.woodcutting!.slots.length)
      expect(sk.slots.length).toBeGreaterThanOrEqual(slotCount(woodcutting, newLevel))
    }
  })

  it('the level a save loses is only ever re-earned, never crashed on', () => {
    const before = setSkillLevel(newGame(OLD), 'woodcutting', woodcutting.maxLevel, OLD)
    const loaded = parseSave(serializeSave(before))
    if (!loaded.ok) throw new Error(loaded.message)
    expect(loaded.state.skills.woodcutting!.level).toBe(225)
    expect(loaded.state.skills.woodcutting!.slots).toHaveLength(woodcutting.slotUnlockLevels.length) // all five, grandfathered
  })
})
