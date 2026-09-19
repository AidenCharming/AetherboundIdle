// The effect engine: collects every trait effect that applies to a creature, then applies the registry cap
// (modifiers.json) and the strongest-only aura rule (design section 4). Adding a capped mechanic is a data
// change, because the cap is read from the registry by key.
import { content, type Content, type Effect, type EffectKey, type Strength } from '../data'
import type { Creature } from '../types/state'

/** A creature that is in a work slot right now. Auras and `active-creatures` scopes read this list. */
export interface ActiveEntry {
  creature: Creature
  skillId: string
}

export interface ModifierSource {
  creatureId: string
  traitId: string
  value: number
  /** Aura group, or null for an ordinary trait effect. */
  aura: string | null
}

export interface ModifierResult {
  /** Sum of ordinary effects plus the strongest value of each aura group, before the cap. */
  total: number
  /** `min(cap, total)`. This is the number the rest of the sim uses. */
  capped: number
  cap: number
  sources: ModifierSource[]
}

/**
 * DYNAMIC-EFFECT HOOK. Overclocked (Coilchirp) is modelled in the data as a `dynamic` effect, but what
 * "resets on task completion" means for an endless idle loop is still an open design question (see
 * docs/PROGRESS.md), so the sim deliberately does not model it: a dynamic effect contributes nothing.
 * Whatever rule the designer picks lands here, and probably needs a stack counter on the creature's state.
 */
export function dynamicEffectValue(_effect: Effect, _source: Creature): number {
  return 0
}

function effectValue(effect: Effect, strength: Strength, source: Creature): number {
  if (effect.dynamic) return dynamicEffectValue(effect, source)
  return Math.max(0, effect.valueByStrength?.[strength] ?? 0)
}

/** Every trait on a creature with the strength it rolled: the signature trait at its fixed default, then the pool. */
function creatureTraits(creature: Creature, c: Content): { effects: readonly Effect[]; traitId: string; strength: Strength }[] {
  const out: { effects: readonly Effect[]; traitId: string; strength: Strength }[] = []
  const def = c.creatureById.get(creature.speciesId)
  const signature = def && c.traitById.get(def.signatureTrait)
  if (signature?.kind === 'signature') out.push({ effects: signature.effects, traitId: signature.id, strength: signature.defaultStrength })
  for (const roll of creature.poolTraits) {
    const trait = c.traitById.get(roll.traitId)
    if (trait) out.push({ effects: trait.effects, traitId: trait.id, strength: roll.strength })
  }
  return out
}

/**
 * The value of one mechanic for one creature, given the skill it is working (null when benched) and everyone
 * else who is active.
 *
 * Scopes: `self` is the creature's own effects; `other-active-in-skill` is an aura from another creature
 * working the same skill; `active-creatures` reaches every creature in a work slot, its own source included;
 * `party` is expedition-only and never applies to work. `scope.skills` is matched against the skill the target
 * is working and `scope.types` against the target's types.
 */
export function modifier(
  key: EffectKey,
  target: Creature,
  targetSkillId: string | null,
  active: readonly ActiveEntry[],
  c: Content = content,
): ModifierResult {
  const cap = c.modifierByKey.get(key)?.cap ?? 0
  const targetTypes = c.creatureById.get(target.speciesId)?.types ?? []
  const activeSkillOf = new Map(active.map((a) => [a.creature.id, a.skillId]))

  const candidates = new Map<string, Creature>([[target.id, target]])
  for (const a of active) candidates.set(a.creature.id, a.creature)

  let plain = 0
  const bestPerAura = new Map<string, number>()
  const sources: ModifierSource[] = []

  for (const source of candidates.values()) {
    for (const { effects, traitId, strength } of creatureTraits(source, c)) {
      for (const effect of effects) {
        if (effect.key !== key) continue
        const { target: scope, skills, types } = effect.scope
        if (scope === 'self' && source.id !== target.id) continue
        if (scope === 'party') continue
        if (scope === 'other-active-in-skill') {
          const sourceSkill = activeSkillOf.get(source.id)
          if (sourceSkill === undefined || targetSkillId === null || sourceSkill !== targetSkillId || source.id === target.id) continue
        }
        if (scope === 'active-creatures' && (!activeSkillOf.has(source.id) || targetSkillId === null)) continue
        if (skills && (targetSkillId === null || !skills.includes(targetSkillId))) continue
        if (types && !types.some((t) => targetTypes.includes(t))) continue

        const value = effectValue(effect, strength, source)
        const group = effect.aura?.group ?? null
        sources.push({ creatureId: source.id, traitId, value, aura: group })
        if (group === null) plain += value
        else bestPerAura.set(group, Math.max(bestPerAura.get(group) ?? 0, value))
      }
    }
  }

  let total = plain
  for (const best of bestPerAura.values()) total += best
  return { total, capped: Math.min(cap, total), cap, sources }
}

/** The capped value of one mechanic, when the breakdown is not needed. */
export function cappedModifier(
  key: EffectKey,
  target: Creature,
  targetSkillId: string | null,
  active: readonly ActiveEntry[],
  c: Content = content,
): number {
  return modifier(key, target, targetSkillId, active, c).capped
}
