// The only way the UI reads the game (plan.md section 1): `src/ui` never imports `src/sim`. Anything the UI would
// otherwise work out for itself, such as a slot's cooldown, whether a tier is locked, how many slots there are
// or a creature's display name, is a selector here, so the rules stay in one place.
//
// Zustand v5 re-renders forever on a selector that returns a fresh object or array on every call. So a selector
// here returns a primitive, a value that is stable by reference (content lookups, and creature views cached per
// creature), or a list that goes through `stable`, which hands back the previous array when nothing changed.
// Selectors taking arguments are used as `useGameStore((s) => selectSlotProgress(s, skillId, slotIndex))`.
import { content, STRENGTHS, type StatLean, type Strength } from '../data'
import { benchedCreatures, creatureEmissionPerMin, emissionPerMin } from '../sim/aether'
import { canWork, creatureDef } from '../sim/creature'
import { xpForLevel, xpToNext } from '../sim/formulas'
import type { OfflineSummary } from '../sim/offline'
import { activeEntries, runningSlot } from '../sim/skills'
import type { Creature, Settings } from '../types/state'
import { buildNav, type NavSection } from './nav'
import { unreadCount, type Notification } from './notifications'
import type { LoadNotice } from './persistence'
import type { GameStore } from './store'

// The roster's pure filter and sort live in roster.ts (node-testable, no React). The UI reads them from here so that
// selectors.ts stays its one door into the state layer.
export * from './roster'
// The navigation model (nav.ts) is pure too, and reaches the UI the same way.
export * from './nav'
export type { NotificationKind } from './notifications'
export type { Notification }
export { visibleToasts } from './notifications'
// The biggest save file an import will read, so the file picker can refuse a wrong pick before reading it.
export { MAX_IMPORT_BYTES } from './persistence'

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

/** How many running slots the sidebar's activity panel lists before it says "+N more" (tuning.ui.activityPanelMax). */
export const activityPanelMax: number = content.tuning.ui.activityPanelMax

/** How many toasts show at once, and how long one stays, in ms (tuning.ui.maxToasts, tuning.ui.toastMs). */
export const maxToasts: number = content.tuning.ui.maxToasts
export const toastMs: number = content.tuning.ui.toastMs

export interface SkillInfo {
  id: string
  name: string
  /** Null when the data gives the skill none. */
  emoji: string | null
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
  /** The action time before any creature speeds it up, in ms, and the XP one action gives. Null for anything that is only dropped. */
  baseActionMs: number | null
  xpPerAction: number | null
  /** The color of its element type. */
  color: string
}

const skillInfos = new Map<string, SkillInfo>(
  content.skills.map((s) => [
    s.id,
    { id: s.id, name: s.name, emoji: s.emoji ?? null, color: s.requiredType ? typeColor(s.requiredType) : null, maxLevel: s.maxLevel, totalSlots: s.slotUnlockLevels.length },
  ]),
)

const resourceInfos = new Map<string, ResourceInfo>(
  content.resources.map((r) => [
    r.id,
    { id: r.id, name: r.name, emoji: r.emoji ?? null, requiredLevel: r.requiredSkillLevel, baseActionMs: r.baseActionMs, xpPerAction: r.xpPerAction, color: typeColor(r.elementType) },
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

export const skillInfo = (skillId: string): SkillInfo => skillInfos.get(skillId) ?? { id: skillId, name: skillId, emoji: null, color: null, maxLevel: 1, totalSlots: 0 }

export const resourceInfo = (resourceId: string): ResourceInfo =>
  resourceInfos.get(resourceId) ?? { id: resourceId, name: resourceId, emoji: null, requiredLevel: null, baseActionMs: null, xpPerAction: null, color: NEUTRAL }

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

// ---------- dev panel choices (content lookups, so every value is stable) ----------

export type { Strength }

export interface CreatureOption {
  id: string
  /** The species or hybrid name (its Form 1 name). */
  name: string
  isHybrid: boolean
  /** Type names, one or two, so two creatures with similar names can be told apart. */
  typeNames: readonly string[]
}

/** Every species, then every hybrid, in the data's order: what the dev panel's grant offers. */
export const creatureOptions: readonly CreatureOption[] = [...content.species, ...content.hybrids].map((def) => ({
  id: def.id,
  name: def.name,
  isHybrid: def.origin === 'breed',
  typeNames: def.types.map((t) => typeChip(t).name),
}))

/** The highest creature level a grant may ask for (tuning.creature.maxLevel). */
export const creatureMaxLevel: number = content.tuning.creature.maxLevel

/** How many pool traits one creature can carry (tuning.creature.maxPoolTraits). */
export const maxPoolTraits: number = content.tuning.creature.maxPoolTraits

export interface PoolTraitOption {
  id: string
  name: string
  text: string
  /** The strengths it can be given: everything from its `minStrength` up (Void-only traits start at moderate). */
  allowedStrengths: readonly Strength[]
}

export const poolTraitOptions: readonly PoolTraitOption[] = content.traits
  .filter((t) => t.kind === 'pool')
  .map((t) => ({ id: t.id, name: t.name, text: t.text, allowedStrengths: STRENGTHS.slice(t.minStrength ? STRENGTHS.indexOf(t.minStrength) : 0) }))

export interface ResourceOption {
  id: string
  name: string
}

/** Every resource the data lists, in the data's order. */
export const resourceOptions: readonly ResourceOption[] = content.resources.map((r) => ({ id: r.id, name: r.name }))

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

// ---------- navigation ----------

// The nav depends on the content (fixed at runtime) and on one setting, so there are only two of them.
const navs = new Map<boolean, readonly NavSection[]>()

/** The sidebar's sections. Stable by identity: it changes only when the dev panel setting does. */
export function selectNav(s: GameStore): readonly NavSection[] {
  const devPanelEnabled = s.game.settings.devPanelEnabled
  let nav = navs.get(devPanelEnabled)
  if (!nav) {
    nav = buildNav({ devPanelEnabled })
    navs.set(devPanelEnabled, nav)
  }
  return nav
}

// ---------- current activity (the sidebar panel) ----------

/** A slot that is really working: a creature on a resource it can gather. */
export interface ActivitySlot {
  skillId: string
  slotIndex: number
}

// One object per slot, kept for good, so the list below can be identical by reference while nothing changes.
const activitySlots = new Map<string, ActivitySlot>()
let lastActivity: readonly ActivitySlot[] = []

/**
 * Every slot that is working right now, skills in the data's order and slots ascending. "Working" is the sim's own
 * `runningSlot` (the same check the tick and the progress bars use), so an idle slot, one whose resource is above the
 * skill's level, or one whose creature is gone is not listed. The tick changes progress but not this list, so it keeps
 * its identity from one tick to the next and the panel re-renders only when a slot starts or stops. Only the progress
 * bars read the tick.
 */
export function selectActivity(s: GameStore): readonly ActivitySlot[] {
  const next: ActivitySlot[] = []
  let creatureById: Map<string, Creature> | null = null
  let active: ReturnType<typeof activeEntries> | null = null
  for (const skill of content.skills) {
    const skillState = s.game.skills[skill.id]
    if (!skillState) continue
    skillState.slots.forEach((slot, slotIndex) => {
      if (!slot) return
      creatureById ??= new Map(s.game.creatures.map((cr) => [cr.id, cr]))
      active ??= activeEntries(s.game)
      if (!runningSlot(skill, skillState, slotIndex, creatureById, active, content)) return
      const key = `${skill.id}:${slotIndex}`
      let entry = activitySlots.get(key)
      if (!entry) activitySlots.set(key, (entry = { skillId: skill.id, slotIndex }))
      next.push(entry)
    })
  }
  if (next.length === lastActivity.length && next.every((e, i) => e === lastActivity[i])) return lastActivity
  return (lastActivity = next)
}

// ---------- notifications (the bell and the toasts) ----------

/** Oldest first. The same array until a notification is added, changed, read or cleared. */
export const selectNotifications = (s: GameStore): readonly Notification[] => s.notifications.items

export const selectUnreadCount = (s: GameStore): number => unreadCount(s.notifications.items)

/** The id the next notification will get: a toast host that mounts now shows only what comes after this. */
export const selectNextNotificationId = (s: GameStore): number => s.notifications.nextId

// ---------- load notice ----------

/** The quarantine notice while the banner should show: null when there was none, or the player dismissed it. */
export function selectQuarantineNotice(s: GameStore): LoadNotice | null {
  const notice = s.loadReport.notice
  return notice?.kind === 'quarantined' && !s.noticeDismissed ? notice : null
}

// ---------- settings ----------

/** The settings the player can flip. Exported so the UI names one without importing the state types. */
export type SettingKey = keyof Settings

export const selectSetting = (s: GameStore, key: SettingKey): boolean => s.game.settings[key]

/** Whether the Dev tab is offered at all. The panel ships in the production build behind this toggle (plan 7.1). */
export const selectDevPanelEnabled = (s: GameStore): boolean => s.game.settings.devPanelEnabled

// ---------- play time (Settings, step 1.9c) ----------

/**
 * Game time earned by ordinary ticks with the game open. Not wall-clock time: a tab sitting on a dialog still
 * ticks, and a tab that was closed adds nothing here (that time arrives as away time on the next load).
 */
export const selectOnlineMs = (s: GameStore): number => s.game.stats.onlineMs

/** Game time granted by offline catch-up: the capped window, so a night away adds the cap, not the whole night. */
export const selectAwayMs = (s: GameStore): number => s.game.stats.awayMs

/** Game time granted by the dev panel's fast-forward. Kept out of the total, because nobody played it. */
export const selectDevMs = (s: GameStore): number => s.game.stats.devMs

/** What the game has really been played for: online plus away. Fast-forward is deliberately not in it. */
export const selectPlayedMs = (s: GameStore): number => s.game.stats.onlineMs + s.game.stats.awayMs

// ---------- skill milestones (Settings, step 1.9c) ----------

/** One row of the "Skill milestones" table. */
export interface SkillMilestone {
  level: number
  /** Real play time when the level was reached, or null for a level that was never stamped (see `SkillState.reached`). */
  playedMs: number | null
  /** Dev fast-forward time that had been added by then. Above zero means the fast-forward did part of the work. */
  devMs: number
  /** This level opens a work slot. */
  slot: boolean
  /** This is the skill's last level. */
  max: boolean
}

/**
 * The levels the table reports, per skill: the slot unlock levels and the max level (both from the data, so they are
 * whatever a retune makes them), plus `tuning.ui.pacingMilestones`. Sorted, de-duplicated, nothing above the max.
 * Content only, so it is computed once per skill and is stable by reference for ever after.
 */
const milestoneLevels = new Map<string, readonly number[]>()
function levelsFor(skillId: string): readonly number[] {
  let levels = milestoneLevels.get(skillId)
  if (!levels) {
    const skill = content.skillById.get(skillId)
    levels = skill
      ? [...new Set([...skill.slotUnlockLevels, ...content.tuning.ui.pacingMilestones, skill.maxLevel])].filter((l) => l <= skill.maxLevel).sort((a, b) => a - b)
      : []
    milestoneLevels.set(skillId, levels)
  }
  return levels
}

// The rows only change when a milestone level is reached, but the skill state object is replaced on every tick, so
// they are compared by value and the previous array handed back when nothing moved (see "stable references" above).
const milestoneCache = new Map<string, readonly SkillMilestone[]>()
const sameRows = (a: readonly SkillMilestone[], b: readonly SkillMilestone[]): boolean =>
  a.length === b.length && a.every((row, i) => row.level === b[i]!.level && row.playedMs === b[i]!.playedMs && row.devMs === b[i]!.devMs)

/** The "Skill milestones" rows for one skill. Empty for a skill the data no longer has. */
export function selectSkillMilestones(s: GameStore, skillId: string): readonly SkillMilestone[] {
  const skill = content.skillById.get(skillId)
  const sk = s.game.skills[skillId]
  const rows = levelsFor(skillId).map((level): SkillMilestone => {
    const stamp = sk?.reached[level]
    return {
      level,
      playedMs: stamp ? stamp[0] : null,
      devMs: stamp ? stamp[1] : 0,
      slot: skill ? skill.slotUnlockLevels.includes(level) : false,
      max: skill ? level === skill.maxLevel : false,
    }
  })
  const prev = milestoneCache.get(skillId)
  if (prev && sameRows(prev, rows)) return prev
  milestoneCache.set(skillId, rows)
  return rows
}

/** The skills that have earned any XP, in the data's order. The milestone table shows one per entry. */
export function selectSkillIdsWithXp(s: GameStore): readonly string[] {
  return stable('skills-with-xp', content.skills.filter((skill) => (s.game.skills[skill.id]?.xp ?? 0) > 0).map((skill) => skill.id))
}

// ---------- welcome back ----------

export interface WelcomeBackResource {
  id: string
  name: string
  emoji: string | null
  color: string
  qty: number
}

export interface WelcomeBackSkill {
  id: string
  name: string
  /** The type color of the skill, or null for the open skills. */
  color: string | null
  actions: number
  xpGained: number
  levelBefore: number
  levelAfter: number
  /** Slot numbers as the player counts them (1-based), ascending. */
  slotsUnlocked: readonly number[]
}

/** Everything the welcome-back dialog shows. Built from the summary the sim produced; it does no maths of its own. */
export interface WelcomeBackView {
  /** How long the player was actually away. */
  awayMs: number
  /** How much of that earned anything: the same as `awayMs` unless the cap bit. */
  earnedMs: number
  /** The cap, so the dialog can name it without a number of its own. */
  capMs: number
  capped: boolean
  /** Floored for display; the stored float keeps its fraction. */
  aetherGained: number
  resources: readonly WelcomeBackResource[]
  skills: readonly WelcomeBackSkill[]
  /** Nothing happened while away (an empty bench and no slot working). */
  empty: boolean
}

// Cached on the summary object, which only changes when a new one is queued, so the dialog is not rebuilt every tick.
const welcomeBackViews = new WeakMap<OfflineSummary, WelcomeBackView>()

function buildWelcomeBackView(summary: OfflineSummary): WelcomeBackView {
  const resources = Object.entries(summary.resourcesGained)
    .filter(([, qty]) => qty > 0)
    .map(([id, qty]) => {
      const info = resourceInfo(id)
      return { id, name: info.name, emoji: info.emoji, color: info.color, qty }
    })
  // The data's order, so the dialog lists resources the way the top bar does, with anything unknown last.
  const order = new Map(content.resources.map((r, i) => [r.id, i]))
  resources.sort((a, b) => (order.get(a.id) ?? order.size) - (order.get(b.id) ?? order.size) || a.id.localeCompare(b.id))

  const skills = summary.skills
    .filter((sk) => sk.actions > 0 || sk.levelAfter > sk.levelBefore || sk.slotsUnlocked.length > 0)
    .map((sk) => {
      const info = skillInfo(sk.skillId)
      return {
        id: sk.skillId,
        name: info.name,
        color: info.color,
        actions: sk.actions,
        xpGained: sk.xpGained,
        levelBefore: sk.levelBefore,
        levelAfter: sk.levelAfter,
        slotsUnlocked: sk.slotsUnlocked.map((i) => i + 1).sort((a, b) => a - b),
      }
    })

  return {
    // A clock-skewed window reports a negative request; the dialog never shows negative time away.
    awayMs: Math.max(0, summary.requestedMs),
    earnedMs: summary.elapsedMs,
    capMs: summary.capMs,
    capped: summary.capped,
    aetherGained: Math.floor(summary.aetherGained),
    resources,
    skills,
    empty: resources.length === 0 && skills.length === 0 && summary.aetherGained < 1,
  }
}

/** The away summary waiting to be shown, ready for display; null when there is none. Stable while it is the same one. */
export function selectWelcomeBack(s: GameStore): WelcomeBackView | null {
  const summary = s.welcomeBack
  if (!summary) return null
  let view = welcomeBackViews.get(summary)
  if (!view) {
    view = buildWelcomeBackView(summary)
    welcomeBackViews.set(summary, view)
  }
  return view
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

/**
 * The level the NEXT slot the player does not have yet unlocks at; null once every slot is open. Counted from
 * the slots that exist, not from the level, because a save can hold more slots than its level currently earns:
 * `reconcile` grows the slot array but never shrinks it, so a retune that raised the unlock levels leaves the
 * slots already granted in place (see docs/PROGRESS.md, step 1.8t). Reading the level alone would offer a slot
 * such a save already has.
 */
export function selectNextSlotLevel(s: GameStore, skillId: string): number | null {
  const skill = content.skillById.get(skillId)
  const sk = s.game.skills[skillId]
  const level = sk?.level ?? 1
  const have = sk?.slots.length ?? 0
  return skill?.slotUnlockLevels.slice(have).find((l) => l > level) ?? null
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

// ---------- bench and Aether per minute ----------

/** One benched creature and what it emits, straight from the sim (`creatureEmissionPerMin`): rarity's rate plus its capped emission traits. */
export interface BenchEntry {
  view: CreatureView
  /** Aether per minute. Fractional once a trait scales it. */
  perMin: number
}

// Emission depends on the creature alone, so an entry is cached per creature object like its view is.
const benchEntries = new WeakMap<Creature, BenchEntry>()

function benchEntryOf(creature: Creature): BenchEntry {
  let entry = benchEntries.get(creature)
  if (!entry) {
    entry = { view: viewOf(creature), perMin: creatureEmissionPerMin(creature) }
    benchEntries.set(creature, entry)
  }
  return entry
}

// Who is benched changes only when `game.creatures` is replaced (an assignment, a grant, later a hatch), never on the
// tick, so both the list and the total are cached on the array itself, as `selectCreatureViews` does.
const benchLists = new WeakMap<readonly Creature[], readonly BenchEntry[]>()
const benchTotals = new WeakMap<readonly Creature[], number>()
let lastBenchList: readonly BenchEntry[] = []

/** Benched creatures, biggest emitter first (then the older creature first). Stable by identity while nobody moves on or off the bench. */
export function selectBenchEntries(s: GameStore): readonly BenchEntry[] {
  const creatures = s.game.creatures
  const cached = benchLists.get(creatures)
  if (cached) return cached
  const next = benchedCreatures(s.game)
    .map(benchEntryOf)
    .sort((a, b) => b.perMin - a.perMin || a.view.seq - b.view.seq)
  const list = lastBenchList.length === next.length && lastBenchList.every((e, i) => e === next[i]) ? lastBenchList : next
  benchLists.set(creatures, list)
  lastBenchList = list
  return list
}

/** The sim's own total (`emissionPerMin`): exactly what `accrueAether` adds, online and offline. */
export function selectAetherPerMinute(s: GameStore): number {
  const creatures = s.game.creatures
  let total = benchTotals.get(creatures)
  if (total === undefined) {
    total = emissionPerMin(s.game)
    benchTotals.set(creatures, total)
  }
  return total
}

const MINUTES_PER_HOUR = 60

export const selectAetherPerHour = (s: GameStore): number => selectAetherPerMinute(s) * MINUTES_PER_HOUR
