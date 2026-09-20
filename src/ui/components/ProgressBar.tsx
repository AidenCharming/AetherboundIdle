import { useLayoutEffect, useRef } from 'react'
import { uiTickMs } from '../../state/selectors'
import { cssVars } from '../format'

interface Props {
  /** 0 to 1. */
  value: number
  /** What the bar measures, for screen readers. */
  label: string
  thin?: boolean
  /** The gold of the UI chrome, for bars that are not a skill's (the sidebar's activity). Otherwise the skill's own accent. */
  tone?: 'gold'
}

/**
 * The state moves in steps of one tick, so the CSS smooths each step with a linear transition as long as the tick.
 * That is right while the value climbs, but when an action finishes the value falls back near 0, and transitioning
 * that would sweep the fill backwards across the bar. So on a fall the width is applied with the transition off
 * and the style flushed at once (reading `offsetWidth` forces it), and only then is the transition restored.
 *
 * It is done to the element directly, not with a class, on purpose: a second store update in the same frame (the
 * autosave lands on the same tick) re-renders the bar, and a class would be gone again before the browser painted.
 * A flushed style cannot be taken back by a later render.
 */
export function ProgressBar({ value, label, thin, tone }: Props) {
  const fill = useRef<HTMLDivElement>(null)
  const clamped = Math.min(1, Math.max(0, value))
  const previous = useRef(clamped)

  useLayoutEffect(() => {
    const el = fill.current
    if (el && clamped < previous.current) {
      el.style.transition = 'none'
      void el.offsetWidth
      el.style.transition = ''
    }
    previous.current = clamped
  }, [clamped])

  return (
    <div
      className={thin ? 'bar thin' : 'bar'}
      data-tone={tone}
      role="progressbar"
      aria-label={label}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={Math.round(clamped * 100)}
    >
      <div ref={fill} className="bar-fill" style={{ width: `${clamped * 100}%`, ...cssVars({ '--smooth': `${uiTickMs}ms` }) }} />
    </div>
  )
}
