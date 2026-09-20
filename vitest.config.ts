import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'node',
    // Without this vitest blanks every .css import, including ?raw, and the architecture test could not read theme.css.
    css: { include: [/\.css/] },
    include: ['test/**/*.test.ts'],
  },
})
