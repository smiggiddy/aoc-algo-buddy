package main

func loadAlgorithms() []Algorithm {
	return []Algorithm{
		// Graph Algorithms
		{
			ID:          "bfs",
			Name:        "Breadth-First Search (BFS)",
			Category:    "Graph",
			Tags:        []string{"traversal", "shortest-path", "grid", "maze"},
			Difficulty:  "Beginner",
			Description: "Explores all neighbors at the current depth before moving to nodes at the next depth level. Guarantees the shortest path in unweighted graphs.",
			WhenToUse: []string{
				"Finding shortest path in unweighted graphs or grids",
				"Level-order traversal",
				"Finding all nodes within a certain distance",
				"Flood fill algorithms",
			},
			PseudoCode: `function BFS(start, goal):
    queue = new Queue()
    visited = new Set()

    queue.enqueue(start)
    visited.add(start)

    while queue is not empty:
        current = queue.dequeue()

        if current == goal:
            return SUCCESS

        for each neighbor of current:
            if neighbor not in visited:
                visited.add(neighbor)
                queue.enqueue(neighbor)

    return NOT_FOUND`,
			Complexity: Complexity{
				Time:  "O(V + E) where V = vertices, E = edges",
				Space: "O(V) for the queue and visited set",
			},
			AoCExamples: []string{
				"Day 12 2022 - Hill Climbing Algorithm",
				"Day 15 2016 - Timing is Everything",
				"Day 13 2019 - Care Package",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Breadth-first_search",
			},
			Examples: []Example{
				{
					Title:       "Shortest Path in a Grid",
					Description: "Find shortest path from S to E where # is a wall",
					Input:       "S . . #\n. # . .\n. . . #\n# . . E",
					Output:      "Shortest path: 6 steps",
					Visual: `BFS explores in "waves" - all cells at distance N before distance N+1:

  Start:           Wave 1:          Wave 2:          Wave 3:
  S . . #          0 1 . #          0 1 2 #          0 1 2 #
  . # . .          1 # . .          1 # 3 .          1 # 3 4
  . . . #          . . . #          2 . . #          2 3 4 #
  # . . E          # . . E          # . . E          # 4 . E

  Wave 4:          Wave 5:          Final Path:
  0 1 2 #          0 1 2 #          S → → #
  1 # 3 4          1 # 3 4          ↓ # ↓ .
  2 3 4 #          2 3 4 #          . → → #
  # 4 5 E          # 4 5 6          # . . E

Numbers show distance from start. BFS guarantees shortest path!`,
					Steps: []Step{
						{Description: "Initialize queue with start position", State: "Queue: [S(0,0)]  Visited: {S}"},
						{Description: "Process S, add neighbors (0,1) and (1,0)", State: "Queue: [(0,1), (1,0)]  Distance: 1"},
						{Description: "Process all distance-1 nodes, add distance-2", State: "Queue: [(0,2), (2,0), (1,2)]  Distance: 2"},
						{Description: "Continue until E is reached at distance 6", State: "Found E at distance 6!"},
					},
				},
			},
		},
		{
			ID:          "dfs",
			Name:        "Depth-First Search (DFS)",
			Category:    "Graph",
			Tags:        []string{"traversal", "recursion", "backtracking", "grid"},
			Difficulty:  "Beginner",
			Description: "Explores as far as possible along each branch before backtracking. Useful for exhaustive search and finding any path (not necessarily shortest).",
			WhenToUse: []string{
				"Detecting cycles in graphs",
				"Topological sorting",
				"Finding connected components",
				"Solving puzzles with backtracking",
			},
			PseudoCode: `function DFS(node, visited):
    if node in visited:
        return

    visited.add(node)
    process(node)

    for each neighbor of node:
        DFS(neighbor, visited)

# Iterative version using stack:
function DFS_iterative(start):
    stack = new Stack()
    visited = new Set()

    stack.push(start)

    while stack is not empty:
        current = stack.pop()
        if current in visited:
            continue
        visited.add(current)
        process(current)
        for each neighbor of current:
            stack.push(neighbor)`,
			Complexity: Complexity{
				Time:  "O(V + E) where V = vertices, E = edges",
				Space: "O(V) for recursion stack",
			},
			AoCExamples: []string{
				"Day 12 2021 - Passage Pathing",
				"Day 7 2022 - No Space Left On Device",
				"Day 18 2021 - Snailfish",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Depth-first_search",
			},
			Examples: []Example{
				{
					Title:       "Tree Traversal",
					Description: "Visit all nodes in a tree structure",
					Input:       "Tree with root A, children B,C; B has children D,E",
					Output:      "Visit order: A, B, D, E, C",
					Visual: `DFS goes deep before going wide:

        A              Visit Order:
       / \             1. A (start)
      B   C            2. B (go deep)
     / \               3. D (deeper!)
    D   E              4. E (backtrack, try sibling)
                       5. C (backtrack to A, try sibling)

  Stack visualization:
  Step 1: [A]           → pop A, push B,C
  Step 2: [C,B]         → pop B, push D,E
  Step 3: [C,E,D]       → pop D (leaf)
  Step 4: [C,E]         → pop E (leaf)
  Step 5: [C]           → pop C (leaf)
  Step 6: []            → done!`,
					Steps: []Step{
						{Description: "Start at root A", State: "Stack: [A]"},
						{Description: "Visit A, push children B and C", State: "Stack: [C, B]"},
						{Description: "Visit B, push children D and E", State: "Stack: [C, E, D]"},
						{Description: "Visit D (leaf), backtrack", State: "Stack: [C, E]"},
						{Description: "Visit E (leaf), backtrack", State: "Stack: [C]"},
						{Description: "Visit C (leaf), done", State: "Stack: []"},
					},
				},
			},
		},
		{
			ID:          "dijkstra",
			Name:        "Dijkstra's Algorithm",
			Category:    "Graph",
			Tags:        []string{"shortest-path", "weighted-graph", "priority-queue"},
			Difficulty:  "Intermediate",
			Description: "Finds the shortest path between nodes in a weighted graph with non-negative edge weights. Uses a priority queue to always process the closest unvisited node.",
			WhenToUse: []string{
				"Shortest path in weighted graphs",
				"Grids where movement costs vary",
				"When you need optimal paths, not just any path",
			},
			PseudoCode: `function Dijkstra(graph, start, goal):
    distances = new Map()  # All set to infinity
    distances[start] = 0
    previous = new Map()
    pq = new PriorityQueue()  # Min-heap by distance

    pq.insert(start, 0)

    while pq is not empty:
        current, dist = pq.extract_min()

        if current == goal:
            return reconstruct_path(previous, goal)

        if dist > distances[current]:
            continue  # Skip if we found better path

        for each (neighbor, weight) of graph[current]:
            new_dist = distances[current] + weight

            if new_dist < distances[neighbor]:
                distances[neighbor] = new_dist
                previous[neighbor] = current
                pq.insert(neighbor, new_dist)

    return distances`,
			Complexity: Complexity{
				Time:  "O((V + E) log V) with binary heap",
				Space: "O(V) for distances and priority queue",
			},
			AoCExamples: []string{
				"Day 15 2021 - Chiton",
				"Day 17 2023 - Clumsy Crucible",
				"Day 23 2021 - Amphipod",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm",
			},
			Examples: []Example{
				{
					Title:       "Weighted Grid Path",
					Description: "Find lowest cost path through a grid with varying costs",
					Input:       "1 3 1\n1 5 1\n4 2 1",
					Output:      "Minimum cost: 7 (path: right, right, down, down)",
					Visual: `Grid costs:        Dijkstra exploration:
  1  3  1          Process nodes by minimum total distance
  1  5  1
  4  2  1          Step 1: Start (0,0), cost=1
                   ┌─────────────────────────┐
  Distances:       │  1   4   5              │
  ∞→1  ∞→4  ∞→5   │  2   7   6              │
  ∞→2  ∞→7  ∞→6   │  6   4   7  ← Goal!     │
  ∞→6  ∞→4  ∞→7   └─────────────────────────┘

  Priority Queue processing order:
  (0,0):1 → (1,0):2 → (0,1):4 → (2,1):4 → (0,2):5 → ...

  Optimal path: (0,0)→(1,0)→(1,1) costs too much
                (0,0)→(0,1)→(0,2)→(1,2)→(2,2) = 1+3+1+1+1 = 7`,
					Steps: []Step{
						{Description: "Initialize start with distance 0, others infinity", State: "PQ: [(0,0):0]"},
						{Description: "Process (0,0), update neighbors", State: "PQ: [(1,0):2, (0,1):4]"},
						{Description: "Always pick minimum distance node next", State: "Process (1,0):2"},
						{Description: "Continue until goal reached", State: "Goal (2,2) reached with cost 7"},
					},
				},
			},
		},
		{
			ID:          "flood-fill",
			Name:        "Flood Fill",
			Category:    "Graph",
			Tags:        []string{"grid", "connected-components", "recursion"},
			Difficulty:  "Beginner",
			Description: "Determines and marks connected regions in a grid. Starting from a seed point, it fills all connected cells that match a condition.",
			WhenToUse: []string{
				"Finding connected regions in 2D grids",
				"Counting islands or enclosed areas",
				"Image processing (bucket fill)",
				"Game map analysis",
			},
			PseudoCode: `function flood_fill(grid, x, y, target, replacement):
    if x < 0 or x >= width or y < 0 or y >= height:
        return
    if grid[y][x] != target:
        return
    if grid[y][x] == replacement:
        return

    grid[y][x] = replacement

    flood_fill(grid, x + 1, y, target, replacement)
    flood_fill(grid, x - 1, y, target, replacement)
    flood_fill(grid, x, y + 1, target, replacement)
    flood_fill(grid, x, y - 1, target, replacement)`,
			Complexity: Complexity{
				Time:  "O(N) where N = number of cells",
				Space: "O(N) for recursion stack",
			},
			AoCExamples: []string{
				"Day 9 2021 - Smoke Basin",
				"Day 12 2022 - Garden Groups",
				"Day 10 2023 - Pipe Maze",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Flood_fill",
			},
			Examples: []Example{
				{
					Title:       "Count Islands",
					Description: "Count separate land masses in a map",
					Input:       "##.#\n##..\n...#\n..##",
					Output:      "3 islands",
					Visual: `Original grid:    After flood fill:

  # # . #         1 1 . 2       Island 1: top-left 2x2
  # # . .         1 1 . .       Island 2: top-right single
  . . . #    →    . . . 3       Island 3: bottom-right 2x2+1
  . . # #         . . 3 3

  Algorithm:
  1. Scan grid for unvisited '#'
  2. When found, flood fill to mark entire island
  3. Increment island count
  4. Continue scanning

  Flood fill on Island 1:
  Start (0,0)  →  Fill (1,0)  →  Fill (0,1)  →  Fill (1,1)
      ↓              ↓              ↓              ↓
    # # . #        1 # . #        1 1 . #        1 1 . #
    # # . .        # # . .        1 # . .        1 1 . .`,
					Steps: []Step{
						{Description: "Find first '#' at (0,0)", State: "Islands: 0"},
						{Description: "Flood fill marks all connected '#' as visited", State: "Islands: 1"},
						{Description: "Continue scanning, find '#' at (3,0)", State: "Islands: 2"},
						{Description: "Find last island at (3,2)", State: "Islands: 3"},
					},
				},
			},
		},
		// Dynamic Programming
		{
			ID:          "memoization",
			Name:        "Memoization",
			Category:    "Dynamic Programming",
			Tags:        []string{"recursion", "caching", "optimization"},
			Difficulty:  "Beginner",
			Description: "Optimization technique that stores results of expensive function calls and returns cached results for repeated inputs. Top-down approach to dynamic programming.",
			WhenToUse: []string{
				"Recursive solutions with overlapping subproblems",
				"When same computations are performed multiple times",
				"Fibonacci-style recurrence relations",
			},
			PseudoCode: `memo = {}

function fib_memo(n):
    if n in memo:
        return memo[n]

    if n <= 1:
        result = n
    else:
        result = fib_memo(n-1) + fib_memo(n-2)

    memo[n] = result
    return result`,
			Complexity: Complexity{
				Time:  "Reduces exponential to polynomial",
				Space: "O(N) for cache storage",
			},
			AoCExamples: []string{
				"Day 12 2023 - Hot Springs",
				"Day 19 2024 - Linen Layout",
				"Day 10 2020 - Adapter Array",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Memoization",
			},
			Examples: []Example{
				{
					Title:       "Fibonacci with Memoization",
					Description: "Calculate fib(5) efficiently",
					Input:       "n = 5",
					Output:      "fib(5) = 5",
					Visual: `Without memoization - EXPONENTIAL calls:

                    fib(5)
                   /      \
              fib(4)      fib(3)      ← fib(3) computed twice!
             /    \       /    \
         fib(3)  fib(2) fib(2) fib(1)  ← fib(2) computed 3 times!
         /   \
     fib(2) fib(1)

Total calls: 15 for fib(5), grows exponentially!

With memoization - LINEAR calls:

    Call fib(5):
    ├─ Call fib(4):
    │  ├─ Call fib(3):
    │  │  ├─ Call fib(2):
    │  │  │  ├─ Call fib(1) → return 1
    │  │  │  └─ Call fib(0) → return 0
    │  │  │  └─ Cache fib(2) = 1
    │  │  └─ Call fib(1) → return 1
    │  │  └─ Cache fib(3) = 2
    │  └─ Lookup fib(2) → return 1 (CACHED!)
    │  └─ Cache fib(4) = 3
    └─ Lookup fib(3) → return 2 (CACHED!)
    └─ Return 5

Total calls: 9, each fib(n) computed only once!`,
					Steps: []Step{
						{Description: "Call fib(5), not in cache", State: "memo: {}"},
						{Description: "Recursively compute, caching results", State: "memo: {0:0, 1:1, 2:1}"},
						{Description: "fib(3) and fib(4) use cached values", State: "memo: {0:0, 1:1, 2:1, 3:2, 4:3}"},
						{Description: "Return fib(5) = 5", State: "memo: {0:0, 1:1, 2:1, 3:2, 4:3, 5:5}"},
					},
				},
			},
		},
		{
			ID:          "sliding-window",
			Name:        "Sliding Window",
			Category:    "String",
			Tags:        []string{"array", "substring", "optimization"},
			Difficulty:  "Beginner",
			Description: "Maintains a window that slides over data to solve problems involving contiguous sequences. Converts O(n²) brute force to O(n).",
			WhenToUse: []string{
				"Finding subarrays/substrings with certain properties",
				"Maximum/minimum in contiguous range",
				"Problems involving k consecutive elements",
			},
			PseudoCode: `# Fixed-size window
function max_sum_subarray(arr, k):
    window_sum = sum(arr[0:k])
    max_sum = window_sum

    for i from k to length(arr) - 1:
        window_sum = window_sum - arr[i-k] + arr[i]
        max_sum = max(max_sum, window_sum)

    return max_sum`,
			Complexity: Complexity{
				Time:  "O(n) single pass",
				Space: "O(1) or O(k)",
			},
			AoCExamples: []string{
				"Day 6 2022 - Tuning Trouble",
				"Day 1 2023 - Trebuchet",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Sliding_window_protocol",
			},
			Examples: []Example{
				{
					Title:       "Find Start-of-Packet Marker",
					Description: "Find first position where last 4 chars are all different",
					Input:       "mjqjpqmgbljsphdztnvjfqwrcgsmlb",
					Output:      "Position: 7 (after 'jpqm')",
					Visual: `Sliding window of size 4:

  m j q j p q m g b l j ...
  └─┬─┘
    Window 1: "mjqj" - has duplicate 'j' ✗

  m j q j p q m g b l j ...
    └─┬─┘
      Window 2: "jqjp" - has duplicate 'j' ✗

  m j q j p q m g b l j ...
      └─┬─┘
        Window 3: "qjpq" - has duplicate 'q' ✗

  m j q j p q m g b l j ...
        └─┬─┘
          Window 4: "jpqm" - all unique! ✓

  Position = 7 (index after window)

  Efficient check using Set:
  ┌─────────────────────────────────────┐
  │ Add char to set as window expands   │
  │ Remove char as window slides left   │
  │ If set.size == window.size → unique │
  └─────────────────────────────────────┘`,
					Steps: []Step{
						{Description: "Initialize window with first 4 chars", State: "Window: mjqj, Set: {m,j,q}"},
						{Description: "Slide: remove 'm', add 'p'", State: "Window: jqjp, Set: {j,q,p}"},
						{Description: "Slide: remove 'j', add 'q'", State: "Window: qjpq, Set: {q,j,p}"},
						{Description: "Slide: remove 'q', add 'm'", State: "Window: jpqm, Set: {j,p,q,m} ✓"},
					},
				},
			},
		},
		{
			ID:          "binary-search",
			Name:        "Binary Search",
			Category:    "Search",
			Tags:        []string{"sorted", "divide-conquer", "optimization"},
			Difficulty:  "Beginner",
			Description: "Efficiently find a target value or boundary in sorted data by repeatedly halving the search space. Also used for optimization problems.",
			WhenToUse: []string{
				"Searching in sorted arrays",
				"Finding insertion point",
				"Binary search the answer",
				"Finding boundary where condition changes",
			},
			PseudoCode: `function binary_search(arr, target):
    left = 0
    right = length(arr) - 1

    while left <= right:
        mid = left + (right - left) / 2

        if arr[mid] == target:
            return mid
        elif arr[mid] < target:
            left = mid + 1
        else:
            right = mid - 1

    return -1  # Not found`,
			Complexity: Complexity{
				Time:  "O(log n)",
				Space: "O(1)",
			},
			AoCExamples: []string{
				"Day 7 2021 - Treachery of Whales",
				"Optimization problems",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Binary_search_algorithm",
			},
			Examples: []Example{
				{
					Title:       "Find Target in Sorted Array",
					Description: "Find value 23 in sorted array",
					Input:       "[2, 5, 8, 12, 16, 23, 38, 56, 72, 91]",
					Output:      "Found at index 5",
					Visual: `Array: [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]
Target: 23

Step 1: left=0, right=9, mid=4
        [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]
         L           M                    R
        arr[4]=16 < 23, search right half

Step 2: left=5, right=9, mid=7
        [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]
                         L       M        R
        arr[7]=56 > 23, search left half

Step 3: left=5, right=6, mid=5
        [2, 5, 8, 12, 16, 23, 38, 56, 72, 91]
                         L   R
                         M
        arr[5]=23 == 23, FOUND!

  ┌─────────────────────────────────────────┐
  │ Each step eliminates HALF the elements  │
  │ 1000 elements → ~10 comparisons         │
  │ 1,000,000 elements → ~20 comparisons    │
  └─────────────────────────────────────────┘`,
					Steps: []Step{
						{Description: "Check middle element (index 4)", State: "16 < 23, go right"},
						{Description: "Check middle of right half (index 7)", State: "56 > 23, go left"},
						{Description: "Check middle (index 5)", State: "23 == 23, found!"},
					},
				},
			},
		},
		{
			ID:          "gcd-lcm",
			Name:        "GCD and LCM",
			Category:    "Math",
			Tags:        []string{"number-theory", "euclidean", "cycles"},
			Difficulty:  "Beginner",
			Description: "Greatest Common Divisor and Least Common Multiple - fundamental number theory algorithms used in cycle detection and synchronization.",
			WhenToUse: []string{
				"Finding when cycles align",
				"Reducing fractions",
				"Synchronization problems",
				"Modular arithmetic",
			},
			PseudoCode: `function gcd(a, b):
    while b != 0:
        a, b = b, a mod b
    return a

function lcm(a, b):
    return (a * b) / gcd(a, b)

function lcm_multiple(numbers):
    result = numbers[0]
    for i from 1 to length(numbers) - 1:
        result = lcm(result, numbers[i])
    return result`,
			Complexity: Complexity{
				Time:  "O(log(min(a,b))) for GCD",
				Space: "O(1)",
			},
			AoCExamples: []string{
				"Day 8 2023 - Haunted Wasteland",
				"Day 12 2019 - N-Body Problem",
				"Day 13 2017 - Packet Scanners",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Euclidean_algorithm",
			},
			Examples: []Example{
				{
					Title:       "When Do Cycles Align?",
					Description: "Three loops with periods 4, 6, and 10. When do all align?",
					Input:       "Periods: 4, 6, 10",
					Output:      "LCM = 60 (all align at step 60)",
					Visual: `Loop A (period 4):  ●───●───●───●───●───●───●...
                    0   4   8   12  16  20  24...

Loop B (period 6):  ●─────●─────●─────●─────●...
                    0     6     12    18    24...

Loop C (period 10): ●─────────●─────────●─────────●...
                    0         10        20        30...

Finding LCM step by step:
┌────────────────────────────────────────────┐
│ LCM(4, 6):                                 │
│   GCD(4, 6) = GCD(6, 4) = GCD(4, 2) = 2   │
│   LCM = 4 × 6 / 2 = 12                     │
│                                            │
│ LCM(12, 10):                               │
│   GCD(12, 10) = GCD(10, 2) = 2            │
│   LCM = 12 × 10 / 2 = 60                   │
└────────────────────────────────────────────┘

All three cycles align at:
  ●─────────────────────────────────────────────────────────●
  0                                                         60`,
					Steps: []Step{
						{Description: "Calculate GCD(4, 6)", State: "GCD = 2"},
						{Description: "Calculate LCM(4, 6) = 24/2", State: "LCM = 12"},
						{Description: "Calculate GCD(12, 10)", State: "GCD = 2"},
						{Description: "Calculate LCM(12, 10) = 120/2", State: "LCM = 60"},
					},
				},
			},
		},
		{
			ID:          "cycle-detection",
			Name:        "Cycle Detection",
			Category:    "Simulation",
			Tags:        []string{"optimization", "repetition", "state"},
			Difficulty:  "Intermediate",
			Description: "Detect when a sequence enters a cycle, then use math to jump ahead without simulating every step. Essential for problems with billions of iterations.",
			WhenToUse: []string{
				"Simulations with huge iteration counts",
				"Finding when patterns repeat",
				"Any problem saying 'repeat 1 billion times'",
			},
			PseudoCode: `function solve_with_cycle(initial, target_iterations):
    seen = {}  # state -> iteration number
    states = [initial]
    current = initial

    for i from 0 to target_iterations - 1:
        state_hash = hash(current)

        if state_hash in seen:
            cycle_start = seen[state_hash]
            cycle_length = i - cycle_start
            remaining = (target - cycle_start) mod cycle_length
            return states[cycle_start + remaining]

        seen[state_hash] = i
        states.append(current)
        current = next_state(current)

    return current`,
			Complexity: Complexity{
				Time:  "O(cycle_start + cycle_length)",
				Space: "O(n) for storing states",
			},
			AoCExamples: []string{
				"Day 14 2023 - Parabolic Reflector Dish",
				"Day 17 2022 - Pyroclastic Flow",
				"Day 12 2019 - N-Body Problem",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Cycle_detection",
			},
			Examples: []Example{
				{
					Title:       "Find State After 1 Billion Iterations",
					Description: "Sequence: A→B→C→D→B→C→D→B→... Find state at iteration 1,000,000,000",
					Input:       "Start: A, Target: 1000000000",
					Output:      "State: D",
					Visual: `State sequence:
  i=0   i=1   i=2   i=3   i=4   i=5   i=6   i=7
   A  →  B  →  C  →  D  →  B  →  C  →  D  →  B  → ...
              └──────────────┘
              Cycle detected! B seen at i=1 and i=4

  ┌─────────────────────────────────────────────────┐
  │ Cycle starts at: 1                              │
  │ Cycle length: 4 - 1 = 3                         │
  │                                                 │
  │ To find state at iteration N:                   │
  │   If N < cycle_start: return states[N]          │
  │   Else:                                         │
  │     offset = (N - cycle_start) mod cycle_length │
  │     return states[cycle_start + offset]         │
  └─────────────────────────────────────────────────┘

  For N = 1,000,000,000:
    offset = (1000000000 - 1) mod 3 = 999999999 mod 3 = 0
    state = states[1 + 0] = B

  Wait, let's recalculate:
    (1000000000 - 1) mod 3 = 2
    state = states[1 + 2] = D ✓`,
					Steps: []Step{
						{Description: "Simulate and record states", State: "seen: {A:0, B:1, C:2, D:3}"},
						{Description: "At i=4, B already in seen!", State: "Cycle found: start=1, len=3"},
						{Description: "Calculate: (1B - 1) mod 3 = 2", State: "Offset = 2"},
						{Description: "Look up states[1+2]", State: "Answer: D"},
					},
				},
			},
		},
		{
			ID:          "union-find",
			Name:        "Union-Find (Disjoint Set)",
			Category:    "Data Structures",
			Tags:        []string{"graph", "connected-components", "grouping"},
			Difficulty:  "Intermediate",
			Description: "Efficiently tracks elements partitioned into disjoint sets. Supports near-constant time union and find operations.",
			WhenToUse: []string{
				"Finding connected components",
				"Kruskal's minimum spanning tree",
				"Detecting cycles in undirected graphs",
				"Dynamic connectivity queries",
			},
			PseudoCode: `class UnionFind:
    parent = []  # parent[i] = parent of i
    rank = []

    function find(x):
        if parent[x] != x:
            parent[x] = find(parent[x])  # Path compression
        return parent[x]

    function union(x, y):
        root_x = find(x)
        root_y = find(y)
        if root_x == root_y:
            return false

        # Union by rank
        if rank[root_x] < rank[root_y]:
            parent[root_x] = root_y
        elif rank[root_x] > rank[root_y]:
            parent[root_y] = root_x
        else:
            parent[root_y] = root_x
            rank[root_x] += 1
        return true`,
			Complexity: Complexity{
				Time:  "O(α(n)) per operation (nearly constant)",
				Space: "O(n)",
			},
			AoCExamples: []string{
				"Day 12 2017 - Digital Plumber",
				"Day 25 2019 - Four-Dimensional Adventure",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Disjoint-set_data_structure",
			},
			Examples: []Example{
				{
					Title:       "Find Connected Components",
					Description: "Given connections, find how many groups exist",
					Input:       "Connections: (0,1), (1,2), (3,4), (5,5)",
					Output:      "3 groups: {0,1,2}, {3,4}, {5}",
					Visual: `Initial state (each node is its own parent):
  Node:    0   1   2   3   4   5
  Parent:  0   1   2   3   4   5

  Trees:   0   1   2   3   4   5
           ●   ●   ●   ●   ●   ●

After union(0, 1):
  Parent:  0   0   2   3   4   5

  Trees:   0       2   3   4   5
          /        ●   ●   ●   ●
         1

After union(1, 2):  [find(1)=0, so union(0,2)]
  Parent:  0   0   0   3   4   5

  Trees:   0       3   4   5
          /\       ●   ●   ●
         1  2

After union(3, 4):
  Parent:  0   0   0   3   3   5

  Trees:   0       3       5
          /\      /        ●
         1  2    4

  Path compression example:
  ┌────────────────────────────────────────┐
  │ Before find(1):    After find(1):      │
  │      0                  0              │
  │     /                 / | \            │
  │    1        →        1  2  (flattened) │
  │   /                                    │
  │  2                                     │
  └────────────────────────────────────────┘`,
					Steps: []Step{
						{Description: "Initialize: each node is own parent", State: "6 separate components"},
						{Description: "union(0,1): link 1 to 0", State: "5 components"},
						{Description: "union(1,2): find(1)=0, link 2 to 0", State: "4 components"},
						{Description: "union(3,4): link 4 to 3", State: "3 components"},
					},
				},
			},
		},
		{
			ID:          "manhattan-distance",
			Name:        "Manhattan Distance & Grid Geometry",
			Category:    "Geometry",
			Tags:        []string{"grid", "distance", "taxicab"},
			Difficulty:  "Beginner",
			Description: "Distance measured as sum of absolute differences in coordinates. Natural metric for grid-based movement with 4-directional moves.",
			WhenToUse: []string{
				"Grid pathfinding heuristics",
				"Taxicab geometry problems",
				"Problems with 4-directional movement",
			},
			PseudoCode: `function manhattan_distance(p1, p2):
    return abs(p1.x - p2.x) + abs(p1.y - p2.y)

# Common grid directions
FOUR_DIRECTIONS = [(0,1), (0,-1), (1,0), (-1,0)]
EIGHT_DIRECTIONS = FOUR_DIRECTIONS + [(1,1), (1,-1), (-1,1), (-1,-1)]

function get_neighbors(x, y, grid):
    neighbors = []
    for (dx, dy) in FOUR_DIRECTIONS:
        nx, ny = x + dx, y + dy
        if in_bounds(nx, ny, grid):
            neighbors.append((nx, ny))
    return neighbors`,
			Complexity: Complexity{
				Time:  "O(1) for distance calculation",
				Space: "O(1)",
			},
			AoCExamples: []string{
				"Day 15 2022 - Beacon Exclusion Zone",
				"Day 3 2019 - Crossed Wires",
				"Nearly every grid puzzle",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Taxicab_geometry",
			},
			Examples: []Example{
				{
					Title:       "Manhattan vs Euclidean Distance",
					Description: "Compare distances from (0,0) to (3,4)",
					Input:       "Points: (0,0) and (3,4)",
					Output:      "Manhattan: 7, Euclidean: 5",
					Visual: `Euclidean (straight line):  Manhattan (grid path):

    4 ─┼───────────●         4 ─┼───────────●
      │          ╱             │           │
    3 ─┼────────╱──            3 ─┼─────────│─
      │       ╱                  │         │
    2 ─┼──────╱────            2 ─┼─────────│─
      │     ╱                    │         │
    1 ─┼────╱──────            1 ─┼─────────│─
      │   ╱                      │         │
    0 ─●─╱─┼───┼───┼           0 ─●───●───●─│─●
      │                          │
      └──┼───┼───┼───          └──┼───┼───┼───
         1   2   3                 1   2   3

  Euclidean: √(3² + 4²) = √25 = 5
  Manhattan: |3-0| + |4-0| = 3 + 4 = 7

  Points at Manhattan distance 2 from origin:
              ●              All points where
            ● ● ●            |x| + |y| = 2
          ●   ●   ●          Forms a diamond!
            ● ● ●
              ●`,
					Steps: []Step{
						{Description: "Manhattan: sum of |Δx| and |Δy|", State: "3 + 4 = 7"},
						{Description: "Euclidean: √(Δx² + Δy²)", State: "√25 = 5"},
						{Description: "Manhattan forms diamond shapes", State: "Not circles!"},
					},
				},
			},
		},
		{
			ID:          "backtracking",
			Name:        "Backtracking",
			Category:    "Search",
			Tags:        []string{"recursion", "constraint", "pruning"},
			Difficulty:  "Intermediate",
			Description: "Systematically explore all possible solutions by building candidates incrementally and abandoning (backtracking) when constraints are violated.",
			WhenToUse: []string{
				"Constraint satisfaction problems",
				"Generating all permutations/combinations",
				"Sudoku, N-Queens type puzzles",
				"When you need to explore all possibilities",
			},
			PseudoCode: `function backtrack(state, choices):
    if is_solution(state):
        process_solution(state)
        return

    for choice in choices:
        if is_valid(state, choice):
            apply(state, choice)
            backtrack(state, remaining_choices)
            undo(state, choice)  # Backtrack!`,
			Complexity: Complexity{
				Time:  "O(b^d) where b=branching, d=depth",
				Space: "O(d) for recursion stack",
			},
			AoCExamples: []string{
				"Day 19 2024 - Linen Layout",
				"Day 12 2023 - Hot Springs",
				"Day 21 2020 - Allergen Assessment",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Backtracking",
			},
			Examples: []Example{
				{
					Title:       "4-Queens Problem",
					Description: "Place 4 queens on 4x4 board so none attack each other",
					Input:       "4x4 chessboard",
					Output:      "2 solutions exist",
					Visual: `Backtracking exploration:

Try row 0:          Try row 1:         Conflict!
  Q . . .           Q . . .            Q . . .
  . . . .     →     . . Q .      →     . . Q .
  . . . .           . . . .            Q . . .  ← attacks Q in col 0!
  . . . .           . . . .            . . . .

Backtrack!          Try next:          Continue:
  Q . . .           Q . . .            Q . . .
  . . Q .     ←     . . . Q      →     . . . Q
  . . . .           . . . .            . Q . .  ✓
  . . . .           . . . .            . . . .

Complete!           Second solution:
  Q . . .           . . Q .
  . . . Q           Q . . .
  . Q . .           . . . Q
  . . . Q  ✓        . Q . .  ✓

  Pruning saves time:
  ┌─────────────────────────────────────────┐
  │ Without pruning: try all 4⁴ = 256 ways  │
  │ With pruning: only explore valid paths  │
  │ Early rejection = huge speedup!         │
  └─────────────────────────────────────────┘`,
					Steps: []Step{
						{Description: "Place Q at (0,0)", State: "Board: Q..."},
						{Description: "Try row 1, (1,2) is safe", State: "Board: Q../..Q."},
						{Description: "Row 2: (2,0) attacks (0,0)!", State: "Conflict - backtrack"},
						{Description: "Try (1,3) instead, find solution", State: "Solution found!"},
					},
				},
			},
		},
		{
			ID:          "priority-queue",
			Name:        "Priority Queue / Heap",
			Category:    "Data Structures",
			Tags:        []string{"heap", "sorting", "scheduling"},
			Difficulty:  "Intermediate",
			Description: "Data structure providing O(1) access to minimum/maximum element with O(log n) insertion and removal. Essential for Dijkstra's algorithm.",
			WhenToUse: []string{
				"Dijkstra's and A* algorithms",
				"K-th smallest/largest element",
				"Task scheduling by priority",
				"Merge K sorted lists",
			},
			PseudoCode: `class MinHeap:
    heap = []

    function insert(value):
        heap.append(value)
        bubble_up(length(heap) - 1)

    function extract_min():
        min_val = heap[0]
        heap[0] = heap.pop()
        bubble_down(0)
        return min_val

    function bubble_up(i):
        while i > 0 and heap[parent(i)] > heap[i]:
            swap(heap[parent(i)], heap[i])
            i = parent(i)`,
			Complexity: Complexity{
				Time:  "O(log n) insert/extract, O(1) peek",
				Space: "O(n)",
			},
			AoCExamples: []string{
				"Day 17 2023 - Clumsy Crucible",
				"Day 15 2021 - Chiton",
				"Any Dijkstra problem",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Binary_heap",
			},
			Examples: []Example{
				{
					Title:       "Min-Heap Operations",
					Description: "Insert and extract from a min-heap",
					Input:       "Insert: 5, 3, 7, 1. Then extract twice.",
					Output:      "Extracted: 1, then 3",
					Visual: `Min-Heap Property: Parent ≤ Children

Insert 5:        Insert 3:        Insert 7:
    [5]              [3]              [3]
                    /               /   \
                   5               5     7

Insert 1:        After bubble-up:
    [3]              [1]
   /   \            /   \
  5     7    →     3     7
 /                /
1                5

Extract min (1):              After bubble-down:
    [1]                           [3]
   /   \     Move 5 to root      /   \
  3     7    then bubble down   5     7
 /
5

Heap as array: [1, 3, 7, 5]
  Index:        0  1  2  3
  Parent(i) = (i-1)/2
  Left(i)   = 2i + 1
  Right(i)  = 2i + 2

  ┌────────────────────────────────────┐
  │ Min always at index 0              │
  │ Insert: add at end, bubble UP      │
  │ Extract: swap with last, bubble DN │
  └────────────────────────────────────┘`,
					Steps: []Step{
						{Description: "Insert 5 (first element)", State: "Heap: [5]"},
						{Description: "Insert 3, bubble up (3 < 5)", State: "Heap: [3, 5]"},
						{Description: "Insert 7 (no bubble needed)", State: "Heap: [3, 5, 7]"},
						{Description: "Insert 1, bubble up to root", State: "Heap: [1, 3, 7, 5]"},
						{Description: "Extract 1, bubble down 5", State: "Heap: [3, 5, 7]"},
					},
				},
			},
		},
	}
}
