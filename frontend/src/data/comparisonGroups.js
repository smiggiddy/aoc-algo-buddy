export const COMPARISON_GROUPS = [
  {
    id: 'graph-traversal',
    name: 'Graph Traversal',
    description: 'BFS vs DFS - when to use which for exploring graphs and trees',
    algorithms: ['bfs', 'dfs'],
    keyDifferences: [
      { aspect: 'Traversal Order', bfs: 'Level by level (breadth)', dfs: 'Branch by branch (depth)' },
      { aspect: 'Data Structure', bfs: 'Queue (FIFO)', dfs: 'Stack/Recursion (LIFO)' },
      { aspect: 'Shortest Path', bfs: 'Yes (unweighted)', dfs: 'No' },
      { aspect: 'Memory Usage', bfs: 'Higher (stores all nodes at current level)', dfs: 'Lower (stores path to current node)' },
      { aspect: 'Complete Search', bfs: 'Finds closest first', dfs: 'May find distant first' }
    ]
  },
  {
    id: 'shortest-path',
    name: 'Shortest Path Algorithms',
    description: 'Dijkstra vs A* vs Bellman-Ford - choosing the right algorithm for weighted graphs',
    algorithms: ['dijkstra', 'a-star', 'bellman-ford'],
    keyDifferences: [
      { aspect: 'Negative Weights', dijkstra: 'No', 'a-star': 'No', 'bellman-ford': 'Yes' },
      { aspect: 'Heuristic', dijkstra: 'No', 'a-star': 'Yes (required)', 'bellman-ford': 'No' },
      { aspect: 'Time Complexity', dijkstra: 'O((V+E) log V)', 'a-star': 'Depends on heuristic', 'bellman-ford': 'O(VE)' },
      { aspect: 'Best For', dijkstra: 'General weighted graphs', 'a-star': 'Pathfinding with known goal', 'bellman-ford': 'Graphs with negative edges' },
      { aspect: 'Cycle Detection', dijkstra: 'No', 'a-star': 'No', 'bellman-ford': 'Yes (negative cycles)' }
    ]
  },
  {
    id: 'dp-patterns',
    name: 'Dynamic Programming Patterns',
    description: 'Memoization vs Tabulation - top-down vs bottom-up approaches',
    algorithms: ['memoization', 'tabulation'],
    keyDifferences: [
      { aspect: 'Direction', memoization: 'Top-down (recursive)', tabulation: 'Bottom-up (iterative)' },
      { aspect: 'Subproblems Solved', memoization: 'Only needed ones', tabulation: 'All subproblems' },
      { aspect: 'Stack Overflow Risk', memoization: 'Yes (deep recursion)', tabulation: 'No' },
      { aspect: 'Space Optimization', memoization: 'Harder', tabulation: 'Easier' },
      { aspect: 'Implementation', memoization: 'Add cache to recursive solution', tabulation: 'Build table iteratively' }
    ]
  },
  {
    id: 'sorting',
    name: 'Sorting Algorithms',
    description: 'Merge Sort vs Quick Sort - stable vs in-place sorting',
    algorithms: ['merge-sort', 'quick-sort'],
    keyDifferences: [
      { aspect: 'Stability', 'merge-sort': 'Stable', 'quick-sort': 'Unstable' },
      { aspect: 'Space', 'merge-sort': 'O(n) extra', 'quick-sort': 'O(log n) stack' },
      { aspect: 'Worst Case', 'merge-sort': 'O(n log n)', 'quick-sort': 'O(n^2)' },
      { aspect: 'Average Case', 'merge-sort': 'O(n log n)', 'quick-sort': 'O(n log n)' },
      { aspect: 'Best For', 'merge-sort': 'Linked lists, stability needed', 'quick-sort': 'Arrays, in-place needed' }
    ]
  },
  {
    id: 'search-techniques',
    name: 'Search Techniques',
    description: 'Binary Search vs Two Pointers - efficient search patterns',
    algorithms: ['binary-search', 'two-pointers'],
    keyDifferences: [
      { aspect: 'Requirement', 'binary-search': 'Sorted array', 'two-pointers': 'Often sorted, sometimes not' },
      { aspect: 'Pointers', 'binary-search': 'Three (low, mid, high)', 'two-pointers': 'Two (various positions)' },
      { aspect: 'Movement', 'binary-search': 'Halves search space', 'two-pointers': 'Moves based on condition' },
      { aspect: 'Use Case', 'binary-search': 'Find target value', 'two-pointers': 'Find pairs, subarrays' },
      { aspect: 'Complexity', 'binary-search': 'O(log n)', 'two-pointers': 'O(n)' }
    ]
  },
  {
    id: 'tree-traversals',
    name: 'Tree Traversals',
    description: 'Pre-order vs In-order vs Post-order - different ways to visit tree nodes',
    algorithms: ['tree-traversals'],
    keyDifferences: [
      { aspect: 'Visit Order', 'pre-order': 'Root, Left, Right', 'in-order': 'Left, Root, Right', 'post-order': 'Left, Right, Root' },
      { aspect: 'BST Property', 'pre-order': 'Copy tree structure', 'in-order': 'Sorted order', 'post-order': 'Delete nodes safely' },
      { aspect: 'Use Case', 'pre-order': 'Serialize tree', 'in-order': 'BST operations', 'post-order': 'Calculate subtree values' }
    ]
  }
]

export function getComparisonGroup(id) {
  return COMPARISON_GROUPS.find(group => group.id === id)
}

export function getGroupByAlgorithms(algorithmIds) {
  const sortedIds = [...algorithmIds].sort()
  return COMPARISON_GROUPS.find(group => {
    const groupIds = [...group.algorithms].sort()
    return groupIds.length === sortedIds.length &&
           groupIds.every((id, i) => id === sortedIds[i])
  })
}
