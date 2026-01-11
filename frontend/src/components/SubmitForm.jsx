import { useState, useEffect } from 'react'
import { Link } from 'react-router-dom'
import './SubmitForm.css'

const API_URL = import.meta.env.VITE_API_URL || ''

const CATEGORIES = [
  'Graph',
  'Dynamic Programming',
  'String',
  'Math',
  'Data Structures',
  'Simulation',
  'Geometry',
  'Search',
  'Bit Operations'
]

const DIFFICULTIES = ['Beginner', 'Intermediate', 'Advanced']

function SubmitForm() {
  const [captcha, setCaptcha] = useState(null)
  const [captchaAnswer, setCaptchaAnswer] = useState('')
  const [submittedBy, setSubmittedBy] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [submitted, setSubmitted] = useState(false)
  const [error, setError] = useState(null)

  const [algorithm, setAlgorithm] = useState({
    name: '',
    category: '',
    tags: '',
    difficulty: 'Beginner',
    description: '',
    whenToUse: '',
    pseudoCode: '',
    timeComplexity: '',
    spaceComplexity: '',
    aocExamples: '',
    resources: ''
  })

  useEffect(() => {
    fetchCaptcha()
  }, [])

  const fetchCaptcha = async () => {
    try {
      const res = await fetch(`${API_URL}/api/captcha`)
      const data = await res.json()
      setCaptcha(data)
      setCaptchaAnswer('')
    } catch (err) {
      setError('Failed to load captcha')
    }
  }

  const handleChange = (e) => {
    const { name, value } = e.target
    setAlgorithm(prev => ({ ...prev, [name]: value }))
  }

  const handleSubmit = async (e) => {
    e.preventDefault()
    setError(null)
    setSubmitting(true)

    const payload = {
      captchaId: captcha?.id,
      captchaAnswer: parseInt(captchaAnswer, 10),
      submittedBy: submittedBy || 'Anonymous',
      algorithm: {
        name: algorithm.name,
        category: algorithm.category,
        tags: algorithm.tags.split(',').map(t => t.trim()).filter(Boolean),
        difficulty: algorithm.difficulty,
        description: algorithm.description,
        whenToUse: algorithm.whenToUse.split('\n').filter(Boolean),
        pseudoCode: algorithm.pseudoCode,
        complexity: {
          time: algorithm.timeComplexity,
          space: algorithm.spaceComplexity
        },
        aocExamples: algorithm.aocExamples.split('\n').filter(Boolean),
        resources: algorithm.resources.split('\n').filter(Boolean)
      }
    }

    try {
      const res = await fetch(`${API_URL}/api/submit`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(payload)
      })

      if (!res.ok) {
        const text = await res.text()
        throw new Error(text || 'Submission failed')
      }

      setSubmitted(true)
    } catch (err) {
      setError(err.message)
      fetchCaptcha()
    } finally {
      setSubmitting(false)
    }
  }

  if (submitted) {
    return (
      <div className="submit-success">
        <h2>Thank You!</h2>
        <p>Your algorithm has been submitted for review.</p>
        <p>Once approved by an admin, it will appear in the algorithm list.</p>
        <Link to="/" className="back-btn">Back to Algorithms</Link>
      </div>
    )
  }

  return (
    <div className="submit-form">
      <div className="form-header">
        <Link to="/" className="back-link">
          <span>&larr;</span> Back
        </Link>
        <h1>Submit an Algorithm</h1>
        <p>Contribute to the community by sharing an algorithm. All submissions are reviewed before publishing.</p>
      </div>

      <form onSubmit={handleSubmit}>
        <div className="form-section">
          <h3>Basic Information</h3>

          <div className="form-group">
            <label htmlFor="name">Algorithm Name *</label>
            <input
              type="text"
              id="name"
              name="name"
              value={algorithm.name}
              onChange={handleChange}
              placeholder="e.g., Breadth-First Search (BFS)"
              required
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label htmlFor="category">Category *</label>
              <select
                id="category"
                name="category"
                value={algorithm.category}
                onChange={handleChange}
                required
              >
                <option value="">Select category</option>
                {CATEGORIES.map(cat => (
                  <option key={cat} value={cat}>{cat}</option>
                ))}
              </select>
            </div>

            <div className="form-group">
              <label htmlFor="difficulty">Difficulty *</label>
              <select
                id="difficulty"
                name="difficulty"
                value={algorithm.difficulty}
                onChange={handleChange}
                required
              >
                {DIFFICULTIES.map(diff => (
                  <option key={diff} value={diff}>{diff}</option>
                ))}
              </select>
            </div>
          </div>

          <div className="form-group">
            <label htmlFor="tags">Tags (comma-separated)</label>
            <input
              type="text"
              id="tags"
              name="tags"
              value={algorithm.tags}
              onChange={handleChange}
              placeholder="e.g., traversal, shortest-path, grid"
            />
          </div>
        </div>

        <div className="form-section">
          <h3>Description</h3>

          <div className="form-group">
            <label htmlFor="description">Description *</label>
            <textarea
              id="description"
              name="description"
              value={algorithm.description}
              onChange={handleChange}
              placeholder="Brief explanation of what this algorithm does and how it works..."
              rows={3}
              required
            />
          </div>

          <div className="form-group">
            <label htmlFor="whenToUse">When to Use (one per line)</label>
            <textarea
              id="whenToUse"
              name="whenToUse"
              value={algorithm.whenToUse}
              onChange={handleChange}
              placeholder="Finding shortest paths&#10;Level-order traversal&#10;Flood fill operations"
              rows={4}
            />
          </div>
        </div>

        <div className="form-section">
          <h3>Implementation</h3>

          <div className="form-group">
            <label htmlFor="pseudoCode">Pseudo Code *</label>
            <textarea
              id="pseudoCode"
              name="pseudoCode"
              value={algorithm.pseudoCode}
              onChange={handleChange}
              placeholder="function algorithm(input):&#10;    # Your pseudo code here..."
              rows={12}
              className="code-input"
              required
            />
          </div>

          <div className="form-row">
            <div className="form-group">
              <label htmlFor="timeComplexity">Time Complexity</label>
              <input
                type="text"
                id="timeComplexity"
                name="timeComplexity"
                value={algorithm.timeComplexity}
                onChange={handleChange}
                placeholder="e.g., O(V + E)"
              />
            </div>

            <div className="form-group">
              <label htmlFor="spaceComplexity">Space Complexity</label>
              <input
                type="text"
                id="spaceComplexity"
                name="spaceComplexity"
                value={algorithm.spaceComplexity}
                onChange={handleChange}
                placeholder="e.g., O(V)"
              />
            </div>
          </div>
        </div>

        <div className="form-section">
          <h3>Examples & Resources</h3>

          <div className="form-group">
            <label htmlFor="aocExamples">AoC Examples (one per line)</label>
            <textarea
              id="aocExamples"
              name="aocExamples"
              value={algorithm.aocExamples}
              onChange={handleChange}
              placeholder="Day 12 2022 - Hill Climbing&#10;Day 15 2021 - Chiton"
              rows={3}
            />
          </div>

          <div className="form-group">
            <label htmlFor="resources">Resource URLs (one per line)</label>
            <textarea
              id="resources"
              name="resources"
              value={algorithm.resources}
              onChange={handleChange}
              placeholder="https://en.wikipedia.org/wiki/..."
              rows={2}
            />
          </div>
        </div>

        <div className="form-section">
          <h3>Submit</h3>

          <div className="form-group">
            <label htmlFor="submittedBy">Your Name (optional)</label>
            <input
              type="text"
              id="submittedBy"
              value={submittedBy}
              onChange={(e) => setSubmittedBy(e.target.value)}
              placeholder="Anonymous"
            />
          </div>

          <div className="captcha-section">
            <label>Verify you're human *</label>
            {captcha && (
              <div className="captcha-box">
                <span className="captcha-question">{captcha.question}</span>
                <input
                  type="number"
                  value={captchaAnswer}
                  onChange={(e) => setCaptchaAnswer(e.target.value)}
                  placeholder="Answer"
                  required
                />
                <button type="button" onClick={fetchCaptcha} className="refresh-btn">
                  New Question
                </button>
              </div>
            )}
          </div>

          {error && <div className="error-message">{error}</div>}

          <button type="submit" className="submit-btn" disabled={submitting}>
            {submitting ? 'Submitting...' : 'Submit for Review'}
          </button>
        </div>
      </form>
    </div>
  )
}

export default SubmitForm
