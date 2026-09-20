import { useState } from 'react'
import { useActions } from '../../state/runtime'
import { creatureMaxLevel, creatureOptions, formNumbers, maxPoolTraits, poolTraitOptions, rarityOptions, type Strength } from '../../state/selectors'
import { DevMessage, toOutcome, type DevOutcome } from './DevMessage'

interface TraitPick {
  /** '' means no trait in this slot. */
  traitId: string
  strength: Strength | ''
}

const NONE: TraitPick = { traitId: '', strength: '' }
const titleCase = (s: string): string => `${s[0]!.toUpperCase()}${s.slice(1)}`

/**
 * Plan 7.1's grant creature. Everything is the tester's pick and nothing is rolled: species or hybrid, rarity, level,
 * form (stored on the creature, so any form at any level is allowed), an optional shiny flag, and up to
 * `maxPoolTraits` pool traits each at a strength that trait allows. The sim validates all of it again.
 */
export function DevGrantCreature() {
  const actions = useActions()
  const [speciesId, setSpeciesId] = useState(creatureOptions[0]!.id)
  const [rarityTier, setRarityTier] = useState(1)
  const [level, setLevel] = useState('1')
  const [form, setForm] = useState(1)
  const [shiny, setShiny] = useState(false)
  const [picks, setPicks] = useState<TraitPick[]>(() => Array.from({ length: maxPoolTraits }, () => NONE))
  const [outcome, setOutcome] = useState<DevOutcome>(null)

  const setPick = (slot: number, next: TraitPick): void => setPicks((all) => all.map((p, i) => (i === slot ? next : p)))

  const chooseTrait = (slot: number, traitId: string): void => {
    const option = poolTraitOptions.find((t) => t.id === traitId)
    // Keep the strength if the new trait allows it, else fall to its lowest allowed one.
    const current = picks[slot]!.strength
    const strength = option ? (current && option.allowedStrengths.includes(current) ? current : option.allowedStrengths[0]!) : ''
    setPick(slot, { traitId, strength })
  }

  const grant = (): void => {
    const chosen = picks.filter((p) => p.traitId !== '')
    setOutcome(toOutcome(actions.grantCreature({ speciesId, rarityTier, level, form, shiny, poolTraits: chosen.map((p) => ({ traitId: p.traitId, strength: p.strength })) })))
  }

  return (
    <div className="dev-control">
      <h3>Grant creature</h3>
      <p className="small muted">
        Adds a benched creature exactly as picked; nothing is rolled. Form is stored separately from level, so any form at
        any level is allowed.
      </p>
      <div className="dev-row">
        <label className="field wide">
          <span className="small muted">Species or hybrid</span>
          <select value={speciesId} onChange={(e) => setSpeciesId(e.target.value)}>
            <optgroup label="Species">
              {creatureOptions
                .filter((o) => !o.isHybrid)
                .map((o) => (
                  <option key={o.id} value={o.id}>
                    {o.name} ({o.typeNames.join(' / ')})
                  </option>
                ))}
            </optgroup>
            <optgroup label="Hybrids">
              {creatureOptions
                .filter((o) => o.isHybrid)
                .map((o) => (
                  <option key={o.id} value={o.id}>
                    {o.name} ({o.typeNames.join(' / ')})
                  </option>
                ))}
            </optgroup>
          </select>
        </label>
        <label className="field">
          <span className="small muted">Rarity</span>
          <select value={rarityTier} onChange={(e) => setRarityTier(Number(e.target.value))}>
            {rarityOptions.map((r) => (
              <option key={r.tier} value={r.tier}>
                {r.tier}. {r.name}
              </option>
            ))}
          </select>
        </label>
      </div>
      <div className="dev-row">
        <label className="field">
          <span className="small muted">Level (1 to {creatureMaxLevel})</span>
          <input className="dev-input" type="text" inputMode="numeric" value={level} onChange={(e) => setLevel(e.target.value)} />
        </label>
        <label className="field">
          <span className="small muted">Form</span>
          <select value={form} onChange={(e) => setForm(Number(e.target.value))}>
            {formNumbers.map((f) => (
              <option key={f} value={f}>
                Form {f}
              </option>
            ))}
          </select>
        </label>
        <label className="check">
          <input type="checkbox" checked={shiny} onChange={(e) => setShiny(e.target.checked)} />
          <span>Shiny</span>
        </label>
      </div>

      <fieldset className="dev-traits">
        <legend className="small muted">Pool traits (up to {maxPoolTraits}, no duplicates)</legend>
        {picks.map((pick, slot) => {
          const option = poolTraitOptions.find((t) => t.id === pick.traitId)
          return (
            <div className="dev-row" key={slot}>
              <label className="field">
                <span className="small muted">Trait {slot + 1}</span>
                <select value={pick.traitId} onChange={(e) => chooseTrait(slot, e.target.value)}>
                  <option value="">None</option>
                  {poolTraitOptions.map((t) => (
                    <option key={t.id} value={t.id} disabled={t.id !== pick.traitId && picks.some((p) => p.traitId === t.id)}>
                      {t.name}
                    </option>
                  ))}
                </select>
              </label>
              <label className="field">
                <span className="small muted">Strength</span>
                <select value={pick.strength} disabled={!option} onChange={(e) => setPick(slot, { ...pick, strength: e.target.value as Strength })}>
                  {option ? option.allowedStrengths.map((s) => <option key={s} value={s}>{titleCase(s)}</option>) : <option value="">-</option>}
                </select>
              </label>
            </div>
          )
        })}
      </fieldset>

      <div className="dev-row">
        <button type="button" onClick={grant}>
          Grant creature
        </button>
      </div>
      <DevMessage outcome={outcome} />
    </div>
  )
}
