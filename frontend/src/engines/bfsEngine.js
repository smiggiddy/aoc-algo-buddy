/**
 * BFS Engine - Generates step-by-step execution for BFS algorithm
 * Used in the Interactive Playground
 */

export class BFSEngine {
  constructor(grid, start, goal) {
    this.grid = grid
    this.start = start
    this.goal = goal
    this.steps = []
    this.rows = grid.length
    this.cols = grid[0]?.length || 0
  }

  generateSteps() {
    this.steps = []
    const queue = [{ ...this.start, distance: 0 }]
    const visited = new Set()
    const parent = new Map()
    visited.add(this.key(this.start))

    this.addStep({
      description: `Initialize: Start at (${this.start.row}, ${this.start.col})`,
      pseudoCodeLine: 1,
      queue: [{ ...this.start }],
      visited: [{ ...this.start }],
      current: null,
      highlight: { type: 'start', cells: [this.start] },
      found: false
    })

    while (queue.length > 0) {
      const current = queue.shift()

      this.addStep({
        description: `Dequeue cell (${current.row}, ${current.col}) at distance ${current.distance}`,
        pseudoCodeLine: 6,
        queue: queue.map(c => ({ row: c.row, col: c.col })),
        visited: this.setToArray(visited),
        current: { row: current.row, col: current.col },
        highlight: { type: 'current', cells: [current] },
        found: false
      })

      if (current.row === this.goal.row && current.col === this.goal.col) {
        const path = this.reconstructPath(parent, current)
        this.addStep({
          description: `Goal found at (${current.row}, ${current.col})! Distance: ${current.distance}`,
          pseudoCodeLine: 9,
          queue: queue.map(c => ({ row: c.row, col: c.col })),
          visited: this.setToArray(visited),
          current: { row: current.row, col: current.col },
          highlight: { type: 'path', cells: path },
          found: true,
          path: path,
          distance: current.distance
        })
        return this.steps
      }

      const neighbors = this.getNeighbors(current)
      for (const neighbor of neighbors) {
        const key = this.key(neighbor)
        if (!visited.has(key) && !this.isWall(neighbor)) {
          visited.add(key)
          parent.set(key, current)
          queue.push({ ...neighbor, distance: current.distance + 1 })

          this.addStep({
            description: `Add neighbor (${neighbor.row}, ${neighbor.col}) to queue`,
            pseudoCodeLine: 14,
            queue: queue.map(c => ({ row: c.row, col: c.col })),
            visited: this.setToArray(visited),
            current: { row: current.row, col: current.col },
            highlight: { type: 'frontier', cells: [neighbor] },
            found: false
          })
        }
      }
    }

    this.addStep({
      description: 'No path found - queue exhausted',
      pseudoCodeLine: 17,
      queue: [],
      visited: this.setToArray(visited),
      current: null,
      highlight: { type: 'failure', cells: [] },
      found: false
    })

    return this.steps
  }

  addStep(stepData) {
    this.steps.push({
      stepNumber: this.steps.length,
      gridState: this.cloneGrid(),
      ...stepData
    })
  }

  getNeighbors(cell) {
    const directions = [
      { row: -1, col: 0 },  // up
      { row: 1, col: 0 },   // down
      { row: 0, col: -1 },  // left
      { row: 0, col: 1 }    // right
    ]
    return directions
      .map(d => ({ row: cell.row + d.row, col: cell.col + d.col }))
      .filter(n => n.row >= 0 && n.row < this.rows && n.col >= 0 && n.col < this.cols)
  }

  isWall(cell) {
    return this.grid[cell.row][cell.col] === 1
  }

  key(cell) {
    return `${cell.row},${cell.col}`
  }

  setToArray(set) {
    return Array.from(set).map(k => {
      const [row, col] = k.split(',').map(Number)
      return { row, col }
    })
  }

  reconstructPath(parent, end) {
    const path = []
    let current = end
    while (current) {
      path.unshift({ row: current.row, col: current.col })
      current = parent.get(this.key(current))
    }
    return path
  }

  cloneGrid() {
    return this.grid.map(row => [...row])
  }

  getStep(index) {
    return this.steps[index]
  }

  get totalSteps() {
    return this.steps.length
  }
}

export function createBFSEngine(grid, start, goal) {
  const engine = new BFSEngine(grid, start, goal)
  engine.generateSteps()
  return engine
}
