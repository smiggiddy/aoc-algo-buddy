import { useState, useEffect } from 'react'
import { useParams, Link } from 'react-router-dom'
import './AlgorithmDetail.css'

const API_URL = import.meta.env.VITE_API_URL || ''

function AlgorithmDetail() {
  const { id } = useParams()
  const [algorithm, setAlgorithm] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [copied, setCopied] = useState(false)

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

        <button onClick={copyLink} className="share-btn">
          {copied ? 'Copied!' : 'Share Link'}
        </button>
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

        {algorithm.aocExamples && algorithm.aocExamples.length > 0 && (
          <section className="section">
            <h2 className="section-title">Advent of Code Examples</h2>
            <ul className="aoc-examples">
              {algorithm.aocExamples.map((example, i) => (
                <li key={i}>{example}</li>
              ))}
            </ul>
          </section>
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
