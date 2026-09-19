import { describe, expect, it } from 'vitest'

// Toolchain check for step 1.2 only. Replaced by real specs from step 1.3 on.
describe('toolchain', () => {
  it('runs vitest with TypeScript', () => {
    const answer: number = 1 + 1
    expect(answer).toBe(2)
  })
})
