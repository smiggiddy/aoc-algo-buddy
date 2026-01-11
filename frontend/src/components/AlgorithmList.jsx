import { useState, useEffect, useMemo } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import './AlgorithmList.css'

const API_URL = import.meta.env.VITE_API_URL || ''

function AlgorithmList() {
  const [algorithms, setAlgorithms] = useState([])
  const [categories, setCategories] = useState([])
  const [tags, setTags] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const [searchParams, setSearchParams] = useSearchParams()
  const search = searchParams.get('search') || ''
  const category = searchParams.get('category') || ''
  const tag = searchParams.get('tag') || ''
  const difficulty = searchParams.get('difficulty') || ''

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [algosRes, catsRes, tagsRes] = await Promise.all([
          fetch(`${API_URL}/api/algorithms`),
          fetch(`${API_URL}/api/categories`),
          fetch(`${API_URL}/api/tags`)
        ])

        if (!algosRes.ok || !catsRes.ok || !tagsRes.ok) {
          throw new Error('Failed to fetch data')
        }

        const [algos, cats, tgs] = await Promise.all([
          algosRes.json(),
          catsRes.json(),
          tagsRes.json()
        ])

        setAlgorithms(algos)
        setCategories(cats.sort())
        setTags(tgs.sort())
        setLoading(false)
      } catch (err) {
        setError(err.message)
        setLoading(false)
      }
    }

    fetchData()
  }, [])

  const filteredAlgorithms = useMemo(() => {
    return algorithms.filter(algo => {
      if (category && algo.category !== category) return false
      if (difficulty && algo.difficulty !== difficulty) return false
      if (tag && !algo.tags.includes(tag)) return false
      if (search) {
        const s = search.toLowerCase()
        const matchName = algo.name.toLowerCase().includes(s)
        const matchDesc = algo.description.toLowerCase().includes(s)
        const matchTags = algo.tags.some(t => t.toLowerCase().includes(s))
        if (!matchName && !matchDesc && !matchTags) return false
      }
      return true
    })
  }, [algorithms, category, difficulty, tag, search])

  const groupedAlgorithms = useMemo(() => {
    const groups = {}
    filteredAlgorithms.forEach(algo => {
      if (!groups[algo.category]) {
        groups[algo.category] = []
      }
      groups[algo.category].push(algo)
    })
    return Object.entries(groups).sort(([a], [b]) => a.localeCompare(b))
  }, [filteredAlgorithms])

  const updateFilter = (key, value) => {
    const params = new URLSearchParams(searchParams)
    if (value) {
      params.set(key, value)
    } else {
      params.delete(key)
    }
    setSearchParams(params)
  }

  const clearFilters = () => {
    setSearchParams({})
  }

  const hasActiveFilters = search || category || tag || difficulty

  if (loading) {
    return <div className="loading">Loading algorithms...</div>
  }

  if (error) {
    return <div className="error">Error: {error}</div>
  }

  return (
    <div className="algorithm-list">
      <div className="filters">
        <div className="search-box">
          <input
            type="text"
            placeholder="Search algorithms..."
            value={search}
            onChange={(e) => updateFilter('search', e.target.value)}
            className="search-input"
          />
        </div>

        <div className="filter-row">
          <select
            value={category}
            onChange={(e) => updateFilter('category', e.target.value)}
            className="filter-select"
          >
            <option value="">All Categories</option>
            {categories.map(cat => (
              <option key={cat} value={cat}>{cat}</option>
            ))}
          </select>

          <select
            value={difficulty}
            onChange={(e) => updateFilter('difficulty', e.target.value)}
            className="filter-select"
          >
            <option value="">All Difficulties</option>
            <option value="Beginner">Beginner</option>
            <option value="Intermediate">Intermediate</option>
            <option value="Advanced">Advanced</option>
          </select>

          <select
            value={tag}
            onChange={(e) => updateFilter('tag', e.target.value)}
            className="filter-select"
          >
            <option value="">All Tags</option>
            {tags.map(t => (
              <option key={t} value={t}>{t}</option>
            ))}
          </select>

          {hasActiveFilters && (
            <button onClick={clearFilters} className="clear-btn">
              Clear Filters
            </button>
          )}
        </div>
      </div>

      <div className="results-info">
        Showing {filteredAlgorithms.length} of {algorithms.length} algorithms
      </div>

      {groupedAlgorithms.length === 0 ? (
        <div className="no-results">
          No algorithms match your filters.
        </div>
      ) : (
        <div className="categories">
          {groupedAlgorithms.map(([categoryName, algos]) => (
            <div key={categoryName} className="category-group">
              <h2 className="category-title">{categoryName}</h2>
              <div className="algorithm-cards">
                {algos.map(algo => (
                  <Link
                    to={`/algorithm/${algo.id}`}
                    key={algo.id}
                    className="algorithm-card"
                  >
                    <div className="card-header">
                      <h3 className="card-title">{algo.name}</h3>
                      <span className={`difficulty difficulty-${algo.difficulty.toLowerCase()}`}>
                        {algo.difficulty}
                      </span>
                    </div>
                    <p className="card-description">{algo.description}</p>
                    <div className="card-tags">
                      {algo.tags.slice(0, 4).map(t => (
                        <span key={t} className="tag">{t}</span>
                      ))}
                    </div>
                  </Link>
                ))}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}

export default AlgorithmList
