import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import Home from './pages/Home'
import './town.css'

const root = document.getElementById('root')

if (!root) {
  throw new Error('MoonTown root element is missing')
}

createRoot(root).render(
  <StrictMode>
    <Home />
  </StrictMode>,
)
