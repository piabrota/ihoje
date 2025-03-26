# Toji - System Doctor

System doctor and dependency checker inspired by Toji Fushiguro from Jujutsu Kaisen.

## Overview

Toji serves as a system doctor for the iHoje ecosystem, ensuring all required dependencies
and services are properly installed and configured. Named after Toji Fushiguro, a character
known for his keen perception and ability to identify weaknesses.

## Features

- Checks for required binary installations (Docker, curl, GCP Cloud binaries, etc.)
- Verifies environment configurations (API keys, database connections)
- Ensures required services are running (PostgreSQL, etc.)
- Provides detailed diagnostic information for missing dependencies

## Usage

```bash
# Run a full system check
just toji-check

# Check specific components
just toji-check postgres
just toji-check docker
just toji-check gcp
```

## Implementation

Toji is implemented in Gleam, a type-safe functional language that compiles to Erlang. 
This provides excellent reliability and concurrency support while maintaining a clean syntax.