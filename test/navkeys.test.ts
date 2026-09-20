import { describe, expect, it } from 'vitest'
import { nextNavIndex } from '../src/ui/navKeys'

describe('nextNavIndex (keyboard movement in the sidebar nav)', () => {
  it('Down and Up step to the neighbour and wrap round the ends', () => {
    expect(nextNavIndex('ArrowDown', 0, 5)).toBe(1)
    expect(nextNavIndex('ArrowDown', 3, 5)).toBe(4)
    expect(nextNavIndex('ArrowDown', 4, 5)).toBe(0)
    expect(nextNavIndex('ArrowUp', 4, 5)).toBe(3)
    expect(nextNavIndex('ArrowUp', 1, 5)).toBe(0)
    expect(nextNavIndex('ArrowUp', 0, 5)).toBe(4)
  })

  it('Home goes to the first entry and End to the last, from anywhere', () => {
    for (let from = 0; from < 6; from++) {
      expect(nextNavIndex('Home', from, 6)).toBe(0)
      expect(nextNavIndex('End', from, 6)).toBe(5)
    }
  })

  it('a single entry stays put on every key it handles', () => {
    for (const key of ['ArrowDown', 'ArrowUp', 'Home', 'End']) expect(nextNavIndex(key, 0, 1)).toBe(0)
  })

  it('walks the whole list in order with Down, and back with Up', () => {
    const count = 7
    let at = 0
    const down = [at]
    for (let i = 1; i < count; i++) down.push((at = nextNavIndex('ArrowDown', at, count)!))
    expect(down).toEqual([0, 1, 2, 3, 4, 5, 6])
    const up = [at]
    for (let i = 1; i < count; i++) up.push((at = nextNavIndex('ArrowUp', at, count)!))
    expect(up).toEqual([6, 5, 4, 3, 2, 1, 0])
  })

  it('leaves every other key to the browser, Left and Right included (a vertical list)', () => {
    for (const key of ['Tab', 'Enter', ' ', 'ArrowLeft', 'ArrowRight', 'Escape', 'a', 'PageDown']) expect(nextNavIndex(key, 1, 4), key).toBeNull()
  })

  it('handles nothing when the focused element is not one of the entries, or there are none', () => {
    expect(nextNavIndex('ArrowDown', -1, 4)).toBeNull()
    expect(nextNavIndex('ArrowDown', 4, 4)).toBeNull()
    expect(nextNavIndex('ArrowDown', 0, 0)).toBeNull()
  })
})
