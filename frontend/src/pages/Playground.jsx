import { useState, useEffect, useCallback, useMemo } from 'react'
import { useParams, Link } from 'react-router-dom'
import { SUPPORTED_ALGORITHMS, EXAMPLE_GRIDS } from '../engines'
import './Playground.css'

function Playground() {
  const { algorithmId } = useParams()
  const [selectedAlgo, setSelectedAlgo] = useState(algorithmId || 'bfs')
  const [selectedExample, setSelectedExample] = useState('simple')
  const [grid, setGrid] = useState(EXAMPLE_GRIDS.simple.grid)
  const [start, setStart] = useState(EXAMPLE_GRIDS.simple.start)
  const [goal, setGoal] = useState(EXAMPLE_GRIDS.simple.goal)
  const [engine, setEngine] = useState(null)
  const [currentStep, setCurrentStep] = useState(0)
  const [isPlaying, setIsPlaying] = useState(false)
  const [playbackSpeed, setPlaybackSpeed] = useState(500)
  const [editMode, setEditMode] = useState(null) // 'wall', 'start', 'goal', 'clear'

  const algorithmInfo = SUPPORTED_ALGORITHMS[selectedAlgo]

  // Generate engine when grid/start/goal/algorithm changes
  useEffect(() => {
    if (algorithmInfo) {
      const newEngine = algorithmInfo.createEngine(grid, start, goal)
      setEngine(newEngine)
      setCurrentStep(0)
      setIsPlaying(false)
    }
  }, [grid, start, goal, selectedAlgo, algorithmInfo])

  // Load example grid
  const loadExample = useCallback((exampleKey) => {
    const example = EXAMPLE_GRIDS[exampleKey]
    if (example) {
      setSelectedExample(exampleKey)
      setGrid(example.grid.map(row => [...row]))
      setStart({ ...example.start })
      setGoal({ ...example.goal })
    }
  }, [])

  // Playback control
  useEffect(() => {
    if (!isPlaying || !engine) return

    const timer = setInterval(() => {
      setCurrentStep(prev => {
        if (prev >= engine.totalSteps - 1) {
          setIsPlaying(false)
          return prev
        }
        return prev + 1
      })
    }, playbackSpeed)

    return () => clearInterval(timer)
  }, [isPlaying, engine, playbackSpeed])

  const stepForward = useCallback(() => {
    if (engine && currentStep < engine.totalSteps - 1) {
      setCurrentStep(prev => prev + 1)
    }
  }, [engine, currentStep])

  const stepBackward = useCallback(() => {
    if (currentStep > 0) {
      setCurrentStep(prev => prev - 1)
    }
  }, [currentStep])

  const reset = useCallback(() => {
    setCurrentStep(0)
    setIsPlaying(false)
  }, [])

  const handleCellClick = useCallback((row, col) => {
    if (!editMode) return

    if (editMode === 'start') {
      if (grid[row][col] !== 1) {
        setStart({ row, col })
      }
    } else if (editMode === 'goal') {
      if (grid[row][col] !== 1) {
        setGoal({ row, col })
      }
    } else if (editMode === 'wall') {
      if (!(row === start.row && col === start.col) && !(row === goal.row && col === goal.col)) {
        setGrid(prev => {
          const newGrid = prev.map(r => [...r])
          newGrid[row][col] = 1
          return newGrid
        })
      }
    } else if (editMode === 'clear') {
      setGrid(prev => {
        const newGrid = prev.map(r => [...r])
        newGrid[row][col] = 0
        return newGrid
      })
    }
  }, [editMode, grid, start, goal])

  const currentState = engine?.getStep(currentStep)

  const getCellClass = useCallback((row, col) => {
    const classes = ['grid-cell']

    // Base cell type
    if (grid[row][col] === 1) {
      classes.push('wall')
    }
    if (row === start.row && col === start.col) {
      classes.push('start')
    }
    if (row === goal.row && col === goal.col) {
      classes.push('goal')
    }

    if (!currentState) return classes.join(' ')

    // Visited cells
    const isVisited = currentState.visited?.some(v => v.row === row && v.col === col)
    if (isVisited) {
      classes.push('visited')
    }

    // Current cell
    if (currentState.current?.row === row && currentState.current?.col === col) {
      classes.push('current')
    }

    // Highlight type
    const highlight = currentState.highlight
    if (highlight?.cells?.some(c => c.row === row && c.col === col)) {
      classes.push(`highlight-${highlight.type}`)
    }

    // Path cells
    if (currentState.path?.some(p => p.row === row && p.col === col)) {
      classes.push('path')
    }

    return classes.join(' ')
  }, [grid, start, goal, currentState])

  const dataStructureItems = useMemo(() => {
    if (!currentState) return []
    return currentState.queue || currentState.stack || []
  }, [currentState])

  return (
    <div className="playground">
      <div className="playground-header">
        <div className="playground-title">
          <h1>Algorithm Playground</h1>
          <p>Visualize algorithms step-by-step with custom inputs</p>
        </div>
        <Link to={`/algorithm/${selectedAlgo}`} className="back-to-algo">
          View {algorithmInfo?.name} Details
        </Link>
      </div>

      <div className="playground-layout">
        <aside className="playground-sidebar">
          <section className="sidebar-section">
            <h3>Algorithm</h3>
            <select
              value={selectedAlgo}
              onChange={(e) => setSelectedAlgo(e.target.value)}
              className="algo-select"
            >
              {Object.entries(SUPPORTED_ALGORITHMS).map(([id, info]) => (
                <option key={id} value={id}>{info.name}</option>
              ))}
            </select>
            <p className="algo-desc">{algorithmInfo?.description}</p>
          </section>

          <section className="sidebar-section">
            <h3>Example Grids</h3>
            <div className="example-buttons">
              {Object.entries(EXAMPLE_GRIDS).map(([key, example]) => (
                <button
                  key={key}
                  className={`example-btn ${selectedExample === key ? 'active' : ''}`}
                  onClick={() => loadExample(key)}
                >
                  {example.name}
                </button>
              ))}
            </div>
          </section>

          <section className="sidebar-section">
            <h3>Edit Grid</h3>
            <div className="edit-buttons">
              <button
                className={`edit-btn ${editMode === 'wall' ? 'active' : ''}`}
                onClick={() => setEditMode(editMode === 'wall' ? null : 'wall')}
              >
                Add Wall
              </button>
              <button
                className={`edit-btn ${editMode === 'clear' ? 'active' : ''}`}
                onClick={() => setEditMode(editMode === 'clear' ? null : 'clear')}
              >
                Clear Cell
              </button>
              <button
                className={`edit-btn ${editMode === 'start' ? 'active' : ''}`}
                onClick={() => setEditMode(editMode === 'start' ? null : 'start')}
              >
                Set Start
              </button>
              <button
                className={`edit-btn ${editMode === 'goal' ? 'active' : ''}`}
                onClick={() => setEditMode(editMode === 'goal' ? null : 'goal')}
              >
                Set Goal
              </button>
            </div>
            {editMode && (
              <p className="edit-hint">Click on the grid to {editMode === 'wall' ? 'add walls' : editMode === 'clear' ? 'clear cells' : `set ${editMode}`}</p>
            )}
          </section>

          <section className="sidebar-section">
            <h3>Playback Speed</h3>
            <div className="speed-control">
              <input
                type="range"
                min="100"
                max="2000"
                step="100"
                value={2100 - playbackSpeed}
                onChange={(e) => setPlaybackSpeed(2100 - Number(e.target.value))}
              />
              <span>{playbackSpeed}ms</span>
            </div>
          </section>
        </aside>

        <main className="playground-main">
          <div className="playback-controls">
            <button onClick={reset} className="control-btn" title="Reset">
              &#8634;
            </button>
            <button
              onClick={stepBackward}
              className="control-btn"
              disabled={currentStep === 0}
              title="Step Back"
            >
              &#9664;&#9664;
            </button>
            <button
              onClick={() => setIsPlaying(!isPlaying)}
              className="control-btn play-btn"
              disabled={!engine || currentStep >= engine.totalSteps - 1}
              title={isPlaying ? 'Pause' : 'Play'}
            >
              {isPlaying ? '&#10074;&#10074;' : '&#9658;'}
            </button>
            <button
              onClick={stepForward}
              className="control-btn"
              disabled={!engine || currentStep >= engine.totalSteps - 1}
              title="Step Forward"
            >
              &#9654;&#9654;
            </button>
            <div className="step-counter">
              Step {currentStep + 1} / {engine?.totalSteps || 0}
            </div>
          </div>

          {currentState && (
            <div className="step-description">
              {currentState.description}
            </div>
          )}

          <div className="grid-container">
            <div
              className="algorithm-grid"
              style={{
                gridTemplateColumns: `repeat(${grid[0]?.length || 5}, 1fr)`
              }}
            >
              {grid.map((row, rowIdx) =>
                row.map((_, colIdx) => (
                  <div
                    key={`${rowIdx}-${colIdx}`}
                    className={getCellClass(rowIdx, colIdx)}
                    onClick={() => handleCellClick(rowIdx, colIdx)}
                  >
                    {rowIdx === start.row && colIdx === start.col && 'S'}
                    {rowIdx === goal.row && colIdx === goal.col && 'G'}
                  </div>
                ))
              )}
            </div>
          </div>

          <div className="legend">
            <div className="legend-item"><span className="legend-color start"></span> Start (S)</div>
            <div className="legend-item"><span className="legend-color goal"></span> Goal (G)</div>
            <div className="legend-item"><span className="legend-color wall"></span> Wall</div>
            <div className="legend-item"><span className="legend-color visited"></span> Visited</div>
            <div className="legend-item"><span className="legend-color current"></span> Current</div>
            <div className="legend-item"><span className="legend-color path"></span> Path</div>
          </div>
        </main>

        <aside className="playground-state">
          <section className="state-section">
            <h3>{algorithmInfo?.dataStructure || 'Data Structure'}</h3>
            <div className="data-structure">
              {dataStructureItems.length === 0 ? (
                <span className="empty-state">Empty</span>
              ) : (
                dataStructureItems.map((item, i) => (
                  <span key={i} className="ds-item">
                    ({item.row},{item.col})
                  </span>
                ))
              )}
            </div>
          </section>

          <section className="state-section">
            <h3>Visited ({currentState?.visited?.length || 0})</h3>
            <div className="visited-list">
              {currentState?.visited?.slice(-10).map((v, i) => (
                <span key={i} className="visited-item">
                  ({v.row},{v.col})
                </span>
              ))}
              {(currentState?.visited?.length || 0) > 10 && (
                <span className="more-items">...and {currentState.visited.length - 10} more</span>
              )}
            </div>
          </section>

          {currentState?.found && (
            <section className="state-section result-section">
              <h3>Result</h3>
              <div className="result-info">
                <p>Path found!</p>
                <p>Length: {currentState.distance ?? currentState.pathLength}</p>
              </div>
            </section>
          )}
        </aside>
      </div>
    </div>
  )
}

export default Playground
