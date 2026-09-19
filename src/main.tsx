import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { App } from './App'
import { bootGame } from './state/runtime'

// The game boots, and its tick driver starts, here and not inside a component: StrictMode runs effects twice in
// development, and a driver started from one would step the sim at double speed.
bootGame()

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
