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

/**
 * How much GAME TIME this save has been advanced by, split by where it came from, in milliseconds. It is not
 * wall-clock time: it only grows when the sim is stepped, so a closed tab adds nothing until the catch-up runs.
 * Written in exactly one place (`creditPlayTime` in sim/tick.ts), from the dt each path actually granted.
 */
export interface PlayStats {
  /** Ordinary ticks while the game is open, after the driver's clamping. */
  onlineMs: number
  /** Windows GRANTED by `applyOffline` for a closed-tab load or a long open-tab gap: the capped window, never the requested one. */
  awayMs: number
  /** Windows granted by the dev panel's fast-forward, kept apart so a testing shortcut never looks like real play time. */
  devMs: number
}

/** The counter a step's dt belongs to, or 'none' for a dt that is nobody's play time. */
export type PlayTimeCredit = keyof PlayStats | 'none'

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
  /** Play time so far, by source. Added in save version 2; migration 1 -> 2 starts an older save at zeros (history cannot be backfilled). */
  stats: PlayStats
}

/** What is written to localStorage. */
export interface SaveFile {
  version: number
  state: GameState
}
