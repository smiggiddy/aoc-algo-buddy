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

    return NOT_FOUND

# For shortest path, track parents:
function BFS_with_path(start, goal):
    queue = new Queue()
    visited = new Set()
    parent = new Map()

    queue.enqueue(start)
    visited.add(start)
    parent[start] = null

    while queue is not empty:
        current = queue.dequeue()

        if current == goal:
            return reconstruct_path(parent, goal)

        for each neighbor of current:
            if neighbor not in visited:
                visited.add(neighbor)
                parent[neighbor] = current
                queue.enqueue(neighbor)

    return NOT_FOUND`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(V + E) where V = vertices, E = edges",
				Space: "O(V) for the queue and visited set",
			},
			AoCExamples: []string{
				"Day 12 2022 - Hill Climbing Algorithm (shortest path on grid)",
				"Day 15 2016 - Timing is Everything (maze navigation)",
				"Day 13 2019 - Care Package (maze exploration)",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Breadth-first_search",
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
				"Path existence (not shortest path)",
			},
			PseudoCode: `# Recursive version
function DFS(node, visited):
    if node in visited:
        return

    visited.add(node)
    process(node)

    for each neighbor of node:
        DFS(neighbor, visited)

# Iterative version
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
            if neighbor not in visited:
                stack.push(neighbor)`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(V + E) where V = vertices, E = edges",
				Space: "O(V) for recursion stack / explicit stack",
			},
			AoCExamples: []string{
				"Day 12 2021 - Passage Pathing (cave exploration)",
				"Day 7 2022 - No Space Left On Device (directory traversal)",
				"Day 18 2021 - Snailfish (tree traversal)",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Depth-first_search",
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
    distances = new Map()  # Initialize all to infinity
    distances[start] = 0
    previous = new Map()
    pq = new PriorityQueue()  # Min-heap by distance

    pq.insert(start, 0)

    while pq is not empty:
        current, dist = pq.extract_min()

        if current == goal:
            return reconstruct_path(previous, goal)

        if dist > distances[current]:
            continue  # Skip if we found a better path

        for each (neighbor, weight) of graph[current]:
            new_dist = distances[current] + weight

            if new_dist < distances[neighbor]:
                distances[neighbor] = new_dist
                previous[neighbor] = current
                pq.insert(neighbor, new_dist)

    return distances  # Or specific path if goal specified`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O((V + E) log V) with binary heap",
				Space: "O(V) for distances and priority queue",
			},
			AoCExamples: []string{
				"Day 15 2021 - Chiton (grid with varying costs)",
				"Day 17 2023 - Clumsy Crucible (constrained pathfinding)",
				"Day 23 2021 - Amphipod (state-space search)",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm",
			},
		},
		{
			ID:          "astar",
			Name:        "A* Search Algorithm",
			Category:    "Graph",
			Tags:        []string{"shortest-path", "heuristic", "pathfinding", "grid"},
			Difficulty:  "Intermediate",
			Description: "An informed search algorithm that uses heuristics to find the shortest path more efficiently than Dijkstra. Combines actual distance traveled with estimated distance to goal.",
			WhenToUse: []string{
				"Pathfinding when you have a good heuristic",
				"Grid-based navigation",
				"When Dijkstra is too slow and you can estimate remaining distance",
			},
			PseudoCode: `function AStar(start, goal, heuristic):
    open_set = new PriorityQueue()  # Min-heap by f_score
    came_from = new Map()

    g_score = new Map()  # Cost from start
    g_score[start] = 0

    f_score = new Map()  # g_score + heuristic estimate
    f_score[start] = heuristic(start, goal)

    open_set.insert(start, f_score[start])

    while open_set is not empty:
        current = open_set.extract_min()

        if current == goal:
            return reconstruct_path(came_from, current)

        for each neighbor of current:
            tentative_g = g_score[current] + distance(current, neighbor)

            if tentative_g < g_score[neighbor]:
                came_from[neighbor] = current
                g_score[neighbor] = tentative_g
                f_score[neighbor] = tentative_g + heuristic(neighbor, goal)

                if neighbor not in open_set:
                    open_set.insert(neighbor, f_score[neighbor])

    return FAILURE

# Common heuristics for grids:
function manhattan_distance(a, b):
    return abs(a.x - b.x) + abs(a.y - b.y)

function euclidean_distance(a, b):
    return sqrt((a.x - b.x)^2 + (a.y - b.y)^2)`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(E) in best case, O(V log V) worst case",
				Space: "O(V) for open and closed sets",
			},
			AoCExamples: []string{
				"Day 12 2022 - Hill Climbing (with elevation heuristic)",
				"Day 15 2021 - Chiton (Manhattan distance heuristic)",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/A*_search_algorithm",
			},
		},
		{
			ID:          "topological-sort",
			Name:        "Topological Sort",
			Category:    "Graph",
			Tags:        []string{"dag", "ordering", "dependencies"},
			Difficulty:  "Intermediate",
			Description: "Orders vertices of a directed acyclic graph (DAG) such that for every edge (u, v), u comes before v. Essential for dependency resolution.",
			WhenToUse: []string{
				"Task scheduling with dependencies",
				"Build systems and compilation order",
				"Course prerequisites",
				"Any dependency resolution problem",
			},
			PseudoCode: `# Kahn's Algorithm (BFS-based)
function topological_sort_kahn(graph):
    in_degree = count incoming edges for each node
    queue = all nodes with in_degree == 0
    result = []

    while queue is not empty:
        node = queue.dequeue()
        result.append(node)

        for each neighbor of node:
            in_degree[neighbor] -= 1
            if in_degree[neighbor] == 0:
                queue.enqueue(neighbor)

    if length(result) != number of nodes:
        return CYCLE_DETECTED

    return result

# DFS-based approach
function topological_sort_dfs(graph):
    visited = new Set()
    stack = []

    function dfs(node):
        visited.add(node)
        for each neighbor of node:
            if neighbor not in visited:
                dfs(neighbor)
        stack.push(node)

    for each node in graph:
        if node not in visited:
            dfs(node)

    return reverse(stack)`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(V + E)",
				Space: "O(V)",
			},
			AoCExamples: []string{
				"Day 7 2018 - The Sum of Its Parts (task ordering)",
				"Day 5 2019 - Sunny with a Chance of Asteroids (instruction ordering)",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Topological_sorting",
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
			PseudoCode: `# Recursive flood fill
function flood_fill(grid, x, y, target, replacement):
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
    flood_fill(grid, x, y - 1, target, replacement)

# BFS version (avoids stack overflow)
function flood_fill_bfs(grid, start_x, start_y, target, replacement):
    if grid[start_y][start_x] != target:
        return

    queue = new Queue()
    queue.enqueue((start_x, start_y))

    while queue is not empty:
        x, y = queue.dequeue()

        if grid[y][x] != target:
            continue

        grid[y][x] = replacement

        for (dx, dy) in [(0,1), (0,-1), (1,0), (-1,0)]:
            nx, ny = x + dx, y + dy
            if 0 <= nx < width and 0 <= ny < height:
                if grid[ny][nx] == target:
                    queue.enqueue((nx, ny))`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(N) where N = number of cells",
				Space: "O(N) for recursion stack or queue",
			},
			AoCExamples: []string{
				"Day 9 2021 - Smoke Basin (finding basins)",
				"Day 12 2022 - Garden Groups (area calculation)",
				"Day 10 2023 - Pipe Maze (enclosed area)",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Flood_fill",
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
			PseudoCode: `# Without memoization (exponential time)
function fib(n):
    if n <= 1:
        return n
    return fib(n-1) + fib(n-2)

# With memoization (linear time)
memo = {}

function fib_memo(n):
    if n in memo:
        return memo[n]

    if n <= 1:
        result = n
    else:
        result = fib_memo(n-1) + fib_memo(n-2)

    memo[n] = result
    return result

# Generic memoization pattern
function memoize(func):
    cache = {}

    function wrapper(*args):
        key = args  # Or create hashable key
        if key not in cache:
            cache[key] = func(*args)
        return cache[key]

    return wrapper`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "Reduces exponential to polynomial in most cases",
				Space: "O(N) for cache storage",
			},
			AoCExamples: []string{
				"Day 12 2023 - Hot Springs (arrangement counting)",
				"Day 19 2024 - Linen Layout (pattern matching)",
				"Day 10 2020 - Adapter Array (path counting)",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Memoization",
			},
		},
		{
			ID:          "tabulation",
			Name:        "Tabulation (Bottom-Up DP)",
			Category:    "Dynamic Programming",
			Tags:        []string{"iteration", "table", "optimization"},
			Difficulty:  "Intermediate",
			Description: "Builds solution iteratively from smallest subproblems to larger ones using a table. Bottom-up approach that avoids recursion overhead.",
			WhenToUse: []string{
				"When you can define clear subproblem structure",
				"To avoid recursion stack limits",
				"When iterative solution is more intuitive",
			},
			PseudoCode: `# Fibonacci with tabulation
function fib_tabulation(n):
    if n <= 1:
        return n

    dp = new Array(n + 1)
    dp[0] = 0
    dp[1] = 1

    for i from 2 to n:
        dp[i] = dp[i-1] + dp[i-2]

    return dp[n]

# Space-optimized version
function fib_optimized(n):
    if n <= 1:
        return n

    prev2 = 0
    prev1 = 1

    for i from 2 to n:
        current = prev1 + prev2
        prev2 = prev1
        prev1 = current

    return prev1

# Generic 1D DP pattern
function solve_1d_dp(input, n):
    dp = new Array(n + 1)
    dp[0] = base_case

    for i from 1 to n:
        dp[i] = combine(dp[j] for relevant j < i)

    return dp[n]`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(N × transitions) typically",
				Space: "O(N) for table, can often be O(1)",
			},
			AoCExamples: []string{
				"Day 10 2020 - Adapter Array",
				"Day 7 2021 - The Treachery of Whales (fuel optimization)",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Dynamic_programming",
			},
		},
		{
			ID:          "longest-common-subsequence",
			Name:        "Longest Common Subsequence (LCS)",
			Category:    "Dynamic Programming",
			Tags:        []string{"string", "sequence", "2d-dp"},
			Difficulty:  "Intermediate",
			Description: "Finds the longest subsequence common to two sequences. A subsequence maintains relative order but doesn't need to be contiguous.",
			WhenToUse: []string{
				"Comparing strings or sequences",
				"Diff algorithms",
				"DNA sequence alignment",
				"Finding similarity between sequences",
			},
			PseudoCode: `function LCS(X, Y):
    m = length(X)
    n = length(Y)
    dp = new Array[m+1][n+1]

    # Initialize first row and column to 0
    for i from 0 to m: dp[i][0] = 0
    for j from 0 to n: dp[0][j] = 0

    # Fill the table
    for i from 1 to m:
        for j from 1 to n:
            if X[i-1] == Y[j-1]:
                dp[i][j] = dp[i-1][j-1] + 1
            else:
                dp[i][j] = max(dp[i-1][j], dp[i][j-1])

    return dp[m][n]

# To reconstruct the actual subsequence:
function reconstruct_LCS(X, Y, dp):
    result = []
    i, j = length(X), length(Y)

    while i > 0 and j > 0:
        if X[i-1] == Y[j-1]:
            result.prepend(X[i-1])
            i -= 1
            j -= 1
        elif dp[i-1][j] > dp[i][j-1]:
            i -= 1
        else:
            j -= 1

    return result`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(m × n)",
				Space: "O(m × n), can be O(min(m,n)) if only length needed",
			},
			AoCExamples: []string{
				"Pattern matching and string comparison problems",
				"Day 19 2020 - Monster Messages (pattern matching)",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Longest_common_subsequence_problem",
			},
		},
		{
			ID:          "knapsack",
			Name:        "Knapsack Problem",
			Category:    "Dynamic Programming",
			Tags:        []string{"optimization", "subset", "bounded"},
			Difficulty:  "Intermediate",
			Description: "Select items with given weights and values to maximize value while staying within weight capacity. Foundation for many optimization problems.",
			WhenToUse: []string{
				"Resource allocation with constraints",
				"Subset selection to maximize/minimize value",
				"Budget optimization",
			},
			PseudoCode: `# 0/1 Knapsack (each item used at most once)
function knapsack_01(weights, values, capacity):
    n = length(weights)
    dp = new Array[n+1][capacity+1]

    for i from 0 to n:
        for w from 0 to capacity:
            if i == 0 or w == 0:
                dp[i][w] = 0
            elif weights[i-1] <= w:
                # Max of: include item or exclude item
                dp[i][w] = max(
                    values[i-1] + dp[i-1][w - weights[i-1]],
                    dp[i-1][w]
                )
            else:
                dp[i][w] = dp[i-1][w]

    return dp[n][capacity]

# Unbounded Knapsack (unlimited items)
function knapsack_unbounded(weights, values, capacity):
    dp = new Array[capacity + 1] filled with 0

    for w from 1 to capacity:
        for i from 0 to length(weights) - 1:
            if weights[i] <= w:
                dp[w] = max(dp[w], dp[w - weights[i]] + values[i])

    return dp[capacity]`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(n × capacity)",
				Space: "O(n × capacity), can be O(capacity) for 1D",
			},
			AoCExamples: []string{
				"Day 7 2021 - Treachery of Whales (optimization)",
				"Resource allocation puzzles",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Knapsack_problem",
			},
		},

		// String Algorithms
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
function fixed_sliding_window(arr, k):
    n = length(arr)
    window_sum = sum(arr[0:k])
    max_sum = window_sum

    for i from k to n - 1:
        # Slide window: remove left, add right
        window_sum = window_sum - arr[i - k] + arr[i]
        max_sum = max(max_sum, window_sum)

    return max_sum

# Variable-size window (e.g., smallest subarray with sum >= target)
function variable_sliding_window(arr, target):
    n = length(arr)
    left = 0
    current_sum = 0
    min_length = infinity

    for right from 0 to n - 1:
        current_sum += arr[right]

        while current_sum >= target:
            min_length = min(min_length, right - left + 1)
            current_sum -= arr[left]
            left += 1

    return min_length if min_length != infinity else 0

# Character frequency window
function find_anagrams(text, pattern):
    result = []
    p_count = character_frequency(pattern)
    w_count = {}

    for i from 0 to length(text) - 1:
        # Add character to window
        w_count[text[i]] += 1

        # Remove character outside window
        if i >= length(pattern):
            left_char = text[i - length(pattern)]
            w_count[left_char] -= 1
            if w_count[left_char] == 0:
                delete w_count[left_char]

        # Check if window matches pattern
        if w_count == p_count:
            result.append(i - length(pattern) + 1)

    return result`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(n) single pass",
				Space: "O(k) or O(1) depending on window tracking",
			},
			AoCExamples: []string{
				"Day 6 2022 - Tuning Trouble (start-of-packet marker)",
				"Day 1 2023 - Trebuchet (digit finding)",
				"Signal processing problems",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Sliding_window_protocol",
			},
		},
		{
			ID:          "two-pointers",
			Name:        "Two Pointers Technique",
			Category:    "String",
			Tags:        []string{"array", "sorted", "optimization"},
			Difficulty:  "Beginner",
			Description: "Uses two pointers to traverse data structure, typically from opposite ends or at different speeds. Efficient for sorted arrays and linked lists.",
			WhenToUse: []string{
				"Finding pairs in sorted arrays",
				"Removing duplicates in-place",
				"Palindrome checking",
				"Merging sorted arrays",
			},
			PseudoCode: `# Two pointers from opposite ends (pair sum)
function two_sum_sorted(arr, target):
    left = 0
    right = length(arr) - 1

    while left < right:
        current_sum = arr[left] + arr[right]

        if current_sum == target:
            return (left, right)
        elif current_sum < target:
            left += 1
        else:
            right -= 1

    return NOT_FOUND

# Fast and slow pointers (cycle detection)
function has_cycle(head):
    slow = head
    fast = head

    while fast != null and fast.next != null:
        slow = slow.next
        fast = fast.next.next

        if slow == fast:
            return true

    return false

# Remove duplicates from sorted array
function remove_duplicates(arr):
    if length(arr) == 0:
        return 0

    write_pos = 1

    for read_pos from 1 to length(arr) - 1:
        if arr[read_pos] != arr[read_pos - 1]:
            arr[write_pos] = arr[read_pos]
            write_pos += 1

    return write_pos`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(n) single pass",
				Space: "O(1) typically",
			},
			AoCExamples: []string{
				"Day 1 2020 - Report Repair (two-sum variant)",
				"Sorted data problems",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Two_pointers_technique",
			},
		},
		{
			ID:          "parsing",
			Name:        "Recursive Descent Parsing",
			Category:    "String",
			Tags:        []string{"expression", "grammar", "recursion"},
			Difficulty:  "Advanced",
			Description: "Parses expressions by building a parser from grammar rules. Each rule becomes a function that may recursively call other rule functions.",
			WhenToUse: []string{
				"Mathematical expression evaluation",
				"Custom language parsing",
				"Nested structure processing",
				"Operator precedence handling",
			},
			PseudoCode: `# Expression grammar:
# expr   -> term (('+' | '-') term)*
# term   -> factor (('*' | '/') factor)*
# factor -> NUMBER | '(' expr ')'

class Parser:
    tokens = []
    pos = 0

    function parse(input):
        tokens = tokenize(input)
        pos = 0
        return expr()

    function expr():
        result = term()

        while current_token() in ['+', '-']:
            op = consume()
            right = term()
            if op == '+':
                result = result + right
            else:
                result = result - right

        return result

    function term():
        result = factor()

        while current_token() in ['*', '/']:
            op = consume()
            right = factor()
            if op == '*':
                result = result * right
            else:
                result = result / right

        return result

    function factor():
        if current_token() == '(':
            consume()  # eat '('
            result = expr()
            consume()  # eat ')'
            return result
        else:
            return parse_number(consume())

    function current_token():
        return tokens[pos] if pos < length(tokens) else null

    function consume():
        token = current_token()
        pos += 1
        return token`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(n) for most grammars",
				Space: "O(depth) for recursion stack",
			},
			AoCExamples: []string{
				"Day 18 2020 - Operation Order (custom operator precedence)",
				"Day 13 2022 - Distress Signal (nested list parsing)",
				"Day 18 2021 - Snailfish (nested number operations)",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Recursive_descent_parser",
			},
		},

		// Math & Number Theory
		{
			ID:          "gcd-lcm",
			Name:        "GCD and LCM",
			Category:    "Math",
			Tags:        []string{"number-theory", "euclidean", "modular"},
			Difficulty:  "Beginner",
			Description: "Greatest Common Divisor and Least Common Multiple - fundamental number theory algorithms used in cycle detection, synchronization, and modular arithmetic.",
			WhenToUse: []string{
				"Finding when cycles align",
				"Reducing fractions",
				"Synchronization problems",
				"Modular arithmetic",
			},
			PseudoCode: `# Euclidean algorithm for GCD
function gcd(a, b):
    while b != 0:
        a, b = b, a mod b
    return a

# Recursive version
function gcd_recursive(a, b):
    if b == 0:
        return a
    return gcd_recursive(b, a mod b)

# LCM using GCD
function lcm(a, b):
    return (a * b) / gcd(a, b)

# LCM of multiple numbers
function lcm_multiple(numbers):
    result = numbers[0]
    for i from 1 to length(numbers) - 1:
        result = lcm(result, numbers[i])
    return result

# Extended Euclidean Algorithm (finds x, y where ax + by = gcd(a,b))
function extended_gcd(a, b):
    if b == 0:
        return (a, 1, 0)

    gcd, x1, y1 = extended_gcd(b, a mod b)
    x = y1
    y = x1 - (a / b) * y1

    return (gcd, x, y)`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(log(min(a,b))) for GCD",
				Space: "O(1) iterative, O(log n) recursive",
			},
			AoCExamples: []string{
				"Day 8 2023 - Haunted Wasteland (cycle alignment with LCM)",
				"Day 12 2019 - N-Body Problem (orbital periods)",
				"Day 13 2017 - Packet Scanners",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Euclidean_algorithm",
			},
		},
		{
			ID:          "modular-arithmetic",
			Name:        "Modular Arithmetic",
			Category:    "Math",
			Tags:        []string{"number-theory", "cryptography", "cycles"},
			Difficulty:  "Intermediate",
			Description: "Arithmetic operations with remainders. Essential for handling large numbers, cycle detection, and many AoC problems involving repetition.",
			WhenToUse: []string{
				"Preventing integer overflow",
				"Problems with cycles or periodicity",
				"When answer is too large, mod by some value",
				"Chinese Remainder Theorem problems",
			},
			PseudoCode: `# Basic modular operations
function mod_add(a, b, m):
    return ((a mod m) + (b mod m)) mod m

function mod_subtract(a, b, m):
    return ((a mod m) - (b mod m) + m) mod m

function mod_multiply(a, b, m):
    return ((a mod m) * (b mod m)) mod m

# Modular exponentiation (a^b mod m)
function mod_pow(base, exp, mod):
    result = 1
    base = base mod mod

    while exp > 0:
        if exp is odd:
            result = (result * base) mod mod
        exp = exp / 2  # integer division
        base = (base * base) mod mod

    return result

# Modular inverse using Fermat's little theorem (when mod is prime)
function mod_inverse(a, prime):
    return mod_pow(a, prime - 2, prime)

# Chinese Remainder Theorem
function CRT(remainders, moduli):
    # Find x such that x ≡ remainders[i] (mod moduli[i])
    M = product of all moduli
    result = 0

    for i from 0 to length(remainders) - 1:
        Mi = M / moduli[i]
        yi = mod_inverse(Mi, moduli[i])
        result += remainders[i] * Mi * yi

    return result mod M`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(log exp) for mod_pow, O(n²) for CRT",
				Space: "O(1) for basic operations",
			},
			AoCExamples: []string{
				"Day 13 2020 - Shuttle Search (Chinese Remainder Theorem)",
				"Day 22 2019 - Slam Shuffle (modular arithmetic)",
				"Day 25 2020 - Combo Breaker (discrete logarithm)",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Modular_arithmetic",
				"https://en.wikipedia.org/wiki/Chinese_remainder_theorem",
			},
		},
		{
			ID:          "sieve-of-eratosthenes",
			Name:        "Sieve of Eratosthenes",
			Category:    "Math",
			Tags:        []string{"primes", "number-theory"},
			Difficulty:  "Beginner",
			Description: "Efficiently finds all prime numbers up to a given limit by iteratively marking composites. Foundation for prime-related algorithms.",
			WhenToUse: []string{
				"Generating all primes up to N",
				"Checking primality of multiple numbers",
				"Problems involving prime factorization",
			},
			PseudoCode: `function sieve_of_eratosthenes(n):
    # Create boolean array, index i represents whether i is prime
    is_prime = new Array[n + 1] filled with true
    is_prime[0] = false
    is_prime[1] = false

    for i from 2 to sqrt(n):
        if is_prime[i]:
            # Mark all multiples of i as not prime
            for j from i*i to n, step i:
                is_prime[j] = false

    # Collect primes
    primes = []
    for i from 2 to n:
        if is_prime[i]:
            primes.append(i)

    return primes

# Optimized: only odd numbers (after 2)
function sieve_optimized(n):
    if n < 2: return []

    # Only track odd numbers
    size = (n - 1) / 2
    is_prime = new Array[size + 1] filled with true

    for i from 1 to sqrt(n) / 2:
        if is_prime[i]:
            # i represents odd number 2i + 1
            # Mark multiples
            p = 2 * i + 1
            for j from 2*i*(i+1) to size, step p:
                is_prime[j] = false

    primes = [2]
    for i from 1 to size:
        if is_prime[i]:
            primes.append(2 * i + 1)

    return primes`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(n log log n)",
				Space: "O(n)",
			},
			AoCExamples: []string{
				"Problems involving prime numbers",
				"Factorization-based puzzles",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Sieve_of_Eratosthenes",
			},
		},

		// Data Structures
		{
			ID:          "priority-queue",
			Name:        "Priority Queue / Heap",
			Category:    "Data Structures",
			Tags:        []string{"heap", "sorting", "scheduling"},
			Difficulty:  "Intermediate",
			Description: "Data structure that always gives quick access to the minimum (or maximum) element. Essential for Dijkstra's algorithm and many scheduling problems.",
			WhenToUse: []string{
				"Dijkstra's and A* algorithms",
				"K-th smallest/largest element",
				"Task scheduling by priority",
				"Merge K sorted lists",
			},
			PseudoCode: `# Min-heap implementation
class MinHeap:
    heap = []

    function parent(i): return (i - 1) / 2
    function left(i): return 2 * i + 1
    function right(i): return 2 * i + 2

    function insert(value):
        heap.append(value)
        bubble_up(length(heap) - 1)

    function bubble_up(i):
        while i > 0 and heap[parent(i)] > heap[i]:
            swap(heap[parent(i)], heap[i])
            i = parent(i)

    function extract_min():
        if heap is empty:
            return null

        min_val = heap[0]
        heap[0] = heap[length(heap) - 1]
        heap.pop()

        if heap is not empty:
            bubble_down(0)

        return min_val

    function bubble_down(i):
        min_index = i
        l = left(i)
        r = right(i)

        if l < length(heap) and heap[l] < heap[min_index]:
            min_index = l
        if r < length(heap) and heap[r] < heap[min_index]:
            min_index = r

        if min_index != i:
            swap(heap[i], heap[min_index])
            bubble_down(min_index)

    function peek():
        return heap[0] if heap is not empty else null`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(log n) insert/extract, O(1) peek",
				Space: "O(n)",
			},
			AoCExamples: []string{
				"Any Dijkstra problem",
				"Day 17 2023 - Clumsy Crucible",
				"Day 15 2021 - Chiton",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Priority_queue",
				"https://en.wikipedia.org/wiki/Binary_heap",
			},
		},
		{
			ID:          "union-find",
			Name:        "Union-Find (Disjoint Set)",
			Category:    "Data Structures",
			Tags:        []string{"graph", "connected-components", "grouping"},
			Difficulty:  "Intermediate",
			Description: "Efficiently tracks elements partitioned into disjoint sets. Supports near-constant time union and find operations with path compression and union by rank.",
			WhenToUse: []string{
				"Finding connected components",
				"Kruskal's minimum spanning tree",
				"Detecting cycles in undirected graphs",
				"Dynamic connectivity queries",
			},
			PseudoCode: `class UnionFind:
    parent = []  # parent[i] = parent of i
    rank = []    # rank[i] = approximate depth of tree rooted at i

    function initialize(n):
        for i from 0 to n - 1:
            parent[i] = i   # Each element is its own parent
            rank[i] = 0

    function find(x):
        # Path compression: make every node point to root
        if parent[x] != x:
            parent[x] = find(parent[x])
        return parent[x]

    function union(x, y):
        root_x = find(x)
        root_y = find(y)

        if root_x == root_y:
            return false  # Already in same set

        # Union by rank: attach smaller tree under larger
        if rank[root_x] < rank[root_y]:
            parent[root_x] = root_y
        elif rank[root_x] > rank[root_y]:
            parent[root_y] = root_x
        else:
            parent[root_y] = root_x
            rank[root_x] += 1

        return true

    function connected(x, y):
        return find(x) == find(y)

    function count_components():
        roots = new Set()
        for i from 0 to n - 1:
            roots.add(find(i))
        return length(roots)`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(α(n)) per operation (nearly constant)",
				Space: "O(n)",
			},
			AoCExamples: []string{
				"Day 12 2017 - Digital Plumber (connected components)",
				"Day 25 2019 - Four-Dimensional Adventure",
				"Grid region grouping problems",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Disjoint-set_data_structure",
			},
		},
		{
			ID:          "trie",
			Name:        "Trie (Prefix Tree)",
			Category:    "Data Structures",
			Tags:        []string{"string", "prefix", "autocomplete"},
			Difficulty:  "Intermediate",
			Description: "Tree structure for storing strings where each node represents a character. Enables efficient prefix-based operations and string matching.",
			WhenToUse: []string{
				"Autocomplete functionality",
				"Spell checking",
				"IP routing (longest prefix match)",
				"Word games and puzzles",
			},
			PseudoCode: `class TrieNode:
    children = {}      # Map from character to TrieNode
    is_end_of_word = false
    value = null       # Optional value stored at word end

class Trie:
    root = new TrieNode()

    function insert(word, value = null):
        node = root

        for char in word:
            if char not in node.children:
                node.children[char] = new TrieNode()
            node = node.children[char]

        node.is_end_of_word = true
        node.value = value

    function search(word):
        node = find_node(word)
        return node != null and node.is_end_of_word

    function starts_with(prefix):
        return find_node(prefix) != null

    function find_node(s):
        node = root
        for char in s:
            if char not in node.children:
                return null
            node = node.children[char]
        return node

    function get_all_words_with_prefix(prefix):
        node = find_node(prefix)
        if node == null:
            return []

        results = []
        collect_words(node, prefix, results)
        return results

    function collect_words(node, current_word, results):
        if node.is_end_of_word:
            results.append(current_word)

        for char, child in node.children:
            collect_words(child, current_word + char, results)`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(m) for insert/search where m = word length",
				Space: "O(alphabet_size × m × n) for n words",
			},
			AoCExamples: []string{
				"Day 19 2023 - Aplenty (pattern matching)",
				"Word search and pattern problems",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Trie",
			},
		},

		// Simulation & State
		{
			ID:          "state-space-search",
			Name:        "State Space Search",
			Category:    "Simulation",
			Tags:        []string{"bfs", "dfs", "optimization", "puzzle"},
			Difficulty:  "Intermediate",
			Description: "Model a problem as states and transitions, then search for goal state. Key is defining state representation that captures all relevant information.",
			WhenToUse: []string{
				"Puzzle solving (15-puzzle, Rubik's cube)",
				"Game state exploration",
				"Resource management problems",
				"When problem can be modeled as state transitions",
			},
			PseudoCode: `# Generic state space search framework
class State:
    # Define what constitutes a state
    # Must be hashable for visited set

    function get_neighbors():
        # Return list of (next_state, cost) tuples
        pass

    function is_goal():
        # Return true if this is a goal state
        pass

    function heuristic():
        # Estimated cost to goal (for A*)
        pass

function state_space_search(initial_state):
    # BFS for shortest path (unweighted)
    queue = new Queue()
    visited = new Set()
    parent = new Map()

    queue.enqueue(initial_state)
    visited.add(initial_state.hash())

    while queue is not empty:
        current = queue.dequeue()

        if current.is_goal():
            return reconstruct_path(parent, current)

        for (next_state, cost) in current.get_neighbors():
            state_hash = next_state.hash()
            if state_hash not in visited:
                visited.add(state_hash)
                parent[state_hash] = current
                queue.enqueue(next_state)

    return null

# Example: State representation tips
# - Include only information needed to determine valid moves
# - Use tuples/frozensets for hashability
# - Consider symmetry reduction (equivalent states)
# - Normalize state representation when possible

# State hash example for a game with positions
function state_hash(player_pos, enemy_positions, items_collected):
    return (player_pos, frozenset(enemy_positions), frozenset(items_collected))`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(states × transitions)",
				Space: "O(states) for visited set",
			},
			AoCExamples: []string{
				"Day 23 2021 - Amphipod",
				"Day 24 2016 - Air Duct Spelunking",
				"Day 11 2016 - Radioisotope Thermoelectric Generators",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/State_space_search",
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
				"Linked list cycle detection",
				"Any problem saying 'repeat 1 billion times'",
			},
			PseudoCode: `# Detect cycle and extrapolate
function solve_with_cycle_detection(initial_state, target_iterations):
    seen = new Map()  # state -> iteration number
    states = [initial_state]  # store states in order
    current = initial_state

    for i from 0 to target_iterations - 1:
        state_hash = hash(current)

        if state_hash in seen:
            # Found cycle!
            cycle_start = seen[state_hash]
            cycle_length = i - cycle_start

            # Calculate final position in cycle
            remaining = target_iterations - cycle_start
            final_pos = cycle_start + (remaining mod cycle_length)

            return states[final_pos]

        seen[state_hash] = i
        states.append(current)
        current = next_state(current)

    return current

# Floyd's cycle detection (tortoise and hare)
function floyd_cycle_detection(start):
    # Find meeting point
    slow = start
    fast = start

    do:
        slow = next(slow)
        fast = next(next(fast))
    while slow != fast

    # Find cycle start
    slow = start
    while slow != fast:
        slow = next(slow)
        fast = next(fast)
    cycle_start = slow

    # Find cycle length
    length = 1
    fast = next(slow)
    while fast != slow:
        fast = next(fast)
        length += 1

    return (cycle_start, length)`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(cycle_start + cycle_length)",
				Space: "O(1) for Floyd's, O(n) for hash-based",
			},
			AoCExamples: []string{
				"Day 14 2023 - Parabolic Reflector Dish (1 billion tilts)",
				"Day 17 2022 - Pyroclastic Flow (1 trillion rocks)",
				"Day 12 2019 - N-Body Problem (orbital period)",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Cycle_detection",
			},
		},
		{
			ID:          "interval-handling",
			Name:        "Interval/Range Operations",
			Category:    "Simulation",
			Tags:        []string{"ranges", "merging", "coordinate-compression"},
			Difficulty:  "Intermediate",
			Description: "Techniques for handling ranges and intervals: merging, finding overlaps, coordinate compression for sparse data.",
			WhenToUse: []string{
				"Problems with overlapping ranges",
				"Calendar/scheduling problems",
				"When coordinates are sparse but ranges are important",
				"Sensor coverage problems",
			},
			PseudoCode: `# Merge overlapping intervals
function merge_intervals(intervals):
    if intervals is empty:
        return []

    # Sort by start time
    sort intervals by interval.start

    merged = [intervals[0]]

    for interval in intervals[1:]:
        last = merged[-1]

        if interval.start <= last.end:
            # Overlapping, merge them
            last.end = max(last.end, interval.end)
        else:
            # No overlap, add new interval
            merged.append(interval)

    return merged

# Find all gaps between intervals
function find_gaps(intervals, range_start, range_end):
    merged = merge_intervals(intervals)
    gaps = []
    current = range_start

    for interval in merged:
        if interval.start > current:
            gaps.append((current, interval.start - 1))
        current = max(current, interval.end + 1)

    if current <= range_end:
        gaps.append((current, range_end))

    return gaps

# Coordinate compression
function coordinate_compress(values):
    sorted_unique = sorted(set(values))
    compress = {}
    for i, val in enumerate(sorted_unique):
        compress[val] = i
    return compress

# Interval coverage counting (sweepline)
function count_coverage(intervals):
    events = []
    for (start, end) in intervals:
        events.append((start, 'start'))
        events.append((end + 1, 'end'))

    sort events by position

    active = 0
    coverage = {}
    prev_pos = null

    for (pos, type) in events:
        if prev_pos != null and active > 0:
            coverage[prev_pos:pos] = active

        if type == 'start':
            active += 1
        else:
            active -= 1

        prev_pos = pos

    return coverage`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(n log n) for sorting-based approaches",
				Space: "O(n) for storing intervals",
			},
			AoCExamples: []string{
				"Day 15 2022 - Beacon Exclusion Zone",
				"Day 5 2023 - If You Give A Seed A Fertilizer",
				"Day 22 2021 - Reactor Reboot (3D cubes)",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Interval_tree",
			},
		},

		// Geometry
		{
			ID:          "manhattan-distance",
			Name:        "Manhattan Distance & Grid Geometry",
			Category:    "Geometry",
			Tags:        []string{"grid", "distance", "taxicab"},
			Difficulty:  "Beginner",
			Description: "Distance measured as sum of absolute differences in coordinates. Natural metric for grid-based movement. Also covers common grid patterns.",
			WhenToUse: []string{
				"Grid pathfinding heuristics",
				"Taxicab geometry problems",
				"Problems with 4-directional movement",
			},
			PseudoCode: `# Manhattan distance
function manhattan_distance(p1, p2):
    return abs(p1.x - p2.x) + abs(p1.y - p2.y)

# 3D Manhattan distance
function manhattan_3d(p1, p2):
    return abs(p1.x - p2.x) + abs(p1.y - p2.y) + abs(p1.z - p2.z)

# Common grid directions
FOUR_DIRECTIONS = [(0, 1), (0, -1), (1, 0), (-1, 0)]
EIGHT_DIRECTIONS = [
    (0, 1), (0, -1), (1, 0), (-1, 0),  # Cardinal
    (1, 1), (1, -1), (-1, 1), (-1, -1)  # Diagonal
]

# Get all neighbors in a grid
function get_neighbors(grid, x, y, directions = FOUR_DIRECTIONS):
    neighbors = []
    for (dx, dy) in directions:
        nx, ny = x + dx, y + dy
        if 0 <= nx < width and 0 <= ny < height:
            neighbors.append((nx, ny))
    return neighbors

# Chebyshev distance (king's move)
function chebyshev_distance(p1, p2):
    return max(abs(p1.x - p2.x), abs(p1.y - p2.y))

# Points within Manhattan distance
function points_within_distance(center, dist):
    points = []
    for dx from -dist to dist:
        remaining = dist - abs(dx)
        for dy from -remaining to remaining:
            points.append((center.x + dx, center.y + dy))
    return points`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(1) for distance calculation",
				Space: "O(1)",
			},
			AoCExamples: []string{
				"Day 15 2022 - Beacon Exclusion Zone",
				"Day 3 2019 - Crossed Wires",
				"Nearly every grid-based puzzle",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Taxicab_geometry",
			},
		},
		{
			ID:          "shoelace-picks",
			Name:        "Shoelace Formula & Pick's Theorem",
			Category:    "Geometry",
			Tags:        []string{"polygon", "area", "lattice"},
			Difficulty:  "Intermediate",
			Description: "Shoelace calculates polygon area from coordinates. Pick's theorem relates area to interior and boundary lattice points. Often used together.",
			WhenToUse: []string{
				"Finding area of polygon from vertices",
				"Counting interior points in polygon",
				"Problems with grid-aligned polygons",
			},
			PseudoCode: `# Shoelace formula for polygon area
function shoelace_area(vertices):
    # vertices = [(x0, y0), (x1, y1), ..., (xn, yn)]
    # Last vertex connects back to first
    n = length(vertices)
    area = 0

    for i from 0 to n - 1:
        j = (i + 1) mod n
        area += vertices[i].x * vertices[j].y
        area -= vertices[j].x * vertices[i].y

    return abs(area) / 2

# Pick's theorem: A = i + b/2 - 1
# Where: A = area, i = interior points, b = boundary points
# Rearranged: i = A - b/2 + 1

function interior_points(vertices, boundary_count):
    area = shoelace_area(vertices)
    return area - boundary_count / 2 + 1

# Total lattice points (interior + boundary)
function total_lattice_points(vertices, boundary_count):
    interior = interior_points(vertices, boundary_count)
    return interior + boundary_count

# Count boundary points on line segment between lattice points
function boundary_points_on_segment(p1, p2):
    # Number of lattice points = GCD of coordinate differences + 1
    dx = abs(p2.x - p1.x)
    dy = abs(p2.y - p1.y)
    return gcd(dx, dy) + 1  # includes endpoints

# Total boundary points for polygon
function total_boundary_points(vertices):
    count = 0
    n = length(vertices)
    for i from 0 to n - 1:
        j = (i + 1) mod n
        # Subtract 1 to avoid double-counting vertices
        count += gcd(
            abs(vertices[j].x - vertices[i].x),
            abs(vertices[j].y - vertices[i].y)
        )
    return count`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(n) for n vertices",
				Space: "O(1)",
			},
			AoCExamples: []string{
				"Day 18 2023 - Lavaduct Lagoon",
				"Day 10 2023 - Pipe Maze (enclosed area)",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Shoelace_formula",
				"https://en.wikipedia.org/wiki/Pick%27s_theorem",
			},
		},

		// Search & Optimization
		{
			ID:          "binary-search",
			Name:        "Binary Search",
			Category:    "Search",
			Tags:        []string{"sorted", "divide-conquer", "optimization"},
			Difficulty:  "Beginner",
			Description: "Efficiently find a target value or boundary in sorted data by repeatedly halving the search space. Also used for optimization (binary search the answer).",
			WhenToUse: []string{
				"Searching in sorted arrays",
				"Finding insertion point",
				"Binary search the answer (optimization)",
				"Finding boundary where condition changes",
			},
			PseudoCode: `# Standard binary search
function binary_search(arr, target):
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

    return -1  # Not found

# Find leftmost (first) occurrence
function binary_search_left(arr, target):
    left = 0
    right = length(arr)

    while left < right:
        mid = left + (right - left) / 2
        if arr[mid] < target:
            left = mid + 1
        else:
            right = mid

    return left

# Find rightmost (last) occurrence
function binary_search_right(arr, target):
    left = 0
    right = length(arr)

    while left < right:
        mid = left + (right - left) / 2
        if arr[mid] <= target:
            left = mid + 1
        else:
            right = mid

    return left - 1

# Binary search the answer (optimization)
function binary_search_answer(low, high, is_feasible):
    # Find minimum value where is_feasible returns true
    while low < high:
        mid = low + (high - low) / 2
        if is_feasible(mid):
            high = mid
        else:
            low = mid + 1

    return low if is_feasible(low) else -1`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(log n)",
				Space: "O(1)",
			},
			AoCExamples: []string{
				"Day 7 2021 - Treachery of Whales",
				"Optimization problems",
				"Finding thresholds",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Binary_search_algorithm",
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
			PseudoCode: `# Generic backtracking template
function backtrack(state, choices):
    if is_solution(state):
        process_solution(state)
        return

    for choice in choices:
        if is_valid(state, choice):
            # Make choice
            apply(state, choice)

            # Recurse
            backtrack(state, get_remaining_choices(choices, choice))

            # Undo choice (backtrack)
            undo(state, choice)

# Example: Generate all permutations
function permutations(elements):
    result = []

    function backtrack(current, remaining):
        if remaining is empty:
            result.append(copy(current))
            return

        for i, element in enumerate(remaining):
            current.append(element)
            backtrack(current, remaining[:i] + remaining[i+1:])
            current.pop()

    backtrack([], elements)
    return result

# Example: N-Queens
function solve_n_queens(n):
    solutions = []

    function backtrack(row, columns, diag1, diag2, board):
        if row == n:
            solutions.append(copy(board))
            return

        for col from 0 to n - 1:
            if col in columns:
                continue
            if (row - col) in diag1:
                continue
            if (row + col) in diag2:
                continue

            columns.add(col)
            diag1.add(row - col)
            diag2.add(row + col)
            board.append(col)

            backtrack(row + 1, columns, diag1, diag2, board)

            columns.remove(col)
            diag1.remove(row - col)
            diag2.remove(row + col)
            board.pop()

    backtrack(0, {}, {}, {}, [])
    return solutions`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "O(b^d) where b = branching factor, d = depth",
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
		},

		// Bit Manipulation
		{
			ID:          "bit-manipulation",
			Name:        "Bit Manipulation",
			Category:    "Bit Operations",
			Tags:        []string{"binary", "bitmask", "optimization"},
			Difficulty:  "Intermediate",
			Description: "Operations on individual bits for efficient computation. Used for compact state representation, subset enumeration, and specific algorithmic tricks.",
			WhenToUse: []string{
				"Compact set representation",
				"Enumerating all subsets",
				"Low-level optimizations",
				"Problems with binary/on-off states",
			},
			PseudoCode: `# Basic operations
AND: a & b    # Both bits must be 1
OR:  a | b    # Either bit is 1
XOR: a ^ b    # Bits must differ
NOT: ~a       # Flip all bits
LEFT SHIFT:  a << n  # Multiply by 2^n
RIGHT SHIFT: a >> n  # Divide by 2^n

# Common patterns
function is_bit_set(num, pos):
    return (num & (1 << pos)) != 0

function set_bit(num, pos):
    return num | (1 << pos)

function clear_bit(num, pos):
    return num & ~(1 << pos)

function toggle_bit(num, pos):
    return num ^ (1 << pos)

function count_set_bits(num):
    count = 0
    while num > 0:
        count += num & 1
        num >>= 1
    return count

# Enumerate all subsets of a set
function all_subsets(n):
    # n items -> 2^n subsets
    for mask from 0 to (1 << n) - 1:
        subset = []
        for i from 0 to n - 1:
            if mask & (1 << i):
                subset.append(i)
        yield subset

# Enumerate all subsets of a given mask
function subsets_of_mask(mask):
    submask = mask
    while submask > 0:
        yield submask
        submask = (submask - 1) & mask
    yield 0

# Bitmask DP state
# Use integer as set: visited_mask represents which nodes visited
function tsp_bitmask(distances, n):
    # dp[mask][i] = min cost to visit nodes in mask, ending at i
    INF = infinity
    dp = array of [2^n][n] filled with INF
    dp[1][0] = 0  # Start at node 0

    for mask from 1 to (1 << n) - 1:
        for last from 0 to n - 1:
            if not (mask & (1 << last)):
                continue
            for next from 0 to n - 1:
                if mask & (1 << next):
                    continue
                new_mask = mask | (1 << next)
                dp[new_mask][next] = min(
                    dp[new_mask][next],
                    dp[mask][last] + distances[last][next]
                )`,
			Complexity: struct {
				Time  string `json:"time"`
				Space string `json:"space"`
			}{
				Time:  "Varies; subset enumeration O(2^n)",
				Space: "O(1) for operations, O(2^n) for bitmask DP",
			},
			AoCExamples: []string{
				"Day 14 2017 - Disk Defragmentation",
				"Day 16 2019 - Flawed Frequency Transmission",
				"State tracking in search problems",
			},
			Resources: []string{
				"https://en.wikipedia.org/wiki/Bit_manipulation",
			},
		},
	}
}
