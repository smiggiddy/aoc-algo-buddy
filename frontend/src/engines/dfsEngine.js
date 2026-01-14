/**
 * DFS Engine - Generates step-by-step execution for DFS algorithm
 * Used in the Interactive Playground
 */

export class DFSEngine {
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
    const stack = [{ ...this.start, path: [this.start] }]
    const visited = new Set()

    this.addStep({
      description: `Initialize: Start at (${this.start.row}, ${this.start.col})`,
      pseudoCodeLine: 1,
      stack: [{ ...this.start }],
      visited: [],
      current: null,
      highlight: { type: 'start', cells: [this.start] },
      found: false
    })

    while (stack.length > 0) {
      const current = stack.pop()
      const key = this.key(current)

      if (visited.has(key)) {
        continue
      }

      visited.add(key)

      this.addStep({
        description: `Pop and visit cell (${current.row}, ${current.col})`,
        pseudoCodeLine: 6,
        stack: stack.map(c => ({ row: c.row, col: c.col })),
        visited: this.setToArray(visited),
        current: { row: current.row, col: current.col },
        highlight: { type: 'current', cells: [current] },
        found: false
      })

      if (current.row === this.goal.row && current.col === this.goal.col) {
        this.addStep({
          description: `Goal found at (${current.row}, ${current.col})! Path length: ${current.path.length}`,
          pseudoCodeLine: 9,
          stack: stack.map(c => ({ row: c.row, col: c.col })),
          visited: this.setToArray(visited),
          current: { row: current.row, col: current.col },
          highlight: { type: 'path', cells: current.path },
          found: true,
          path: current.path,
          pathLength: current.path.length
        })
        return this.steps
      }

      const neighbors = this.getNeighbors(current)
      // Reverse to maintain left-to-right, top-to-bottom order when popping
      for (const neighbor of neighbors.reverse()) {
        const neighborKey = this.key(neighbor)
        if (!visited.has(neighborKey) && !this.isWall(neighbor)) {
          stack.push({ ...neighbor, path: [...current.path, neighbor] })

          this.addStep({
            description: `Push neighbor (${neighbor.row}, ${neighbor.col}) to stack`,
            pseudoCodeLine: 14,
            stack: stack.map(c => ({ row: c.row, col: c.col })),
            visited: this.setToArray(visited),
            current: { row: current.row, col: current.col },
            highlight: { type: 'frontier', cells: [neighbor] },
            found: false
          })
        }
      }
    }

    this.addStep({
      description: 'No path found - stack exhausted',
      pseudoCodeLine: 17,
      stack: [],
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

export function createDFSEngine(grid, start, goal) {
  const engine = new DFSEngine(grid, start, goal)
  engine.generateSteps()
  return engine
}
