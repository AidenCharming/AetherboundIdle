// Skills: slot unlocks, assigning creatures to slots, and action resolution. `advanceSkills` is THE code path
// for both the online tick and offline catch-up: a 200 ms frame and a 12-hour window differ only in `dt`
// (plan.md 4.4, 4.5), so they cannot drift apart.
import { content, type Content, type Resource, type Skill } from '../data'
import type { Creature, GameState, LevelStamp, SkillState, SlotState } from '../types/state'
import { canWork, creatureCooldown } from './creature'
import type { SimEvent, SimResult } from './events'
import { completedActions, levelForXp, sanitizeDt, xpForLevel } from './formulas'
import { cappedModifier, type ActiveEntry } from './modifiers'
import { createRng } from './rng'

// ---------- slots and levels ----------

/** Number of unlocked work slots: the `slotUnlockLevels` entries at or below the level. */
export function slotCount(skill: Skill, level: number): number {
  return skill.slotUnlockLevels.filter((l) => l <= level).length
}

export function skillLevelFor(skill: Skill, xp: number, c: Content = content): number {
  return levelForXp(c.tuning.xp.skillCurve, xp, skill.maxLevel)
}

// ---------- when a level was reached (step 1.9c) ----------

/**
 * The play-time counters at the two ends of the window being stepped, so a level crossed inside it can be placed in
 * time. Built by `step` (sim/tick.ts), which is the only place that knows both the window and where its time is
 * counted; nothing here reads a clock.
 *
 * ACCURACY. A level reached during an ordinary tick is stamped at that tick, so it is accurate to one tick
 * (`tuning.ui.tickMs`, 100 ms). A level crossed inside ONE offline or fast-forward window (`interpolate`) is placed
 * by linear interpolation across the window by XP, which is approximate: the XP rate is assumed constant for the
 * whole window, and it is not when a slot unlocks part-way through (the levels after that unlock arrived sooner than
 * the straight line says). A twelve-hour window that crosses a slot unlock can therefore misplace a level by hours.
 * It is never wrong about the window a level fell in, only about where inside it.
 */
export interface StampWindow {
  startPlayedMs: number
  startDevMs: number
  endPlayedMs: number
  endDevMs: number
  /** An offline or fast-forward window: place levels by XP inside it. An online tick stamps at the end of the tick. */
  interpolate: boolean
}

/** Keeps an interpolated value inside its own window, whatever the float arithmetic does at the ends. */
const between = (start: number, end: number, t: number): number => Math.min(Math.max(start + t * (end - start), start), end)

function stampFor(w: StampWindow, level: number, skill: Skill, xpBefore: number, xpGained: number, c: Content): LevelStamp {
  if (!w.interpolate || !(xpGained > 0)) return [w.endPlayedMs, w.endDevMs]
  const threshold = xpForLevel(c.tuning.xp.skillCurve, level, skill.maxLevel)
  const t = Math.min(1, Math.max(0, (threshold - xpBefore) / xpGained))
  return [between(w.startPlayedMs, w.endPlayedMs, t), between(w.startDevMs, w.endDevMs, t)]
}

/**
 * The only place skill XP or level changes, so `level` can never disagree with `xp`. Emits one
 * `skill-level-up` per level crossed and a `slot-unlocked` at each slot threshold, in ascending order, and
 * grows `slots` to match (never shrinks it).
 *
 * `stamp` records when each level crossed here was reached. It is optional on purpose: the dev panel's "Set skill
 * level" (`raiseSkillToLevel`) passes nothing, so the levels it hands out stay ABSENT, because no time passed for
 * them. A level that already has a stamp keeps it: the first time a level is reached is the one that counts, so a
 * retune that re-levels a save cannot rewrite its history.
 */
export function addSkillXp(state: SkillState, skill: Skill, amount: number, c: Content = content, stamp?: StampWindow): SimResult<SkillState> {
  const gained = Math.max(0, amount)
  const xp = state.xp + gained
  const level = Math.max(state.level, skillLevelFor(skill, xp, c))
  const events: SimEvent[] = []
  let reached = state.reached
  for (let l = state.level + 1; l <= level; l++) {
    events.push({ type: 'skill-level-up', skillId: skill.id, level: l })
    skill.slotUnlockLevels.forEach((unlock, slotIndex) => {
      if (unlock === l) events.push({ type: 'slot-unlocked', skillId: skill.id, slotIndex })
    })
    if (stamp && reached[l] === undefined) {
      if (reached === state.reached) reached = { ...state.reached }
      reached[l] = stampFor(stamp, l, skill, state.xp, gained, c)
    }
  }
  const slots = state.slots.slice()
  while (slots.length < slotCount(skill, level)) slots.push(null)
  return { state: { level, xp, slots, reached }, events }
}

export type RaiseResult = { ok: true; state: GameState; events: SimEvent[] } | { ok: false; reason: string }

/**
 * The dev panel's "set skill level" (designer-approved, step 1.8b): raises a skill's XP to the cumulative XP its
 * `level` needs, through `addSkillXp`, so the cached level and the slot unlocks come out exactly as if the XP had
 * been earned. It only raises: a skill already at or past `level` is refused with a reason and nothing changes.
 * The XP lands exactly on that level's threshold, also when the current `xp` is fractional (bonus_xp makes it so):
 * for 0 <= xp < target, `xp + (target - xp)` rounds back to `target`, and the tests pin that on fractional totals.
 * Fast-forward is capped at 12 h a press, so without this the upper levels cannot be reached from the UI.
 */
export function raiseSkillToLevel(state: GameState, skillId: string, level: number, c: Content = content): RaiseResult {
  const skill = c.skillById.get(skillId)
  const skillState = state.skills[skillId]
  if (!skill || !skillState) return { ok: false, reason: `unknown skill "${skillId}"` }
  if (!Number.isInteger(level) || level < 1 || level > skill.maxLevel) return { ok: false, reason: `${skill.name} level must be a whole number from 1 to ${skill.maxLevel}` }
  const target = xpForLevel(c.tuning.xp.skillCurve, level, skill.maxLevel)
  if (skillState.xp >= target) return { ok: false, reason: `${skill.name} is already level ${skillState.level}; this only raises` }
  const raised = addSkillXp(skillState, skill, target - skillState.xp, c)
  return { ok: true, state: { ...state, skills: { ...state.skills, [skillId]: raised.state } }, events: raised.events }
}

/** Everyone currently in a work slot. Auras and `active-creatures` scopes read this. */
export function activeEntries(state: GameState): ActiveEntry[] {
  const byId = new Map(state.creatures.map((cr) => [cr.id, cr]))
  const out: ActiveEntry[] = []
  for (const [skillId, sk] of Object.entries(state.skills)) {
    for (const slot of sk.slots) {
      const creature = slot && byId.get(slot.creatureId)
      if (creature) out.push({ creature, skillId })
    }
  }
  return out
}

// ---------- assigning ----------

export type AssignResult = { ok: true; state: GameState } | { ok: false; reason: string }

function checkResource(state: GameState, skillId: string, resourceId: string, c: Content): string | null {
  const resource = c.resourceById.get(resourceId)
  if (!resource) return `unknown resource "${resourceId}"`
  if (resource.kind !== 'raw' || resource.skill !== skillId) return `${resource.name} cannot be gathered by ${skillId}`
  if (resource.requiredSkillLevel! > (state.skills[skillId]?.level ?? 0)) return `${resource.name} needs ${skillId} level ${resource.requiredSkillLevel}`
  return null
}

/**
 * Puts `creatureId` in a slot working `resourceId`. A creature already working elsewhere is moved, and
 * whoever held the slot is benched. Returns a reason instead of throwing so the UI can show it.
 */
export function assignCreature(
  state: GameState,
  creatureId: string,
  skillId: string,
  slotIndex: number,
  resourceId: string,
  c: Content = content,
): AssignResult {
  const creature = state.creatures.find((cr) => cr.id === creatureId)
  const skillState = state.skills[skillId]
  if (!creature) return { ok: false, reason: `unknown creature "${creatureId}"` }
  if (!skillState || !c.skillById.has(skillId)) return { ok: false, reason: `unknown skill "${skillId}"` }
  if (!canWork(creature, skillId, c)) return { ok: false, reason: `${creature.speciesId} cannot work ${skillId}` }
  if (!Number.isInteger(slotIndex) || slotIndex < 0 || slotIndex >= skillState.slots.length) return { ok: false, reason: `${skillId} slot ${slotIndex} is locked` }
  const bad = checkResource(state, skillId, resourceId, c)
  if (bad) return { ok: false, reason: bad }

  const existing = skillState.slots[slotIndex]
  const benched = new Set<string>()
  if (existing && existing.creatureId !== creatureId) benched.add(existing.creatureId)

  // Vacate the creature's previous slot (unless it is this one), then fill the target.
  const skills: Record<string, SkillState> = { ...state.skills }
  const prev = creature.assignment
  if (prev && !(prev.skillId === skillId && prev.slotIndex === slotIndex)) {
    const prevSkill = skills[prev.skillId]
    if (prevSkill) skills[prev.skillId] = { ...prevSkill, slots: prevSkill.slots.map((s, i) => (i === prev.slotIndex ? null : s)) }
  }
  const target = skills[skillId]!
  const slot: SlotState =
    existing?.creatureId === creatureId && existing.resourceId === resourceId ? existing : { creatureId, resourceId, progressMs: 0 }
  skills[skillId] = { ...target, slots: target.slots.map((s, i) => (i === slotIndex ? slot : s)) }

  const creatures = state.creatures.map((cr): Creature => {
    if (cr.id === creatureId) return { ...cr, assignment: { skillId, slotIndex } }
    return benched.has(cr.id) ? { ...cr, assignment: null } : cr
  })
  return { ok: true, state: { ...state, creatures, skills } }
}

/** Benches a creature, emptying its slot. A no-op if it is already benched. */
export function unassignCreature(state: GameState, creatureId: string): GameState {
  const creature = state.creatures.find((cr) => cr.id === creatureId)
  const prev = creature?.assignment
  if (!creature || !prev) return state
  const skill = state.skills[prev.skillId]
  const skills = skill
    ? { ...state.skills, [prev.skillId]: { ...skill, slots: skill.slots.map((s, i) => (i === prev.slotIndex ? null : s)) } }
    : state.skills
  return { ...state, skills, creatures: state.creatures.map((cr) => (cr.id === creatureId ? { ...cr, assignment: null } : cr)) }
}

/** Switches the resource an occupied slot gathers, keeping its creature. Progress on the old action is lost. */
export function setSlotResource(state: GameState, skillId: string, slotIndex: number, resourceId: string, c: Content = content): AssignResult {
  const slot = state.skills[skillId]?.slots[slotIndex]
  if (!slot) return { ok: false, reason: `${skillId} slot ${slotIndex} is empty` }
  return assignCreature(state, slot.creatureId, skillId, slotIndex, resourceId, c)
}

// ---------- action resolution ----------

/** A slot that is really working, with everything `advanceSkills` and the UI's progress bar both need. */
export interface RunningSlot {
  slot: SlotState
  creature: Creature
  resource: Resource
  cooldownMs: number
}

/**
 * The one place that decides whether a slot is working, so the tick and the progress bar cannot disagree. A slot
 * whose creature or resource no longer resolves (a rebalance removed it), or whose resource is above the skill's
 * level, idles instead of throwing: this returns null.
 */
export function runningSlot(
  skill: Skill,
  skillState: SkillState,
  slotIndex: number,
  creatureById: ReadonlyMap<string, Creature>,
  active: readonly ActiveEntry[],
  c: Content = content,
): RunningSlot | null {
  const slot = skillState.slots[slotIndex]
  const creature = slot && creatureById.get(slot.creatureId)
  const resource = slot && c.resourceById.get(slot.resourceId)
  if (!slot || !creature || !resource) return null
  if (resource.kind !== 'raw' || resource.skill !== skill.id) return null
  if (resource.baseActionMs === null || resource.requiredSkillLevel === null || resource.requiredSkillLevel > skillState.level) return null
  return { slot, creature, resource, cooldownMs: creatureCooldown(creature, skill.id, resource.baseActionMs, active, c).cooldownMs }
}

export interface AdvanceOptions {
  /** True on the offline path: adds `offline_extra_output_chance` to the extra-output roll. */
  offline?: boolean
  /** Where in play time this window sits, so a level crossed in it can be stamped. `step` builds it; absent means no stamping. */
  stamp?: StampWindow
}

/**
 * Advances every working slot by `dtMs`. Bulk, never a tick replay: per slot it adds `dt` to the action in
 * progress, divides by the cooldown to get the number of finished actions, then rolls outputs for all of them
 * at once (binomial draws, not one roll per action).
 *
 * Nothing about a running slot depends on the skill's level, and no skill consumes resources yet, so a window
 * that crosses a level-up needs no segmenting: XP is summed and the level derived once at the end, with an
 * event per level crossed. If a later phase makes cooldown or input depend on level, this is where plan 4.5's
 * per-level segmentation goes (see docs/PROGRESS.md).
 *
 * RNG order is fixed so results are reproducible: skills in skills.json order, slots ascending, and per slot
 * the extra-output draw before the rare-drop draw. The RNG state is written back to `rngState` on return.
 */
export function advanceSkills(state: GameState, dtMs: number, opts: AdvanceOptions = {}, c: Content = content): SimResult<GameState> {
  const dt = sanitizeDt(dtMs)
  if (dt === 0) return { state, events: [] }

  const rng = createRng(state.rngState)
  const active = activeEntries(state)
  const creatureById = new Map(state.creatures.map((cr) => [cr.id, cr]))
  const events: SimEvent[] = []
  const resources = { ...state.resources }
  const skills = { ...state.skills }

  for (const skill of c.skills) {
    const skillState = state.skills[skill.id]
    if (!skillState) continue
    const slots = skillState.slots.slice()
    const slotEvents: SimEvent[] = []
    let xpGained = 0

    skillState.slots.forEach((_, slotIndex) => {
      const running = runningSlot(skill, skillState, slotIndex, creatureById, active, c)
      if (!running) return
      const { slot, creature, resource, cooldownMs } = running

      const total = slot.progressMs + dt
      const n = completedActions(total, cooldownMs)
      slots[slotIndex] = { ...slot, progressMs: Math.max(0, total - n * cooldownMs) }
      if (n === 0) return

      const mod = (key: Parameters<typeof cappedModifier>[0]) => cappedModifier(key, creature, skill.id, active, c)
      const extraChance = Math.min(1, mod('extra_output_chance') + (opts.offline ? mod('offline_extra_output_chance') : 0))
      const extra = rng.binomial(n, extraChance)
      const outputs: Record<string, number> = { [resource.id]: n + extra }
      if (resource.rareDrop) {
        // Scales the drop's base chance (+10% on a 1% drop is 1.1%), rather than adding percentage points.
        const rareChance = Math.min(1, resource.rareDrop.chance * (1 + mod('rare_drop_chance')))
        const rare = rng.binomial(n, rareChance)
        if (rare > 0) outputs[resource.rareDrop.id] = (outputs[resource.rareDrop.id] ?? 0) + rare
      }
      // Hook: partner_element_drop_chance (hybrid signature), save_material_chance and treasure_drop_chance
      // are not consumed yet: no hybrids exist before phase 2 and no skill consumes materials before phase 3.

      const skillXp = n * (resource.xpPerAction ?? 0) * (1 + mod('bonus_xp'))
      xpGained += skillXp
      for (const [id, qty] of Object.entries(outputs)) resources[id] = (resources[id] ?? 0) + qty
      slotEvents.push({ type: 'action-complete', skillId: skill.id, slotIndex, creatureId: creature.id, resourceId: resource.id, count: n, outputs, skillXp })
    })

    const leveled = addSkillXp({ ...skillState, slots }, skill, xpGained, c, opts.stamp)
    skills[skill.id] = leveled.state
    events.push(...slotEvents, ...leveled.events)
  }

  return { state: { ...state, resources, skills, rngState: rng.state }, events }
}
