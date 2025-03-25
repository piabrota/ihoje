# iHoje Event Scraper

A Rust-based event data collection system with anime-inspired module naming.

## Documentation

- [Claude Context System Documentation](/docs/claude/README.md) - Multi-tiered context system for Claude Code
- [Project Documentation](/docs/project/README.md) - Contributing, testing, and general guides
- [Domain Documentation](/docs/domain/README.md) - Technical implementation details

## Core Modules

| Module | Description | Documentation |
|--------|-------------|---------------|
| **Sharingan** | Event pattern recognition system (Naruto) | [/docs/domain/sharingan_implementation.md](/docs/domain/sharingan_implementation.md) |
| **Tobira** | WebAssembly frontend gate (Fullmetal Alchemist) | [/tobira/README.md](/tobira/README.md) |
| **Mangekyou** | Implementation planning system (Naruto) | [/scripts/mangekyou-mcp/README.md](/scripts/mangekyou-mcp/README.md) |

## Architecture

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
    
    subgraph AI["AI Integration"]
        Claude[Claude Code]
        Mangekyou[Mangekyou MCP Tool]
        SequentialThinking[Sequential Thinking]
    end
    
    subgraph Data["Data Storage"]
        Postgres[PostgreSQL]
        SQLite[SQLite Checkpoints]
    end
    
    Scraper --> Sharingan
    Scraper --> RateLimiter
    Sharingan --> Exporter
    Exporter --> Database
    Database --> Postgres
    
    ApiClient --> Database
    Components --> ApiClient
    Router --> Components
    Yew --> Router
    
    Claude --> Mangekyou
    Claude --> SequentialThinking
    Claude --> SQLite
    
    classDef core fill:#f9d5e5,stroke:#333,stroke-width:1px
    classDef frontend fill:#eeeeee,stroke:#333,stroke-width:1px
    classDef ai fill:#d5f9f2,stroke:#333,stroke-width:1px
    classDef data fill:#f9f9d5,stroke:#333,stroke-width:1px
    
    class Sharingan,Scraper,RateLimiter,Exporter,Database core
    class Yew,Components,Router,ApiClient frontend
    class Claude,Mangekyou,SequentialThinking ai
    class Postgres,SQLite data
```

## Claude Commands

| Command | Token Usage | Purpose |
|---------|-------------|---------|
| `just claude-micro` | ~200 tokens | Quick questions, simple commands |
| `just claude-minimal` | ~500 tokens | Focused tasks with minimal context |
| `just claude` | ~1000 tokens | Standard development tasks |
| `just claude-domain DOMAIN` | ~1200 tokens | Domain-specific tasks (sharingan, frontend, mangekyou) |
| `just dump-context` | ~3000+ tokens | Complex tasks requiring full context |

For more details on the Claude context system, see the [Claude Context System Documentation](/docs/claude/README.md).