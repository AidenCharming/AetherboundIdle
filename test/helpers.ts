// Shared fixtures for the sim tests. Nothing here is production code.
import { content, loadContent, rawContent, type Content, type Strength } from '../src/data'
import { canWork, makeCreature } from '../src/sim/creature'
import { formForLevel, xpForLevel } from '../src/sim/formulas'
import { addSkillXp, assignCreature } from '../src/sim/skills'
import { createInitialState } from '../src/sim/state'
import type { Env } from '../src/state/driver'
import type { StorageLike } from '../src/state/persistence'
import type { Creature, GameState, PoolTraitRoll } from '../src/types/state'

/** Loads a copy of the content with `mutate` applied to its raw JSON, e.g. to move a tuning knob. */
export function variant(mutate: (raw: any) => void): Content {
  const raw = structuredClone(rawContent) as Record<string, any>
  mutate(raw)
  return loadContent(raw)
}

/**
 * Real content with every random source switched off: Sproutlet's Overgrowth is worth 0 and no resource drops
 * anything rare. Lets a test assert exact action, output and XP counts instead of statistics.
 */
export function quietContent(): Content {
  return variant((raw) => {
    for (const r of raw.resources) if (r.rareDrop) r.rareDrop.chance = 0
    raw.traits.find((t: any) => t.id === 'overgrowth').effects[0].valueByStrength = { moderate: 0 }
  })
}

export const NOW = 1_700_000_000_000
export const HOUR = 3_600_000

export const newGame = (c: Content = content, seed = 12345, now = NOW): GameState => createInitialState(seed, now, c)

export const pool = (traitId: string, strength: Strength = 'moderate'): PoolTraitRoll => ({ traitId, strength, locked: false })

export function addCreature(state: GameState, speciesId: string, overrides: Partial<Creature> = {}, c: Content = content): { state: GameState; creature: Creature } {
  const creature = makeCreature(`creature-${state.nextCreatureSeq}`, speciesId, overrides, c)
  return { state: { ...state, creatures: [...state.creatures, creature], nextCreatureSeq: state.nextCreatureSeq + 1 }, creature }
}

/** Sets a skill's level (and its xp and slot count) directly. */
export function setSkillLevel(state: GameState, skillId: string, level: number, c: Content = content): GameState {
  const skill = c.skillById.get(skillId)!
  const xp = xpForLevel(c.tuning.xp.skillCurve, level, skill.maxLevel)
  const next = addSkillXp({ level: 1, xp: 0, slots: [null] }, skill, xp, c).state
  return { ...state, skills: { ...state.skills, [skillId]: { ...next, slots: next.slots.map((s, i) => state.skills[skillId]!.slots[i] ?? s) } } }
}

export function work(state: GameState, creatureId: string, skillId = 'woodcutting', slotIndex = 0, resourceId = 'oak-log', c: Content = content): GameState {
  const result = assignCreature(state, creatureId, skillId, slotIndex, resourceId, c)
  if (!result.ok) throw new Error(`test setup: ${result.reason}`)
  return result.state
}

/** The starter Sproutlet, already gathering oak logs. */
export function sproutletAtWork(c: Content = content, seed = 12345): GameState {
  const state = newGame(c, seed)
  return work(state, 'creature-1', 'woodcutting', 0, 'oak-log', c)
}

/** creature.assignment and the skill slots are two views of one fact; they must never disagree. */
export function assignmentProblems(state: GameState): string[] {
  const problems: string[] = []
  for (const cr of state.creatures) {
    if (!cr.assignment) continue
    const slot = state.skills[cr.assignment.skillId]?.slots[cr.assignment.slotIndex]
    if (slot?.creatureId !== cr.id) problems.push(`${cr.id} says it works ${JSON.stringify(cr.assignment)} but that slot holds ${slot?.creatureId ?? 'nobody'}`)
  }
  for (const [skillId, sk] of Object.entries(state.skills)) {
    sk.slots.forEach((slot, i) => {
      if (!slot) return
      const cr = state.creatures.find((c) => c.id === slot.creatureId)
      if (cr?.assignment?.skillId !== skillId || cr.assignment.slotIndex !== i) problems.push(`${skillId}[${i}] holds ${slot.creatureId} but it is assigned elsewhere`)
    })
  }
  return problems
}

/** localStorage stand-in for node. `failWrites` / `failReads` simulate a full, blocked or absent store. */
export class MemoryStorage implements StorageLike {
  data = new Map<string, string>()
  failWrites = false
  failReads = false
  /** Successful writes so far, to tell one flush from two. */
  writes = 0
  getItem(key: string): string | null {
    if (this.failReads) throw new Error('storage read blocked')
    return this.data.get(key) ?? null
  }
  setItem(key: string, value: string): void {
    if (this.failWrites) throw new Error('quota exceeded')
    this.data.set(key, value)
    this.writes++
  }
  removeItem(key: string): void {
    this.data.delete(key)
  }
}

/**
 * Everything the tick driver takes from the browser, under the test's control: a clock that only moves when the
 * test moves it, timers that only fire when the test fires them, and window / document event targets.
 */
export class FakeEnv implements Env {
  storage = new MemoryStorage()
  clock = NOW
  seedDraws = 0
  seed = 424242
  /** How many times the page was asked to reload (the dev panel's reset save). */
  reloads = 0
  visibility = 'visible'
  win = new EventTarget()
  doc: EventTarget & { readonly visibilityState: string }
  /** Live intervals by handle. */
  intervals = new Map<number, { fn: () => void; ms: number }>()
  private nextHandle = 1

  constructor() {
    // A live getter, so flipping `visibility` is seen by the driver's listener. (Object.assign would copy the value.)
    const doc = new EventTarget()
    Object.defineProperty(doc, 'visibilityState', { get: () => this.visibility })
    this.doc = doc as EventTarget & { readonly visibilityState: string }
  }

  now = (): number => this.clock
  reload = (): void => {
    this.reloads++
  }
  randomSeed = (): number => {
    this.seedDraws++
    return this.seed
  }
  setInterval(fn: () => void, ms: number): number {
    const handle = this.nextHandle++
    this.intervals.set(handle, { fn, ms })
    return handle
  }
  clearInterval(handle: unknown): void {
    this.intervals.delete(handle as number)
  }
  /** Fires every live interval registered with this period. */
  fire(ms: number): void {
    for (const t of [...this.intervals.values()]) if (t.ms === ms) t.fn()
  }
  /** Periods of the live intervals, sorted. */
  get periods(): number[] {
    return [...this.intervals.values()].map((t) => t.ms).sort((a, b) => a - b)
  }
}


/**
 * A roster of `count` creatures (plus the starter Sproutlet) built only from the real data, and deterministic: the
 * same call always gives the same game. Every species and hybrid appears, cycling through all rarity tiers, levels
 * 1 to 99 (with the form the level earns), some shinies, 0 to 3 real pool traits at all three strengths, and, once
 * Woodcutting is opened to all its slots, everyone who can cut wood fills a slot until they run out.
 */
export function rosterGame(count = 120, c: Content = content): GameState {
  const defs = [...c.creatureById.values()]
  const poolTraits = c.traits.filter((t) => t.kind === 'pool')
  const strengths: Strength[] = ['minor', 'moderate', 'major']
  let state = setSkillLevel(newGame(c), 'woodcutting', c.skillById.get('woodcutting')!.maxLevel, c)
  for (let i = 0; i < count; i++) {
    const def = defs[i % defs.length]!
    const level = 1 + ((i * 37) % 99)
    const traits = Array.from({ length: i % 4 }, (_, j) => pool(poolTraits[(i * 7 + j * 5) % poolTraits.length]!.id, strengths[(i + j) % 3]))
    state = addCreature(
      state,
      def.id,
      { level, form: formForLevel(level, c.tuning), rarityTier: 1 + ((i * 5) % c.rarities.length), shiny: i % 9 === 0, poolTraits: traits },
      c,
    ).state
  }
  const slots = state.skills.woodcutting!.slots.length
  let filled = 0
  for (const cr of state.creatures) {
    if (filled >= slots) break
    if (canWork(cr, 'woodcutting', c)) state = work(state, cr.id, 'woodcutting', filled++, 'oak-log', c)
  }
  return state
}
