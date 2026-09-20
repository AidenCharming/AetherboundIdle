import { useState } from 'react'
import { useActions } from '../../state/runtime'
import { DevGrantCreature } from '../components/DevGrantCreature'
import { DevGrants } from '../components/DevGrants'
import { DevReset } from '../components/DevReset'
import { DevSkillLevel } from '../components/DevSkillLevel'
import { PageTitle } from '../components/PageTitle'

/** The presets the buttons offer. Not balance: they are just handy spans to test with. */
const PRESETS = [1, 12, 100]

/**
 * Testing tools, behind the Settings toggle (plan.md 7.1): fast-forward, grant creature, add resources / Aether / gold,
 * set skill level (designer-approved in 1.8b) and reset save. Every control is an action in `state/actions.ts`, so it
 * goes through the same store and the same save path the game uses.
 *
 * Fast-forward has **no maths of its own**. It asks the driver to re-run the real offline path for N hours, which is
 * the same `applyOffline` a closed tab and a sleeping laptop go through, so the cap applies here too: 100 hours under
 * a 12-hour cap grants 12 hours, and the result arrives in the same welcome-back dialog.
 */
export function DevPanel() {
  const actions = useActions()
  const [hours, setHours] = useState('1')
  const typed = Number(hours)
  const valid = Number.isFinite(typed) && typed > 0

  return (
    <section className="page" aria-label="Dev panel">
      <PageTitle lead="For testing. Everything here goes through the same actions and the same save path the game uses.">Dev panel</PageTitle>
      <div className="panel">
        <div className="dev-control">
          <h2>Fast-forward</h2>
          <p className="small muted">
            Re-runs the real offline catch-up as if you had been away that long, so the offline cap applies: asking for
            more than the cap grants the cap, not the hours you typed.
          </p>
          <div className="dev-row">
            <label className="field">
              <span className="small muted">Hours</span>
              <input
                className="dev-hours"
                type="number"
                min="0"
                step="1"
                inputMode="decimal"
                value={hours}
                onChange={(e) => setHours(e.target.value)}
              />
            </label>
            <button type="button" className="primary" disabled={!valid} onClick={() => actions.fastForwardHours(typed)}>
              Fast-forward
            </button>
          </div>
          <div className="dev-row">
            {PRESETS.map((h) => (
              <button key={h} type="button" onClick={() => actions.fastForwardHours(h)}>
                {h} h
              </button>
            ))}
          </div>
        </div>

        <p className="small muted">
          Fast-forward exists because editing <code>lastSeen</code> in localStorage by hand does not work while the tab
          is open: the tab flushes its own save on unload and overwrites the edit.
        </p>

        <DevGrantCreature />
        <DevGrants />
        <DevSkillLevel />
        <DevReset />
      </div>
    </section>
  )
}
