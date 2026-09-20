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
import { xpToNext } from '../src/sim/formulas'

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

  const milestones: ReadonlyArray<readonly [string, number, number]> = [
    ['the first level-up, about 75 s', 2, 75 * SECOND],
    ['level 30, about 46 min', 30, 46 * MINUTE],
    ['level 100, about 8 h', 100, 8 * HOUR],
    ['level 250 (the cap), about 4 months', woodcutting.maxLevel, 4 * MONTH],
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
