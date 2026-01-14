export { BFSEngine, createBFSEngine } from './bfsEngine'
export { DFSEngine, createDFSEngine } from './dfsEngine'

// Default example grids
export const EXAMPLE_GRIDS = {
  simple: {
    name: 'Simple 5x5 Grid',
    grid: [
      [0, 0, 0, 0, 0],
      [0, 1, 1, 0, 0],
      [0, 0, 0, 1, 0],
      [0, 1, 0, 0, 0],
      [0, 0, 0, 0, 0]
    ],
    start: { row: 0, col: 0 },
    goal: { row: 4, col: 4 }
  },
  maze: {
    name: 'Maze',
    grid: [
      [0, 1, 0, 0, 0, 0, 0],
      [0, 1, 0, 1, 1, 1, 0],
      [0, 0, 0, 0, 0, 1, 0],
      [0, 1, 1, 1, 0, 1, 0],
      [0, 0, 0, 1, 0, 0, 0],
      [1, 1, 0, 1, 1, 1, 0],
      [0, 0, 0, 0, 0, 0, 0]
    ],
    start: { row: 0, col: 0 },
    goal: { row: 6, col: 6 }
  },
  open: {
    name: 'Open Field',
    grid: [
      [0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0],
      [0, 0, 0, 0, 0]
    ],
    start: { row: 0, col: 0 },
    goal: { row: 4, col: 4 }
  },
  obstacle: {
    name: 'Central Obstacle',
    grid: [
      [0, 0, 0, 0, 0],
      [0, 1, 1, 1, 0],
      [0, 1, 1, 1, 0],
      [0, 1, 1, 1, 0],
      [0, 0, 0, 0, 0]
    ],
    start: { row: 0, col: 0 },
    goal: { row: 4, col: 4 }
  }
}

export const SUPPORTED_ALGORITHMS = {
  bfs: {
    name: 'Breadth-First Search (BFS)',
    createEngine: (grid, start, goal) => createBFSEngine(grid, start, goal),
    dataStructure: 'Queue',
    description: 'Explores level by level, guarantees shortest path'
  },
  dfs: {
    name: 'Depth-First Search (DFS)',
    createEngine: (grid, start, goal) => createDFSEngine(grid, start, goal),
    dataStructure: 'Stack',
    description: 'Explores as deep as possible before backtracking'
  }
}
