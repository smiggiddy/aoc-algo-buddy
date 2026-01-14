import { useState, useEffect, useMemo } from 'react'
import { Link } from 'react-router-dom'
import { useSettings } from '../context/SettingsContext'
import './Dashboard.css'

const API_URL = import.meta.env.VITE_API_URL || ''

function Dashboard() {
  const [algorithms, setAlgorithms] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const {
    favorites,
    learnedAlgorithms,
    isLearned,
    toggleLearned,
    recentlyViewed
  } = useSettings()

  useEffect(() => {
    const fetchAlgorithms = async () => {
      try {
        const res = await fetch(`${API_URL}/api/algorithms`)
        if (!res.ok) throw new Error('Failed to fetch algorithms')
        const data = await res.json()
        setAlgorithms(data)
        setLoading(false)
      } catch (err) {
        setError(err.message)
        setLoading(false)
      }
    }
    fetchAlgorithms()
  }, [])

  const learnedIds = useMemo(() =>
    new Set(learnedAlgorithms.map(item => item.id)),
    [learnedAlgorithms]
  )

  const stats = useMemo(() => {
    const total = algorithms.length
    const learned = learnedAlgorithms.length
    const favorited = favorites.length
    const percentage = total > 0 ? Math.round((learned / total) * 100) : 0
    return { total, learned, favorited, percentage }
  }, [algorithms.length, learnedAlgorithms.length, favorites.length])

  const suggestedNext = useMemo(() => {
    if (algorithms.length === 0) return []

    return algorithms
      .filter(algo => !learnedIds.has(algo.id))
      .filter(algo => {
        // All prerequisites must be learned (or no prerequisites)
        if (!algo.prerequisites || algo.prerequisites.length === 0) return true
        return algo.prerequisites.every(prereq => learnedIds.has(prereq))
      })
      .sort((a, b) => {
        // Prioritize: favorited > beginner difficulty
        const aFav = favorites.includes(a.id) ? -1 : 0
        const bFav = favorites.includes(b.id) ? -1 : 0
        if (aFav !== bFav) return aFav - bFav

        const difficultyOrder = { 'Beginner': 0, 'Intermediate': 1, 'Advanced': 2 }
        return (difficultyOrder[a.difficulty] || 1) - (difficultyOrder[b.difficulty] || 1)
      })
      .slice(0, 5)
  }, [algorithms, learnedIds, favorites])

  const categoryProgress = useMemo(() => {
    const progress = {}
    algorithms.forEach(algo => {
      if (!progress[algo.category]) {
        progress[algo.category] = { total: 0, learned: 0 }
      }
      progress[algo.category].total++
      if (learnedIds.has(algo.id)) {
        progress[algo.category].learned++
      }
    })
    return Object.entries(progress)
      .sort(([a], [b]) => a.localeCompare(b))
  }, [algorithms, learnedIds])

  const recentlyLearned = useMemo(() => {
    return learnedAlgorithms
      .sort((a, b) => new Date(b.learnedAt) - new Date(a.learnedAt))
      .slice(0, 5)
      .map(item => {
        const algo = algorithms.find(a => a.id === item.id)
        return algo ? { ...algo, learnedAt: item.learnedAt } : null
      })
      .filter(Boolean)
  }, [learnedAlgorithms, algorithms])

  if (loading) {
    return <div className="loading">Loading dashboard...</div>
  }

  if (error) {
    return <div className="error">Error: {error}</div>
  }

  return (
    <div className="dashboard">
      <div className="dashboard-header">
        <h1>Your Learning Dashboard</h1>
        <p className="dashboard-subtitle">Track your algorithm mastery progress</p>
      </div>

      <section className="stats-section">
        <div className="stat-card">
          <span className="stat-value">{stats.learned}</span>
          <span className="stat-label">Algorithms Learned</span>
        </div>
        <div className="stat-card">
          <span className="stat-value">{stats.favorited}</span>
          <span className="stat-label">Favorited</span>
        </div>
        <div className="stat-card">
          <span className="stat-value">{stats.percentage}%</span>
          <span className="stat-label">Overall Progress</span>
        </div>
        <div className="stat-card">
          <span className="stat-value">{stats.total}</span>
          <span className="stat-label">Total Algorithms</span>
        </div>
      </section>

      <div className="dashboard-grid">
        <section className="dashboard-section suggested-section">
          <h2>Suggested Next</h2>
          <p className="section-subtitle">Based on prerequisites you've completed</p>
          {suggestedNext.length === 0 ? (
            <p className="empty-state">
              {learnedAlgorithms.length === algorithms.length
                ? 'Congratulations! You have learned all algorithms!'
                : 'Start learning algorithms to get personalized suggestions.'}
            </p>
          ) : (
            <div className="suggestion-list">
              {suggestedNext.map(algo => (
                <div key={algo.id} className="suggestion-card">
                  <div className="suggestion-info">
                    <Link to={`/algorithm/${algo.id}`} className="suggestion-name">
                      {algo.name}
                    </Link>
                    <span className={`difficulty difficulty-${algo.difficulty.toLowerCase()}`}>
                      {algo.difficulty}
                    </span>
                  </div>
                  <p className="suggestion-desc">{algo.description}</p>
                  {algo.prerequisites && algo.prerequisites.length > 0 && (
                    <div className="prereq-info">
                      Prerequisites completed: {algo.prerequisites.join(', ')}
                    </div>
                  )}
                  <button
                    className="learn-btn"
                    onClick={() => toggleLearned(algo.id)}
                  >
                    Mark as Learned
                  </button>
                </div>
              ))}
            </div>
          )}
        </section>

        <section className="dashboard-section progress-section">
          <h2>Progress by Category</h2>
          <div className="category-progress-list">
            {categoryProgress.map(([category, { total, learned }]) => {
              const percent = Math.round((learned / total) * 100)
              return (
                <div key={category} className="progress-row">
                  <div className="progress-info">
                    <span className="progress-category">{category}</span>
                    <span className="progress-count">{learned}/{total}</span>
                  </div>
                  <div className="progress-bar">
                    <div
                      className="progress-fill"
                      style={{ width: `${percent}%` }}
                    />
                  </div>
                </div>
              )
            })}
          </div>
        </section>

        {recentlyLearned.length > 0 && (
          <section className="dashboard-section learned-section">
            <h2>Recently Learned</h2>
            <div className="learned-list">
              {recentlyLearned.map(algo => (
                <Link
                  key={algo.id}
                  to={`/algorithm/${algo.id}`}
                  className="learned-item"
                >
                  <span className="learned-check">&#10003;</span>
                  <span className="learned-name">{algo.name}</span>
                  <span className="learned-date">
                    {new Date(algo.learnedAt).toLocaleDateString()}
                  </span>
                </Link>
              ))}
            </div>
          </section>
        )}

        {recentlyViewed.length > 0 && (
          <section className="dashboard-section viewed-section">
            <h2>Recently Viewed</h2>
            <div className="viewed-list">
              {recentlyViewed.slice(0, 5).map(item => (
                <Link
                  key={item.id}
                  to={`/algorithm/${item.id}`}
                  className="viewed-item"
                >
                  <span className="viewed-name">{item.name}</span>
                  {isLearned(item.id) && (
                    <span className="learned-badge">Learned</span>
                  )}
                </Link>
              ))}
            </div>
          </section>
        )}
      </div>
    </div>
  )
}

export default Dashboard
