import { useEffect, useRef, useState, type KeyboardEvent, type ReactNode, type RefObject } from 'react'
import { flattenNav, type NavSection, type PageId } from '../../state/selectors'
import { nextNavIndex } from '../navKeys'
import { Brand } from './Brand'

interface Props {
  nav: readonly NavSection[]
  page: PageId
  onSelect: (id: PageId) => void
  /** A phone: the sidebar is a drawer that slides over the page. Otherwise it is a fixed column. */
  drawer: boolean
  open: boolean
  onClose: () => void
  /** The menu button in the header: where focus goes back to when the drawer closes. */
  returnFocus: RefObject<HTMLElement | null>
  /** Pinned at the bottom (the current activity panel and the autosave line). */
  footer?: ReactNode
}

/**
 * The sidebar navigation, under small section headings. A fixed column from 768 px; below that a drawer.
 *
 * As a drawer it behaves like a modal dialog: while it is open, focus moves into it (onto the current page), Escape and
 * a click on the backdrop close it, the page behind it is inert (App sets that), and closing it puts focus back on the
 * menu button. Closed, it is `inert` too, so its links are neither reachable by Tab nor read out.
 *
 * Keyboard in the nav: only one entry is in the Tab order (a roving tabindex, so Tab passes the whole list in one stop),
 * Down, Up, Home and End move focus through the entries across the section headings, Enter or Space opens the page.
 */
export function Sidebar({ nav, page, onSelect, drawer, open, onClose, returnFocus, footer }: Props) {
  const modal = drawer && open
  const root = useRef<HTMLElement>(null)
  const buttons = useRef(new Map<PageId, HTMLButtonElement>())
  const entries = flattenNav(nav)
  // The entry with focus is the one in the Tab order; with focus elsewhere it is the current page.
  const [focused, setFocused] = useState<PageId | null>(null)
  const tabStop = focused && entries.some((e) => e.id === focused) ? focused : page

  // Read through a ref so the effect below runs when the drawer opens or closes, not whenever a parent re-renders.
  const closeRef = useRef(onClose)
  closeRef.current = onClose

  useEffect(() => {
    if (!modal) return
    root.current?.querySelector<HTMLElement>('[aria-current="page"]')?.focus()
    const onKey = (e: globalThis.KeyboardEvent): void => {
      if (e.key !== 'Escape') return
      e.preventDefault()
      closeRef.current()
    }
    document.addEventListener('keydown', onKey)
    const scroll = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    return () => {
      document.removeEventListener('keydown', onKey)
      document.body.style.overflow = scroll
      returnFocus.current?.focus()
    }
  }, [modal, returnFocus])

  const onKeyDown = (e: KeyboardEvent<HTMLElement>): void => {
    const id = (e.target as HTMLElement).closest('[data-nav-id]')?.getAttribute('data-nav-id')
    const to = nextNavIndex(e.key, entries.findIndex((entry) => entry.id === id), entries.length)
    if (to === null) return
    e.preventDefault()
    buttons.current.get(entries[to]!.id)?.focus()
  }

  return (
    <>
      {modal && <div className="backdrop" onClick={onClose} aria-hidden="true" />}
      <aside
        ref={root}
        id="sidebar"
        className="sidebar"
        data-drawer={drawer}
        data-open={open}
        inert={drawer && !open}
        role={modal ? 'dialog' : undefined}
        aria-modal={modal ? true : undefined}
        aria-label={drawer ? 'Menu' : 'Sidebar'}
      >
        <div className="sidebar-top">
          <Brand />
          {drawer && (
            <button type="button" className="icon-btn" aria-label="Close menu" onClick={onClose}>
              <span aria-hidden="true">✕</span>
            </button>
          )}
        </div>

        <nav
          className="nav"
          aria-label="Pages"
          onKeyDown={onKeyDown}
          onBlur={(e) => {
            if (!e.currentTarget.contains(e.relatedTarget)) setFocused(null)
          }}
        >
          {nav.map((section) => (
            <div key={section.id} className="nav-section">
              <h2 className="nav-heading" id={`nav-${section.id}`}>
                {section.heading}
              </h2>
              <ul aria-labelledby={`nav-${section.id}`}>
                {section.entries.map((entry) => (
                  <li key={entry.id}>
                    <button
                      ref={(el) => {
                        if (el) buttons.current.set(entry.id, el)
                        else buttons.current.delete(entry.id)
                      }}
                      type="button"
                      className="nav-item"
                      data-nav-id={entry.id}
                      aria-current={entry.id === page ? 'page' : undefined}
                      tabIndex={entry.id === tabStop ? 0 : -1}
                      onFocus={() => setFocused(entry.id)}
                      onClick={() => onSelect(entry.id)}
                    >
                      <span className="nav-icon" aria-hidden="true">
                        {entry.icon}
                      </span>
                      <span>{entry.label}</span>
                    </button>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </nav>

        {footer && <div className="sidebar-foot">{footer}</div>}
      </aside>
    </>
  )
}
