import type { ReactNode, RefObject } from 'react'
import { Brand } from './Brand'
import { Stats } from './Stats'

interface Props {
  /** A phone: show the menu button and the game's name, because the sidebar (with its own name) is a closed drawer. */
  drawer: boolean
  drawerOpen: boolean
  onMenu: () => void
  menuRef: RefObject<HTMLButtonElement | null>
  /** The right-hand end of the header (the notification bell). */
  end?: ReactNode
}

/**
 * The header. On a wide screen it is one line: the stats (gold, Aether and its rate, the resources) and, at the right
 * end, the bell. On a phone only the menu button, the name and the bell are in the sticky header, so it stays a slim
 * line, and the stats sit under it in the page where they scroll away.
 */
export function Header({ drawer, drawerOpen, onMenu, menuRef, end }: Props) {
  return (
    <>
      <header className="header">
        {drawer && (
          <>
            <button ref={menuRef} type="button" className="icon-btn" aria-label="Open menu" aria-expanded={drawerOpen} aria-controls="sidebar" onClick={onMenu}>
              <span aria-hidden="true">☰</span>
            </button>
            <Brand />
          </>
        )}
        {!drawer && <Stats />}
        <div className="header-end">{end}</div>
      </header>
      {drawer && (
        <section className="stats-bar" aria-label="Gold, Aether and resources">
          <Stats />
        </section>
      )}
    </>
  )
}
