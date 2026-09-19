// Game state shapes (plan.md section 5). Player progress and IDs only, never copies of content, so
// rebalancing a JSON file updates existing saves automatically.
import type { Strength } from '../data/schema'

export interface PoolTraitRoll {
  traitId: string
  strength: Strength
  locked: boolean
}

/** Where a creature is working. `null` on the creature means it is benched. */
export interface Assignment {
  skillId: string
  slotIndex: number
}

export interface Creature {
  id: string
  speciesId: string
  isHybrid: boolean
  rarityTier: number
  level: number
  /** Cumulative creature XP; level is derived from it. Only combat awards it (design section 8), so nothing in phase 1 does. */
  xp: number
  form: 1 | 2 | 3
  shiny: boolean
  poolTraits: PoolTraitRoll[]
  assignment: Assignment | null
}

/** One occupied work slot. Progress is per slot because each slot's creature has its own cooldown. */
export interface SlotState {
  creatureId: string
  resourceId: string
  /** Time spent on the action in progress, in ms. Always below that creature's cooldown between steps. */
  progressMs: number
}

export interface SkillState {
  /** Cached from `xp`. Only `addSkillXp` may change either, so the two cannot disagree. */
  level: number
  /** Cumulative skill XP (not XP within the level). Fractional once bonus_xp applies. */
  xp: number
  /** Always exactly `slotCount(skill, level)` long; `null` is an empty slot. */
  slots: (SlotState | null)[]
}

export interface Collection {
  speciesSeen: string[]
  rarityTiersSeen: Record<string, number[]>
  recipesFound: string[]
  shiniesFound: string[]
  /** Highest form reached per species. */
  formsUnlocked: Record<string, number>
}

export interface Settings {
  offlineSummary: boolean
  devPanelEnabled: boolean
}

export interface GameState {
  version: number
  /** Epoch ms, written on autosave and unload. Offline progress is measured from it. */
  lastSeen: number
  /** The CURRENT mulberry32 state, advanced on every consume (plan 4.6). Never the initial seed. */
  rngState: number
  /** Float. Only the display rounds. */
  aether: number
  gold: number
  resources: Record<string, number>
  creatures: Creature[]
  /** Source for creature ids (`creature-<n>`), so ids never need Math.random. */
  nextCreatureSeq: number
  skills: Record<string, SkillState>
  collection: Collection
  settings: Settings
}

/** What is written to localStorage. */
export interface SaveFile {
  version: number
  state: GameState
}
