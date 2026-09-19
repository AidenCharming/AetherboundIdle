// Wires the store, the actions and the tick driver to the real browser, once, and hands the UI its two hooks.
// This is the only file in `src/state` that touches `window`, `localStorage`, `crypto` or `Date.now`; everything it
// builds takes those as arguments, so the pieces are tested without a browser.
import { useStore } from 'zustand'
import { createActions, type Actions } from './actions'
import { createTickDriver, type Env, type TickDriver } from './driver'
import { loadGame, type StorageLike } from './persistence'
import { createGameStore, type GameStore, type GameStoreApi } from './store'

export interface Runtime {
  store: GameStoreApi
  actions: Actions
  driver: TickDriver
}

/** Storage that reads empty and refuses writes, for when the browser will not hand over localStorage at all. */
const unavailableStorage: StorageLike = {
  getItem: () => null,
  setItem: () => {
    throw new Error('localStorage is unavailable')
  },
}

export function browserEnv(): Env {
  let storage: StorageLike
  try {
    storage = window.localStorage
  } catch {
    // Some privacy settings make even reading `window.localStorage` throw. Play without saving, don't white-screen.
    console.warn('localStorage is unavailable: progress will not be saved.')
    storage = unavailableStorage
  }
  return {
    storage,
    now: () => Date.now(),
    randomSeed: () => crypto.getRandomValues(new Uint32Array(1))[0]!,
    setInterval: (fn, ms) => window.setInterval(fn, ms),
    clearInterval: (handle) => window.clearInterval(handle as number),
    win: window,
    doc: document,
  }
}

let runtime: Runtime | null = null

/**
 * Loads the save, catches it up to now, builds the store, and starts the tick driver. Called once from main.tsx,
 * outside React: StrictMode double-mounts effects in development, and a driver started from one would run twice.
 * A second call returns the running game and starts nothing.
 *
 * The seed for a brand-new game is drawn here, once, from `crypto.getRandomValues`. After the first save the
 * state's own `rngState` carries the stream on, so it never matters again.
 */
export function bootGame(env: Env = browserEnv()): Runtime {
  if (runtime) return runtime
  const outcome = loadGame(env.storage, env.now(), env.randomSeed())
  const store = createGameStore(outcome)
  const driver = createTickDriver(store, env)
  runtime = { store, actions: createActions(store, driver, env.storage), driver }
  driver.start()
  return runtime
}

/** Stops the driver and forgets the running game. For tests and hot reload; the app never calls it. */
export function stopGame(): void {
  runtime?.driver.stop()
  runtime = null
}

function requireRuntime(): Runtime {
  if (!runtime) throw new Error('bootGame() must run before anything reads the game (main.tsx does this)')
  return runtime
}

/** Subscribes a component to a slice of the game. Pass a selector from selectors.ts. */
export function useGameStore<T>(selector: (state: GameStore) => T): T {
  return useStore(requireRuntime().store, selector)
}

/** The actions, a stable object. */
export function useActions(): Actions {
  return requireRuntime().actions
}
