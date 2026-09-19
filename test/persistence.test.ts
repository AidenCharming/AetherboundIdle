import { describe, expect, it } from 'vitest'
import { content } from '../src/data'
import { createRng } from '../src/sim/rng'
import { parseSave } from '../src/sim/save'
import { createInitialState } from '../src/sim/state'
import { brokenSaveKey, commitRoll, flushSave, loadGame, SAVE_KEY } from '../src/state/persistence'
import type { GameState } from '../src/types/state'
import { addCreature, HOUR, MemoryStorage, NOW, sproutletAtWork } from './helpers'

const stored = (storage: MemoryStorage): GameState => {
  const r = parseSave(storage.data.get(SAVE_KEY)!)
  if (!r.ok) throw new Error(`the stored save does not load: ${r.reason}: ${r.message}`)
  return r.state
}

describe('flushSave', () => {
  it('writes { version, state } under the one save key, stamping lastSeen = now', () => {
    const storage = new MemoryStorage()
    const s = sproutletAtWork()
    const r = flushSave(storage, s, NOW + 5000)
    expect(r.saved).toBe(true)
    expect(r.state.lastSeen).toBe(NOW + 5000)
    expect([...storage.data.keys()]).toEqual([SAVE_KEY])
    expect(stored(storage)).toEqual(r.state)
  })

  it('reports a failed write instead of throwing, and still returns the state', () => {
    const storage = new MemoryStorage()
    storage.failWrites = true
    const s = sproutletAtWork()
    const r = flushSave(storage, s, NOW)
    expect(r.saved).toBe(false)
    expect(r.state.creatures).toEqual(s.creatures)
  })

  it('does not stamp a non-finite clock into the save', () => {
    const storage = new MemoryStorage()
    const r = flushSave(storage, sproutletAtWork(), NaN)
    expect(r.state.lastSeen).toBe(NOW)
    expect(stored(storage).lastSeen).toBe(NOW)
  })
})

describe('loadGame', () => {
  it('starts a new game from the seed when there is no save, and writes it at once', () => {
    const storage = new MemoryStorage()
    const out = loadGame(storage, NOW, 31337)
    expect(out).toMatchObject({ isNewGame: true, summary: null, notice: null, migratedFrom: null, events: [] })
    expect(out.state).toEqual(createInitialState(31337, NOW))
    expect(stored(storage)).toEqual(out.state)
  })

  it('a storage that cannot be read starts a new game rather than throwing', () => {
    const storage = new MemoryStorage()
    storage.failReads = true
    expect(loadGame(storage, NOW, 1).isNewGame).toBe(true)
  })

  it('catches up offline progress from lastSeen and writes the result back', () => {
    const storage = new MemoryStorage()
    const s = addCreature(sproutletAtWork(), 'sproutlet', { rarityTier: 3 }).state
    flushSave(storage, s, NOW)

    const out = loadGame(storage, NOW + 2 * HOUR, 999)
    expect(out.isNewGame).toBe(false)
    expect(out.notice).toBeNull()
    expect(out.summary).toMatchObject({ requestedMs: 2 * HOUR, elapsedMs: 2 * HOUR, capped: false, clockSkewed: false })
    expect(out.summary!.skills[0]).toMatchObject({ skillId: 'woodcutting', actions: 2400 })
    expect(out.summary!.aetherGained).toBeCloseTo(4 * 120)
    expect(out.state.lastSeen).toBe(NOW + 2 * HOUR)
    expect(stored(storage)).toEqual(out.state) // written back, so a second load is not double-counted
  })

  it('loading twice in a row grants the offline time once', () => {
    const storage = new MemoryStorage()
    flushSave(storage, sproutletAtWork(), NOW)
    const first = loadGame(storage, NOW + HOUR, 1)
    const second = loadGame(storage, NOW + HOUR, 1)
    expect(first.summary!.elapsedMs).toBe(HOUR)
    expect(second.summary!.elapsedMs).toBe(0)
    expect(second.state).toEqual(first.state)
  })

  it('a clock that went backwards grants nothing and rewrites lastSeen', () => {
    const storage = new MemoryStorage()
    const s = sproutletAtWork()
    flushSave(storage, s, NOW)
    const out = loadGame(storage, NOW - 3 * HOUR, 1)
    expect(out.summary).toMatchObject({ clockSkewed: true, elapsedMs: 0 })
    expect(out.state).toEqual({ ...s, lastSeen: NOW - 3 * HOUR })
    expect(stored(storage).lastSeen).toBe(NOW - 3 * HOUR)
  })

  it('the offline window is capped at capHours', () => {
    const storage = new MemoryStorage()
    flushSave(storage, sproutletAtWork(), NOW)
    expect(loadGame(storage, NOW + 200 * HOUR, 1).summary).toMatchObject({ elapsedMs: 12 * HOUR, capped: true })
  })
})

describe('a save that cannot be loaded is quarantined, not discarded', () => {
  const brokenTexts: [string, string][] = [
    ['corrupt JSON', '{"version":1,"state":{'],
    ['a state that fails validation', JSON.stringify({ version: 1, state: { nope: true } })],
    ['a save from a newer build', JSON.stringify({ version: 99, state: {} })],
  ]
  for (const [label, raw] of brokenTexts) {
    it(`${label}: the raw text is copied to save-broken-<timestamp>, a fresh game starts, and the player is told`, () => {
      const storage = new MemoryStorage()
      storage.data.set(SAVE_KEY, raw)
      const out = loadGame(storage, NOW, 555)

      expect(storage.data.get(brokenSaveKey(NOW))).toBe(raw) // byte-for-byte
      expect(brokenSaveKey(NOW)).toBe(`aetherbound-idle:save-broken-${NOW}`)
      expect(out.isNewGame).toBe(true)
      expect(out.state).toEqual(createInitialState(555, NOW))
      expect(out.notice).toMatchObject({ kind: 'quarantined', brokenKey: brokenSaveKey(NOW) })
      expect(out.notice!.message.length).toBeGreaterThan(0)
      expect(stored(storage)).toEqual(out.state) // the live slot now holds a valid fresh save
    })
  }

  it('reports which failure it was', () => {
    const reasonOf = (raw: string) => {
      const storage = new MemoryStorage()
      storage.data.set(SAVE_KEY, raw)
      return loadGame(storage, NOW, 1).notice!.reason
    }
    expect(reasonOf('nope')).toBe('corrupt')
    expect(reasonOf(JSON.stringify({ version: 1, state: {} }))).toBe('invalid')
    expect(reasonOf(JSON.stringify({ version: 99, state: {} }))).toBe('too-new')
  })

  it('after quarantining, the next load is a normal one with no notice', () => {
    const storage = new MemoryStorage()
    storage.data.set(SAVE_KEY, 'garbage')
    loadGame(storage, NOW, 1)
    const again = loadGame(storage, NOW + HOUR, 1)
    expect(again.notice).toBeNull()
    expect(again.isNewGame).toBe(false)
  })

  it('still reports a notice when the quarantine copy itself cannot be written', () => {
    const storage = new MemoryStorage()
    storage.data.set(SAVE_KEY, 'garbage')
    const realSet = storage.setItem.bind(storage)
    storage.setItem = (k, v) => {
      if (k.includes('save-broken')) throw new Error('quota')
      realSet(k, v)
    }
    expect(loadGame(storage, NOW, 1).notice).toMatchObject({ kind: 'quarantined' })
  })
})

describe('commitRoll: outcome-committing rolls flush the advanced RNG state at once (plan 4.6)', () => {
  /** A stand-in for breed / hatch / capture: consumes the persisted RNG and returns what it rolled. */
  const roll = (s: GameState) => {
    const rng = createRng(s.rngState)
    const result = rng.next()
    return { state: { ...s, rngState: rng.state }, result }
  }

  it('writes the result and the advanced RNG state in one flush, with no autosave in between', () => {
    const storage = new MemoryStorage()
    const s = sproutletAtWork(content, 20260919)
    flushSave(storage, s, NOW)
    const before = stored(storage).rngState

    const r = commitRoll(storage, s, roll, NOW + 1000)
    expect(r.saved).toBe(true)
    expect(stored(storage).rngState).toBe(r.state.rngState) // already on disk
    expect(stored(storage).rngState).not.toBe(before)
  })

  it('a reload right after the roll continues the stream: it cannot re-roll the same outcome', () => {
    const storage = new MemoryStorage()
    const s = sproutletAtWork(content, 20260919)
    const committed = commitRoll(storage, s, roll, NOW)

    const reloaded = loadGame(storage, NOW, 1).state // quit and reopen at once
    const nextAfterReload = roll(reloaded).result
    const nextLive = roll(committed.state).result

    expect(nextAfterReload).toBe(nextLive) // exactly what the live game would have rolled next
    expect(nextAfterReload).not.toBe(committed.result) // and NOT the outcome that was just committed
  })

  it('the failure it prevents: a save that only kept the initial seed replays the same outcome after reload', () => {
    const s = sproutletAtWork(content, 20260919)
    const first = roll(s).result
    const seedOnly = { ...s } // reload restores the seed, not the advanced state
    expect(roll(seedOnly).result).toBe(first)
  })

  it('reports a failed write, and still hands back the rolled state', () => {
    const storage = new MemoryStorage()
    storage.failWrites = true
    const s = sproutletAtWork(content, 5)
    const r = commitRoll(storage, s, roll, NOW)
    expect(r.saved).toBe(false)
    expect(r.state.rngState).not.toBe(s.rngState)
  })

  it('roll -> commit -> reload -> roll matches an uninterrupted run of the same rolls', () => {
    const storage = new MemoryStorage()
    let live = sproutletAtWork(content, 8080)
    const uninterrupted: number[] = []
    for (let i = 0; i < 6; i++) {
      const r = roll(live)
      uninterrupted.push(r.result)
      live = r.state
    }

    let s = sproutletAtWork(content, 8080)
    const withReloads: number[] = []
    for (let i = 0; i < 6; i++) {
      const r = commitRoll(storage, s, roll, NOW)
      withReloads.push(r.result)
      s = loadGame(storage, NOW, 1).state // reload between every roll
    }
    expect(withReloads).toEqual(uninterrupted)
  })
})
