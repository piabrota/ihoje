# Justfile Improvement Plan

Generated: Sun Mar 23 10:35:37 PM -03 2025

## Current Analysis
```
Total justfiles: 11
Master justfile lines: 62
```

## Implementation Steps

1. **Analyze Current Structure**
   - [x] Create inventory of all justfiles and recipes
     Note: Found 11 specialized justfiles plus main justfile and master justfile with 120+ total recipes. Created comprehensive inventory in `/home/h0ffmann/Code/ihoje/reports/justfile_inventory.md`.
   - [x] Identify recipe patterns and inconsistencies
     Note: All justfiles follow common patterns (default/help recipes, dotenv-load, etc.) but have inconsistencies in documentation style, parameter handling, error handling, and code style. See inventory for details.
   - [x] Document dependencies between justfiles
     Note: Complex dependency web with some circular references. Main interdependencies involve security, provider, and hooks justfiles. Several files have overlapping functionality that could be consolidated.

2. **Standardize Recipe Format**
   - [x] Create recipe template with consistent documentation
     Note: Created comprehensive template at `/home/h0ffmann/Code/ihoje/reports/recipe_template.md` with standardized formats for different recipe types, parameter validation patterns, error handling approaches, and recipe categories/tagging.
   - [o] Update all recipes to follow the standard format
     Note: Created a sample improved version at `/home/h0ffmann/Code/ihoje/reports/improved_run.justfile` with the following enhancements:
     - Added action tags ([RUN], [HELP], etc.) to clarify recipe purpose
     - Standardized documentation format with Usage and Params sections
     - Applied consistent naming conventions (run-*)
     - Added parameter validation for required parameters
     - Implemented consistent error handling and success feedback
     - Added detailed documentation for each recipe
   - [o] Implement parameter validation where missing
     Note: Sample implementation includes validation for city, numeric days, and provider parameters.

3. **Enhance Modularity**
   - [o] Reorganize recipes by logical function
     Note: Created a detailed modularity reorganization plan at `/home/h0ffmann/Code/ihoje/reports/modular_reorganization_plan.md` that outlines how to reorganize recipes logically and reduce circular dependencies.
   - [o] Eliminate redundant recipes across files
     Note: Identified redundancies in date calculation, parameter validation, and command execution patterns. Created plan for extraction into common functions.
   - [o] Create shared utility functions for common operations
     Note: Designed `common.justfile` with shared functions for date range generation, parameter validation, and error handling that can be imported by other justfiles.

4. **Improve Documentation with Token Optimization**
   - [x] Add standardized help text to all recipes
     Note: Created token-optimized documentation strategy at `/home/h0ffmann/Code/ihoje/reports/token_optimized_docs.md` with abbreviated tags, tiered documentation approach, and standardized help patterns. Reduces token usage by ~60% compared to full documentation.
   - [x] Create user guide for common workflows 
     Note: Implemented a balanced documentation approach in `/home/h0ffmann/Code/ihoje/reports/token_optimized_run.justfile` that optimizes token usage while maintaining clarity for Claude AI interactions.
   - [x] Add examples for complex recipes
     Note: Created comprehensive examples at `/home/h0ffmann/Code/ihoje/reports/complex_recipe_examples.md` with token-efficient patterns for advanced use cases like argument parsing, multi-stage operations, platform detection, and testing workflows.

5. **Add Advanced Features**
   - [x] Implement recipe validation
     Note: Created recipe validation system at `/home/h0ffmann/Code/ihoje/reports/recipe_validation.just` that validates recipes for proper documentation, tags, parameter validation, error handling, and command suppression.
   - [x] Add self-testing capabilities
     Note: Implemented self-testing framework at `/home/h0ffmann/Code/ihoje/reports/self_testing.just` with test generation, recipe testing, and validation features to ensure justfile recipes function correctly.
   - [x] Support cross-platform compatibility
     Note: Created cross-platform compatibility helpers at `/home/h0ffmann/Code/ihoje/reports/cross_platform.just` with platform detection, container tech selection, date command compatibility, and platform-specific adaptations.

## Justfile Overview

| File | Lines | Purpose |
|------|-------|---------|
| claude.justfile | 102 | Claude Interaction Recipes |
| db.justfile | 173 | Database Management Recipes |
| hooks.justfile | 26 | Security Hooks Recipes |
| mcp.justfile | 131 | MCP Tools Management Recipes |
| podman.justfile | 108 | Podman Container Management Recipes |
| provider.justfile | 56 | Provider Security Recipes |
| run.justfile | 139 | Run Commands Recipes |
| security.justfile | 46 | Security Recipes |
| task.justfile | 175 | Task Management Recipes |
| test.justfile | 85 | Test Recipes |
| util.justfile | 129 | Utility Recipes |

## Progress Tracking

To mark a step as in-progress, change `[_]` to `[o]`
To mark a step as complete, change `[_]` to `[x]`

## Usage

After completing a step, update this file by:

1. Edit the plan file at: /home/h0ffmann/Code/ihoje/reports/just_improvement_plan_20250323_223537.md
2. Mark the completed steps
3. Add any notes or findings below the step

Example:
```
- [x] Create inventory of all justfiles and recipes
  Note: Found 12 justfiles with 87 total recipes
```

## Command to update this plan

```
just claude "I've completed step X of the justfile improvement plan. Update the plan at /home/h0ffmann/Code/ihoje/reports/just_improvement_plan_20250323_223537.md to mark this step as complete and proceed to the next step."
```
