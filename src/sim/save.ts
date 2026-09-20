// Save format, validation and migrations (plan.md section 5). Pure: it turns a GameState into text and text
// back into a GameState. Touching localStorage, and the broken-save quarantine copy, is state/persistence.ts.
//
// The save holds IDs and player progress only, never copies of content. So on load `reconcile` re-derives
// what is derived from content (skill levels from XP, slot counts, skills added since), and a rebalance of
// a JSON file updates existing saves automatically.
import { z } from 'zod'
import { content, STRENGTHS, type Content } from '../data'
import type { GameState, SaveFile } from '../types/state'
import { levelForXp } from './formulas'
import { slotCount } from './skills'

/**
 * `MIGRATIONS[n]` upgrades a version-n state to version n + 1 and must return the new state. `parseSave` walks
 * the chain from the file's version up to `tuning.save.version`, stamping the version after each step, so a
 * migration only changes the shape. Empty until the first schema change.
 */
export type Migration = (state: any) => any
export const MIGRATIONS: Record<number, Migration> = {}

// ---------- schema ----------

const Finite = z.number()
const Count = z.number().min(0)
const Id = z.string().min(1)

const CreatureSchema = z.strictObject({
  id: Id,
  speciesId: Id,
  isHybrid: z.boolean(),
  rarityTier: z.number().int().min(1),
  level: z.number().int().min(1),
  xp: Count,
  form: z.union([z.literal(1), z.literal(2), z.literal(3)]),
  shiny: z.boolean(),
  poolTraits: z.array(z.strictObject({ traitId: Id, strength: z.enum(STRENGTHS), locked: z.boolean() })),
  assignment: z.strictObject({ skillId: Id, slotIndex: z.number().int().min(0) }).nullable(),
})

const SlotSchema = z.strictObject({ creatureId: Id, resourceId: Id, progressMs: Count })

const GameStateSchema = z.strictObject({
  version: z.number().int().min(1),
  lastSeen: Finite,
  rngState: z.number().int().min(0).max(0xffffffff),
  aether: Count,
  gold: Count,
  resources: z.record(Id, Count),
  creatures: z.array(CreatureSchema),
  nextCreatureSeq: z.number().int().min(1),
  skills: z.record(Id, z.strictObject({ level: z.number().int().min(1), xp: Count, slots: z.array(SlotSchema.nullable()) })),
  collection: z.strictObject({
    speciesSeen: z.array(Id),
    rarityTiersSeen: z.record(Id, z.array(z.number().int())),
    recipesFound: z.array(Id),
    shiniesFound: z.array(Id),
    formsUnlocked: z.record(Id, z.number().int()),
  }),
  settings: z.strictObject({ offlineSummary: z.boolean(), devPanelEnabled: z.boolean() }),
})

// ---------- serialize ----------

/** The text written to localStorage: `{ version, state }`. Doubles round-trip exactly through JSON. */
export function serializeSave(state: GameState): string {
  const file: SaveFile = { version: state.version, state }
  return JSON.stringify(file)
}

// ---------- integrity ----------

/**
 * Cross-checks a schema-valid state against content and against itself: every ID resolves, and a creature's
 * `assignment` and the slot it points at agree (they are two views of one fact). Returns every problem.
 * Deliberately not flagged, so a rebalance cannot brick a save: a slot whose resource no longer exists (the sim
 * just idles it), and a creature's form or level lagging a changed threshold.
 */
export function integrityProblems(state: GameState, c: Content = content): string[] {
  const problems: string[] = []
  const ids = new Set<string>()
  for (const cr of state.creatures) {
    if (ids.has(cr.id)) problems.push(`duplicate creature id "${cr.id}"`)
    ids.add(cr.id)
    if (!c.creatureById.has(cr.speciesId)) problems.push(`creature ${cr.id}: unknown species "${cr.speciesId}"`)
    if (cr.rarityTier > c.rarities.length) problems.push(`creature ${cr.id}: rarity tier ${cr.rarityTier} does not exist`)
    if (cr.level > c.tuning.creature.maxLevel) problems.push(`creature ${cr.id}: level ${cr.level} is above the max`)
    for (const t of cr.poolTraits) if (c.traitById.get(t.traitId)?.kind !== 'pool') problems.push(`creature ${cr.id}: "${t.traitId}" is not a pool trait`)
    if (cr.assignment) {
      const slot = state.skills[cr.assignment.skillId]?.slots[cr.assignment.slotIndex]
      if (slot?.creatureId !== cr.id) problems.push(`creature ${cr.id} says it works ${cr.assignment.skillId}[${cr.assignment.slotIndex}], which holds ${slot?.creatureId ?? 'nobody'}`)
    }
  }
  for (const [skillId, sk] of Object.entries(state.skills)) {
    const skill = c.skillById.get(skillId)
    if (!skill) {
      problems.push(`unknown skill "${skillId}"`)
      continue
    }
    if (sk.level > skill.maxLevel) problems.push(`${skillId}: level ${sk.level} is above the max`)
    sk.slots.forEach((slot, i) => {
      if (!slot) return
      const cr = state.creatures.find((x) => x.id === slot.creatureId)
      if (!cr) problems.push(`${skillId}[${i}] holds unknown creature "${slot.creatureId}"`)
      else if (cr.assignment?.skillId !== skillId || cr.assignment.slotIndex !== i) problems.push(`${skillId}[${i}] holds ${cr.id}, which is assigned elsewhere`)
    })
  }
  return problems
}

// ---------- reconcile with content ----------

/**
 * Brings a loaded state in line with today's content: skills added since the save get a fresh entry; each
 * skill's cached level is re-derived from its XP (the XP curve may have been retuned); slots grow to the
 * count that level unlocks. Never removes a slot or a creature.
 *
 * Slots are grandfathered on purpose. A retune can lower the level a save's XP is worth, or raise the levels
 * the slots unlock at (step 1.8t did both), leaving a save holding more slots than its level now earns. Those
 * slots and the creatures in them stay exactly as they are: the player keeps working, and nothing they had is
 * taken away for a balance change they did not make. The alternative, benching the creature and dropping the
 * slot, costs a player production for someone else's decision, so it is not done. `selectNextSlotLevel` counts
 * from the slots that exist so the UI never offers a slot such a save already has. A slot whose resource tier
 * the new level no longer unlocks simply idles (`runningSlot`), it is not emptied.
 */
export function reconcile(state: GameState, c: Content = content): GameState {
  const skills: GameState['skills'] = { ...state.skills }
  for (const skill of c.skills) {
    const existing = skills[skill.id]
    const level = existing ? levelForXp(c.tuning.xp.skillCurve, existing.xp, skill.maxLevel) : 1
    const slots = existing ? existing.slots.slice() : []
    while (slots.length < slotCount(skill, level)) slots.push(null)
    skills[skill.id] = { level, xp: existing?.xp ?? 0, slots }
  }
  return { ...state, skills }
}

// ---------- parse ----------

export type LoadFailure = 'corrupt' | 'invalid' | 'too-new' | 'migration-failed'

export type LoadResult =
  | { ok: true; state: GameState; /** The version the file was written at, when it had to be migrated. */ migratedFrom: number | null }
  | { ok: false; reason: LoadFailure; message: string }

export interface ParseOptions {
  /** Defaults to `tuning.save.version`. Overridable so tests can exercise a migration chain. */
  targetVersion?: number
  migrations?: Record<number, Migration>
}

const fail = (reason: LoadFailure, message: string): LoadResult => ({ ok: false, reason, message })

function describeIssues(error: z.ZodError): string {
  const shown = error.issues.slice(0, 5).map((i) => `${i.path.join('.') || '(root)'}: ${i.message}`)
  return shown.join('; ') + (error.issues.length > 5 ? `; and ${error.issues.length - 5} more` : '')
}

/**
 * Text -> state, or a reason it cannot be. A failure is never a silent discard: the caller quarantines the
 * raw text and tells the player (persistence.ts).
 */
export function parseSave(text: string, c: Content = content, opts: ParseOptions = {}): LoadResult {
  const target = opts.targetVersion ?? c.tuning.save.version
  const migrations = opts.migrations ?? MIGRATIONS

  let file: unknown
  try {
    file = JSON.parse(text)
  } catch {
    return fail('corrupt', 'the save is not valid JSON')
  }
  if (typeof file !== 'object' || file === null || !('version' in file) || !('state' in file)) return fail('corrupt', 'the save has no version or state')
  const fileVersion = (file as { version: unknown }).version
  if (typeof fileVersion !== 'number' || !Number.isInteger(fileVersion) || fileVersion < 1) return fail('corrupt', `the save has a bad version (${String(fileVersion)})`)
  if (fileVersion > target) return fail('too-new', `the save is version ${fileVersion} but this build only understands up to ${target}`)

  let state: unknown = (file as { state: unknown }).state
  for (let v = fileVersion; v < target; v++) {
    const migrate = migrations[v]
    if (!migrate) return fail('migration-failed', `no migration from version ${v} to ${v + 1}`)
    try {
      state = migrate(state)
    } catch (e) {
      return fail('migration-failed', `migrating version ${v} to ${v + 1} threw: ${e instanceof Error ? e.message : String(e)}`)
    }
    if (typeof state === 'object' && state !== null) state = { ...state, version: v + 1 }
  }

  const parsed = GameStateSchema.safeParse(state)
  if (!parsed.success) return fail('invalid', describeIssues(parsed.error))
  if (parsed.data.version !== target) return fail('invalid', `state.version is ${parsed.data.version} but the file is version ${target}`)
  const problems = integrityProblems(parsed.data, c)
  if (problems.length > 0) return fail('invalid', problems.slice(0, 5).join('; ') + (problems.length > 5 ? `; and ${problems.length - 5} more` : ''))

  return { ok: true, state: reconcile(parsed.data, c), migratedFrom: fileVersion < target ? fileVersion : null }
}
