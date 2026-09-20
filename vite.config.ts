import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  // Relative asset URLs, so the built page loads from file:// inside the desktop wrapper (electron/) as well as from a server.
  base: './',
  plugins: [react()],
})
