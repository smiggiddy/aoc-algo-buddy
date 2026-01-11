# AoC Algo Buddy

A web app to help developers learn common algorithms for solving Advent of Code problems. Features language-agnostic pseudo code, clean filtering, and shareable links.

## Tech Stack

- **Backend**: Go (standard library)
- **Frontend**: React + Vite

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

1. **Build the frontend**:

```bash
cd frontend
npm run build
```

This outputs to `backend/static/`

2. **Run the server**:

```bash
cd backend
go run .
```

The full app is now served at `http://localhost:8080`

## API Endpoints

| Endpoint | Description |
|----------|-------------|
| `GET /api/algorithms` | List all algorithms (supports `?category`, `?tag`, `?difficulty`, `?search`) |
| `GET /api/algorithms/:id` | Get single algorithm by ID |
| `GET /api/categories` | List all categories |
| `GET /api/tags` | List all tags |

## Features

- **Search**: Full-text search across names, descriptions, and tags
- **Filtering**: Filter by category, difficulty level, or specific tags
- **Shareable URLs**: Every filter state and algorithm page has a unique URL
- **Pseudo Code**: Language-agnostic implementations with complexity analysis
- **AoC Examples**: Real Advent of Code problems where each algorithm applies

## Adding Algorithms

Edit `backend/data.go` to add new algorithms. Each algorithm includes:

- Name and ID (URL slug)
- Category and tags
- Difficulty level
- Description and when to use
- Pseudo code implementation
- Time and space complexity
- AoC example problems
- External resources

## License

MIT
