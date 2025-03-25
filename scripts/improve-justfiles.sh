#!/bin/bash
set -e

# Move to the project root directory
cd "$(dirname "$0")/.."
root_dir="$(pwd)"

echo "===== Just Improvement Tool ====="
echo "Creating improvement plan and action tracker in ${root_dir}..."

# Create reports directory
mkdir -p reports
timestamp=$(date +%Y%m%d_%H%M%S)
plan_file="${root_dir}/reports/just_improvement_plan_${timestamp}.md"
action_file="${root_dir}/reports/just_improvement_actions_${timestamp}.md"

# Start plan document
cat > "$plan_file" << EOL
# Justfile Improvement Plan

Generated: $(date)

## Current Analysis
\`\`\`
Total justfiles: $(find "${root_dir}/justfiles" -name "*.justfile" | wc -l)
Master justfile lines: $(wc -l < "${root_dir}/justfile")
\`\`\`

## Implementation Steps

1. **Analyze Current Structure**
   - [_] Create inventory of all justfiles and recipes
   - [_] Identify recipe patterns and inconsistencies
   - [_] Document dependencies between justfiles

2. **Standardize Recipe Format**
   - [_] Create recipe template with consistent documentation
   - [_] Update all recipes to follow the standard format
   - [_] Implement parameter validation where missing

3. **Enhance Modularity**
   - [_] Reorganize recipes by logical function
   - [_] Eliminate redundant recipes across files
   - [_] Create shared utility functions for common operations

4. **Improve Documentation**
   - [_] Add standardized help text to all recipes
   - [_] Create user guide for common workflows
   - [_] Add examples for complex recipes

5. **Add Advanced Features**
   - [_] Implement recipe validation
   - [_] Add self-testing capabilities
   - [_] Support cross-platform compatibility

## Justfile Overview

| File | Lines | Purpose |
|------|-------|---------|
EOL

# Generate justfile table
for file in $(find "${root_dir}/justfiles" -name "*.justfile" | sort); do
  lines=$(wc -l < "$file")
  purpose=$(grep -m 1 "^# " "$file" | sed 's/^# //' || echo "No description found")
  filename=$(basename "$file")
  echo "| $filename | $lines | $purpose |" >> "$plan_file"
done

# Create action tracking file
cat > "$action_file" << EOL
# Justfile Improvement Actions

Generated: $(date)

This file tracks the implementation of improvements to the justfile structure.

## Research Phase

- [ ] Research current justfile best practices from GitHub repos
- [ ] Review Reddit r/rust and r/commandline for justfile discussions
- [ ] Study popular open source projects using just for inspiration
- [ ] Document findings and patterns

## Analysis Phase

- [ ] Identify redundancies across justfiles
- [ ] Find opportunities for recipe standardization
- [ ] Analyze command parameter patterns
- [ ] Check for modularization improvements

## Design Phase

- [ ] Create template for standardized justfile structure
- [ ] Design improved parameter handling system
- [ ] Plan documentation improvements
- [ ] Create naming convention guidelines

## Implementation Phase

- [ ] Standardize recipe formats
- [ ] Improve parameter handling
- [ ] Consolidate duplicate functionality
- [ ] Enhance documentation
- [ ] Add validation recipes
- [ ] Create testing framework for justfiles

## Validation Phase

- [ ] Test all modified justfiles
- [ ] Verify backward compatibility
- [ ] Measure performance improvements
- [ ] Document changes and benefits

## Completion Report

- [ ] Document all changes implemented
- [ ] List benefits achieved
- [ ] Provide usage examples
- [ ] Share lessons learned

## Follow-up Tasks

- [ ] Schedule periodic review
- [ ] Create automated linting for justfiles
- [ ] Setup maintenance plan

## Initial Research Findings

### Best Practices from GitHub

**Popular Repositories Using Just:**
- [casey/just](https://github.com/casey/just) - The official repository
- Various Rust projects with modular justfile approaches
- Enterprise repositories using just for CI/CD pipelines

**Common Patterns:**
- Modular organization with separate files for logical groups
- Consistent naming conventions (verb-noun format)
- Extensive documentation in justfiles
- Parameter validation and error handling
- Use of shared variables and constants
- Cross-platform compatibility techniques

### Techniques to Implement

1. **Consistent Recipe Format**
   - Standard documentation header
   - Argument validation blocks
   - Common error handling patterns

2. **Improved Modularity**
   - Logical grouping by function
   - Explicit dependencies between justfiles
   - Reduced duplication across files

3. **Enhanced Documentation**
   - Standardized help text format
   - Examples for complex recipes
   - Visual separation of sections

4. **Advanced Features**
   - Tab completion support
   - CI/CD integration patterns
   - Validation recipes
   - Self-testing justfiles

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
- [x] Create inventory of all justfiles and recipes
  Note: Found 12 justfiles with 87 total recipes
\`\`\`

## Command to update this plan

\`\`\`
just claude "I've completed step X of the justfile improvement plan. Update the plan at $plan_file to mark this step as complete and proceed to the next step."
\`\`\`
EOL

# Display file locations
echo "Action plan created at $action_file"
echo "Implementation plan created at $plan_file"

# Simply display the first few lines of the plan instead of opening editor
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
echo "'Research latest justfile best practices and begin implementing the first step of the plan at $plan_file'"
echo ""
echo "2. After completing each step, update the plan using:"
echo "'just claude \"Mark step X complete in $plan_file and proceed to next step\"'"