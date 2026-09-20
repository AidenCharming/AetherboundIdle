import { useState, type ReactNode } from 'react'
import type { DevActionResult } from '../../state/actions'
import { useActions } from '../../state/runtime'
import { resourceOptions } from '../../state/selectors'
import { DevMessage, toOutcome, type DevOutcome } from './DevMessage'

/**
 * One "add N of something" row. The amount stays text until the sim reads it, so an empty box, a minus sign, "abc" or
 * a huge number all reach the validation and come back as a visible reason instead of being coerced quietly.
 */
function AmountRow({ label, onAdd, children }: { label: string; onAdd: (amount: string) => DevActionResult; children?: ReactNode }) {
  const [amount, setAmount] = useState('')
  const [outcome, setOutcome] = useState<DevOutcome>(null)
  return (
    <div className="dev-amount">
      <div className="dev-row">
        {children}
        <label className="field">
          <span className="small muted">{label}</span>
          <input className="dev-input" type="text" inputMode="decimal" value={amount} placeholder="Amount" onChange={(e) => setAmount(e.target.value)} />
        </label>
        <button type="button" className="primary" onClick={() => setOutcome(toOutcome(onAdd(amount)))}>
          Add
        </button>
      </div>
      <DevMessage outcome={outcome} />
    </div>
  )
}

/** Plan 7.1's add resources, add Aether and add gold. Each is an action that validates and saves at once. */
export function DevGrants() {
  const actions = useActions()
  const [resourceId, setResourceId] = useState(resourceOptions[0]!.id)
  return (
    <div className="dev-control">
      <h2>Add resources, Aether and gold</h2>
      <p className="small muted">Whole numbers for resources and gold; Aether may have a fraction.</p>
      <AmountRow label="Resource amount" onAdd={(amount) => actions.addResource(resourceId, amount)}>
        <label className="field">
          <span className="small muted">Resource</span>
          <select value={resourceId} onChange={(e) => setResourceId(e.target.value)}>
            {resourceOptions.map((r) => (
              <option key={r.id} value={r.id}>
                {r.name}
              </option>
            ))}
          </select>
        </label>
      </AmountRow>
      <AmountRow label="Aether" onAdd={(amount) => actions.addAether(amount)} />
      <AmountRow label="Gold" onAdd={(amount) => actions.addGold(amount)} />
    </div>
  )
}
