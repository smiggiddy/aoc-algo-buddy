import { useState, useEffect, useMemo } from 'react'
import { Link, useParams, useNavigate } from 'react-router-dom'
import { COMPARISON_GROUPS, getComparisonGroup } from '../data/comparisonGroups'
import './Compare.css'

const API_URL = import.meta.env.VITE_API_URL || ''

function Compare() {
  const { ids } = useParams()
  const navigate = useNavigate()
  const [algorithms, setAlgorithms] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [selectedIds, setSelectedIds] = useState([])

  // Parse URL parameter
  useEffect(() => {
    if (ids) {
      setSelectedIds(ids.split(',').filter(Boolean))
    }
  }, [ids])

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

  const selectedAlgorithms = useMemo(() =>
    selectedIds
      .map(id => algorithms.find(a => a.id === id))
      .filter(Boolean),
    [algorithms, selectedIds]
  )

  const preDefinedGroup = useMemo(() => {
    if (selectedIds.length < 2) return null
    return COMPARISON_GROUPS.find(group =>
      selectedIds.every(id => group.algorithms.includes(id)) &&
      group.algorithms.every(id => selectedIds.includes(id))
    )
  }, [selectedIds])

  const handleAlgorithmToggle = (algoId) => {
    setSelectedIds(prev => {
      let newIds
      if (prev.includes(algoId)) {
        newIds = prev.filter(id => id !== algoId)
      } else if (prev.length >= 4) {
        return prev // Max 4 algorithms
      } else {
        newIds = [...prev, algoId]
      }
      // Update URL
      if (newIds.length > 0) {
        navigate(`/compare/${newIds.join(',')}`, { replace: true })
      } else {
        navigate('/compare', { replace: true })
      }
      return newIds
    })
  }

  const handleQuickCompare = (group) => {
    navigate(`/compare/${group.algorithms.join(',')}`)
  }

  const clearSelection = () => {
    setSelectedIds([])
    navigate('/compare', { replace: true })
  }

  if (loading) {
    return <div className="loading">Loading algorithms...</div>
  }

  if (error) {
    return <div className="error">Error: {error}</div>
  }

  return (
    <div className="compare-page">
      <div className="compare-header">
        <h1>Compare Algorithms</h1>
        <p className="compare-subtitle">
          Select algorithms to compare side-by-side, or choose a quick comparison below
        </p>
      </div>

      <section className="quick-compare-section">
        <h2>Quick Comparisons</h2>
        <div className="quick-compare-grid">
          {COMPARISON_GROUPS.map(group => (
            <button
              key={group.id}
              className={`quick-compare-card ${preDefinedGroup?.id === group.id ? 'active' : ''}`}
              onClick={() => handleQuickCompare(group)}
            >
              <h3>{group.name}</h3>
              <p>{group.description}</p>
              <div className="quick-compare-algos">
                {group.algorithms.map(id => (
                  <span key={id} className="algo-chip">{id}</span>
                ))}
              </div>
            </button>
          ))}
        </div>
      </section>

      <section className="custom-compare-section">
        <div className="custom-compare-header">
          <h2>Custom Comparison</h2>
          {selectedIds.length > 0 && (
            <button className="clear-selection-btn" onClick={clearSelection}>
              Clear Selection
            </button>
          )}
        </div>
        <p className="selection-info">
          Select up to 4 algorithms ({selectedIds.length}/4 selected)
        </p>
        <div className="algorithm-selector">
          {algorithms.map(algo => (
            <button
              key={algo.id}
              className={`selector-chip ${selectedIds.includes(algo.id) ? 'selected' : ''}`}
              onClick={() => handleAlgorithmToggle(algo.id)}
              disabled={!selectedIds.includes(algo.id) && selectedIds.length >= 4}
            >
              {algo.name}
            </button>
          ))}
        </div>
      </section>

      {selectedAlgorithms.length >= 2 && (
        <section className="comparison-section">
          <h2>Comparison</h2>

          {preDefinedGroup && preDefinedGroup.keyDifferences && (
            <div className="key-differences">
              <h3>Key Differences</h3>
              <div className="differences-table">
                <div className="diff-header">
                  <div className="diff-cell aspect-cell">Aspect</div>
                  {selectedAlgorithms.map(algo => (
                    <div key={algo.id} className="diff-cell algo-header">
                      <Link to={`/algorithm/${algo.id}`}>{algo.name}</Link>
                    </div>
                  ))}
                </div>
                {preDefinedGroup.keyDifferences.map((diff, i) => (
                  <div key={i} className="diff-row">
                    <div className="diff-cell aspect-cell">{diff.aspect}</div>
                    {selectedAlgorithms.map(algo => (
                      <div key={algo.id} className="diff-cell">
                        {diff[algo.id] || '-'}
                      </div>
                    ))}
                  </div>
                ))}
              </div>
            </div>
          )}

          <div className="comparison-table">
            <div className="comparison-header-row">
              <div className="comparison-cell label-cell">Attribute</div>
              {selectedAlgorithms.map(algo => (
                <div key={algo.id} className="comparison-cell algo-name-cell">
                  <Link to={`/algorithm/${algo.id}`}>{algo.name}</Link>
                </div>
              ))}
            </div>

            <ComparisonRow
              label="Category"
              values={selectedAlgorithms.map(a => a.category)}
            />
            <ComparisonRow
              label="Difficulty"
              values={selectedAlgorithms.map(a => a.difficulty)}
              type="difficulty"
            />
            <ComparisonRow
              label="Time Complexity"
              values={selectedAlgorithms.map(a => a.complexity?.time)}
            />
            <ComparisonRow
              label="Space Complexity"
              values={selectedAlgorithms.map(a => a.complexity?.space)}
            />
            <ComparisonRow
              label="Key Insight"
              values={selectedAlgorithms.map(a => a.keyInsight)}
              type="text"
            />
            <ComparisonRow
              label="When to Use"
              values={selectedAlgorithms.map(a => a.whenToUse)}
              type="list"
            />
            <ComparisonRow
              label="Common Pitfalls"
              values={selectedAlgorithms.map(a => a.commonPitfalls)}
              type="list"
            />
            <ComparisonRow
              label="Prerequisites"
              values={selectedAlgorithms.map(a => a.prerequisites)}
              type="links"
            />
          </div>

          <div className="pseudo-code-comparison">
            <h3>Pseudo Code Comparison</h3>
            <div className="code-grid">
              {selectedAlgorithms.map(algo => (
                <div key={algo.id} className="code-column">
                  <h4>{algo.name}</h4>
                  <pre className="compare-code">{algo.pseudoCode}</pre>
                </div>
              ))}
            </div>
          </div>
        </section>
      )}

      {selectedAlgorithms.length === 1 && (
        <div className="single-selection-msg">
          Select at least one more algorithm to compare
        </div>
      )}
    </div>
  )
}

function ComparisonRow({ label, values, type = 'text' }) {
  const renderValue = (value, index) => {
    if (value === undefined || value === null) return <span className="no-value">-</span>

    switch (type) {
      case 'difficulty':
        return (
          <span className={`difficulty-badge difficulty-${value.toLowerCase()}`}>
            {value}
          </span>
        )
      case 'list':
        if (!Array.isArray(value) || value.length === 0) return <span className="no-value">-</span>
        return (
          <ul className="compare-list">
            {value.slice(0, 3).map((item, i) => (
              <li key={i}>{item}</li>
            ))}
            {value.length > 3 && <li className="more-items">+{value.length - 3} more</li>}
          </ul>
        )
      case 'links':
        if (!Array.isArray(value) || value.length === 0) return <span className="no-value">None</span>
        return (
          <div className="compare-links">
            {value.map((id, i) => (
              <Link key={i} to={`/algorithm/${id}`} className="prereq-link">
                {id}
              </Link>
            ))}
          </div>
        )
      default:
        return <span>{value}</span>
    }
  }

  return (
    <div className="comparison-row">
      <div className="comparison-cell label-cell">{label}</div>
      {values.map((value, i) => (
        <div key={i} className="comparison-cell">
          {renderValue(value, i)}
        </div>
      ))}
    </div>
  )
}

export default Compare
