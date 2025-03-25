#!/bin/bash
set -e

# Move to the project root directory
cd "$(dirname "$0")/.."
root_dir="$(pwd)"

echo "===== Rust Improvement Tool ====="
echo "Creating improvement plan and action tracker in ${root_dir}..."

# Create reports directory
mkdir -p reports
timestamp=$(date +%Y%m%d_%H%M%S)
plan_file="${root_dir}/reports/rust_improvement_plan_${timestamp}.md"
action_file="${root_dir}/reports/rust_improvement_actions_${timestamp}.md"

# Start plan document
cat > "$plan_file" << EOL
# Rust Code Improvement Plan

Generated: $(date)

## Current Analysis
\`\`\`
Total Rust files: $(find "${root_dir}/src" -name "*.rs" | wc -l)
\`\`\`

## Implementation Steps

1. **Analyze Current Structure**
   - [_] Create inventory of all Rust files and modules
   - [_] Identify code patterns and inconsistencies
   - [_] Document dependencies between modules

2. **Standardize Code Format**
   - [_] Create code style template with consistent documentation
   - [_] Update all files to follow the standard format
   - [_] Implement error handling where missing

3. **Enhance Modularity**
   - [_] Reorganize code by logical function
   - [_] Eliminate redundant functions across files
   - [_] Create shared utility functions for common operations

4. **Improve Documentation**
   - [_] Add standardized documentation to all functions
   - [_] Create user guide for common workflows
   - [_] Add examples for complex functions

5. **Add Advanced Features**
   - [_] Implement error type improvements
   - [_] Add benchmarking capabilities
   - [_] Support cross-platform compatibility

## Rust Files Overview

| File | Lines | Purpose |
|------|-------|---------|
EOL

# Generate Rust file table
for file in $(find "${root_dir}/src" -name "*.rs" | sort); do
  lines=$(wc -l < "$file")
  rel_path=$(realpath --relative-to="${root_dir}" "$file")
  # Try to extract purpose from the first doc comment or module declaration
  purpose=$(grep -m 1 "//!" "$file" | sed 's/\/\/! //' || \
            grep -m 1 "///" "$file" | sed 's/\/\/\/ //' || \
            grep -m 1 "^pub mod" "$file" | sed 's/pub mod \([a-z_]*\).*/\1 module/' || \
            echo "No description found")
  echo "| $rel_path | $lines | $purpose |" >> "$plan_file"
done

# Create action tracking file
cat > "$action_file" << EOL
# Rust Improvement Actions

Generated: $(date)

This file tracks the implementation of improvements to the Rust code structure.

## Research Phase

- [ ] Research current Rust best practices from the Rust Book and community
- [ ] Review Reddit r/rust for discussions on code organization
- [ ] Study popular open source Rust projects for inspiration
- [ ] Document findings and patterns

## Analysis Phase

- [ ] Identify redundancies across Rust modules
- [ ] Find opportunities for trait implementations
- [ ] Analyze error handling patterns
- [ ] Check for modularization improvements

## Design Phase

- [ ] Create template for standardized module structure
- [ ] Design improved error handling system
- [ ] Plan documentation improvements
- [ ] Create naming convention guidelines

## Implementation Phase

- [ ] Standardize module formats
- [ ] Improve error handling
- [ ] Consolidate duplicate functionality
- [ ] Enhance documentation
- [ ] Add validation functionality
- [ ] Create testing framework for modules

## Validation Phase

- [ ] Test all modified code
- [ ] Verify backward compatibility
- [ ] Measure performance improvements
- [ ] Document changes and benefits

## Completion Report

- [ ] Document all changes implemented
- [ ] List benefits achieved
- [ ] Provide usage examples
- [ ] Share lessons learned

## Initial Research Findings

### Best Practices from Rust Community

**Popular Style Guides:**
- [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/)
- The Rust Book's recommendations
- rustfmt default configuration

**Common Patterns:**
- Error handling with custom error types
- Module organization with public interfaces
- Type-driven design
- Consistent documentation format
- Use of traits for abstraction
- Builder patterns for configuration

### Techniques to Implement

1. **Consistent Error Handling**
   - Custom error types with thiserror
   - Context propagation with anyhow
   - Result wrapping patterns

2. **Improved Modularity**
   - Logical grouping by function
   - Clear public interfaces
   - Reduced visibility of implementation details

3. **Enhanced Documentation**
   - Standardized doc comments
   - Examples in documentation
   - MSRV (Minimum Supported Rust Version) notation

4. **Advanced Features**
   - Benchmarking setups
   - Feature flags for optional components
   - Cross-platform adaptations

---

To mark a task as complete, change \`[ ]\` to \`[x]\` in this file.
EOL

# Add progress tracking feature
cat >> "$plan_file" << EOL

## Progress Tracking

To mark a step as in-progress, change \`[_]\` to \`[o]\`
To mark a step as complete, change \`[_]\` to \`[x]\`

## Usage

After completing a step, update this file by:

1. Edit the plan file at: $plan_file
2. Mark the completed steps
3. Add any notes or findings below the step

Example:
\`\`\`
- [x] Create inventory of all Rust files
  Note: Found 12 Rust files with 87 total functions
\`\`\`

## Command to update this plan

\`\`\`
just claude "I've completed step X of the Rust improvement plan. Update the plan at $plan_file to mark this step as complete and proceed to the next step."
\`\`\`
EOL

# Display file locations
echo "Action plan created at $action_file"
echo "Implementation plan created at $plan_file"

# Simply display the first few lines of the plan
echo ""
echo "Implementation Plan Preview:"
echo "==========================="
head -n 25 "$plan_file"
echo "..."
echo ""
echo "Action Tracker Preview:"
echo "======================="
head -n 25 "$action_file"
echo "..."

echo ""
echo "To begin implementation:"
echo "1. Run 'just claude' with this prompt:"
echo "'Research latest Rust best practices and begin implementing the first step of the plan at $plan_file'"
echo ""
echo "2. After completing each step, update the plan using:"
echo "'just claude \"Mark step X complete in $plan_file and proceed to next step\"'"