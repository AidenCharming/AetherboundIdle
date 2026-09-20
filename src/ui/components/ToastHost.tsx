import { useCallback, useEffect, useState } from 'react'
import { useGameStore } from '../../state/runtime'
import { maxToasts, selectNextNotificationId, selectNotifications, skillInfo, toastMs, visibleToasts, type Notification } from '../../state/selectors'
import { KIND_LABEL } from '../format'

function Toast({ n, onDismiss }: { n: Notification; onDismiss: (id: number, at: number) => void }) {
  const [hover, setHover] = useState(false)
  const [focus, setFocus] = useState(false)
  const paused = hover || focus

  // Effect-based, and never in the store: the toast leaves `toastMs` after it appeared or was last updated, and the clock
  // stops while the pointer or focus is on it (it starts over from the full time when they leave). A level-up that
  // coalesces into it changes `n.at`, which restarts the timer too.
  const { id, at } = n
  useEffect(() => {
    if (paused) return
    const timer = window.setTimeout(() => onDismiss(id, at), toastMs)
    return () => window.clearTimeout(timer)
  }, [paused, id, at, onDismiss])

  return (
    <div
      className="toast"
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      onFocus={() => setFocus(true)}
      onBlur={(e) => {
        if (!e.currentTarget.contains(e.relatedTarget)) setFocus(false)
      }}
    >
      <span className="toast-emoji" aria-hidden="true">
        {skillInfo(n.skillId).emoji ?? '◆'}
      </span>
      <div className="toast-main">
        <p className="eyebrow">{KIND_LABEL[n.kind]}</p>
        <p className="toast-text">{n.text}</p>
      </div>
      <button type="button" className="icon-btn toast-close" aria-label="Dismiss notification" onClick={() => onDismiss(id, at)}>
        <span aria-hidden="true">✕</span>
      </button>
    </div>
  )
}

/**
 * Toasts for what happens while the player plays: bottom-right on a wide screen, bottom-centred on a phone. At most
 * `tuning.ui.maxToasts` show at once (the newest), each leaves after `tuning.ui.toastMs` or on its dismiss button, and
 * stays while hovered or focused. The live region (`role="status"`, polite) is always there, so an announcement is
 * spoken when a toast arrives.
 *
 * Which toasts exist is derived, not stored: every notification recorded after this host mounted, minus the ones the
 * player dismissed or that timed out. A notification that coalesces into a dismissed toast has a newer `at`, so it shows
 * again with its new text. The bell keeps them all regardless.
 */
export function ToastHost() {
  const items = useGameStore(selectNotifications)
  const nextId = useGameStore(selectNextNotificationId)
  const [firstId] = useState(nextId)
  // id -> the `at` that was dismissed
  const [dismissed, setDismissed] = useState<ReadonlyMap<number, number>>(new Map())

  const dismiss = useCallback((id: number, at: number) => setDismissed((d) => new Map(d).set(id, at)), [])

  // The log drops its oldest entries (and Clear empties it), so forget dismissals for ids that are gone: this stays small.
  useEffect(() => {
    const oldest = items[0]?.id ?? nextId
    setDismissed((d) => {
      const kept = [...d].filter(([id]) => id >= oldest)
      return kept.length === d.size ? d : new Map(kept)
    })
  }, [items, nextId])

  const visible = visibleToasts(items, firstId, dismissed, maxToasts)

  return (
    <div className="toasts" role="status" aria-live="polite">
      {visible.map((n) => (
        <Toast key={n.id} n={n} onDismiss={dismiss} />
      ))}
    </div>
  )
}
