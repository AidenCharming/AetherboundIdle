import { useEffect, useRef, useState } from 'react'
import { useActions, useGameStore } from '../../state/runtime'
import { selectNotifications, selectUnreadCount, skillInfo, type Notification } from '../../state/selectors'
import { KIND_LABEL } from '../format'

const time = (at: number): string => new Date(at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })

function Item({ n }: { n: Notification }) {
  const info = skillInfo(n.skillId)
  return (
    <li className="notif-item" data-unread={!n.read}>
      <span className="notif-emoji" aria-hidden="true">
        {info.emoji ?? '◆'}
      </span>
      <div className="notif-main">
        <p className="notif-text">{n.text}</p>
        <p className="small muted">
          {KIND_LABEL[n.kind]} · <time dateTime={new Date(n.at).toISOString()}>{time(n.at)}</time>
          {!n.read && <span className="notif-new"> · new</span>}
        </p>
      </div>
    </li>
  )
}

/**
 * The bell in the header, with a count of what is unread (hidden at zero), and the panel it opens: recent notifications,
 * newest first, with "Mark all read" and "Clear". It is a non-modal dialog. Opening it moves focus into it; Escape closes
 * it and puts focus back on the bell; a press outside closes it and leaves focus where the player put it.
 */
export function NotificationBell() {
  const actions = useActions()
  const items = useGameStore(selectNotifications)
  const unread = useGameStore(selectUnreadCount)
  const [open, setOpen] = useState(false)
  const wrap = useRef<HTMLDivElement>(null)
  const bell = useRef<HTMLButtonElement>(null)
  const panel = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!open) return
    panel.current?.focus()
    const onKey = (e: KeyboardEvent): void => {
      if (e.key !== 'Escape') return
      e.preventDefault()
      setOpen(false)
      bell.current?.focus()
    }
    const onPress = (e: PointerEvent): void => {
      if (!wrap.current?.contains(e.target as Node)) setOpen(false)
    }
    document.addEventListener('keydown', onKey)
    document.addEventListener('pointerdown', onPress)
    return () => {
      document.removeEventListener('keydown', onKey)
      document.removeEventListener('pointerdown', onPress)
    }
  }, [open])

  return (
    <div className="bell-wrap" ref={wrap}>
      <button
        ref={bell}
        type="button"
        className="icon-btn bell"
        aria-label={unread > 0 ? `Notifications, ${unread} unread` : 'Notifications'}
        aria-haspopup="dialog"
        aria-expanded={open}
        aria-controls="notifications"
        onClick={() => setOpen((o) => !o)}
      >
        <span aria-hidden="true">🔔</span>
        {unread > 0 && (
          <span className="badge-count" aria-hidden="true">
            {unread > 99 ? '99+' : unread}
          </span>
        )}
      </button>

      {open && (
        <div id="notifications" ref={panel} className="notif-panel" role="dialog" aria-label="Notifications" tabIndex={-1}>
          <div className="notif-head">
            <h2>Notifications</h2>
            <div className="notif-actions">
              <button type="button" onClick={actions.markNotificationsRead}>
                Mark all read
              </button>
              <button type="button" onClick={actions.clearNotifications}>
                Clear
              </button>
            </div>
          </div>
          {items.length === 0 ? (
            <p className="muted small notif-empty">Nothing yet. Level-ups and new slots show up here.</p>
          ) : (
            <ul className="notif-list">
              {[...items].reverse().map((n) => (
                <Item key={n.id} n={n} />
              ))}
            </ul>
          )}
        </div>
      )}
    </div>
  )
}
