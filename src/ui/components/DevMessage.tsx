import type { DevActionResult } from '../../state/actions'

/** What a dev control last did, in words. `null` until it has been used. */
export type DevOutcome = { ok: boolean; text: string } | null

export const toOutcome = (result: DevActionResult): DevOutcome => (result.ok ? { ok: true, text: result.message } : { ok: false, text: result.reason })

/**
 * The result line under a dev control. A refusal is an alert (read out at once, in the danger color); a success is a
 * quiet status. Nothing here throws or hides: an invalid entry always gets a visible reason.
 */
export function DevMessage({ outcome }: { outcome: DevOutcome }) {
  if (!outcome) return null
  return (
    <p role={outcome.ok ? 'status' : 'alert'} className={outcome.ok ? 'small muted' : 'small error'}>
      {outcome.text}
    </p>
  )
}
