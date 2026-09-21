// The dev panel's grants (plan.md 7.1): creatures, resources, Aether and gold. Pure functions like the rest of the
// sim. Each validates its input and returns a reason instead of throwing, so the panel can show it. None of them
// touches the RNG: a grant is exactly what the tester picked, nothing is rolled (designer, 2026-09-20; a pool-trait
// roll is Phase 2 design). Set skill level lives beside `addSkillXp` in skills.ts (`raiseSkillToLevel`).
import { content, STRENGTHS, type Content } from '../data'
import type { Creature, GameState, PoolTraitRoll } from '../types/state'
import { makeCreature } from './creature'
import { xpForLevel } from './formulas'
import { raiseSkillToLevel, unassignCreature } from './skills'

/**
 * Largest amount one grant may add. An input guard for the dev tool, not a balance number: it keeps a typo like
 * 1e30 from turning every counter into something the display and the save cannot hold.
 */
export const DEV_MAX_AMOUNT = 1_000_000_000_000

export type DevResult = { ok: true; state: GameState; message: string } | { ok: false; reason: string }

type Parsed = { ok: true; value: number } | { ok: false; reason: string }

const fail = (reason: string): { ok: false; reason: string } => ({ ok: false, reason })
const fmt = (n: number): string => n.toLocaleString('en-US')

/**
 * Text or a number to a finite number. Empty text is refused here, because `Number('')` is 0 and would otherwise
 * pass for a real entry; anything else that is not a finite number ('abc', 'Infinity', '1e999', NaN) is refused too.
 */
function toNumber(raw: unknown, what: string): Parsed {
  let value: unknown = raw
  if (typeof raw === 'string') {
    if (raw.trim() === '') return fail(`Enter ${what}.`)
    value = Number(raw)
  }
  if (typeof value !== 'number') return fail(`Enter ${what}.`)
  if (!Number.isFinite(value)) return fail('That is not a valid number.')
  return { ok: true, value }
}

function parseAmount(raw: unknown, whole: boolean, current: number): Parsed {
  const n = toNumber(raw, 'an amount')
  if (!n.ok) return n
  if (n.value < 0) return fail('Amount cannot be negative.')
  if (n.value === 0) return fail('Amount must be greater than zero.')
  if (whole && !Number.isInteger(n.value)) return fail('Amount must be a whole number.')
  if (n.value > DEV_MAX_AMOUNT) return fail(`Amount must be at most ${fmt(DEV_MAX_AMOUNT)}.`)
  if (current + n.value > Number.MAX_SAFE_INTEGER) return fail('That would push the total past the largest number the game can hold.')
  return n
}

// ---------- resources, Aether, gold ----------

/** Adds a whole number of any resource the data lists. */
export function addResource(state: GameState, resourceId: string, rawAmount: unknown, c: Content = content): DevResult {
  const resource = c.resourceById.get(resourceId)
  if (!resource) return fail(`Unknown resource "${resourceId}".`)
  const held = state.resources[resourceId] ?? 0
  const amount = parseAmount(rawAmount, true, held)
  if (!amount.ok) return amount
  return { ok: true, state: { ...state, resources: { ...state.resources, [resourceId]: held + amount.value } }, message: `Added ${fmt(amount.value)} ${resource.name}.` }
}

/** Aether is a float in the save (bench emission accrues fractionally), so a fractional grant is allowed. */
export function addAether(state: GameState, rawAmount: unknown): DevResult {
  const amount = parseAmount(rawAmount, false, state.aether)
  if (!amount.ok) return amount
  return { ok: true, state: { ...state, aether: state.aether + amount.value }, message: `Added ${fmt(amount.value)} Aether.` }
}

export function addGold(state: GameState, rawAmount: unknown): DevResult {
  const amount = parseAmount(rawAmount, true, state.gold)
  if (!amount.ok) return amount
  return { ok: true, state: { ...state, gold: state.gold + amount.value }, message: `Added ${fmt(amount.value)} gold.` }
}

// ---------- skill level ----------

/**
 * "Set skill level": the text a field holds, checked, then `raiseSkillToLevel` (skills.ts), which does the XP and the
 * slot unlocks through the sim's own `addSkillXp`. It only raises.
 */
export function setSkillLevel(state: GameState, skillId: string, rawLevel: unknown, c: Content = content): DevResult {
  const skill = c.skillById.get(skillId)
  if (!skill) return fail(`Unknown skill "${skillId}".`)
  const level = toNumber(rawLevel, 'a level')
  if (!level.ok) return level
  const raised = raiseSkillToLevel(state, skillId, level.value, c)
  if (!raised.ok) return fail(`${raised.reason}.`)
  return { ok: true, state: raised.state, message: `Set ${skill.name} to level ${level.value}.` }
}

// ---------- creatures ----------

export interface GrantSpec {
  speciesId: string
  rarityTier: number
  /** A number or the text a field holds. */
  level: number | string
  /** Any of 1, 2, 3 whatever the level: form is stored on the creature, not derived from its level (plan 7.1). */
  form: number
  shiny: boolean
  poolTraits: readonly { traitId: string; strength: string }[]
}

/**
 * A benched creature exactly as specified. Its XP is set to what its level takes on the creature curve, so the level
 * and the XP agree and a later `grantCreatureXp` continues from the right place. It takes the next `creature-<n>`
 * id and leaves the RNG alone. Pool traits are the tester's picks: up to `creature.maxPoolTraits`, distinct, each at
 * a strength the trait allows (a trait with a `minStrength` cannot go below it).
 */
export function grantCreature(state: GameState, spec: GrantSpec, c: Content = content): DevResult {
  const def = c.creatureById.get(spec.speciesId)
  if (!def) return fail(`Unknown species "${spec.speciesId}".`)
  const rarity = c.rarities[spec.rarityTier - 1]
  if (!Number.isInteger(spec.rarityTier) || !rarity) return fail(`Rarity must be one of the ${c.rarities.length} tiers.`)

  const { maxLevel, maxPoolTraits } = c.tuning.creature
  const lvl = toNumber(spec.level, 'a level')
  if (!lvl.ok) return lvl
  if (!Number.isInteger(lvl.value) || lvl.value < 1 || lvl.value > maxLevel) return fail(`Level must be a whole number from 1 to ${maxLevel}.`)
  const level = lvl.value

  if (spec.form !== 1 && spec.form !== 2 && spec.form !== 3) return fail('Form must be 1, 2 or 3.')

  if (spec.poolTraits.length > maxPoolTraits) return fail(`A creature has at most ${maxPoolTraits} pool traits.`)
  const seen = new Set<string>()
  const poolTraits: PoolTraitRoll[] = []
  for (const pick of spec.poolTraits) {
    const trait = c.traitById.get(pick.traitId)
    if (!trait || trait.kind !== 'pool') return fail(`"${pick.traitId}" is not a pool trait.`)
    if (seen.has(trait.id)) return fail(`${trait.name} is picked twice; a creature cannot carry the same trait twice.`)
    seen.add(trait.id)
    const strength = STRENGTHS.find((s) => s === pick.strength)
    if (!strength) return fail(`"${pick.strength}" is not a strength.`)
    if (trait.minStrength && STRENGTHS.indexOf(strength) < STRENGTHS.indexOf(trait.minStrength)) return fail(`${trait.name} cannot roll below ${trait.minStrength}.`)
    poolTraits.push({ traitId: trait.id, strength, locked: false })
  }

  const id = `creature-${state.nextCreatureSeq}`
  const overrides: Partial<Omit<Creature, 'id' | 'speciesId'>> = {
    rarityTier: spec.rarityTier,
    level,
    xp: xpForLevel(c.tuning.xp.creatureCurve, level, maxLevel),
    form: spec.form,
    shiny: spec.shiny === true,
    poolTraits,
  }
  const creature = makeCreature(id, def.id, overrides, c)
  const formName = def.forms[spec.form - 1]!.name
  return {
    ok: true,
    state: { ...state, creatures: [...state.creatures, creature], nextCreatureSeq: state.nextCreatureSeq + 1 },
    message: `Granted ${formName} (${id}): ${rarity.name}, level ${level}, form ${spec.form}${creature.shiny ? ', shiny' : ''}.`,
  }
}

/**
 * Removes a creature from the game (the trash can on a Nexus card while the Dev panel is on). One that works a slot is
 * benched first through the sim's own `unassignCreature`, so the slot is emptied and nothing is left pointing at a creature
 * that no longer exists (the save check refuses that). `nextCreatureSeq` is left alone, so the id is never handed out again.
 * Anyone can be deleted, the last creature included: the Nexus shows an empty state, and Reset save starts a new game.
 */
export function deleteCreature(state: GameState, creatureId: string, c: Content = content): DevResult {
  const creature = state.creatures.find((cr) => cr.id === creatureId)
  if (!creature) return fail(`Unknown creature "${creatureId}".`)
  const benched = unassignCreature(state, creatureId)
  const name = c.creatureById.get(creature.speciesId)?.forms[creature.form - 1]?.name ?? creature.speciesId
  return {
    ok: true,
    state: { ...benched, creatures: benched.creatures.filter((cr) => cr.id !== creatureId) },
    message: `Deleted ${name} (${creatureId}).`,
  }
}
