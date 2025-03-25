# Justfile Modular Reorganization Plan

This document outlines the plan for reorganizing justfile recipes to improve modularity, eliminate redundancy, and create shared utility functions.

## Current Issues

From the inventory analysis, we identified several modularity issues:

1. **Circular Dependencies**:
   - `security` → `hooks` → `provider` → `security`

2. **Functionality Overlaps**:
   - `claude.justfile` and `util.justfile` both have context handling
   - `provider.justfile` and `run.justfile` both have provider running
   - Multiple files have similar help patterns
   - Date calculation appears in multiple recipes

3. **Inconsistent Organization**:
   - Some files have too many recipes with varying purposes
   - Logical groups sometimes spread across files

## Reorganization Strategy

### 1. Create Common Functions File

Create a `common.justfile` to hold shared functions that can be imported by other justfiles:

```just
# Common utility functions for justfiles

# Generate standard date range (7-14 days ahead)
generate-date-range-vars:
    #!/usr/bin/env bash
    # Calculate start date (today + 7 days)
    START_DATE=$(date -d "+7 days" +"%Y-%m-%d")
    # Calculate end date (today + 14 days)
    END_DATE=$(date -d "+14 days" +"%Y-%m-%d")
    echo "export START_DATE=${START_DATE} END_DATE=${END_DATE}"

# Validate parameters from other justfiles
validate-city city:
    #!/usr/bin/env bash
    if [ -z "{{city}}" ]; then
        echo "Error: 'city' parameter is required"
        exit 1
    fi
    echo "City parameter '{{city}}' is valid"

# Validate provider parameter
validate-provider provider:
    #!/usr/bin/env bash
    if [[ "{{provider}}" != "pikachu" && "{{provider}}" != "charmander" ]]; then
        echo "Error: 'provider' must be one of: pikachu, charmander"
        exit 1
    fi
    echo "Provider '{{provider}}' is valid"

# Standard error checking function
check-command-status command_name exit_code:
    #!/usr/bin/env bash
    if [ {{exit_code}} -eq 0 ]; then
        echo "{{command_name}} completed successfully"
    else
        echo "{{command_name}} failed"
        exit {{exit_code}}
    fi
```

### 2. Reorganize Existing Justfiles

Restructure existing justfiles to have clearer boundaries:

1. **Run-Related**: 
   - Consolidate all run commands into `run.justfile`
   - Use standardized naming (`run-*` pattern)
   - Import common functions for parameter validation

2. **Database-Related**:
   - Keep all database commands in `db.justfile`
   - Extract common database validation to common functions

3. **Provider-Related**:
   - Consolidate provider functionality in `provider.justfile`
   - Remove duplicate provider commands from run.justfile
   - Create clear provider interface

4. **Security-Related**:
   - Restructure to remove circular dependencies
   - Create clear boundary between hooks and security

5. **Context-Related**:
   - Consolidate context handling in one file (either claude or util)
   - Standardize context operations

### 3. Eliminate Redundancy

Remove redundant code by:

1. **Extract Common Patterns**:
   - Date range calculation (appears in multiple recipes)
   - Parameter validation (city, provider, etc.)
   - Error handling

2. **Standardize Help Commands**:
   - Create consistent format for all help commands
   - Group related commands logically

3. **Unify Command Structure**:
   - Use common recipe patterns across all files
   - Apply standardized recipe format consistently

### 4. Implement Shared Utility Functions

Create a set of utility functions that can be used across justfiles:

1. **Date Utilities**:
   - Date range generation
   - Date validation

2. **Validation Utilities**:
   - Parameter validation
   - File/directory existence checks

3. **Error Handling Utilities**:
   - Standardized error reporting
   - Success/failure feedback

4. **Documentation Utilities**:
   - Help text generation
   - Manual page creation

## Implementation Plan

1. Create the `common.justfile` with shared functions
2. Update each justfile one by one, starting with `run.justfile`
3. Eliminate redundant recipes during the update process
4. Test all modifications to ensure functionality is preserved
5. Update main justfiles and forwarding patterns to match the new organization

## Expected Benefits

1. **Reduced Duplication**: Less duplicate code across files
2. **Clearer Organization**: Logical grouping of related functionality
3. **Better Maintainability**: Easier to update and extend
4. **Improved Documentation**: Consistent documentation across all files
5. **Simplified Dependencies**: Clearer dependency structure
6. **Enhanced Reliability**: Consistent error handling and validation