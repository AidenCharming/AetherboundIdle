// The zustand store (plan.md section 1). It holds the live GameState and what loading said about it, and nothing
// else: no timers, no storage, no clock. The tick driver (driver.ts) and the actions (actions.ts) write to it;
// the UI reads it only through selectors.ts. It is a vanilla store so all of that runs in plain node tests.
import { createStore, type StoreApi } from 'zustand/vanilla'
import type { GameState } from '../types/state'
import type { LoadOutcome } from './persistence'

/**
 * What `loadGame` reported, minus its `state`: that is the state as loaded, and the live one is `game`, so keeping
 * both would leave a stale copy lying around to be read by mistake. Step 1.8 renders `summary` and `events`.
 */
export type LoadReport = Omit<LoadOutcome, 'state'>

export interface GameStore {
  /** The live state. Replaced (never mutated) by every step and action. */
  game: GameState
  loadReport: LoadReport
  /** The player closed the quarantine banner. The notice itself stays in `loadReport`. */
  noticeDismissed: boolean
}

export type GameStoreApi = StoreApi<GameStore>

export function createGameStore(outcome: LoadOutcome): GameStoreApi {
  const { state, ...loadReport } = outcome
  return createStore<GameStore>()(() => ({ game: state, loadReport, noticeDismissed: false }))
}
