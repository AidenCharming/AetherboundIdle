import { useEffect, useRef } from 'react'
import { useActions, useGameStore } from '../../state/runtime'
import { selectWelcomeBack, type WelcomeBackSkill, type WelcomeBackView } from '../../state/selectors'
import { cssVars, formatCount, formatDuration, formatGain } from '../format'
import { ResourceIcon } from './ResourceIcon'

function SkillRow({ skill }: { skill: WelcomeBackSkill }) {
  const levelled = skill.levelAfter > skill.levelBefore
  return (
    <li className="wb-skill" style={cssVars({ '--accent': skill.color })}>
      <h3>{skill.name}</h3>
      <p className="small">
        {formatCount(skill.actions)} actions · {formatGain(skill.xpGained)} XP
      </p>
      <p className="small">
        {levelled ? (
          <>
            Level {skill.levelBefore} <span aria-hidden="true">&rarr;</span> <strong>{skill.levelAfter}</strong>
          </>
        ) : (
          <span className="muted">Level {skill.levelAfter}</span>
        )}
      </p>
      {skill.slotsUnlocked.length > 0 && (
        <p className="small">
          <strong>New {skill.slotsUnlocked.length === 1 ? 'slot' : 'slots'}:</strong> {skill.slotsUnlocked.join(', ')}
        </p>
      )}
    </li>
  )
}

function Body({ view }: { view: WelcomeBackView }) {
  return (
    <>
      <p>
        You were away for <strong>{formatDuration(view.awayMs)}</strong>.
      </p>
      {view.capped && (
        <p className="wb-capped">
          Offline progress is capped at {formatDuration(view.capMs)}, so only the first {formatDuration(view.earnedMs)} earned anything. The rest
          earned nothing.
        </p>
      )}

      {view.empty ? (
        <p className="muted">Nothing was working and nobody was on the bench, so there is nothing to collect.</p>
      ) : (
        <>
          <dl className="wb-gains">
            <div>
              <dt>Aether</dt>
              <dd>{formatGain(view.aetherGained)}</dd>
            </div>
            {view.resources.map((r) => (
              <div key={r.id}>
                <dt>
                  <ResourceIcon info={r} /> {r.name}
                </dt>
                <dd>{formatGain(r.qty)}</dd>
              </div>
            ))}
          </dl>

          {view.skills.length > 0 && (
            <ul className="wb-skills">
              {view.skills.map((sk) => (
                <SkillRow key={sk.id} skill={sk} />
              ))}
            </ul>
          )}
        </>
      )}
    </>
  )
}

/**
 * What happened while the player was away: shown after a load with a long gap, after the tab itself was away long
 * enough (a sleeping laptop), and after the dev panel's fast-forward — all three are the same summary from the same
 * sim path, so this renders one thing.
 *
 * It is a native `<dialog>` opened with `showModal()`, which is what makes it accessible without hand-rolling any of
 * it: an implicit `role="dialog"` with `aria-modal`, focus moved inside and restored to where it was on close, the
 * rest of the page inert, and Escape closing it. Closing however it happens runs one handler, so the summary is
 * cleared exactly once. Escape and the Close button do it directly, and a browser-level `cancel` (which is not Escape)
 * is caught and does the same.
 */
export function WelcomeBack() {
  const view = useGameStore(selectWelcomeBack)
  const actions = useActions()
  const ref = useRef<HTMLDialogElement>(null)

  // `showModal()` is what makes this a real modal: the browser moves focus inside, keeps it there, marks the rest
  // of the page inert and draws the backdrop. Only the opening is the element's; closing is React clearing the
  // summary and unmounting the dialog, which takes it out of the top layer.
  //
  // The dialog's own `close` event is NOT used, and neither is Escape-to-close: neither fires in every browser
  // build (both were dead in the one this was tested in), and a dialog that closes itself without telling the
  // store would leave a closed, invisible dialog mounted over a summary the player never saw.
  const opener = useRef<HTMLElement | null>(null)

  useEffect(() => {
    if (!view) {
      // The dialog has been unmounted by this point, so focus can go back where it came from. Removing the element
      // is what takes it out of the top layer, and it is also what loses the focus the browser would have restored.
      const back = opener.current
      opener.current = null
      if (back?.isConnected) back.focus()
      return
    }
    const dialog = ref.current
    if (dialog && !dialog.open) {
      opener.current = document.activeElement as HTMLElement | null
      dialog.showModal()
    }
  }, [view])

  if (!view) return null
  return (
    <dialog
      className="wb"
      ref={ref}
      // Both are implicit on a modal <dialog>, but written out so the contract is visible and testable.
      role="dialog"
      aria-modal="true"
      aria-labelledby="wb-title"
      // preventDefault keeps the browser's own close watcher out of it, so the one path above is the only one.
      onKeyDown={(e) => {
        if (e.key !== 'Escape') return
        e.preventDefault()
        actions.dismissWelcomeBack()
      }}
      // A browser-level cancel that is not the Escape key (the Android back button, a close request) fires `cancel`,
      // and left alone it would close the dialog and leave the summary pending. Refuse the browser's close and dismiss
      // through the one path instead. (Where the browser closes it anyway, the summary is already gone.)
      onCancel={(e) => {
        e.preventDefault()
        actions.dismissWelcomeBack()
      }}
    >
      <h2 id="wb-title">Welcome back</h2>
      <Body view={view} />
      <p className="wb-close">
        <button type="button" onClick={actions.dismissWelcomeBack}>
          Close
        </button>
      </p>
    </dialog>
  )
}
