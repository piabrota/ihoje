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
| **Toji** | System doctor and dependency checker (Jujutsu Kaisen) | [/docs/domain/toji_implementation.md](/docs/domain/toji_implementation.md) |

## Running Modes

The application supports two extraction modes:

1. **FireCrawler Mode** (default): Uses the FireCrawl API to scrape websites in real-time.
   ```bash
   # Run with FireCrawler mode (default)
   just provider pikachu
   ```

2. **Static Mode**: Uses pre-downloaded HTML files from HTTrack extractions.
   ```bash
   # Download a website with HTTrack
   just download-site https://example.com/events extraction_folder
   
   # Run using the downloaded files
   just run-static extraction_folder pikachu
   
   # Or run an end-to-end test (download + run)
   just e2e-static-test pikachu
   ```

## Architecture

<!-- 
To view this diagram properly on GitHub:
1. Use a browser extension like "GitHub + Mermaid"
2. Or view through GitHub's Mermaid rendering support 
-->

```mermaid
%%{init: {'theme': 'neutral', 'themeVariables': { 'fontSize': '16px', 'fontFamily': 'arial', 'lineColor': '#333333', 'primaryColor': '#bb99aa' }}}%%
graph TB
    subgraph Core["Core System"]
        direction TB
        Sharingan[Sharingan<br>Pattern Recognition]
        Scraper[Event Scraper]
        RateLimiter[Rate Limiter]
        Exporter[Data Exporter]
        Database[Database API]
        Toji[Toji<br>System Doctor]
    end
    
    subgraph Frontend["Tobira (Gate of Truth)"]
        direction TB
        Yew[Yew Framework]
        Components[UI Components]
        Router[Router]
        ApiClient[API Client]
    end
    
    subgraph AI["AI Integration"]
        direction TB
        Claude[Claude Code]
        Mangekyou[Mangekyou MCP Tool]
        SequentialThinking[Sequential Thinking]
        BraveSearch[Brave Search MCP]
        Puppeteer[Puppeteer MCP]
        Filesystem[Filesystem MCP]
    end
    
    subgraph Data["Data Storage"]
        direction TB
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
    Claude --> BraveSearch
    Claude --> Puppeteer
    Claude --> Filesystem
    Claude --> SQLite
    
    classDef core fill:#f9d5e5,stroke:#333,stroke-width:1px
    classDef frontend fill:#eeeeee,stroke:#333,stroke-width:1px
    classDef ai fill:#d5f9f2,stroke:#333,stroke-width:1px
    classDef data fill:#f9f9d5,stroke:#333,stroke-width:1px
    
    class Sharingan,Scraper,RateLimiter,Exporter,Database,Toji core
    class Yew,Components,Router,ApiClient frontend
    class Claude,Mangekyou,SequentialThinking,BraveSearch,Puppeteer,Filesystem ai
    class Postgres,SQLite data
```

<details>
<summary>📊 View Enhanced Diagram (if not rendering properly)</summary>

![Architecture Diagram](https://mermaid.ink/img/pako:eNqNVEtv2zAM_iuETl3RZk3XrC3aQ9ED1mPRA9vTMASMTDtCZcmQ5S5G4P8-ynHsNF27y0HiI_n4fSTnIFMtQENW7OI6s-VG-daNTj0v3YNZyRV-X7vW3bH0Xrbb1m23FD6WgMY2Bj-qLhOWnTKlrXf5kc1Sxj1JaQzQUZ8G10GUQNf6bV0aFJ96rfWlcX77YKwnzw1JK2c9Xa2m1FcUIWDQtF3V1vkyp5b1YdUWQMDZrZ-BPwvOa63DKHqrJuK_G7Vc1K6qnB9S0BwlWpQU8T5b45rr1jUbwcm_wUmYJHcxfzAcHVptb6SzKx2S5XmAj9eTL-FNxsJhmJb-XucbGiYlbm1HuBm1zNLRdVIUJRbhHBxBr_OMYJHxDsZyLJ-P5YW23jtZE5Yg5LvIc-ZnMSrPSRj-M-Wgl5SxkbJDq-c7VbWPfPsD3_6g5h7GcuaPGRvoZnB0DhoEcHKGDGPYq4sKMqgqzG-OGWZs98CUkaPh0cQHJkfR18jhYMIbOuuPn3_qCHjRxe16_bGJgMc7Nt5Ll1U53TRcDC2fQs0Pd0R4V7oCakFMnj2JwH6eqDTEyc1Agg5MbCy6eDcZO1jyX4v0qKe4t5sXTY4L3_BL_MBvYA4poLZEsrGx-BYOEQsnRTYORTFEFrN4XywzeFX9mjAWC0hFMSaQwOiIhL8ivW1L34jqZ0fXFtIMXtLnbGDBTfgfTfDNFrLZH_ejTzA?type=png)

</details>

## Claude Commands

| Command | Token Usage | Purpose |
|---------|-------------|---------|
| `just claude-micro` | ~200 tokens | Quick questions, simple commands |
| `just claude-minimal` | ~500 tokens | Focused tasks with minimal context |
| `just claude` | ~1000 tokens | Standard development tasks |
| `just claude-domain DOMAIN` | ~1200 tokens | Domain-specific tasks (sharingan, frontend, mangekyou) |
| `just dump-context` | ~3000+ tokens | Complex tasks requiring full context |

For more details on the Claude context system, see the [Claude Context System Documentation](/docs/claude/README.md).