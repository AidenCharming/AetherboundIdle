import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import {
  completedActions,
  cooldown,
  efficiency,
  formForLevel,
  levelForXp,
  sanitizeDt,
  statValue,
  xpForLevel,
  xpToNext,
  type CooldownInput,
} from '../src/sim/formulas'
import { slotCount } from '../src/sim/skills'
import { variant } from './helpers'

const { tuning } = content
const curve = tuning.xp.skillCurve
const MAX = tuning.creature.maxLevel

describe('xp curve (plan 4.3)', () => {
  it('xpToNext is round(base * growth^(L-1))', () => {
    expect(xpToNext(curve, 1)).toBe(100)
    expect(xpToNext(curve, 2)).toBe(110)
    expect(xpToNext(curve, 3)).toBe(121)
    expect(xpToNext(curve, 10)).toBe(Math.round(100 * 1.1 ** 9))
  })

  it('level -> xp -> level round-trips at every level, and one XP short is the level below', () => {
    expect(xpForLevel(curve, 1, MAX)).toBe(0)
    for (let level = 1; level <= MAX; level++) {
      const xp = xpForLevel(curve, level, MAX)
      expect(levelForXp(curve, xp, MAX), `at exactly level ${level}`).toBe(level)
      if (level > 1) expect(levelForXp(curve, xp - 0.001, MAX), `just below level ${level}`).toBe(level - 1)
    }
  })

  it('the cumulative table is the running sum of xpToNext', () => {
    let running = 0
    for (let level = 1; level < MAX; level++) {
      expect(xpForLevel(curve, level, MAX)).toBe(running)
      running += xpToNext(curve, level)
    }
  })

  it('clamps: bad input is level 1, and huge XP stops at max level', () => {
    for (const bad of [-5, 0, NaN, -Infinity]) expect(levelForXp(curve, bad, MAX)).toBe(1)
    expect(levelForXp(curve, 1e15, MAX)).toBe(MAX)
    expect(levelForXp(curve, Infinity, MAX)).toBe(MAX)
    expect(xpForLevel(curve, MAX + 10, MAX)).toBe(xpForLevel(curve, MAX, MAX))
  })

  it('a level-xp table is built per curve, so the skill and creature curves do not share one', () => {
    expect(xpForLevel(tuning.xp.creatureCurve, 2, MAX)).toBe(80)
    expect(xpForLevel(curve, 2, MAX)).toBe(100)
  })
})

describe('slot unlocks (plan 4.3)', () => {
  const skill = content.skillById.get('woodcutting')!
  it('unlocks at exactly levels 1 / 20 / 40 / 65 / 90', () => {
    expect(skill.slotUnlockLevels).toEqual([1, 20, 40, 65, 90])
    const count = (l: number) => slotCount(skill, l)
    expect([1, 19, 20, 39, 40, 64, 65, 89, 90, 99].map(count)).toEqual([1, 1, 2, 2, 3, 3, 4, 4, 5, 5])
  })
})

describe('forms', () => {
  it('Form 2 at level 30 and Form 3 at level 60', () => {
    expect([1, 29, 30, 59, 60, 99].map((l) => formForLevel(l, tuning))).toEqual([1, 1, 2, 2, 3, 3])
  })
})

describe('stats (plan 4.1)', () => {
  const base = { level: 1, rarityStatMultiplier: 1, form: 1 as const, traitBonus: 0 }
  it('applies the lean, level, rarity, form and a percentage trait bonus', () => {
    expect(statValue({ ...base, stat: 'guard', lean: 'guard' }, tuning)).toBeCloseTo(10 * 1.25)
    expect(statValue({ ...base, stat: 'health', lean: 'guard' }, tuning)).toBeCloseTo(50 * 0.9)
    // level 11 = +40%, Radiant x8.5, Form 2 x1.2, +10% trait, on a leaned Power stat
    expect(statValue({ stat: 'power', lean: 'power', level: 11, rarityStatMultiplier: 8.5, form: 2, traitBonus: 0.1 }, tuning)).toBeCloseTo(10 * 1.25 * 1.4 * 8.5 * 1.2 * 1.1)
  })
  it('the trait bonus is a percentage of the stat, not a flat add', () => {
    const plain = statValue({ ...base, stat: 'health', lean: 'health' }, tuning)
    const boosted = statValue({ ...base, stat: 'health', lean: 'health', traitBonus: 0.2 }, tuning)
    expect(boosted / plain).toBeCloseTo(1.2)
    const big = statValue({ ...base, stat: 'health', lean: 'health', rarityStatMultiplier: 24 }, tuning)
    expect(statValue({ ...base, stat: 'health', lean: 'health', rarityStatMultiplier: 24, traitBonus: 0.2 }, tuning) / big).toBeCloseTo(1.2)
  })
})

describe('sanitizeDt', () => {
  it('turns negative, NaN and infinite windows into zero', () => {
    expect([-1, -1e9, NaN, Infinity, -Infinity, 0].map(sanitizeDt)).toEqual([0, 0, 0, 0, 0, 0])
    expect(sanitizeDt(250)).toBe(250)
  })
})

describe('completedActions', () => {
  it('counts whole actions and absorbs float dust', () => {
    expect(completedActions(2999, 3000)).toBe(0)
    expect(completedActions(3000, 3000)).toBe(1)
    expect(completedActions(0.1 + 0.2 + 2999.7, 3000)).toBe(1) // 3000.0000000000005 territory
    expect(completedActions(3000 - 1e-12, 3000)).toBe(1)
    expect(completedActions(9000, 3000)).toBe(3)
    expect(completedActions(-5, 3000)).toBe(0)
    expect(completedActions(5000, 0)).toBe(0)
  })
})

describe('cooldown (plan 4.2)', () => {
  const specialist: CooldownInput = { baseActionMs: 3000, offPrimary: false, secondaryAptitude: false, level: 1, rarityTier: 1, form: 1, traitReduction: 0 }

  it('a Dim Form 1 specialist with no traits takes exactly the base time', () => {
    expect(cooldown(specialist, tuning).cooldownMs).toBe(3000)
  })

  it('intrinsic growth is hyperbolic: 1 / (1 + level, rarity and form terms)', () => {
    // level 31 -> 0.12, rarity tier 3 -> 0.12, Form 2 -> 0.08: term 0.32
    const cd = cooldown({ ...specialist, level: 31, rarityTier: 3, form: 2 }, tuning)
    expect(cd.intrinsicTerm).toBeCloseTo(0.32)
    expect(cd.cooldownMs).toBeCloseTo(3000 / 1.32)
    // diminishing returns: doubling the term does not halve the time
    const more = cooldown({ ...specialist, level: 61, rarityTier: 5, form: 3 }, tuning)
    expect(more.cooldownMs).toBeGreaterThan(cd.cooldownMs / 2)
  })

  it('applies the trait reduction after the intrinsic multiplier', () => {
    const cd = cooldown({ ...specialist, level: 26, traitReduction: 0.2 }, tuning) // term 0.1
    expect(cd.cooldownMs).toBeCloseTo((3000 / 1.1) * 0.8)
  })

  describe('efficiency is a divisor on the base time', () => {
    it('off-primary 0.60 makes the action longer: base / 0.60', () => {
      const cd = cooldown({ ...specialist, offPrimary: true }, tuning)
      expect(cd.efficiency).toBeCloseTo(0.6)
      expect(cd.adjustedBase).toBeCloseTo(5000)
      expect(cd.cooldownMs).toBeCloseTo(5000)
      expect(cd.cooldownMs).toBeGreaterThan(3000)
    })
    it('secondary aptitude 0.15 makes it shorter: base / 1.15', () => {
      const cd = cooldown({ ...specialist, secondaryAptitude: true }, tuning)
      expect(cd.efficiency).toBeCloseTo(1.15)
      expect(cd.cooldownMs).toBeCloseTo(3000 / 1.15)
      expect(cd.cooldownMs).toBeLessThan(3000)
    })
    it('the two compose multiplicatively (0.60 * 1.15 = 0.69), and stay out of the cooldown_reduction cap', () => {
      // A real creature never has both (aptitude is an open skill, off-primary is a locked one), but the
      // formula composes them as plan 4.2 writes it.
      const cd = cooldown({ ...specialist, offPrimary: true, secondaryAptitude: true, traitReduction: 0.5 }, tuning)
      expect(efficiency({ offPrimary: true, secondaryAptitude: true }, tuning)).toBeCloseTo(0.69)
      expect(cd.adjustedBase).toBeCloseTo(3000 / 0.69)
      expect(cd.traitReduction).toBe(0.5)
    })
  })

  describe('the floor is taken from the efficiency-adjusted base', () => {
    // With the shipped numbers the strongest possible creature (level 99, Zenith, Form 3, cap-level traits)
    // still lands above the 20% floor, so it is a safety net. Raise it to prove the maths where it binds.
    const binding = variant((raw) => {
      raw.tuning.cooldown.floorFraction = 0.6
    }).tuning
    const maxed = { level: 99, rarityTier: 9, form: 3 as const, traitReduction: 0.5 }

    it('floors at adjustedBase * floorFraction', () => {
      const cd = cooldown({ ...specialist, ...maxed }, binding)
      expect(cd.floored).toBe(true)
      expect(cd.floor).toBeCloseTo(3000 * 0.6)
      expect(cd.cooldownMs).toBeCloseTo(1800)
    })

    it('an off-primary hybrid floors at 1/0.60 of a specialist floor, not at the same number', () => {
      const s = cooldown({ ...specialist, ...maxed }, binding)
      const h = cooldown({ ...specialist, ...maxed, offPrimary: true }, binding)
      expect(s.floored && h.floored).toBe(true)
      expect(h.floor).toBeCloseTo((3000 / 0.6) * 0.6) // adjusted base * floor
      expect(h.cooldownMs / s.cooldownMs).toBeCloseTo(1 / 0.6)
    })

    it('a maxed off-primary hybrid is strictly slower than a floored specialist on the same resource', () => {
      for (const t of [binding, tuning]) {
        const s = cooldown({ ...specialist, ...maxed }, t)
        const h = cooldown({ ...specialist, ...maxed, offPrimary: true }, t)
        expect(h.cooldownMs, t === binding ? 'floor binding' : 'shipped tuning').toBeGreaterThan(s.cooldownMs)
      }
    })

    it('an unadjusted floor would erase the difference; this proves the adjusted one does not', () => {
      const h = cooldown({ ...specialist, ...maxed, offPrimary: true }, binding)
      const wrongFloor = 3000 * 0.6 // floor taken from the unadjusted base
      expect(h.raw).toBeLessThan(wrongFloor) // raw would collapse onto the specialist's floor...
      expect(h.cooldownMs).toBeGreaterThan(wrongFloor) // ...but the real floor holds it back
    })

    it('a secondary-aptitude specialist has a lower floor than a plain one (higher efficiency = faster)', () => {
      const plain = cooldown({ ...specialist, ...maxed }, binding)
      const apt = cooldown({ ...specialist, ...maxed, secondaryAptitude: true }, binding)
      expect(apt.floor).toBeCloseTo(plain.floor / 1.15)
    })
  })
})
