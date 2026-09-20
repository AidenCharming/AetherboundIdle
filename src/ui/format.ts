// Display-only formatting. Nothing here changes a stored value.
import type { CSSProperties } from 'react'
import type { NotificationKind } from '../state/selectors'

const count = new Intl.NumberFormat('en-US')

/** What each kind of notification is called, as a small heading on a toast and a line in the bell's list. */
export const KIND_LABEL: Record<NotificationKind, string> = {
  'skill-level-up': 'Level up',
  'slot-unlocked': 'Slot unlocked',
}

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

// A rate is small and often fractional (a Dim creature is 1 a minute, a trait makes it 1.05), so fewer decimals show as it grows.
const rate2 = new Intl.NumberFormat('en-US', { maximumFractionDigits: 2 })
const rate1 = new Intl.NumberFormat('en-US', { maximumFractionDigits: 1 })
const rate0 = new Intl.NumberFormat('en-US', { maximumFractionDigits: 0 })

/**
 * Aether per minute (or per hour) for display: "0", "0.5", "12.5", "256", "1,024". Up to two decimals below 10, one below 1,000,
 * none above, trailing zeros dropped, and anything tiny but not zero says "<0.01" rather than a misleading "0".
 */
export function formatRate(n: number): string {
  if (!(n > 0)) return '0'
  if (n < 0.01) return '<0.01'
  return (n < 10 ? rate2 : n < 1000 ? rate1 : rate0).format(n)
}
