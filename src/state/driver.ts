// The tick driver: the only thing that moves game time forward while the app is open. It measures real elapsed
// time, hands it to the sim's one `step` function, autosaves, and flushes on the way out. Everything outside the
// game (storage, the clock, timers, window and document events) comes in as an argument, so it runs in plain node.
//
// Two rules hold it together:
//  - dt is real elapsed time. A negative dt (the clock went backwards) is clamped to 0, and a huge one (a
//    throttled or backgrounded tab, a sleeping laptop) goes straight to `step`, which handles any dt in bulk.
//    Never loop `step` to catch up.
//  - `flushSave` stamps lastSeen = now, so it assumes the sim has been stepped up to now. Every flush therefore
//    steps to now immediately before it, or the time since the last tick would be forfeited on the next load.
import { content, type Content } from '../data'
import { step as simStep } from '../sim/tick'
import { flushSave, type StorageLike } from './persistence'
import type { GameStoreApi } from './store'

/** The browser, as far as the game needs it. The real one is `browserEnv()` in runtime.ts. */
export interface Env {
  storage: StorageLike
  /** Epoch ms. */
  now(): number
  /** A fresh uint32, drawn once at boot to seed a brand-new game. */
  randomSeed(): number
  setInterval(fn: () => void, ms: number): unknown
  clearInterval(handle: unknown): void
  /** `window`: `pagehide` and `beforeunload`. */
  win: Pick<EventTarget, 'addEventListener' | 'removeEventListener'>
  /** `document`: `visibilitychange`. */
  doc: Pick<EventTarget, 'addEventListener' | 'removeEventListener'> & { readonly visibilityState: string }
}

export interface TickDriver {
  /** Steps the sim up to the clock's now and returns that now. Cheap when no time has passed. */
  stepToNow(): number
  /** Steps to now, then writes the save. The only way the game saves. */
  flush(): void
  /** Starts the tick and autosave timers and the unload / visibility hooks. Calling it again does nothing. */
  start(): void
  stop(): void
}

export function createTickDriver(
  store: GameStoreApi,
  env: Pick<Env, 'storage' | 'now' | 'setInterval' | 'clearInterval' | 'win' | 'doc'>,
  c: Content = content,
  step: typeof simStep = simStep,
): TickDriver {
  // The game was caught up to its own lastSeen on load (or created at it), so time is measured from there.
  let lastTick = store.getState().game.lastSeen

  function stepToNow(): number {
    const now = env.now()
    if (!Number.isFinite(now)) return lastTick
    // Negative dt (clock skew) becomes 0. Re-anchoring lastTick to the new now matters: leaving it in the future
    // would make every later tick negative too and freeze progress until the clock caught up.
    const dt = Math.max(0, now - lastTick)
    lastTick = now
    if (dt > 0) {
      const { game } = store.getState()
      store.setState({ game: step(game, dt, {}, c).state })
    }
    return now
  }

  function flush(): void {
    const now = stepToNow()
    const flushed = flushSave(env.storage, store.getState().game, now)
    store.setState({ game: flushed.state })
  }

  let timers: unknown[] = []
  let cleanup: (() => void) | null = null

  function start(): void {
    if (cleanup) return
    timers = [
      env.setInterval(() => void stepToNow(), c.tuning.ui.tickMs),
      env.setInterval(flush, c.tuning.save.autosaveMs),
    ]
    const onVisibility = (): void => {
      if (env.doc.visibilityState === 'visible') stepToNow()
    }
    env.win.addEventListener('pagehide', flush)
    env.win.addEventListener('beforeunload', flush)
    env.doc.addEventListener('visibilitychange', onVisibility)
    cleanup = () => {
      env.win.removeEventListener('pagehide', flush)
      env.win.removeEventListener('beforeunload', flush)
      env.doc.removeEventListener('visibilitychange', onVisibility)
    }
  }

  function stop(): void {
    for (const t of timers) env.clearInterval(t)
    timers = []
    cleanup?.()
    cleanup = null
  }

  return { stepToNow, flush, start, stop }
}
