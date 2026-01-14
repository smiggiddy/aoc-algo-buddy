import { useState, useMemo } from 'react'
import { Link } from 'react-router-dom'
import './AlgorithmOfDay.css'

const STORAGE_KEY = 'aoc-aotd-dismissed'

// Deterministic selection based on date - same for all users
function getDailyAlgorithm(algorithms, date) {
  if (!algorithms || algorithms.length === 0) return null

  // Use date string as seed for consistent selection
  const dateStr = date.toISOString().split('T')[0] // "2026-01-14"
  const seed = dateStr.split('-').join('') // "20260114"

  // Simple hash to get a pseudo-random but deterministic index
  let hash = 0
  for (let i = 0; i < seed.length; i++) {
    hash = ((hash << 5) - hash) + seed.charCodeAt(i)
    hash = hash & hash // Convert to 32bit integer
  }

  const index = Math.abs(hash) % algorithms.length
  return algorithms[index]
}

function getTodayString() {
  return new Date().toISOString().split('T')[0]
}

function getInitialDismissedState() {
  const dismissedDate = localStorage.getItem(STORAGE_KEY)
  const today = getTodayString()
  if (dismissedDate === today) {
    return true
  }
  // Clear old dismissal
  localStorage.removeItem(STORAGE_KEY)
  return false
}

function AlgorithmOfDay({ algorithms }) {
  const [dismissed, setDismissed] = useState(getInitialDismissedState)

  // Get today's algorithm using useMemo
  const algorithm = useMemo(() => {
    if (algorithms && algorithms.length > 0) {
      return getDailyAlgorithm(algorithms, new Date())
    }
    return null
  }, [algorithms])

  const handleDismiss = () => {
    localStorage.setItem(STORAGE_KEY, getTodayString())
    setDismissed(true)
  }

  if (dismissed || !algorithm) {
    return null
  }

  return (
    <div className="algorithm-of-day">
      <div className="aotd-header">
        <div className="aotd-badge">
          <span className="aotd-icon">{'\u2728'}</span>
          Algorithm of the Day
        </div>
        <button
          className="aotd-dismiss"
          onClick={handleDismiss}
          title="Dismiss for today"
        >
          &times;
        </button>
      </div>
      <Link to={`/algorithm/${algorithm.id}`} className="aotd-content">
        <h3 className="aotd-title">{algorithm.name}</h3>
        <div className="aotd-meta">
          <span className="aotd-category">{algorithm.category}</span>
          <span className={`aotd-difficulty difficulty-${algorithm.difficulty.toLowerCase()}`}>
            {algorithm.difficulty}
          </span>
        </div>
        <p className="aotd-description">{algorithm.description}</p>
        <span className="aotd-cta">Learn more &rarr;</span>
      </Link>
    </div>
  )
}

export default AlgorithmOfDay
