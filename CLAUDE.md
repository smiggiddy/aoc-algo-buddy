# CLAUDE.md - Project Context for AI Assistants

## Project Overview

AoC Algo Buddy is an algorithm learning platform designed for self-taught developers. It focuses on practical problem-solving skills through Advent of Code examples while building foundational CS understanding.

**Key Goals:**
- Deep learning through applied examples (not interview cramming)
- Visual step-by-step explanations
- Language-agnostic pseudo code
- Community contributions with admin review

## Tech Stack

- **Backend**: Go (standard library only, no frameworks)
- **Frontend**: React 19 + Vite + React Router DOM
- **Data Storage**: JSON file persistence (`backend/data.json`)
- **Styling**: CSS with CSS variables (dark theme)

## Project Structure

```
aoc-algo-buddy/
├── backend/
│   ├── main.go           # API routes, handlers, database operations
│   ├── data.go           # Legacy seed data (deprecated, kept for reference)
│   ├── seed_data.json    # Algorithm definitions (PRIMARY DATA SOURCE)
│   └── go.mod
├── frontend/
│   ├── src/
│   │   ├── components/   # React components
│   │   │   ├── AlgorithmList.jsx    # Main listing page
│   │   │   ├── AlgorithmDetail.jsx  # Single algorithm view
│   │   │   ├── SubmitForm.jsx       # Contribution form
│   │   │   └── Header.jsx
│   │   ├── App.jsx       # Router setup
│   │   ├── main.jsx      # Entry point
│   │   └── index.css     # Global styles
│   └── package.json
├── ALGORITHM_REVIEW.md   # Catalog assessment and recommendations
└── README.md
```

## Running the Project

### Development Mode

```bash
# Terminal 1: Backend (port 8080)
cd backend && go run .

# Terminal 2: Frontend (port 5173)
cd frontend && npm install && npm run dev
```

### Production Build

```bash
cd frontend && npm run build
cd ../backend && go run .
# Full app served at http://localhost:8080
```

## Key Files

### `backend/seed_data.json`
**This is the primary file for algorithm definitions.** When adding or modifying algorithms, edit this file.

Each algorithm entry includes:
```json
{
  "id": "algorithm-slug",
  "name": "Display Name",
  "category": "Category Name",
  "tags": ["tag1", "tag2"],
  "difficulty": "Beginner|Intermediate|Advanced",
  "description": "Brief description",
  "whenToUse": ["Use case 1", "Use case 2"],
  "pseudoCode": "function example():\n    ...",
  "complexity": {"time": "O(n)", "space": "O(1)"},
  "aocExamples": ["2023 Day 12 - Problem Name"],
  "resources": ["https://wikipedia.org/..."],
  "prerequisites": ["other-algorithm-id"],
  "keyInsight": "The 'aha' moment explanation",
  "commonPitfalls": ["Mistake 1", "Mistake 2"],
  "relatedAlgos": ["related-id"],
  "recognitionHints": ["Pattern to look for"],
  "examples": [{
    "title": "Example Title",
    "description": "Problem description",
    "input": "Input data",
    "output": "Expected output",
    "visual": "ASCII diagram showing execution",
    "steps": [
      {"description": "Step 1", "state": "State after step"}
    ]
  }]
}
```

### `backend/main.go`
- HTTP handlers for all API endpoints
- Database operations (load, save, CRUD)
- CAPTCHA generation and validation
- Admin authentication (Basic Auth)

### Categories (defined in `SubmitForm.jsx`)
- Graph Traversal
- Shortest Path
- Graph Algorithms
- Sorting
- Trees
- Dynamic Programming
- Search Techniques
- State Modeling
- Optimization Patterns
- Data Structures
- Math & Number Theory
- Geometry
- Greedy
- Bit Operations

## Adding New Algorithms

1. Edit `backend/seed_data.json`
2. Add new entry to the JSON array following the schema above
3. Restart the backend (or delete `data.json` to reload seed data)

**Important fields for learning:**
- `keyInsight`: The fundamental "why it works" explanation
- `commonPitfalls`: Mistakes learners commonly make
- `prerequisites`: Algorithm IDs to learn first
- `recognitionHints`: How to identify when to use this algorithm
- `visual`: ASCII art showing algorithm execution step-by-step

## API Endpoints

### Public
- `GET /api/algorithms` - List all (supports `?category`, `?tag`, `?difficulty`, `?search`)
- `GET /api/algorithms/:id` - Single algorithm
- `GET /api/categories` - All categories
- `GET /api/tags` - All tags
- `GET /api/captcha` - CAPTCHA challenge
- `POST /api/submit` - Submit new algorithm

### Admin (Basic Auth: `ADMIN_USER`/`ADMIN_PASS` env vars)
- `GET /api/admin/submissions` - Pending submissions
- `POST /api/admin/approve/:id` - Approve submission
- `POST /api/admin/reject/:id` - Reject submission

## Current Algorithm Catalog (36 algorithms)

| Category | Algorithms |
|----------|------------|
| Graph Traversal | BFS, DFS, Flood Fill |
| Shortest Path | Dijkstra, A*, Bellman-Ford |
| Graph Algorithms | Topological Sort |
| Sorting | Merge Sort, Quick Sort, Insertion Sort |
| Trees | Tree Traversals, Binary Search Tree |
| Dynamic Programming | Memoization, Tabulation, LCS, Knapsack |
| Search Techniques | Binary Search, Two Pointers, Backtracking |
| State Modeling | State Space BFS |
| Optimization Patterns | Cycle Detection, Sliding Window, Interval Merging |
| Data Structures | Union-Find, Priority Queue, Monotonic Stack, Trie |
| Math & Number Theory | GCD/LCM, Modular Arithmetic |
| Geometry | Manhattan Distance, Shoelace/Pick's, Coordinate Compression |
| Greedy | Activity Selection |
| Bit Operations | Bit Manipulation, Bitmasking |

## Code Style

### Go (Backend)
- Standard library only (no external dependencies)
- Handlers follow `func handleX(w http.ResponseWriter, r *http.Request)` pattern
- Thread-safe with `sync.RWMutex` for database operations
- JSON responses with proper Content-Type headers

### React (Frontend)
- Functional components with hooks
- CSS modules per component (e.g., `AlgorithmList.css`)
- React Router for navigation
- Fetch API for backend communication

## Testing

Currently no automated tests. Manual testing:
1. Start backend and frontend
2. Browse algorithms at `http://localhost:5173`
3. Test filters (category, difficulty, tags, search)
4. Test algorithm detail pages
5. Test submission form with CAPTCHA

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Backend server port |
| `ADMIN_USER` | `admin` | Admin username |
| `ADMIN_PASS` | `changeme` | Admin password |

## Data Reset

To reset to seed data:
```bash
rm backend/data.json
# Restart backend - it will regenerate from seed_data.json
```

## Common Tasks

### Add a new algorithm
Edit `backend/seed_data.json`, add entry, restart backend

### Modify an existing algorithm
Edit the entry in `backend/seed_data.json`, delete `backend/data.json`, restart

### Add a new category
1. Add to `categories` array in `frontend/src/components/SubmitForm.jsx`
2. Use the category in algorithm entries

### Change styling
Edit CSS variables in `frontend/src/index.css` for global theme changes
