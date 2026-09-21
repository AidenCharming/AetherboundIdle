import { useEffect, useRef, useState, type FormEvent } from 'react'
import { useActions } from '../../state/runtime'
import { DELETE_CONFIRM_WORDS, isDeleteConfirmed } from '../../state/selectors'
import { downloadFile } from '../downloadFile'

/**
 * The question. A native `<dialog>` opened with `showModal()`, the same pattern as the welcome-back dialog (see
 * WelcomeBack.tsx for why it is built this way): the browser makes it modal and inert-around, gives it the dialog role
 * and moves focus in; Escape and a browser-level cancel are both caught here and close it through the one path, which
 * unmounts it; the section puts focus back on the button that opened it.
 *
 * OK stays disabled until the typed text is a confirmation (`isDeleteConfirmed`), and it is the only way to delete: Enter
 * in the box submits the form only when the text already confirms. Focus starts in the box, so a stray Enter or Space
 * cannot do anything. "Export a backup first" is the same download Settings' Export save makes.
 */
function DeleteDialog({ onClose }: { onClose: () => void }) {
  const actions = useActions()
  const dialog = useRef<HTMLDialogElement>(null)
  const input = useRef<HTMLInputElement>(null)
  const [text, setText] = useState('')
  const [message, setMessage] = useState<string | null>(null)
  const [deleting, setDeleting] = useState(false)
  const confirmed = isDeleteConfirmed(text)

  useEffect(() => {
    const el = dialog.current
    if (el && !el.open) el.showModal()
    input.current?.focus()
  }, [])

  const exportFirst = (): void => {
    const { fileName, text: saved } = actions.exportSave()
    downloadFile(fileName, saved)
    setMessage(`Backup started: ${fileName}`)
  }

  const submit = (e: FormEvent): void => {
    e.preventDefault()
    if (!confirmed || deleting) return
    setDeleting(true)
    // Retires the tick driver first, removes only the main save key, then reloads into a new game.
    actions.resetSave()
  }

  return (
    <dialog
      className="wb delete-dialog"
      ref={dialog}
      role="dialog"
      aria-modal="true"
      aria-labelledby="delete-title"
      aria-describedby="delete-text"
      onKeyDown={(e) => {
        if (e.key !== 'Escape') return
        e.preventDefault()
        onClose()
      }}
      onCancel={(e) => {
        e.preventDefault()
        onClose()
      }}
    >
      <form onSubmit={submit}>
        <h2 id="delete-title">Delete your save?</h2>
        <p id="delete-text">
          This permanently deletes your game: creatures, levels, resources and play time. Backup copies made by imports or by damaged saves are kept. Export a backup first if you might want this game back.
        </p>

        <div className="dev-row">
          <button type="button" onClick={exportFirst} disabled={deleting}>
            Export a backup first
          </button>
        </div>
        {message && (
          <p role="status" className="small muted">
            {message}
          </p>
        )}

        <label className="field" htmlFor="delete-confirm">
          <span>Type {DELETE_CONFIRM_WORDS.join(' or ')} to confirm</span>
          <input
            id="delete-confirm"
            ref={input}
            className="dev-input"
            type="text"
            value={text}
            onChange={(e) => setText(e.target.value)}
            disabled={deleting}
            autoComplete="off"
            autoCapitalize="off"
            autoCorrect="off"
            spellCheck={false}
          />
        </label>

        <div className="dev-row">
          <button type="submit" className="danger" disabled={!confirmed || deleting}>
            OK
          </button>
          <button type="button" onClick={onClose} disabled={deleting}>
            Cancel
          </button>
        </div>

        {deleting && (
          <p role="status" className="small muted">
            Save deleted. Reloading...
          </p>
        )}
      </form>
    </dialog>
  )
}

/**
 * Settings' "Delete save" section, for players (the Dev panel's Reset save is separate and stays as it is). One button
 * that opens the question; deleting is `actions.resetSave`, the same action the Dev panel uses, so the reset trap (the
 * old game written back by this tab's own flush after the wipe) is closed the same way. It wipes only the main save
 * key: the backup copies that imports and damaged saves leave behind are kept.
 */
export function DeleteSave() {
  const [open, setOpen] = useState(false)
  const trigger = useRef<HTMLButtonElement>(null)
  const wasOpen = useRef(false)

  // Once the dialog has gone (it is unmounted, which is what takes it out of the top layer), focus goes back to where
  // it came from. Not on the first render.
  useEffect(() => {
    if (open) wasOpen.current = true
    else if (wasOpen.current) {
      wasOpen.current = false
      trigger.current?.focus()
    }
  }, [open])

  return (
    <div className="dev-control danger-zone">
      <h2>Delete save</h2>
      <p className="small muted">
        Deletes your game and starts a new one: your creatures, levels, resources and play time. It cannot be undone. Backup copies made by imports or by damaged saves are kept, and Export save above makes a copy first.
      </p>
      <div className="dev-row">
        <button type="button" className="danger" ref={trigger} onClick={() => setOpen(true)}>
          Delete save...
        </button>
      </div>
      {open && <DeleteDialog onClose={() => setOpen(false)} />}
    </div>
  )
}
