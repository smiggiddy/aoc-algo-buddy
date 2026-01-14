import { useState, useEffect, useCallback, useMemo } from 'react'
import { useLocation, useNavigate } from 'react-router-dom'
import './PseudoCodeBlock.css'

function PseudoCodeBlock({ code }) {
  const location = useLocation()
  const navigate = useNavigate()
  const [selectedLines, setSelectedLines] = useState(new Set())
  const [lastClickedLine, setLastClickedLine] = useState(null)
  const [copied, setCopied] = useState(false)
  const [copyType, setCopyType] = useState(null)

  const lines = useMemo(() => code.split('\n'), [code])

  // Parse URL hash to get selected lines
  const parseHash = useCallback((hash) => {
    const match = hash.match(/^#L(\d+)(?:-L?(\d+))?$/)
    if (match) {
      const start = parseInt(match[1], 10)
      const end = match[2] ? parseInt(match[2], 10) : start
      const selected = new Set()
      for (let i = Math.min(start, end); i <= Math.max(start, end); i++) {
        if (i >= 1 && i <= lines.length) {
          selected.add(i)
        }
      }
      return selected
    }
    return new Set()
  }, [lines.length])

  // Initialize selected lines from URL hash
  useEffect(() => {
    const selected = parseHash(location.hash)
    setSelectedLines(selected)

    // Scroll to first selected line if any
    if (selected.size > 0) {
      const firstLine = Math.min(...selected)
      setTimeout(() => {
        const lineEl = document.getElementById(`L${firstLine}`)
        if (lineEl) {
          lineEl.scrollIntoView({ behavior: 'smooth', block: 'center' })
        }
      }, 100)
    }
  }, [location.hash, parseHash])

  // Update URL hash when selection changes
  const updateHash = useCallback((newSelection) => {
    if (newSelection.size === 0) {
      // Remove hash without triggering navigation
      if (location.hash) {
        navigate(location.pathname + location.search, { replace: true })
      }
      return
    }

    const sortedLines = [...newSelection].sort((a, b) => a - b)
    const start = sortedLines[0]
    const end = sortedLines[sortedLines.length - 1]

    // Check if it's a contiguous range
    const isContiguous = sortedLines.every((line, i) =>
      i === 0 || line === sortedLines[i - 1] + 1
    )

    let hash
    if (isContiguous && start !== end) {
      hash = `#L${start}-L${end}`
    } else if (newSelection.size === 1) {
      hash = `#L${start}`
    } else {
      // For non-contiguous, just use the range
      hash = `#L${start}-L${end}`
    }

    navigate(location.pathname + location.search + hash, { replace: true })
  }, [location.pathname, location.search, location.hash, navigate])

  const handleLineClick = useCallback((lineNum, event) => {
    event.preventDefault()

    let newSelection

    if (event.shiftKey && lastClickedLine !== null) {
      // Range selection
      const start = Math.min(lastClickedLine, lineNum)
      const end = Math.max(lastClickedLine, lineNum)
      newSelection = new Set()
      for (let i = start; i <= end; i++) {
        newSelection.add(i)
      }
    } else {
      // Single line toggle
      newSelection = new Set(selectedLines)
      if (newSelection.has(lineNum)) {
        newSelection.delete(lineNum)
      } else {
        newSelection.clear()
        newSelection.add(lineNum)
      }
      setLastClickedLine(lineNum)
    }

    setSelectedLines(newSelection)
    updateHash(newSelection)
  }, [selectedLines, lastClickedLine, updateHash])

  const getSelectedCode = useCallback(() => {
    if (selectedLines.size === 0) {
      return code
    }
    const sortedLines = [...selectedLines].sort((a, b) => a - b)
    return sortedLines.map(lineNum => lines[lineNum - 1]).join('\n')
  }, [selectedLines, lines, code])

  const copyToClipboard = useCallback(async (copyAll = false) => {
    const textToCopy = copyAll ? code : getSelectedCode()
    try {
      await navigator.clipboard.writeText(textToCopy)
      setCopied(true)
      setCopyType(copyAll ? 'all' : 'selected')
      setTimeout(() => {
        setCopied(false)
        setCopyType(null)
      }, 2000)
    } catch (err) {
      console.error('Failed to copy:', err)
    }
  }, [code, getSelectedCode])

  const clearSelection = useCallback(() => {
    setSelectedLines(new Set())
    setLastClickedLine(null)
    if (location.hash) {
      navigate(location.pathname + location.search, { replace: true })
    }
  }, [location.hash, location.pathname, location.search, navigate])

  return (
    <div className="pseudo-code-block">
      <div className="code-toolbar">
        <div className="selection-info">
          {selectedLines.size > 0 && (
            <>
              <span className="selection-count">
                {selectedLines.size} line{selectedLines.size !== 1 ? 's' : ''} selected
              </span>
              <button
                className="clear-selection-btn"
                onClick={clearSelection}
                title="Clear selection"
              >
                Clear
              </button>
            </>
          )}
        </div>
        <div className="copy-buttons">
          {selectedLines.size > 0 && (
            <button
              className="copy-btn"
              onClick={() => copyToClipboard(false)}
              title="Copy selected lines"
            >
              {copied && copyType === 'selected' ? 'Copied!' : 'Copy Selected'}
            </button>
          )}
          <button
            className="copy-btn copy-all-btn"
            onClick={() => copyToClipboard(true)}
            title="Copy all code"
          >
            {copied && copyType === 'all' ? 'Copied!' : 'Copy All'}
          </button>
        </div>
      </div>
      <div className="code-container">
        <table className="code-table">
          <tbody>
            {lines.map((line, index) => {
              const lineNum = index + 1
              const isSelected = selectedLines.has(lineNum)
              return (
                <tr
                  key={lineNum}
                  id={`L${lineNum}`}
                  className={`code-line ${isSelected ? 'selected' : ''}`}
                >
                  <td
                    className="line-number"
                    onClick={(e) => handleLineClick(lineNum, e)}
                    data-line={lineNum}
                  >
                    {lineNum}
                  </td>
                  <td className="line-content">
                    <pre><code>{line || ' '}</code></pre>
                  </td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}

export default PseudoCodeBlock
