import { useGameStore } from '../../state/runtime'
import { selectAwayMs, selectDevMs, selectDevPanelEnabled, selectOnlineMs, selectPlayedMs } from '../../state/selectors'
import { formatDuration } from '../format'

function Figure({ label, ms, hint }: { label: string; ms: number; hint?: string }) {
  return (
    <div>
      <dt>
        {label}
        {hint && <span className="small muted block">{hint}</span>}
      </dt>
      <dd>{formatDuration(ms)}</dd>
    </div>
  )
}

/**
 * How long this save has been played, split by where the time came from (step 1.9c). It exists because the dev
 * panel's fast-forward makes game time and real time diverge: without the split there is no way to tell a save
 * that was played for a week from one that was fast-forwarded through it.
 *
 * "Total played" is online plus away only. Fast-forwarded time is listed apart and never added in, and its line is
 * hidden entirely on a save that has never used it and has the Dev panel switched off.
 */
export function PlayTime() {
  const played = useGameStore(selectPlayedMs)
  const online = useGameStore(selectOnlineMs)
  const away = useGameStore(selectAwayMs)
  const dev = useGameStore(selectDevMs)
  const devPanel = useGameStore(selectDevPanelEnabled)
  return (
    <div className="dev-control">
      <h2>Play time</h2>
      <p className="small muted">Game time this save has earned. It counts only time the game was actually advanced, so a closed tab adds nothing until the catch-up runs.</p>
      <dl className="playtime">
        <Figure label="Total played" ms={played} hint="Online and away" />
        <Figure label="Online" ms={online} hint="Game open" />
        <Figure label="Away" ms={away} hint="Offline progress, capped" />
        {(dev > 0 || devPanel) && <Figure label="Dev fast-forward" ms={dev} hint="Not real play time" />}
      </dl>
    </div>
  )
}
