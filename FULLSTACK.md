# iHoje Full-Stack Application

This guide explains how to run the complete iHoje application with both the Rust backend API and the WebAssembly frontend.

## Overview

The iHoje application consists of two main components:

1. **Backend API** - A Rust-based event scraper with an API server
2. **Frontend** - A WebAssembly application built with Yew

## Running the Complete Stack

### Step 1: Build the WebAssembly Frontend

```bash
# Build the frontend
just frontend-build
```

### Step 2: Start the Backend API Server

```bash
# Start the API server on port 8080
just run-api
```

### Step 3: Serve the Frontend

```bash
# In a separate terminal, serve the frontend
just frontend-serve
```

### Step 4: Access the Application

Open your browser to http://localhost:8080 to view the application.

## Development Workflow

For active development, follow these steps:

### Backend Development

1. Start the API server with auto-reload:
   ```bash
   cargo watch -x "run -- --api"
   ```

2. Make changes to the Rust backend code
3. The server will automatically restart with your changes

### Frontend Development

1. Start the frontend development server:
   ```bash
   just frontend-dev
   ```

2. Make changes to the frontend code
3. The page will automatically reload with your changes

## API Endpoints

The backend API provides the following endpoints:

- `GET /api/events` - Get all events (query params: city, search, date_from, date_to, free_only)
- `GET /api/events/:id` - Get details for a specific event
- `GET /api/cities` - Get list of available cities

## Configuration

### Backend Configuration

The backend reads configuration from environment variables, which can be set in a `.env` file:

```
# .env example
CITY=FL
TARGET_URL=https://example.com
```

### Frontend Configuration

The frontend configuration is in `frontend/src/api/client.rs` and can be modified to point to a different API URL if needed.

## Deployment

### Backend Deployment

The backend can be deployed as a standalone Rust application or as a Docker container:

```bash
# Build Docker container
docker build -t ihoje-api .

# Run Docker container
docker run -p 8080:8080 ihoje-api --api
```

### Frontend Deployment

The frontend can be deployed to any static file host:

```bash
# Build optimized frontend for production
just frontend release

# Bundle for deployment
just frontend bundle
```

The resulting `ihoje-frontend.zip` can be deployed to any static file host.

## Troubleshooting

- If the API server fails to start, check if port 8080 is already in use
- If the frontend can't connect to the API, check that CORS is properly configured
- For database issues, verify your PostgreSQL connection settings