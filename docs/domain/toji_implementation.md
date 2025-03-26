# Toji Implementation (System Doctor)

Toji is a system doctor tool inspired by Toji Fushiguro from Jujutsu Kaisen.

## Overview

Toji serves as a system doctor for the iHoje ecosystem, ensuring all required dependencies
and services are properly installed and configured. Named after Toji Fushiguro, a character
known for his keen perception and ability to identify weaknesses.

## Technical Details

### Language Choice: Gleam

Toji is implemented in Gleam, a type-safe functional language that compiles to Erlang bytecode.
Gleam provides:

1. Excellent reliability with its strong type system
2. Concise, expressive syntax
3. Good interoperability with Erlang and Elixir libraries
4. The ability to compile to a standalone binary
5. Cross-platform compatibility

### Core Functionality

Toji's primary purpose is to check the system environment for required dependencies:

- **Binary Dependencies**: Docker, curl, GCP Cloud CLI, and other executables
- **Environment Configuration**: Checks for required environment variables like API keys
- **Service Dependencies**: Verifies that services like PostgreSQL are running and accessible
- **Diagnostic Information**: Provides detailed information about what's missing or misconfigured
- **Database Information**: Provides comprehensive information about PostgreSQL database status, tables, and row counts

### Database Diagnostics

Toji provides detailed PostgreSQL database diagnostics, including:

- **Database Overview**: Lists all databases with their sizes and connection status
- **Table Information**: Shows tables, their schemas, column counts, and row counts
- **Database Views**: Lists all custom views defined in the database
- **Server Information**: Provides PostgreSQL server version, configuration, and performance metrics
- **Database Activity**: Shows current connections, transactions, and query statistics
- **User Information**: Lists database roles and their permissions

### Integration with iHoje

Toji integrates with the existing iHoje architecture:

1. Available through the `just` task system (`just toji-check`)
2. Component-specific checks (`just toji-check postgres`)
3. Detailed database information command (`just toji-db-info`)
4. Clear, actionable output with error codes and suggestions for fixing issues

## Usage Examples

Check all system components:
```
just toji-check
```

Check PostgreSQL database with detailed information:
```
just toji-check db
```

Just display database information:
```
just toji-db-info
```

## Future Development

Potential enhancements to Toji include:

1. Automatic fixing of common issues
2. Integration with CI/CD systems for environment validation
3. More comprehensive checks for all iHoje components
4. Network connectivity and API availability testing
5. Query performance monitoring and optimization suggestions
6. Database health scoring system