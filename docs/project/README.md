# iHoje Project Documentation

This directory contains general project documentation for iHoje, covering development processes, contribution guidelines, and general information.

## Available Documentation

| Document | Description |
|----------|-------------|
| [Contributing Guide](contributing.md) | How to contribute to the project |
| [Testing Guide](testing.md) | Testing approach and best practices |
| [Fullstack Development](fullstack.md) | Frontend and backend architecture |
| [Dependency Updates](dependency_updates.md) | Managing and updating dependencies |

## Project Overview

iHoje is a Rust-based event data collection system with anime-inspired module naming. It consists of:

- A backend scraper for collecting event data
- A pattern recognition system (Sharingan)
- A WebAssembly frontend (Tobira)
- Implementation planning tools (Mangekyou)

## Architecture Diagram

```mermaid
graph TB
    subgraph Core["Core System"]
        Sharingan[Sharingan<br>Pattern Recognition]
        Scraper[Event Scraper]
        RateLimiter[Rate Limiter]
        Exporter[Data Exporter]
        Database[Database API]
    end
    
    subgraph Frontend["Tobira (Gate of Truth)"]
        Yew[Yew Framework]
        Components[UI Components]
        Router[Router]
        ApiClient[API Client]
    end
    
    Scraper --> Sharingan
    Scraper --> RateLimiter
    Sharingan --> Exporter
    Exporter --> Database
    
    ApiClient --> Database
    Components --> ApiClient
    Router --> Components
    Yew --> Router
    
    classDef core fill:#f9d5e5,stroke:#333,stroke-width:1px
    classDef frontend fill:#eeeeee,stroke:#333,stroke-width:1px
    
    class Sharingan,Scraper,RateLimiter,Exporter,Database core
    class Yew,Components,Router,ApiClient frontend
```

## Key Development Commands

| Command | Description |
|---------|-------------|
| `just build` | Build the application |
| `just test` | Run all tests |
| `just run` | Run the application |
| `just run-frontend` | Run the frontend |
| `just add-task` | Create a new development task |
| `just claude` | Interact with Claude Code |

## Getting Started

For new developers, we recommend starting with the [Contributing Guide](contributing.md), which covers the setup process and development workflow.