import { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import { useSettings, SPOILER_PREFS } from '../context/SettingsContext'
import './AlgorithmDetail.css'
import SpoilerDialog from './SpoilerDialog'

const API_URL = import.meta.env.VITE_API_URL || ''

function AlgorithmDetail() {
  const { id } = useParams()
  const [algorithm, setAlgorithm] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [copied, setCopied] = useState(false)
  const [showSpoilerDialog, setShowSpoilerDialog] = useState(false)
  const [showAocExamples, setShowAocExamples] = useState(false)
  const { toggleFavorite, isFavorite, spoilerPref } = useSettings()

  useEffect(() => {
    const fetchAlgorithm = async () => {
      try {
        const res = await fetch(`${API_URL}/api/algorithms/${id}`)
        if (!res.ok) {
          throw new Error('Algorithm not found')
        }
        const data = await res.json()
        setAlgorithm(data)
        setLoading(false)
      } catch (err) {
        setError(err.message)
        setLoading(false)
      }
    }

    fetchAlgorithm()
  }, [id])

  const copyLink = async () => {
    try {
      await navigator.clipboard.writeText(window.location.href)
      setCopied(true)
      setTimeout(() => setCopied(false), 2000)
    } catch (err) {
      console.error('Failed to copy:', err)
    }
  }

  if (loading) {
    return <div className="loading">Loading...</div>
  }

  if (error) {
    return (
      <div className="error-page">
        <h2>Algorithm not found</h2>
        <p>The algorithm you're looking for doesn't exist.</p>
        <Link to="/" className="back-link">Back to all algorithms</Link>
      </div>
    )
  }

  return (
    <div className="algorithm-detail">
      <div className="detail-header">
        <Link to="/" className="back-link">
          <span className="back-arrow">&larr;</span> All Algorithms
        </Link>

        <div className="header-actions">
          <button
            onClick={() => toggleFavorite(id)}
            className={`favorite-detail-btn ${isFavorite(id) ? 'active' : ''}`}
            title={isFavorite(id) ? 'Remove from favorites' : 'Add to favorites'}
          >
            {isFavorite(id) ? '\u2605' : '\u2606'}
          </button>
          <button onClick={copyLink} className="share-btn">
            {copied ? 'Copied!' : 'Share Link'}
          </button>
        </div>
      </div>

      <div className="detail-content">
        <div className="title-section">
          <h1 className="detail-title">{algorithm.name}</h1>
          <div className="meta-row">
            <span className="category-badge">{algorithm.category}</span>
            <span className={`difficulty-badge difficulty-${algorithm.difficulty.toLowerCase()}`}>
              {algorithm.difficulty}
            </span>
          </div>
        </div>

        <div className="tags-section">
          {algorithm.tags.map(tag => (
            <Link
              key={tag}
              to={`/?tag=${encodeURIComponent(tag)}`}
              className="tag-link"
            >
              {tag}
            </Link>
          ))}
        </div>

        <section className="section">
          <h2 className="section-title">Description</h2>
          <p className="description">{algorithm.description}</p>
        </section>

        {algorithm.keyInsight && (
          <section className="section key-insight-section">
            <h2 className="section-title">Key Insight</h2>
            <div className="key-insight">
              <span className="insight-icon">💡</span>
              <p>{algorithm.keyInsight}</p>
            </div>
          </section>
        )}

        {algorithm.recognitionHints && algorithm.recognitionHints.length > 0 && (
          <section className="section">
            <h2 className="section-title">How to Recognize</h2>
            <ul className="recognition-hints">
              {algorithm.recognitionHints.map((hint, i) => (
                <li key={i}>{hint}</li>
              ))}
            </ul>
          </section>
        )}

        <section className="section">
          <h2 className="section-title">When to Use</h2>
          <ul className="use-cases">
            {algorithm.whenToUse.map((use, i) => (
              <li key={i}>{use}</li>
            ))}
          </ul>
        </section>

        <section className="section">
          <h2 className="section-title">Pseudo Code</h2>
          <div className="code-block">
            <pre><code>{algorithm.pseudoCode}</code></pre>
          </div>
        </section>

        <section className="section">
          <h2 className="section-title">Complexity</h2>
          <div className="complexity">
            <div className="complexity-item">
              <span className="complexity-label">Time:</span>
              <span className="complexity-value">{algorithm.complexity.time}</span>
            </div>
            <div className="complexity-item">
              <span className="complexity-label">Space:</span>
              <span className="complexity-value">{algorithm.complexity.space}</span>
            </div>
          </div>
        </section>

        {algorithm.commonPitfalls && algorithm.commonPitfalls.length > 0 && (
          <section className="section pitfalls-section">
            <h2 className="section-title">Common Pitfalls</h2>
            <ul className="pitfalls-list">
              {algorithm.commonPitfalls.map((pitfall, i) => (
                <li key={i}>
                  <span className="pitfall-icon">⚠️</span>
                  {pitfall}
                </li>
              ))}
            </ul>
          </section>
        )}

        {algorithm.prerequisites && algorithm.prerequisites.length > 0 && (
          <section className="section">
            <h2 className="section-title">Prerequisites</h2>
            <div className="related-links">
              {algorithm.prerequisites.map((prereq, i) => (
                <Link key={i} to={`/algorithm/${prereq}`} className="related-link">
                  {prereq}
                </Link>
              ))}
            </div>
          </section>
        )}

        {algorithm.relatedAlgos && algorithm.relatedAlgos.length > 0 && (
          <section className="section">
            <h2 className="section-title">Related Algorithms</h2>
            <div className="related-links">
              {algorithm.relatedAlgos.map((related, i) => (
                <Link key={i} to={`/algorithm/${related}`} className="related-link">
                  {related}
                </Link>
              ))}
            </div>
          </section>
        )}

        {algorithm.aocExamples && algorithm.aocExamples.length > 0 && (
          <section className="section">
            <h2 className="section-title">Advent of Code Examples</h2>
            {spoilerPref === SPOILER_PREFS.HIDE ? (
              <p className="spoiler-hidden-msg">Spoilers are hidden. Change in settings to view.</p>
            ) : showAocExamples || spoilerPref === SPOILER_PREFS.SHOW ? (
              <ul className="aoc-examples">
                {algorithm.aocExamples.map((example, i) => (
                  <li key={i}>{example}</li>
                ))}
              </ul>
            ) : (
              <button
                className="spoiler-reveal-btn"
                onClick={() => setShowSpoilerDialog(true)}
              >
                <span className="spoiler-reveal-icon">?</span>
                Click to reveal AoC examples (spoilers)
              </button>
            )}
          </section>
        )}

        {showSpoilerDialog && (
          <SpoilerDialog
            onConfirm={() => {
              setShowAocExamples(true)
              setShowSpoilerDialog(false)
            }}
            onCancel={() => setShowSpoilerDialog(false)}
          />
        )}

        {algorithm.examples && algorithm.examples.length > 0 && (
          <section className="section examples-section">
            <h2 className="section-title">Interactive Examples</h2>
            {algorithm.examples.map((example, i) => (
              <div key={i} className="example-card">
                <h3 className="example-title">{example.title}</h3>
                <p className="example-description">{example.description}</p>

                <div className="example-io">
                  <div className="io-block">
                    <span className="io-label">Input:</span>
                    <pre className="io-content">{example.input}</pre>
                  </div>
                  <div className="io-block">
                    <span className="io-label">Output:</span>
                    <pre className="io-content">{example.output}</pre>
                  </div>
                </div>

                {example.visual && (
                  <div className="visual-block">
                    <span className="visual-label">Visualization:</span>
                    <pre className="visual-content">{example.visual}</pre>
                  </div>
                )}

                {example.steps && example.steps.length > 0 && (
                  <div className="steps-block">
                    <span className="steps-label">Step by Step:</span>
                    <ol className="steps-list">
                      {example.steps.map((step, j) => (
                        <li key={j} className="step-item">
                          <span className="step-desc">{step.description}</span>
                          <code className="step-state">{step.state}</code>
                        </li>
                      ))}
                    </ol>
                  </div>
                )}
              </div>
            ))}
          </section>
        )}

        {algorithm.resources && algorithm.resources.length > 0 && (
          <section className="section">
            <h2 className="section-title">Resources</h2>
            <ul className="resources">
              {algorithm.resources.map((resource, i) => (
                <li key={i}>
                  <a href={resource} target="_blank" rel="noopener noreferrer">
                    {resource}
                  </a>
                </li>
              ))}
            </ul>
          </section>
        )}
      </div>
    </div>
  )
}

export default AlgorithmDetail
