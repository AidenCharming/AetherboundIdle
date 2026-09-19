// The phase 1 formulas (plan.md section 4), as pure functions over tuning numbers. Nothing here knows about
// creatures or state; creature.ts and skills.ts assemble the inputs. Every constant comes from tuning.json.
import type { StatLean, Tuning } from '../data/schema'

type Curve = Tuning['xp']['skillCurve']
export type Form = 1 | 2 | 3

// ---------- XP curve (plan 4.3) ----------

/** XP needed to go from `level` to `level + 1`: round(base * growth^(level-1)). */
export function xpToNext(curve: Curve, level: number): number {
  return Math.round(curve.base * curve.growth ** (level - 1))
}

// Cumulative tables are built once per (curve, maxLevel) and memoized. table[L] = total XP needed to be at
// level L, so table[1] = 0. Index 0 is unused.
const tables = new Map<string, number[]>()

function table(curve: Curve, maxLevel: number): number[] {
  const key = `${curve.base}|${curve.growth}|${maxLevel}`
  let t = tables.get(key)
  if (!t) {
    t = [0, 0]
    for (let level = 2; level <= maxLevel; level++) t[level] = t[level - 1]! + xpToNext(curve, level - 1)
    tables.set(key, t)
  }
  return t
}

/** Cumulative XP at which `level` is reached. */
export function xpForLevel(curve: Curve, level: number, maxLevel: number): number {
  return table(curve, maxLevel)[Math.min(Math.max(level, 1), maxLevel)]!
}

/** The level a cumulative XP total sits at, clamped to [1, maxLevel]. */
export function levelForXp(curve: Curve, xp: number, maxLevel: number): number {
  const t = table(curve, maxLevel)
  if (!(xp > 0)) return 1
  let lo = 1
  let hi = maxLevel
  while (lo < hi) {
    const mid = (lo + hi + 1) >> 1
    if (t[mid]! <= xp) lo = mid
    else hi = mid - 1
  }
  return lo
}

// ---------- forms ----------

/** Form is automatic on reaching the level (design section 4). */
export function formForLevel(level: number, tuning: Tuning): Form {
  const { formUnlockLevels } = tuning.creature
  if (level >= formUnlockLevels['3']) return 3
  if (level >= formUnlockLevels['2']) return 2
  return 1
}

// ---------- stats (plan 4.1) ----------

export interface StatInput {
  stat: StatLean
  /** The creature's `statLean`. */
  lean: StatLean
  level: number
  rarityStatMultiplier: number
  form: Form
  /** Capped `bonus_<stat>` total: a percentage of the stat, not a flat add. */
  traitBonus: number
}

export function statValue(input: StatInput, tuning: Tuning): number {
  const { baseStats, statLeanMultiplier, statPerLevel, formMultiplier } = tuning.creature
  const lean = input.stat === input.lean ? statLeanMultiplier.leaned : statLeanMultiplier.other
  return (
    baseStats[input.stat] *
    lean *
    (1 + statPerLevel * (input.level - 1)) *
    input.rarityStatMultiplier *
    formMultiplier[input.form] *
    (1 + input.traitBonus)
  )
}

// ---------- action cooldown (plan 4.2) ----------

export interface CooldownInput {
  baseActionMs: number
  /** A hybrid working a covered skill that is not its primary skill. */
  offPrimary: boolean
  /** The skill is open and matches the creature's secondary aptitude. */
  secondaryAptitude: boolean
  level: number
  rarityTier: number
  form: Form
  /** Already capped by the shared `cooldown_reduction` registry cap (modifiers.ts). */
  traitReduction: number
}

export interface CooldownBreakdown {
  /** Job fit. A DIVISOR on the base time, so below 1 means slower. */
  efficiency: number
  adjustedBase: number
  intrinsicTerm: number
  intrinsicMult: number
  traitReduction: number
  raw: number
  /** `adjustedBase * floorFraction`: taken from the efficiency-adjusted base, not the raw one. */
  floor: number
  cooldownMs: number
  floored: boolean
}

/**
 * Efficiency is a divisor on the base time, so "higher is always better" for both knobs: 0.60 makes an
 * off-primary hybrid take 1/0.60 = 1.667x as long, and a 0.15 secondary-aptitude bonus makes the action take
 * 1/1.15 as long. It is not part of the cooldown_reduction cap because it describes job fit, not a stacking
 * speed bonus.
 */
export function efficiency(input: Pick<CooldownInput, 'offPrimary' | 'secondaryAptitude'>, tuning: Tuning): number {
  let e = 1
  if (input.offPrimary) e *= tuning.skills.hybridOffPrimaryEfficiency
  if (input.secondaryAptitude) e *= 1 + tuning.skills.secondaryAptitudeBonus
  return e
}

export function cooldown(input: CooldownInput, tuning: Tuning): CooldownBreakdown {
  const { levelTermPerLevel, rarityTermPerTier, formTerm, floorFraction } = tuning.cooldown

  // stage 1: efficiency
  const eff = efficiency(input, tuning)
  const adjustedBase = input.baseActionMs / eff

  // stage 2: intrinsic growth from level, rarity and form, hyperbolic so it has diminishing returns
  const intrinsicTerm = levelTermPerLevel * (input.level - 1) + rarityTermPerTier * (input.rarityTier - 1) + formTerm[input.form]
  const intrinsicMult = 1 / (1 + intrinsicTerm)

  // stage 3: capped trait reduction, then one hard floor over the last two stages. The floor comes from the
  // efficiency-adjusted base so an off-primary hybrid's floor is 1/efficiency times a specialist's and no
  // amount of level, rarity, form or traits lets it reach specialist speed.
  const raw = adjustedBase * intrinsicMult * (1 - input.traitReduction)
  const floor = adjustedBase * floorFraction
  return {
    efficiency: eff,
    adjustedBase,
    intrinsicTerm,
    intrinsicMult,
    traitReduction: input.traitReduction,
    raw,
    floor,
    cooldownMs: Math.max(raw, floor),
    floored: raw < floor,
  }
}

// ---------- time ----------

/**
 * Every step clamps its `dt` here: negative (clock skew), NaN and infinite windows all become zero, so a bad
 * clock can never run the sim backwards or hand out unbounded progress.
 */
export function sanitizeDt(dtMs: number): number {
  return Number.isFinite(dtMs) && dtMs > 0 ? dtMs : 0
}

// ---------- action counting ----------

/** Absorbs float dust so 3000ms of progress against a 3000ms cooldown is one action, not 0.9999999. */
const COMPLETION_EPSILON = 1e-9

/** Whole actions finished by `elapsedMs` of accumulated progress against `cooldownMs`. */
export function completedActions(elapsedMs: number, cooldownMs: number): number {
  if (!(elapsedMs > 0) || !(cooldownMs > 0)) return 0
  return Math.floor(elapsedMs / cooldownMs + COMPLETION_EPSILON)
}
