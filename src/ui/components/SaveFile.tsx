import { useEffect, useRef, useState, type ChangeEvent } from 'react'
import { useActions } from '../../state/runtime'
import { MAX_IMPORT_BYTES } from '../../state/selectors'
import { downloadFile } from '../downloadFile'

type Step = { kind: 'idle' } | { kind: 'asking'; fileName: string; text: string; creatures: number; savedAt: number } | { kind: 'done' }
type Message = { ok: boolean; text: string } | null

/**
 * Save export and import (Settings). Export downloads the save as a .json file. Import reads a file the player picks,
 * checks it (a bad file is refused with the reason and nothing changes), and only then asks, in two steps like the
 * dev panel's Reset, before it replaces the game. The action retires the tick driver and reloads, so the page boots
 * through the normal load: offline time, the cap and the welcome-back summary all apply to an old file.
 */
export function SaveFile() {
  const actions = useActions()
  const [step, setStep] = useState<Step>({ kind: 'idle' })
  const [message, setMessage] = useState<Message>(null)
  const picker = useRef<HTMLInputElement>(null)
  const cancel = useRef<HTMLButtonElement>(null)

  useEffect(() => {
    if (step.kind === 'asking') cancel.current?.focus()
  }, [step.kind])

  const exportSave = (): void => {
    const { fileName, text } = actions.exportSave()
    downloadFile(fileName, text)
    setMessage({ ok: true, text: `Export started: ${fileName}` })
  }

  const onPick = async (e: ChangeEvent<HTMLInputElement>): Promise<void> => {
    const file = e.target.files?.[0]
    e.target.value = '' // so choosing the same file again still counts as a change
    if (!file) return
    setMessage(null)
    if (file.size > MAX_IMPORT_BYTES) {
      setMessage({ ok: false, text: `${file.name} is too large to be a save (over ${MAX_IMPORT_BYTES / 1_000_000} MB). Nothing was changed.` })
      return
    }
    let text: string
    try {
      text = await file.text()
    } catch {
      setMessage({ ok: false, text: `${file.name} could not be read. Nothing was changed.` })
      return
    }
    const checked = actions.inspectSave(text)
    if (!checked.ok) {
      setMessage({ ok: false, text: `${file.name}: ${checked.reason} Nothing was changed.` })
      return
    }
    setStep({ kind: 'asking', fileName: file.name, text, creatures: checked.creatures, savedAt: checked.savedAt })
  }

  const confirm = (text: string): void => {
    const result = actions.importSave(text)
    if (result.ok) {
      setStep({ kind: 'done' })
    } else {
      setStep({ kind: 'idle' })
      setMessage({ ok: false, text: result.reason })
    }
  }

  return (
    <div className="dev-control">
      <h2>Save file</h2>
      <p className="small muted">
        Export keeps a copy of your game as a file, for a backup or to move it to another computer. Import replaces the game you are playing with such a file.
      </p>

      {step.kind !== 'done' && (
        <div className="dev-row">
          <button type="button" className="primary" onClick={exportSave}>
            Export save
          </button>
          <button type="button" onClick={() => picker.current?.click()} disabled={step.kind === 'asking'}>
            Import save...
          </button>
          <input ref={picker} type="file" accept=".json,application/json" hidden onChange={onPick} />
        </div>
      )}

      {step.kind === 'asking' && (
        <div role="alertdialog" aria-label="Confirm import" className="dev-confirm" onKeyDown={(e) => e.key === 'Escape' && setStep({ kind: 'idle' })}>
          <p role="alert" className="error">
            Replace your current game with {step.fileName}? It holds {step.creatures} creature{step.creatures === 1 ? '' : 's'} and was saved {new Date(step.savedAt).toLocaleString()}. Your current game is
            copied to a backup first, but there is no button to bring it back, so export it first if you want to keep it.
          </p>
          <div className="dev-row">
            <button type="button" className="danger" onClick={() => confirm(step.text)}>
              Yes, replace my game
            </button>
            <button type="button" ref={cancel} onClick={() => setStep({ kind: 'idle' })}>
              Cancel
            </button>
          </div>
        </div>
      )}

      {step.kind === 'done' && (
        <p role="status" className="small muted">
          Save imported. Reloading...
        </p>
      )}

      {message && (
        <p role={message.ok ? 'status' : 'alert'} className={message.ok ? 'small muted' : 'small error'}>
          {message.text}
        </p>
      )}
    </div>
  )
}
