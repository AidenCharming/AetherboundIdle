// The zustand store (plan.md section 1). It holds the live GameState and what loading said about it, and nothing
// else: no timers, no storage, no clock. The tick driver (driver.ts) and the actions (actions.ts) write to it;
// the UI reads it only through selectors.ts. It is a vanilla store so all of that runs in plain node tests.
import { createStore, type StoreApi } from 'zustand/vanilla'
import type { OfflineSummary } from '../sim/offline'
import type { GameState } from '../types/state'
import type { LoadOutcome } from './persistence'
import { queueWelcomeBack } from './welcomeBack'

/**
 * What `loadGame` reported, minus its `state`: that is the state as loaded, and the live one is `game`, so keeping
 * both would leave a stale copy lying around to be read by mistake.
 */
export type LoadReport = Omit<LoadOutcome, 'state'>

export interface GameStore {
  /** The live state. Replaced (never mutated) by every step and action. */
  game: GameState
  loadReport: LoadReport
  /** The player closed the quarantine banner. The notice itself stays in `loadReport`. */
  noticeDismissed: boolean
  /**
   * The away summary waiting to be shown, from the load or from a long gap on an open tab (driver.ts). Null once
   * the player dismisses it, or when there was nothing worth reporting (welcomeBack.ts decides which).
   */
  welcomeBack: OfflineSummary | null
}

export type GameStoreApi = StoreApi<GameStore>

export function createGameStore(outcome: LoadOutcome): GameStoreApi {
  const { state, ...loadReport } = outcome
  const welcomeBack = queueWelcomeBack(null, loadReport.summary, { isNewGame: loadReport.isNewGame, settings: state.settings })
  return createStore<GameStore>()(() => ({ game: state, loadReport, noticeDismissed: false, welcomeBack }))
}
