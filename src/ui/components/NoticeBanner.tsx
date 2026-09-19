import { useActions, useGameStore } from '../../state/runtime'
import { selectQuarantineNotice } from '../../state/selectors'

/**
 * Shown when the save on disk could not be loaded, so the player is never silently reset. The old save was
 * copied aside byte for byte and a fresh game started. (The welcome-back summary is step 1.8, not this.)
 */
export function NoticeBanner() {
  const notice = useGameStore(selectQuarantineNotice)
  const actions = useActions()
  if (!notice) return null
  return (
    <div className="banner" role="alert">
      <div>
        <p>
          <strong>Your saved game could not be loaded, so a new game was started.</strong>
        </p>
        <p>{notice.message}</p>
        <p className="muted small">
          The old save was kept as <code>{notice.brokenKey}</code>.
        </p>
      </div>
      <button type="button" onClick={actions.dismissNotice}>
        Dismiss
      </button>
    </div>
  )
}
