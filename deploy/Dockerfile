# Stage 1: Build frontend
FROM node:22-alpine AS frontend-builder

WORKDIR /app/frontend

# Copy package files and install dependencies
COPY frontend/package*.json ./
RUN npm ci

# Copy frontend source and build
COPY frontend/ ./
RUN npm run build

# Stage 2: Build backend
FROM golang:1.24-bookworm AS backend-builder

WORKDIR /app/backend

# Copy go module files and download dependencies
COPY backend/go.mod ./
RUN go mod download

# Copy backend source
COPY backend/*.go ./
COPY backend/*.json ./

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o server .

# Stage 3: Production image (distroless)
FROM gcr.io/distroless/static-debian12:nonroot

WORKDIR /app

# Copy the compiled backend binary
COPY --from=backend-builder /app/backend/server ./

# Copy data files
COPY --from=backend-builder /app/backend/seed_data.json ./

# Copy built frontend static files
COPY --from=frontend-builder /app/backend/static ./static

# Expose port
EXPOSE 8080

# Environment variables with defaults
ENV PORT=8080 \
    ADMIN_USER=admin \
    ADMIN_PASS=changeme \
    DATA_DIR=

# Run the server
ENTRYPOINT ["./server"]
