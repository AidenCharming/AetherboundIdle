import { NoticeBanner } from './ui/components/NoticeBanner'
import { TopBar } from './ui/components/TopBar'
import { Skills } from './ui/screens/Skills'
import './ui/theme.css'

// The layout shell. There is one screen until the roster arrives in step 1.7, so no router yet.
export function App() {
  return (
    <div className="app">
      <TopBar />
      <NoticeBanner />
      <main style={{ display: 'contents' }}>
        <Skills />
      </main>
    </div>
  )
}
