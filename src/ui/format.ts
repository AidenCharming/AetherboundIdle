// Display-only formatting. Nothing here changes a stored value.
import type { CSSProperties } from 'react'

const count = new Intl.NumberFormat('en-US')

/** A whole-number count with thousands separators. Fractions are dropped, not rounded up. */
export const formatCount = (n: number): string => count.format(Math.floor(n))

/** 3000 -> "3.0 s". */
export const formatSeconds = (ms: number): string => `${(ms / 1000).toFixed(1)} s`

/** Passes CSS custom properties (--accent, --dot, ...) through React's `style`, dropping any that are unset. */
export function cssVars(vars: Record<`--${string}`, string | null | undefined>): CSSProperties {
  return Object.fromEntries(Object.entries(vars).filter(([, v]) => v != null)) as CSSProperties
}
