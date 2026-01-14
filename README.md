# AoC Algo Buddy

[![Live Demo](https://img.shields.io/badge/demo-live-brightgreen)](https://aoc-buddy.thecodedom.com)
[![Go](https://img.shields.io/badge/Go-1.21+-00ADD8?logo=go&logoColor=white)](https://go.dev/)
[![React](https://img.shields.io/badge/React-18+-61DAFB?logo=react&logoColor=black)](https://react.dev/)
[![Vite](https://img.shields.io/badge/Vite-5+-646CFF?logo=vite&logoColor=white)](https://vitejs.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](http://makeapullrequest.com)

A collaborative web app to help developers learn common algorithms for solving Advent of Code problems. Features language-agnostic pseudo code, visual examples, community contributions, and shareable links.

**[Live Demo](https://aoc-buddy.thecodedom.com)**

## Tech Stack

- **Backend**: Go (standard library + JSON file storage)
- **Frontend**: React + Vite

## Features

- **Visual Examples**: Each algorithm includes step-by-step visualizations with ASCII diagrams
- **Community Contributions**: Anyone can submit new algorithms (with CAPTCHA protection)
- **Admin Review**: Submissions require approval before publishing
- **Search & Filter**: Full-text search, filter by category/difficulty/tags
- **Shareable URLs**: Every page has a unique, shareable URL
- **Language Agnostic**: All implementations in pseudo code

## Getting Started

### Prerequisites

- Go 1.21+
- Node.js 18+

### Development

1. **Start the backend**:

```bash
cd backend
go run .
```

The API will be available at `http://localhost:8080`

2. **Start the frontend** (in a new terminal):

```bash
cd frontend
npm install
npm run dev
```

The app will be available at `http://localhost:5173`

### Production Build

```bash
cd frontend && npm run build
cd ../backend && go run .
```

The full app is served at `http://localhost:8080`

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `8080` | Server port |
| `ADMIN_USER` | `admin` | Admin username |
| `ADMIN_PASS` | `changeme` | Admin password |

## API Endpoints

### Public

| Endpoint | Description |
|----------|-------------|
| `GET /api/algorithms` | List approved algorithms (supports `?category`, `?tag`, `?difficulty`, `?search`) |
| `GET /api/algorithms/:id` | Get single algorithm by ID |
| `GET /api/categories` | List all categories |
| `GET /api/tags` | List all tags |
| `GET /api/captcha` | Get a new CAPTCHA challenge |
| `POST /api/submit` | Submit a new algorithm for review |

### Admin (Basic Auth required)

| Endpoint | Description |
|----------|-------------|
| `GET /api/admin/submissions` | List pending submissions |
| `POST /api/admin/approve/:id` | Approve a submission |
| `POST /api/admin/reject/:id` | Reject a submission |

## Contributing Algorithms

### Via Web UI

1. Click "Contribute" in the header
2. Fill in the algorithm details
3. Complete the CAPTCHA
4. Submit for review

### Via Code

Edit `backend/data.go` to add new seed algorithms. Each algorithm includes:

- Name and ID (URL slug)
- Category and tags
- Difficulty level (Beginner/Intermediate/Advanced)
- Description and when to use
- Pseudo code implementation
- Time and space complexity
- Visual examples with step-by-step breakdowns
- AoC example problems
- External resources

## Data Storage

Algorithms are stored in `backend/data.json` which is automatically created on first run. This file contains:

- All approved algorithms
- Pending/reviewed submissions

To reset to seed data, delete `data.json` and restart the server.

## Algorithms Included

- **Graph**: BFS, DFS, Dijkstra, Flood Fill
- **Dynamic Programming**: Memoization, Sliding Window
- **Search**: Binary Search, Backtracking
- **Math**: GCD/LCM, Cycle Detection
- **Data Structures**: Priority Queue, Union-Find
- **Geometry**: Manhattan Distance

## License

MIT
