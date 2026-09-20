import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  // Relative asset URLs, so the built page loads from file:// inside the desktop wrapper (electron/) as well as from a server.
  base: './',
  plugins: [react()],
  // The dev server must not watch the packaged app: electron-builder writes locked files into release/, and Vite's watcher
  // crashes the server with EBUSY on them (seen in step 1.9b, when the exe was rebuilt while the dev server ran).
  server: { watch: { ignored: ['**/release/**'] } },
})
