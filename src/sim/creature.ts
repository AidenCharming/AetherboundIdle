// Derived creature numbers: stats, which skills it can work, effective cooldown, and creature XP.
// Assembles inputs for formulas.ts; the maths itself lives there.
import { content, type Content, type Hybrid, type Species, type StatLean } from '../data'
import type { Creature } from '../types/state'
import type { SimEvent, SimResult } from './events'
import { cooldown, formForLevel, levelForXp, statValue, type CooldownBreakdown } from './formulas'
import { cappedModifier, type ActiveEntry } from './modifiers'

export function creatureDef(creature: Creature, c: Content = content): Species | Hybrid | undefined {
  return c.creatureById.get(creature.speciesId)
}

/** Locked skills need a matching type (a hybrid covers both parents' skills); open skills take anyone. */
export function canWork(creature: Creature, skillId: string, c: Content = content): boolean {
  const def = creatureDef(creature, c)
  const skill = c.skillById.get(skillId)
  if (!def || !skill) return false
  if (skill.open) return true
  if ('coveredSkills' in def) return def.coveredSkills.includes(skillId)
  return skill.requiredType !== null && def.types.includes(skill.requiredType)
}

// ---------- stats (plan 4.1) ----------

export type Stats = Record<StatLean, number>

export function creatureStats(creature: Creature, c: Content = content): Stats {
  const def = creatureDef(creature, c)
  const rarity = c.rarities[creature.rarityTier - 1]
  if (!def || !rarity) throw new Error(`creatureStats: unknown species "${creature.speciesId}" or rarity tier ${creature.rarityTier}`)
  const stat = (name: StatLean): number =>
    statValue(
      {
        stat: name,
        lean: def.statLean,
        level: creature.level,
        rarityStatMultiplier: rarity.statMultiplier,
        form: creature.form,
        // Vitality / Brawn / Stalwart / Champion: a capped percentage of the stat.
        traitBonus: cappedModifier(`bonus_${name}`, creature, null, [], c),
      },
      c.tuning,
    )
  return { health: stat('health'), power: stat('power'), guard: stat('guard') }
}

// ---------- action cooldown (plan 4.2) ----------

/**
 * Full cooldown breakdown for `creature` working `skillId` on a resource with `baseActionMs`. `active` is
 * everyone currently in a work slot, since auras read it.
 */
export function creatureCooldown(
  creature: Creature,
  skillId: string,
  baseActionMs: number,
  active: readonly ActiveEntry[],
  c: Content = content,
): CooldownBreakdown {
  const def = creatureDef(creature, c)
  const skill = c.skillById.get(skillId)
  if (!def || !skill) throw new Error(`creatureCooldown: unknown species "${creature.speciesId}" or skill "${skillId}"`)
  return cooldown(
    {
      baseActionMs,
      // "Covered skills" are a hybrid's locked skills (plan 3.7); open skills are nobody's off-primary.
      offPrimary: creature.isHybrid && !skill.open && skillId !== def.primarySkill,
      secondaryAptitude: skill.open && skillId === def.secondaryAptitude,
      level: creature.level,
      rarityTier: creature.rarityTier,
      form: creature.form,
      traitReduction: cappedModifier('cooldown_reduction', creature, skillId, active, c),
    },
    c.tuning,
  )
}

// ---------- creature XP, levels and forms ----------

/**
 * Adds creature XP, emitting one `creature-level-up` per level crossed and a `form-evolved` at each form
 * threshold. Evolution is automatic (design section 4) and a form never goes back down. Nothing calls this in
 * phase 1: only combat awards creature XP (design section 8), and combat is phase 3.
 */
export function grantCreatureXp(creature: Creature, amount: number, c: Content = content): SimResult<Creature> {
  const { creatureCurve } = c.tuning.xp
  const { maxLevel } = c.tuning.creature
  const xp = creature.xp + Math.max(0, amount)
  const level = Math.max(creature.level, levelForXp(creatureCurve, xp, maxLevel))

  const events: SimEvent[] = []
  for (let l = creature.level + 1; l <= level; l++) {
    events.push({ type: 'creature-level-up', creatureId: creature.id, level: l })
    const form = formForLevel(l, c.tuning)
    if (form > formForLevel(l - 1, c.tuning)) events.push({ type: 'form-evolved', creatureId: creature.id, form })
  }
  return { state: { ...creature, xp, level, form: Math.max(creature.form, formForLevel(level, c.tuning)) as Creature['form'] }, events }
}

/** A fresh creature: Form 1, level 1, benched. The caller supplies the id (see `GameState.nextCreatureSeq`). */
export function makeCreature(
  id: string,
  speciesId: string,
  overrides: Partial<Omit<Creature, 'id' | 'speciesId'>> = {},
  c: Content = content,
): Creature {
  const def = c.creatureById.get(speciesId)
  if (!def) throw new Error(`makeCreature: unknown species "${speciesId}"`)
  return {
    id,
    speciesId,
    isHybrid: def.origin === 'breed',
    rarityTier: 1,
    level: 1,
    xp: 0,
    form: 1,
    shiny: false,
    poolTraits: [],
    assignment: null,
    ...overrides,
  }
}
