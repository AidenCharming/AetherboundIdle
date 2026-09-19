// localStorage plumbing around the pure save format in sim/save.ts (plan.md section 5). This is the one place
// the clock and the browser storage are touched, and both come in as arguments: `storage` is anything shaped
// like localStorage, and `now` is the caller's `Date.now()`. That keeps it testable in plain node.
import { content, type Content } from '../data'
import type { SimEvent } from '../sim/events'
import { applyOffline, type OfflineSummary } from '../sim/offline'
import { parseSave, serializeSave, type LoadFailure } from '../sim/save'
import { createInitialState } from '../sim/state'
import type { GameState } from '../types/state'

export const SAVE_KEY = 'aetherbound-idle:save'
export const brokenSaveKey = (now: number): string => `aetherbound-idle:save-broken-${now}`

/** The slice of localStorage this uses. */
export interface StorageLike {
  getItem(key: string): string | null
  setItem(key: string, value: string): void
}

// ---------- writing ----------

export interface FlushResult {
  /** The state as written: `lastSeen` stamped to `now`. Returned even when the write failed. */
  state: GameState
  saved: boolean
}

/**
 * Writes the save synchronously, stamping `lastSeen = now` (the moment offline time is measured from). Storage
 * can be full, blocked or absent (private windows), so a failed write is reported, not thrown.
 * Assumes the sim has been stepped up to `now`, which the tick driver guarantees while the game is running.
 */
export function flushSave(storage: StorageLike, state: GameState, now: number): FlushResult {
  const stamped = Number.isFinite(now) ? { ...state, lastSeen: now } : state
  try {
    storage.setItem(SAVE_KEY, serializeSave(stamped))
    return { state: stamped, saved: true }
  } catch {
    return { state: stamped, saved: false }
  }
}

/**
 * For outcome-committing rolls: breeding a pair, hatching an egg, a capture or bind attempt (plan 4.6). Runs
 * `roll`, then flushes the result AND the advanced RNG state in one write, so a crash or a deliberate reload
 * between the roll and the next autosave cannot rewind either. `state/actions.ts` routes those three actions
 * through this once the store exists. Idle progress stays on the 15 s autosave: low stakes, high write volume.
 */
export function commitRoll<R>(
  storage: StorageLike,
  state: GameState,
  roll: (state: GameState) => { state: GameState; result: R },
  now: number,
): { state: GameState; result: R; saved: boolean } {
  const rolled = roll(state)
  const flushed = flushSave(storage, rolled.state, now)
  return { state: flushed.state, result: rolled.result, saved: flushed.saved }
}

// ---------- loading ----------

/** Shown to the player. A save that cannot be loaded is never silently discarded. */
export type LoadNotice = { kind: 'quarantined'; reason: LoadFailure; message: string; brokenKey: string }

export interface LoadOutcome {
  /** The state to play from, already caught up to `now` and written back. */
  state: GameState
  events: SimEvent[]
  /** What happened while away. Null for a new game, where there was no away. */
  summary: OfflineSummary | null
  isNewGame: boolean
  migratedFrom: number | null
  notice: LoadNotice | null
}

/**
 * Loads the save and catches it up to `now` (offline progress is computed on load from `lastSeen`). With no
 * save it starts a new game from `freshSeed`. With a save that cannot be loaded it copies the raw text to
 * `aetherbound-idle:save-broken-<now>`, starts fresh, and reports a notice: nothing is lost, and a newer build
 * can still recover a save it was too old to read.
 *
 * `freshSeed` is only used to start a new game; the caller draws it (from crypto or Math.random), once.
 */
export function loadGame(storage: StorageLike, now: number, freshSeed: number, c: Content = content): LoadOutcome {
  let raw: string | null = null
  try {
    raw = storage.getItem(SAVE_KEY)
  } catch {
    raw = null
  }

  const newGame = (notice: LoadNotice | null): LoadOutcome => {
    const state = flushSave(storage, createInitialState(freshSeed, now, c), now).state
    return { state, events: [], summary: null, isNewGame: true, migratedFrom: null, notice }
  }

  if (raw === null) return newGame(null)

  const parsed = parseSave(raw, c)
  if (!parsed.ok) {
    const brokenKey = brokenSaveKey(now)
    try {
      storage.setItem(brokenKey, raw)
    } catch {
      // Nowhere to put the copy. The notice still tells the player, and the original stays under SAVE_KEY
      // until the fresh game's first write replaces it.
    }
    return newGame({ kind: 'quarantined', reason: parsed.reason, message: parsed.message, brokenKey })
  }

  const caughtUp = applyOffline(parsed.state, now, c)
  const state = flushSave(storage, caughtUp.state, now).state
  return { state, events: caughtUp.events, summary: caughtUp.summary, isNewGame: false, migratedFrom: parsed.migratedFrom, notice: null }
}
