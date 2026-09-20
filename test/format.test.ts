import { describe, expect, it } from 'vitest'
import { formatCount, formatDuration, formatGain, formatSeconds } from '../src/ui/format'

// Display only: nothing here may round a number up, or the UI would promise more than the game granted.

describe('formatDuration', () => {
  const S = 1000
  const M = 60 * S
  const H = 60 * M
  const D = 24 * H

  it('uses the two largest units that matter, and drops a zero remainder', () => {
    expect(formatDuration(45 * S)).toBe('45 s')
    expect(formatDuration(M)).toBe('1 m')
    expect(formatDuration(7 * M + 20 * S)).toBe('7 m 20 s')
    expect(formatDuration(H)).toBe('1 h')
    expect(formatDuration(12 * H + 30 * M)).toBe('12 h 30 m')
    expect(formatDuration(20 * H)).toBe('20 h')
    expect(formatDuration(D)).toBe('1 d')
    expect(formatDuration(3 * D + 4 * H + 30 * M)).toBe('3 d 4 h') // minutes are below the two units shown
    expect(formatDuration(100 * H)).toBe('4 d 4 h')
  })

  it('rounds down, so it never claims more time than passed', () => {
    expect(formatDuration(H + 59 * S)).toBe('1 h')
    expect(formatDuration(2 * M - 1)).toBe('1 m 59 s')
    expect(formatDuration(999)).toBe('0 s')
  })

  it('never shows negative time', () => {
    expect(formatDuration(-5 * H)).toBe('0 s')
    expect(formatDuration(0)).toBe('0 s')
  })
})

describe('the other display helpers', () => {
  it('formats counts, gains and seconds', () => {
    expect(formatCount(12345)).toBe('12,345')
    expect(formatCount(9.9)).toBe('9') // floors, never rounds up
    expect(formatGain(1500)).toBe('+1,500')
    expect(formatGain(0)).toBe('+0')
    expect(formatSeconds(3000)).toBe('3.0 s')
  })
})
