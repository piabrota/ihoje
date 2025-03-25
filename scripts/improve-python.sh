#!/bin/bash
set -e

# Move to the project root directory
cd "$(dirname "$0")/.."
root_dir="$(pwd)"

echo "===== Python Improvement Tool ====="
echo "Creating improvement plan and action tracker in ${root_dir}..."

# Create reports directory
mkdir -p reports
timestamp=$(date +%Y%m%d_%H%M%S)
plan_file="${root_dir}/reports/python_improvement_plan_${timestamp}.md"
action_file="${root_dir}/reports/python_improvement_actions_${timestamp}.md"

# Locate Python files in the project
script_dirs=("scripts" "scripts/mangekyou-mcp" "scripts/mangekyo-mcp")
python_files=()

for dir in "${script_dirs[@]}"; do
  if [ -d "${root_dir}/${dir}" ]; then
    while IFS= read -r file; do
      python_files+=("$file")
    done < <(find "${root_dir}/${dir}" -name "*.py" 2>/dev/null)
  fi
done

# Count Python files
total_python_files=${#python_files[@]}

# Start plan document
cat > "$plan_file" << EOL
# Python Code Improvement Plan

Generated: $(date)

## Current Analysis
\`\`\`
Total Python files: $total_python_files
\`\`\`

## Implementation Steps

1. **Analyze Current Structure**
   - [_] Create inventory of all Python files and modules
   - [_] Identify code patterns and inconsistencies
   - [_] Document dependencies between modules

2. **Standardize Code Format**
   - [_] Apply PEP 8 style guidelines consistently
   - [_] Update all files to follow the standard format
   - [_] Implement error handling and logging improvements

3. **Enhance Modularity**
   - [_] Reorganize code by logical function
   - [_] Remove duplicate functionality
   - [_] Create shared utility functions for common operations

4. **Improve Documentation**
   - [_] Add docstrings to all functions and classes
   - [_] Create user guide for common workflows
   - [_] Add type hints for better IDE support

5. **Add Advanced Features**
   - [_] Implement resource management improvements
   - [_] Add monitoring and observability
   - [_] Support for configuration management

## Python Files Overview

| File | Lines | Purpose |
|------|-------|---------|
EOL

# Generate Python file table
for file in "${python_files[@]}"; do
  if [ -f "$file" ]; then
    lines=$(wc -l < "$file")
    rel_path=$(realpath --relative-to="${root_dir}" "$file")
    # Try to extract purpose from doc comment or first comment
    purpose=$(grep -m 1 '"""' "$file" | grep -v '"""$' | sed 's/"""//' || \
              grep -m 1 "^#" "$file" | sed 's/# //' || \
              echo "No description found")
    echo "| $rel_path | $lines | $purpose |" >> "$plan_file"
  fi
done

# Create action tracking file
cat > "$action_file" << EOL
# Python Improvement Actions

Generated: $(date)

This file tracks the implementation of improvements to the Python code structure.

## Research Phase

- [ ] Research current Python best practices (PEP 8, PEP 257)
- [ ] Review modern Python patterns on Real Python and Python.org
- [ ] Study popular open source Python projects for inspiration
- [ ] Document findings and patterns

## Analysis Phase

- [ ] Identify redundancies across Python modules
- [ ] Find opportunities for class-based organization
- [ ] Analyze error handling and logging patterns
- [ ] Check for modularization improvements

## Design Phase

- [ ] Create template for standardized module structure
- [ ] Design improved error handling system
- [ ] Plan documentation improvements
- [ ] Create naming convention guidelines

## Implementation Phase

- [ ] Apply standard code formatting with Black/autopep8
- [ ] Improve error handling and logging
- [ ] Consolidate duplicate functionality
- [ ] Enhance documentation with docstrings
- [ ] Add type hints for better IDE support
- [ ] Implement resource management improvements

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

### Best Practices from Python Community

**Popular Style Guides:**
- [PEP 8](https://peps.python.org/pep-0008/) - Style Guide for Python Code
- [PEP 257](https://peps.python.org/pep-0257/) - Docstring Conventions
- Google Python Style Guide

**Common Patterns:**
- Type hints with mypy validation
- Context managers for resource handling
- Comprehensive logging
- Environment-based configuration
- Dependency injection
- Testing with pytest

### Techniques to Implement

1. **Consistent Error Handling**
   - Exception hierarchies
   - Context managers
   - Centralized logging
   - Exception chaining with `from`

2. **Improved Modularity**
   - Logical package organization
   - Clear imports structure
   - Private vs public interfaces
   - Factory patterns when appropriate

3. **Enhanced Documentation**
   - Standardized docstrings (Google/NumPy style)
   - README files for packages
   - Examples in documentation
   - Type hints for better IDE integration

4. **Advanced Features**
   - Resource utilization monitoring
   - Signal handling
   - Configuration management
   - Process isolation

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
- [x] Create inventory of all Python files
  Note: Found $total_python_files Python files across various components
\`\`\`

## Command to update this plan

\`\`\`
just claude "I've completed step X of the Python improvement plan. Update the plan at $plan_file to mark this step as complete and proceed to the next step."
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
echo "'Research latest Python best practices and begin implementing the first step of the plan at $plan_file'"
echo ""
echo "2. After completing each step, update the plan using:"
echo "'just claude \"Mark step X complete in $plan_file and proceed to next step\"'"