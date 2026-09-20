// The only way the UI reads the game (plan.md section 1): `src/ui` never imports `src/sim`. Anything the UI would
// otherwise work out for itself, such as a slot's cooldown, whether a tier is locked, how many slots there are
// or a creature's display name, is a selector here, so the rules stay in one place.
//
// Zustand v5 re-renders forever on a selector that returns a fresh object or array on every call. So a selector
// here returns a primitive, a value that is stable by reference (content lookups, and creature views cached per
// creature), or a list that goes through `stable`, which hands back the previous array when nothing changed.
// Selectors taking arguments are used as `useGameStore((s) => selectSlotProgress(s, skillId, slotIndex))`.
import { content, type StatLean, type Strength } from '../data'
import { canWork, creatureDef } from '../sim/creature'
import { xpForLevel, xpToNext } from '../sim/formulas'
import { activeEntries, runningSlot } from '../sim/skills'
import type { Creature } from '../types/state'
import type { LoadNotice } from './persistence'
import type { GameStore } from './store'

// The roster's pure filter and sort live in roster.ts (node-testable, no React). The UI reads them from here so that
// selectors.ts stays its one door into the state layer.
export * from './roster'

// ---------- stable references ----------

const stableCache = new Map<string, readonly string[]>()

/** Returns the previous array under `key` if it holds the same ids in the same order, so React sees no change. */
function stable(key: string, next: readonly string[]): readonly string[] {
  const prev = stableCache.get(key)
  if (prev && prev.length === next.length && prev.every((id, i) => id === next[i])) return prev
  stableCache.set(key, next)
  return next
}

// ---------- content (never changes at runtime, so every value is stable) ----------

/** Fill for anything whose color the data does not give (an id that a rebalance removed). */
const NEUTRAL = 'currentColor'
const typeColor = (typeId: string | null | undefined): string => (typeId ? (content.typeById.get(typeId)?.color ?? NEUTRAL) : NEUTRAL)

/** How often the tick driver steps the sim; the progress bar smooths over exactly this long. */
export const uiTickMs: number = content.tuning.ui.tickMs

/** The CSS hue rotation, in degrees, that makes a shiny's art differ from a normal one (tuning.ui.shinyHueDeg). */
export const shinyHueDeg: number = content.tuning.ui.shinyHueDeg

export interface SkillInfo {
  id: string
  name: string
  /** The color of the type the skill belongs to; null for the open skills. */
  color: string | null
  maxLevel: number
  /** How many slots the skill can ever have. */
  totalSlots: number
}

export interface ResourceInfo {
  id: string
  name: string
  /** Null when the data gives the resource none; the UI then falls back to a dot in `color`. */
  emoji: string | null
  /** The skill level a gatherable resource needs; null for anything that is only dropped. */
  requiredLevel: number | null
  /** The color of its element type. */
  color: string
}

const skillInfos = new Map<string, SkillInfo>(
  content.skills.map((s) => [
    s.id,
    { id: s.id, name: s.name, color: s.requiredType ? typeColor(s.requiredType) : null, maxLevel: s.maxLevel, totalSlots: s.slotUnlockLevels.length },
  ]),
)

const resourceInfos = new Map<string, ResourceInfo>(
  content.resources.map((r) => [
    r.id,
    { id: r.id, name: r.name, emoji: r.emoji ?? null, requiredLevel: r.requiredSkillLevel, color: typeColor(r.elementType) },
  ]),
)

/** Gatherable resources per skill, lowest level first, then the order the data lists them. */
const gatherableBySkill = new Map<string, readonly string[]>()
for (const skill of content.skills) {
  const ids = content.resources
    .filter((r) => r.kind === 'raw' && r.skill === skill.id)
    .sort((a, b) => a.requiredSkillLevel! - b.requiredSkillLevel!)
    .map((r) => r.id)
  gatherableBySkill.set(skill.id, ids)
}

/** Skills a player can work right now: the ones with at least one gatherable resource. Phase 1 has Woodcutting. */
export const gatherableSkillIds: readonly string[] = content.skills.filter((s) => gatherableBySkill.get(s.id)!.length > 0).map((s) => s.id)

export const skillInfo = (skillId: string): SkillInfo => skillInfos.get(skillId) ?? { id: skillId, name: skillId, color: null, maxLevel: 1, totalSlots: 0 }

export const resourceInfo = (resourceId: string): ResourceInfo =>
  resourceInfos.get(resourceId) ?? { id: resourceId, name: resourceId, emoji: null, requiredLevel: null, color: NEUTRAL }

export const gatherableResourceIds = (skillId: string): readonly string[] => gatherableBySkill.get(skillId) ?? []

// ---------- roster vocabulary (content lookups; the filter bar's choices) ----------

export interface TypeChip {
  id: string
  name: string
  color: string
  /** Position in types.json, which is what sorting by type uses. */
  order: number
}

export interface RarityInfo {
  tier: number
  id: string
  name: string
  /** The frame color from rarities.json. */
  tint: string
  /** How strong the glow is, 0 to 1. */
  glow: number
}

const typeChips = new Map<string, TypeChip>(content.types.map((t, order) => [t.id, { id: t.id, name: t.name, color: t.color, order }]))
const rarityInfos: readonly RarityInfo[] = content.rarities.map((r) => ({ tier: r.tier, id: r.id, name: r.name, tint: r.frame.tint, glow: r.frame.glow }))

/** Every type, in the data's order. */
export const typeOptions: readonly TypeChip[] = [...typeChips.values()]
/** Every rarity, lowest tier first. */
export const rarityOptions: readonly RarityInfo[] = rarityInfos
/** Every skill, in the data's order (the filter offers all of them; assigning only ever offers the gatherable ones). */
export const skillOptions: readonly SkillInfo[] = [...skillInfos.values()]
/** The form numbers a creature can be, from the data (1, 2, 3). */
export const formNumbers: readonly number[] = Object.keys(content.tuning.creature.formMultiplier).map(Number).sort((a, b) => a - b)

const typeChip = (typeId: string): TypeChip => typeChips.get(typeId) ?? { id: typeId, name: typeId, color: NEUTRAL, order: typeChips.size }
/** A creature whose rarity tier the data no longer has still shows: plain frame, no glow. */
const rarityInfo = (tier: number): RarityInfo => rarityInfos[tier - 1] ?? { tier, id: `tier-${tier}`, name: `Tier ${tier}`, tint: NEUTRAL, glow: 0 }

// ---------- currencies and resources (top bar) ----------

export const selectGold = (s: GameStore): number => s.game.gold

/**
 * Aether is stored as a float and accrues fractionally, so this floors it for display and nothing else. Selecting
 * the whole number also means a component re-renders once per Aether gained, not once per tick.
 */
export const selectAetherDisplay = (s: GameStore): number => Math.floor(s.game.aether)

/** Ids of the resources the player holds any of, in the data's order (then anything the data no longer lists). */
export function selectHeldResourceIds(s: GameStore): readonly string[] {
  const held = s.game.resources
  const known = content.resources.filter((r) => (held[r.id] ?? 0) > 0).map((r) => r.id)
  const orphans = Object.keys(held).filter((id) => !content.resourceById.has(id) && held[id]! > 0).sort()
  return stable('held-resources', [...known, ...orphans])
}

export const selectResourceQty = (s: GameStore, resourceId: string): number => s.game.resources[resourceId] ?? 0

// ---------- load notice ----------

/** The quarantine notice while the banner should show: null when there was none, or the player dismissed it. */
export function selectQuarantineNotice(s: GameStore): LoadNotice | null {
  const notice = s.loadReport.notice
  return notice?.kind === 'quarantined' && !s.noticeDismissed ? notice : null
}

// ---------- skills ----------

export const selectSkillLevel = (s: GameStore, skillId: string): number => s.game.skills[skillId]?.level ?? 1

/** XP earned inside the current level, floored for display. */
export function selectSkillXpInLevel(s: GameStore, skillId: string): number {
  const sk = s.game.skills[skillId]
  const info = skillInfos.get(skillId)
  if (!sk || !info) return 0
  return Math.max(0, Math.floor(sk.xp - xpForLevel(content.tuning.xp.skillCurve, sk.level, info.maxLevel)))
}

/** XP the current level takes to finish; null at the maximum level. */
export function selectSkillXpToNext(s: GameStore, skillId: string): number | null {
  const sk = s.game.skills[skillId]
  const info = skillInfos.get(skillId)
  if (!sk || !info || sk.level >= info.maxLevel) return null
  return xpToNext(content.tuning.xp.skillCurve, sk.level)
}

/** How many slots the skill has unlocked at its current level. */
export const selectSlotCount = (s: GameStore, skillId: string): number => s.game.skills[skillId]?.slots.length ?? 0

/** The level the next slot unlocks at; null once every slot is open. */
export function selectNextSlotLevel(s: GameStore, skillId: string): number | null {
  const skill = content.skillById.get(skillId)
  const level = s.game.skills[skillId]?.level ?? 1
  return skill?.slotUnlockLevels.find((l) => l > level) ?? null
}

/** Whether the skill's level is high enough to gather this resource. This is what greys a tier out. */
export function selectResourceUnlocked(s: GameStore, skillId: string, resourceId: string): boolean {
  const need = resourceInfos.get(resourceId)?.requiredLevel
  return need != null && need <= selectSkillLevel(s, skillId)
}

/** What an empty slot starts on: the lowest-level resource the skill can gather now. */
export function selectDefaultResourceId(s: GameStore, skillId: string): string | null {
  const ids = gatherableResourceIds(skillId)
  return ids.find((id) => selectResourceUnlocked(s, skillId, id)) ?? ids[0] ?? null
}

// ---------- slots ----------

export const selectSlotCreatureId = (s: GameStore, skillId: string, slotIndex: number): string | null =>
  s.game.skills[skillId]?.slots[slotIndex]?.creatureId ?? null

export const selectSlotResourceId = (s: GameStore, skillId: string, slotIndex: number): string | null =>
  s.game.skills[skillId]?.slots[slotIndex]?.resourceId ?? null

/**
 * The resource a creature put in this slot from the roster gathers: what the slot is already on, else the lowest
 * tier the skill has unlocked. The Skills screen's picker uses the same two rules (plus its own pending choice).
 */
export const selectSlotAssignResourceId = (s: GameStore, skillId: string, slotIndex: number): string | null =>
  selectSlotResourceId(s, skillId, slotIndex) ?? selectDefaultResourceId(s, skillId)

/** The sim's verdict on a slot, or null when it is empty or idle. Shared with the tick, so they cannot disagree. */
function running(s: GameStore, skillId: string, slotIndex: number) {
  const skill = content.skillById.get(skillId)
  const skillState = s.game.skills[skillId]
  if (!skill || !skillState?.slots[slotIndex]) return null
  const creatureById = new Map(s.game.creatures.map((cr) => [cr.id, cr]))
  return runningSlot(skill, skillState, slotIndex, creatureById, activeEntries(s.game), content)
}

/** How long one action takes in this slot, in ms; null when nothing is working there. */
export const selectSlotCooldownMs = (s: GameStore, skillId: string, slotIndex: number): number | null => running(s, skillId, slotIndex)?.cooldownMs ?? null

/** Fraction of the current action done, 0 to 1. Always 0 for an empty or idle slot. */
export function selectSlotProgress(s: GameStore, skillId: string, slotIndex: number): number {
  const r = running(s, skillId, slotIndex)
  return r ? Math.min(1, Math.max(0, r.slot.progressMs / r.cooldownMs)) : 0
}

// ---------- creatures ----------

export interface TraitView {
  id: string
  name: string
  text: string
  strength: Strength
}

/**
 * Everything a roster card and its details need about one creature. Built once per creature object (see below), so
 * it is an identity-stable value that only changes when the creature does. `RosterItem` (roster.ts) is the part the
 * filter and sort read.
 */
export interface CreatureView {
  id: string
  /** The number in `creature-<n>`: the roster's sort tiebreak. */
  seq: number
  /** The name of its current form (Sproutlet, later Timberhorn). */
  name: string
  /** The species or hybrid it belongs to, whatever form it is in. */
  speciesName: string
  isHybrid: boolean
  emoji: string
  /** The color of its first type. */
  color: string
  /** One type, or two for a hybrid. */
  types: readonly TypeChip[]
  rarity: RarityInfo
  /** Form number, 1 to 3. The form's name is `name`. */
  form: number
  level: number
  shiny: boolean
  statLean: StatLean
  /** Names, not ids: these are for display. */
  primarySkill: string
  secondaryAptitude: string
  signatureTrait: TraitView | null
  poolTraits: readonly TraitView[]
  /** Every skill the sim lets it work (its `canWork`), which is what the roster's "can work" filter reads. */
  workableSkillIds: readonly string[]
  /** Those of them that currently have something to gather: where the roster can offer to assign it. */
  assignableSkillIds: readonly string[]
  working: boolean
  /** "Woodcutting, slot 1" while it works, null while it is benched. */
  workingAt: string | null
}

const creatureSeq = (id: string): number => {
  const n = Number(id.match(/(\d+)$/)?.[1])
  return Number.isFinite(n) ? n : Number.MAX_SAFE_INTEGER
}

function traitView(traitId: string, strength: Strength | null): TraitView {
  const trait = content.traitById.get(traitId)
  return {
    id: traitId,
    name: trait?.name ?? traitId,
    text: trait?.text ?? '',
    strength: strength ?? (trait?.kind === 'signature' ? trait.defaultStrength : 'minor'),
  }
}

function buildCreatureView(creature: Creature): CreatureView {
  const def = creatureDef(creature)
  const form = def?.forms[creature.form - 1]
  const workable = content.skills.filter((sk) => canWork(creature, sk.id)).map((sk) => sk.id)
  return {
    id: creature.id,
    seq: creatureSeq(creature.id),
    name: form?.name ?? creature.speciesId,
    speciesName: def?.name ?? creature.speciesId,
    isHybrid: creature.isHybrid,
    emoji: form?.emoji ?? '❔',
    color: typeColor(def?.types[0]),
    types: (def?.types ?? []).map(typeChip),
    rarity: rarityInfo(creature.rarityTier),
    form: creature.form,
    level: creature.level,
    shiny: creature.shiny,
    statLean: def?.statLean ?? 'health',
    primarySkill: def ? skillInfo(def.primarySkill).name : '',
    secondaryAptitude: def ? skillInfo(def.secondaryAptitude).name : '',
    signatureTrait: def ? traitView(def.signatureTrait, null) : null,
    poolTraits: creature.poolTraits.map((t) => traitView(t.traitId, t.strength)),
    workableSkillIds: workable,
    assignableSkillIds: workable.filter((id) => gatherableBySkill.get(id)!.length > 0),
    working: creature.assignment !== null,
    workingAt: creature.assignment ? `${skillInfo(creature.assignment.skillId).name}, slot ${creature.assignment.slotIndex + 1}` : null,
  }
}

// A creature object is replaced only when something about it changes, so caching per object keeps the view
// stable across the 10 ticks a second that never touch it.
const creatureViews = new WeakMap<Creature, CreatureView>()

function viewOf(creature: Creature): CreatureView {
  let view = creatureViews.get(creature)
  if (!view) {
    view = buildCreatureView(creature)
    creatureViews.set(creature, view)
  }
  return view
}

export function selectCreatureView(s: GameStore, creatureId: string): CreatureView | null {
  const creature = s.game.creatures.find((cr) => cr.id === creatureId)
  return creature ? viewOf(creature) : null
}

// The tick never replaces `game.creatures` (only an assignment, or later a hatch or capture, does), so the list is
// cached on the array itself: a tick costs one WeakMap lookup however big the roster is. When the array is new, the
// previous list is reused if every view in it is the same object, so a change that leaves nobody's view different
// still gives React nothing to re-render.
const viewLists = new WeakMap<readonly Creature[], readonly CreatureView[]>()
let lastViewList: readonly CreatureView[] = []

/** Every creature's view, in the order the game holds them. Stable by identity while no creature changes. */
export function selectCreatureViews(s: GameStore): readonly CreatureView[] {
  const creatures = s.game.creatures
  const cached = viewLists.get(creatures)
  if (cached) return cached
  const next = creatures.map(viewOf)
  const list = lastViewList.length === next.length && lastViewList.every((v, i) => v === next[i]) ? lastViewList : next
  viewLists.set(creatures, list)
  lastViewList = list
  return list
}

/** Creatures that can be put in this slot: everyone who can work the skill and is not already in it. */
export function selectAssignableCreatureIds(s: GameStore, skillId: string, slotIndex: number): readonly string[] {
  const ids = s.game.creatures
    .filter((cr) => canWork(cr, skillId) && !(cr.assignment?.skillId === skillId && cr.assignment.slotIndex === slotIndex))
    .map((cr) => cr.id)
  return stable(`assignable:${skillId}:${slotIndex}`, ids)
}
