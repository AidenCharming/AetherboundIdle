// Display-only formatting. Nothing here changes a stored value.
import type { CSSProperties } from 'react'

const count = new Intl.NumberFormat('en-US')

/** A whole-number count with thousands separators. Fractions are dropped, not rounded up. */
export const formatCount = (n: number): string => count.format(Math.floor(n))

/** 3000 -> "3.0 s". */
export const formatSeconds = (ms: number): string => `${(ms / 1000).toFixed(1)} s`

const MINUTE = 60_000
const HOUR = 60 * MINUTE
const DAY = 24 * HOUR

/**
 * A span of time away, in the two largest units that matter: "3 d 4 h", "12 h 30 m", "7 m 20 s", "45 s". Rounds
 * down, so it never claims more time than passed, and never says "0 s" for a span that was not zero.
 */
export function formatDuration(ms: number): string {
  const total = Math.max(0, Math.floor(ms))
  if (total < MINUTE) return `${Math.floor(total / 1000)} s`
  const [big, small, bigUnit, smallUnit] = total >= DAY ? [DAY, HOUR, 'd', 'h'] : total >= HOUR ? [HOUR, MINUTE, 'h', 'm'] : [MINUTE, 1000, 'm', 's']
  const whole = Math.floor(total / big)
  const rest = Math.floor((total % big) / small)
  return rest === 0 ? `${whole} ${bigUnit}` : `${whole} ${bigUnit} ${rest} ${smallUnit}`
}

/** "+3", or "3" with no sign wanted. Used for gains, which are never negative here. */
export const formatGain = (n: number): string => `+${formatCount(n)}`

/** Passes CSS custom properties (--accent, --dot, ...) through React's `style`, dropping any that are unset. */
export function cssVars(vars: Record<`--${string}`, string | null | undefined>): CSSProperties {
  return Object.fromEntries(Object.entries(vars).filter(([, v]) => v != null)) as CSSProperties
}
