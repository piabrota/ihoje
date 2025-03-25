# Token-Optimized Documentation Strategy

This document outlines an approach to justfile documentation that balances best practices with token usage optimization for Claude AI interactions.

## Token Usage Considerations

Based on CLAUDE.md guidelines, token usage is a key concern:

| Command         | Tokens | Cost   | Usage                        |
|-----------------|--------|--------|------------------------------|
| claude-micro    | ~200   | Lowest | Quick questions              |
| claude-minimal  | ~500   | Low    | Focused tasks                |
| claude          | ~1000  | Medium | Daily development            |
| dump-context    | ~3000+ | High   | Complex tasks                |

## Documentation Tradeoffs

### Full Documentation (High Token Usage)
- Comprehensive inline documentation
- Detailed parameter descriptions
- Full usage examples
- Verbose error handling

### Minimal Documentation (Low Token Usage)
- Concise one-line descriptions
- Minimal parameter information
- No examples
- Limited error handling

## Balanced Documentation Approach

We propose a balanced approach that optimizes token usage while maintaining clear documentation:

### 1. Use Tag-Based Documentation

Use abbreviated tags that convey purpose without excessive text:

```just
# [R] Run the application with a specific city
#
# Usage: just run-city CITY
# City: Target city code (default: FL)
run-city city="FL":
    CITY={{city}} cargo run
```

This provides essential information in ~40 tokens vs ~100 tokens for full documentation.

### 2. Standardized Help Recipes

Consolidate detailed documentation in help recipes:

```just
# [H] Show run command help
help:
    @echo "=== Run Commands ==="
    @echo "Basic:"
    @echo "  run [ARGS]     - Run with args"
    @echo "  run-city CITY  - Run with city"
    @echo "  run-date       - Run with date range"
```

This keeps individual recipes slim while providing complete documentation on demand.

### 3. Parameter Validation with Token Efficiency

Use concise but effective parameter validation:

```just
run-city city="FL":
    #!/usr/bin/env bash
    # Required param check
    [ -z "{{city}}" ] && echo "Error: city required" && exit 1
    
    CITY={{city}} cargo run
```

This pattern uses ~30 tokens vs ~80 tokens for verbose validation.

### 4. Common Functions File

Extract common functions but optimize imports:

```just
# Import common functions (1 line per import)
date-range := `cat common.justfile | sed -n '/date-range-fn/,/^$/p'`
```

This allows selective importing of functions to avoid loading entire files.

### 5. Tiered Documentation Strategy

Apply different documentation levels based on recipe complexity:

1. **Simple Recipes**: Minimal documentation
   ```just
   # [R] Run app
   run +args="":
       cargo run {{args}}
   ```

2. **Medium Complexity**: Tag + usage line
   ```just
   # [R] Run with city
   # Usage: just run-city CITY
   run-city city="FL":
       CITY={{city}} cargo run
   ```

3. **High Complexity**: Full documentation
   ```just
   # [R] Run with custom date range and options
   #
   # Usage: just run-custom-date START END [ARGS]
   # Start: Start days ahead (number, default: 7)
   # End: End days ahead (number, default: 14)
   # Args: Optional app arguments
   run-custom-date start="7" end="14" +args="":
       #!/usr/bin/env bash
       # Validate numeric params
       [[ ! "{{start}}" =~ ^[0-9]+$ ]] && echo "Error: start must be a number" && exit 1
       [[ ! "{{end}}" =~ ^[0-9]+$ ]] && echo "Error: end must be a number" && exit 1
       
       START_DATE=$(date -d "+{{start}} days" +"%Y-%m-%d")
       END_DATE=$(date -d "+{{end}} days" +"%Y-%m-%d")
       START_DATE=${START_DATE} END_DATE=${END_DATE} cargo run {{args}}
   ```

## Documentation Abbreviations

Use consistent abbreviations to save tokens:

- `[R]` - Run command 
- `[B]` - Build command
- `[T]` - Test command
- `[S]` - Setup command
- `[C]` - Clean command
- `[I]` - Info command
- `[H]` - Help command
- `[F]` - Forward command
- `[L]` - List command

## Implementation Guidelines

1. **Concise File Headers**:
   ```just
   # Run Commands (app execution recipes)
   ```

2. **Abbreviated Parameter Validation**:
   ```just
   [ condition ] && echo "Error: message" && exit 1
   ```

3. **Structured Help Text**:
   Group related commands with clear hierarchy but minimal spacing.

4. **Comments Only Where Needed**:
   Add comments only for non-obvious operations.

5. **Leverage Default Values**:
   Use default values to reduce required documentation.

## Token Usage Comparison

| Documentation Style | Tokens per Recipe | Tokens per File | Claude Context Cost |
|--------------------|-------------------|-----------------|---------------------|
| Full Docs          | ~100              | ~2000           | High               |
| Minimal Docs       | ~20               | ~400            | Very Low           |
| Balanced Approach  | ~40               | ~800            | Medium             |

The balanced approach reduces token usage by ~60% compared to full documentation while maintaining essential clarity and usability.

## Sample Recipe with Balanced Documentation

```just
# [R] Run with custom date range
# Usage: just run-date START END [ARGS]
# Validates numeric params
run-date start="7" end="14" +args="":
    #!/usr/bin/env bash
    # Validate params
    [[ ! "{{start}}" =~ ^[0-9]+$ ]] && echo "Error: start must be number" && exit 1
    [[ ! "{{end}}" =~ ^[0-9]+$ ]] && echo "Error: end must be number" && exit 1
    
    START=$(date -d "+{{start}} days" +"%Y-%m-%d")
    END=$(date -d "+{{end}} days" +"%Y-%m-%d")
    START_DATE=${START} END_DATE=${END} cargo run {{args}}
```