// Seeded RNG (plan.md 4.6). mulberry32's whole state is one uint32 that advances on every consume, and
// that live value is what the save holds (`GameState.rngState`), never the initial seed: persisting the seed
// alone would let a reload replay the same numbers, which is the exact reroll this exists to prevent.

export interface Rng {
  /** uint32. Advances on every consume; mirror it into `GameState.rngState` when a step finishes. */
  state: number
  /** Uniform in [0, 1). */
  next(): number
  /** Uniform integer in [0, n). */
  int(n: number): number
  /** True with probability p. Always consumes exactly one value, whatever p is. */
  chance(p: number): boolean
  /** Successes in n independent trials of probability p. See `binomial` below for the method. */
  binomial(n: number, p: number): number
}

const TWO_POW_32 = 4294967296

/** Above this expected success count the exact waiting-time method gets slow, so it switches to normal. */
const EXACT_BINOMIAL_LIMIT = 30

export function createRng(state: number): Rng {
  const rng: Rng = {
    state: state >>> 0,
    next() {
      rng.state = (rng.state + 0x6d2b79f5) >>> 0
      let t = rng.state
      t = Math.imul(t ^ (t >>> 15), t | 1)
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
      return ((t ^ (t >>> 14)) >>> 0) / TWO_POW_32
    },
    int(n) {
      return Math.floor(rng.next() * n)
    },
    chance(p) {
      return rng.next() < p
    },
    binomial(n, p) {
      return binomial(rng, n, p)
    },
  }
  return rng
}

/**
 * Binomial draw without n individual rolls (plan 4.5). Bulk offline windows can be tens of thousands of
 * actions, and the rare-drop chance is tiny.
 *
 * - Small expected count (n * min(p, 1-p) < 30): the exact waiting-time method. The gap to the next success
 *   is geometric, so it costs about n*p draws instead of n.
 * - Larger: a normal approximation (Box-Muller), rounded and clamped to [0, n]. At 30+ expected successes
 *   its error is far below anything a player could notice.
 *
 * Both are deterministic functions of the RNG stream. p at or below 0 or above 1 is clamped, and a draw that
 * cannot vary (n <= 0, p <= 0, p >= 1) consumes nothing.
 */
export function binomial(rng: Rng, n: number, p: number): number {
  if (!(n > 0) || !(p > 0)) return 0
  if (p >= 1) return n
  const flip = p > 0.5
  const q = flip ? 1 - p : p
  let successes: number
  if (n * q < EXACT_BINOMIAL_LIMIT) {
    const logFail = Math.log1p(-q)
    successes = 0
    let position = 0
    for (;;) {
      // 1 - next() is in (0, 1], so the log is finite.
      position += Math.floor(Math.log(1 - rng.next()) / logFail) + 1
      if (position > n) break
      successes++
    }
  } else {
    const mean = n * q
    const sd = Math.sqrt(n * q * (1 - q))
    const z = Math.sqrt(-2 * Math.log(1 - rng.next())) * Math.cos(2 * Math.PI * rng.next())
    successes = Math.min(n, Math.max(0, Math.round(mean + sd * z)))
  }
  return flip ? n - successes : successes
}
