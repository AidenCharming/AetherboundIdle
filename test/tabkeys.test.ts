import { describe, expect, it } from 'vitest'
import { nextTabIndex } from '../src/ui/tabKeys'

describe('nextTabIndex (keyboard movement in the tab bar)', () => {
  it('Right and Left step to the neighbour and wrap round the ends', () => {
    expect(nextTabIndex('ArrowRight', 0, 4)).toBe(1)
    expect(nextTabIndex('ArrowRight', 2, 4)).toBe(3)
    expect(nextTabIndex('ArrowRight', 3, 4)).toBe(0)
    expect(nextTabIndex('ArrowLeft', 3, 4)).toBe(2)
    expect(nextTabIndex('ArrowLeft', 1, 4)).toBe(0)
    expect(nextTabIndex('ArrowLeft', 0, 4)).toBe(3)
  })

  it('Home goes to the first tab and End to the last, from anywhere', () => {
    for (let from = 0; from < 5; from++) {
      expect(nextTabIndex('Home', from, 5)).toBe(0)
      expect(nextTabIndex('End', from, 5)).toBe(4)
    }
  })

  it('a single tab stays put on every key it handles', () => {
    for (const key of ['ArrowRight', 'ArrowLeft', 'Home', 'End']) expect(nextTabIndex(key, 0, 1)).toBe(0)
  })

  it('leaves every other key to the browser (Tab, Enter, Space, Up, Down, letters)', () => {
    for (const key of ['Tab', 'Enter', ' ', 'ArrowUp', 'ArrowDown', 'Escape', 'a', 'PageDown']) expect(nextTabIndex(key, 1, 4), key).toBeNull()
  })

  it('handles nothing when the focused element is not one of the tabs, or there are none', () => {
    expect(nextTabIndex('ArrowRight', -1, 4)).toBeNull()
    expect(nextTabIndex('ArrowRight', 4, 4)).toBeNull()
    expect(nextTabIndex('ArrowRight', 0, 0)).toBeNull()
  })
})
