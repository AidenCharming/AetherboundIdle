import { useEffect, useRef, useState } from 'react'
import { useGameStore } from './state/runtime'
import { DEFAULT_SORT, NO_FILTER, resolvePage, selectNav, skillIdOfPage, type PageId, type RosterFilter, type RosterSort } from './state/selectors'
import { ActivityPanel } from './ui/components/ActivityPanel'
import { Header } from './ui/components/Header'
import { NoticeBanner } from './ui/components/NoticeBanner'
import { NotificationBell } from './ui/components/NotificationBell'
import { Sidebar } from './ui/components/Sidebar'
import { ToastHost } from './ui/components/ToastHost'
import { WelcomeBack } from './ui/components/WelcomeBack'
import { DevPanel } from './ui/screens/DevPanel'
import { Nexus } from './ui/screens/Nexus'
import { Roster } from './ui/screens/Roster'
import { Settings } from './ui/screens/Settings'
import { SkillPage } from './ui/screens/SkillPage'
import { useMediaQuery } from './ui/useMediaQuery'
import './ui/theme.css'

// The width from which the sidebar is a fixed column instead of a drawer. It is the only place the breakpoint is written
// for the shell: the layout CSS follows the `data-drawer` attribute this decides, so CSS and script cannot disagree.
const DESKTOP = '(min-width: 768px)'

// The layout shell and the page switch. Which page is open is plain UI state (no router, and not in the save). The tick
// driver runs whichever page is showing, so nothing pauses while you look at the roster.
export function App() {
  const nav = useGameStore(selectNav)
  const [chosen, setChosen] = useState<PageId | null>(null)
  const page = resolvePage(nav, chosen)
  // The roster's filter and sort live here, not in the Roster, so a trip to another page and back keeps them.
  // Still UI-local: none of it is in the game state or the save.
  const [filter, setFilter] = useState<RosterFilter>(NO_FILTER)
  const [sort, setSort] = useState<RosterSort>(DEFAULT_SORT)

  const drawer = !useMediaQuery(DESKTOP)
  const [drawerOpen, setDrawerOpen] = useState(false)
  const menuRef = useRef<HTMLButtonElement>(null)
  // Widening the window while the drawer is open makes it a column again, so it must not stay "open".
  useEffect(() => {
    if (!drawer) setDrawerOpen(false)
  }, [drawer])
  const modal = drawer && drawerOpen

  const select = (id: PageId): void => {
    setChosen(id)
    setDrawerOpen(false)
  }

  const skillId = skillIdOfPage(page)
  return (
    <div className="shell" data-drawer={drawer} data-modal={modal}>
      <Sidebar nav={nav} page={page} onSelect={select} drawer={drawer} open={drawerOpen} onClose={() => setDrawerOpen(false)} returnFocus={menuRef} footer={<ActivityPanel />} />
      {/* While the drawer is open, everything behind it is inert: no focus, no clicks, and hidden from screen readers. */}
      <div className="main-col" inert={modal}>
        <Header drawer={drawer} drawerOpen={drawerOpen} onMenu={() => setDrawerOpen(true)} menuRef={menuRef} end={<NotificationBell />} />
        <NoticeBanner />
        <main id="main" className="content">
          {skillId && <SkillPage key={skillId} skillId={skillId} />}
          {page === 'roster' && <Roster filter={filter} sort={sort} onFilter={setFilter} onSort={setSort} />}
          {page === 'nexus' && <Nexus />}
          {page === 'settings' && <Settings />}
          {page === 'dev' && <DevPanel />}
        </main>
        <ToastHost />
      </div>
      <WelcomeBack />
    </div>
  )
}
