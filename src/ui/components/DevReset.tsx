import { useEffect, useRef, useState } from 'react'
import { useActions } from '../../state/runtime'

/**
 * Reset save, behind two steps: "Reset save..." only opens the question, and only "Yes, wipe my save" acts. The
 * action retires the tick driver before it wipes, so this tab's own unload flush cannot write the old game back.
 * Focus lands on Cancel when the question opens, so a stray Enter or Space does not confirm it.
 */
export function DevReset() {
  const actions = useActions()
  const [step, setStep] = useState<'idle' | 'asking' | 'done'>('idle')
  const cancel = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    if (step === 'asking') cancel.current?.focus()
  }, [step])

  return (
    <div className="dev-control">
      <h2>Reset save</h2>
      <p className="small muted">Wipes the save and reloads into a new game with one Sproutlet. Backup copies of broken saves are kept.</p>
      {step === 'idle' && (
        <div className="dev-row">
          <button type="button" onClick={() => setStep('asking')}>
            Reset save...
          </button>
        </div>
      )}
      {step === 'asking' && (
        <div role="alertdialog" aria-label="Confirm reset" className="dev-confirm" onKeyDown={(e) => e.key === 'Escape' && setStep('idle')}>
          <p role="alert" className="error">
            This deletes every creature, resource and level, and it cannot be undone. Are you sure?
          </p>
          <div className="dev-row">
            <button
              type="button"
              className="danger"
              onClick={() => {
                setStep('done')
                actions.resetSave()
              }}
            >
              Yes, wipe my save
            </button>
            <button type="button" ref={cancel} onClick={() => setStep('idle')}>
              Cancel
            </button>
          </div>
        </div>
      )}
      {step === 'done' && (
        <p role="status" className="small muted">
          Save wiped. Reloading...
        </p>
      )}
    </div>
  )
}
