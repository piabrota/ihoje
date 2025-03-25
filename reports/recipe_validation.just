# Recipe Validation System
# This justfile provides validation functions for justfile recipes

# Load .env file if present
set dotenv-load

# [L] List validation recipes
default:
    @just --list

# [H] Show validation help
help:
    @echo "=== Justfile Validation Tools ==="
    @echo ""
    @echo "Usage:"
    @echo "  just validate-recipe JUSTFILE RECIPE - Validate a specific recipe"
    @echo "  just validate-file JUSTFILE          - Validate entire justfile"
    @echo "  just validate-all                    - Validate all justfiles"
    @echo "  just fix-recipe JUSTFILE RECIPE      - Fix common recipe issues"
    @echo "  just fix-file JUSTFILE               - Fix common issues in justfile"
    @echo ""
    @echo "Examples:"
    @echo "  just validate-recipe run.justfile run-city"
    @echo "  just validate-file db.justfile"
    @echo "  just validate-all"

# [V] Validate a specific recipe in a justfile
# 
# Usage: just validate-recipe JUSTFILE RECIPE
validate-recipe justfile recipe:
    #!/usr/bin/env bash
    # Validate parameters
    [ -z "{{justfile}}" ] && echo "Error: justfile required" && exit 1
    [ -z "{{recipe}}" ] && echo "Error: recipe required" && exit 1
    
    echo "Validating recipe '{{recipe}}' in {{justfile}}..."
    
    # Check if justfile exists
    [ ! -f "{{justfile}}" ] && echo "Error: justfile not found: {{justfile}}" && exit 1
    
    # Extract recipe content
    RECIPE_CONTENT=$(sed -n "/^{{recipe}}[[:space:]]*[:+*]/,/^[a-zA-Z0-9_-][a-zA-Z0-9_-]*[:+*]/p" "{{justfile}}" | sed '$d')
    
    # Check if recipe exists
    [ -z "$RECIPE_CONTENT" ] && echo "Error: recipe not found: {{recipe}}" && exit 1
    
    # Run validations
    ISSUES=0
    
    # 1. Check for documentation comment
    if ! echo "$RECIPE_CONTENT" | grep -q "^#"; then
        echo "Warning: Missing documentation comment for {{recipe}}"
        ((ISSUES++))
    fi
    
    # 2. Check for tag in documentation
    if ! echo "$RECIPE_CONTENT" | grep -q "^# \[[A-Z]\]"; then
        echo "Warning: Missing [TAG] in documentation for {{recipe}}"
        ((ISSUES++))
    fi
    
    # 3. Check for parameter validation (if parameters exist)
    if echo "$RECIPE_CONTENT" | grep -q "{{recipe}}.*[a-zA-Z0-9_-][a-zA-Z0-9_-]*="; then
        # Recipe has parameters, check for validation
        if echo "$RECIPE_CONTENT" | grep -q "#!/usr/bin/env bash" && ! echo "$RECIPE_CONTENT" | grep -q "\[ -z"; then
            echo "Warning: Recipe has parameters but no validation for {{recipe}}"
            ((ISSUES++))
        fi
    fi
    
    # 4. Check for error handling (in bash script recipes)
    if echo "$RECIPE_CONTENT" | grep -q "#!/usr/bin/env bash"; then
        if ! echo "$RECIPE_CONTENT" | grep -q "exit 1"; then
            echo "Warning: Missing error handling in bash script for {{recipe}}"
            ((ISSUES++))
        fi
    fi
    
    # 5. Check for command suppression (@) where appropriate
    if echo "$RECIPE_CONTENT" | grep -q "echo" && ! echo "$RECIPE_CONTENT" | grep -q "@echo"; then
        echo "Warning: Missing @ on echo commands in {{recipe}}"
        ((ISSUES++))
    fi
    
    # Report results
    if [ $ISSUES -eq 0 ]; then
        echo "✅ Recipe '{{recipe}}' validation passed!"
    else
        echo "⚠️ Recipe '{{recipe}}' has $ISSUES validation issues"
    fi
    
    exit $ISSUES

# [V] Validate all recipes in a justfile
#
# Usage: just validate-file JUSTFILE
validate-file justfile:
    #!/usr/bin/env bash
    # Validate parameters
    [ -z "{{justfile}}" ] && echo "Error: justfile required" && exit 1
    
    echo "Validating all recipes in {{justfile}}..."
    
    # Check if justfile exists
    [ ! -f "{{justfile}}" ] && echo "Error: justfile not found: {{justfile}}" && exit 1
    
    # Extract all recipe names
    RECIPES=$(grep -E "^[a-zA-Z0-9_-]+[ ]*[\:\+\*]" "{{justfile}}" | sed -E 's/^([a-zA-Z0-9_-]+)[ ]*[\:\+\*].*/\1/')
    
    # Initialize counters
    TOTAL=0
    PASSED=0
    FAILED=0
    
    # Validate each recipe
    for recipe in $RECIPES; do
        echo "Checking recipe: $recipe"
        if just validate-recipe "{{justfile}}" "$recipe" > /dev/null 2>&1; then
            echo "  ✅ Passed"
            ((PASSED++))
        else
            echo "  ⚠️ Failed"
            ((FAILED++))
        fi
        ((TOTAL++))
    done
    
    # Report results
    echo ""
    echo "Validation Summary for {{justfile}}:"
    echo "Total recipes: $TOTAL"
    echo "Passed: $PASSED"
    echo "Failed: $FAILED"
    
    # Exit with failure if any recipe failed
    [ $FAILED -gt 0 ] && exit 1 || exit 0

# [V] Validate all justfiles in the project
validate-all:
    #!/usr/bin/env bash
    echo "Validating all justfiles..."
    
    # Find all justfiles
    JUSTFILES=$(find justfiles -name "*.justfile")
    
    # Add main justfile
    JUSTFILES="$JUSTFILES justfile"
    
    # Initialize counters
    TOTAL_FILES=0
    PASSED_FILES=0
    FAILED_FILES=0
    
    # Validate each justfile
    for justfile in $JUSTFILES; do
        echo "Checking justfile: $justfile"
        if just validate-file "$justfile" > /dev/null 2>&1; then
            echo "  ✅ Passed"
            ((PASSED_FILES++))
        else
            echo "  ⚠️ Failed"
            ((FAILED_FILES++))
        fi
        ((TOTAL_FILES++))
    done
    
    # Report results
    echo ""
    echo "Validation Summary:"
    echo "Total justfiles: $TOTAL_FILES"
    echo "Passed: $PASSED_FILES"
    echo "Failed: $FAILED_FILES"
    
    # Exit with failure if any justfile failed
    [ $FAILED_FILES -gt 0 ] && exit 1 || exit 0

# [F] Fix common issues in a recipe
#
# Usage: just fix-recipe JUSTFILE RECIPE
fix-recipe justfile recipe:
    #!/usr/bin/env bash
    # Validate parameters
    [ -z "{{justfile}}" ] && echo "Error: justfile required" && exit 1
    [ -z "{{recipe}}" ] && echo "Error: recipe required" && exit 1
    
    echo "Fixing recipe '{{recipe}}' in {{justfile}}..."
    
    # Check if justfile exists
    [ ! -f "{{justfile}}" ] && echo "Error: justfile not found: {{justfile}}" && exit 1
    
    # Create backup
    cp "{{justfile}}" "{{justfile}}.bak"
    
    # Get recipe type (first letter uppercased)
    RECIPE_TYPE=$(echo "{{recipe}}" | sed -E 's/^([a-z])[a-z]*-.*/\1/' | tr '[:lower:]' '[:upper:]')
    [ -z "$RECIPE_TYPE" ] && RECIPE_TYPE="R"  # Default to R (run)
    
    # Fix 1: Add documentation if missing
    if ! grep -A 1 "^{{recipe}}[[:space:]]*[:+*]" "{{justfile}}" | grep -q "^#"; then
        # Add basic documentation
        sed -i "/^{{recipe}}[[:space:]]*[:+*]/i # [${RECIPE_TYPE}] {{recipe}} command" "{{justfile}}"
        echo "Added basic documentation"
    fi
    
    # Fix 2: Add tag if missing
    if ! grep -A 1 "^{{recipe}}[[:space:]]*[:+*]" "{{justfile}}" | grep -q "^# \[[A-Z]\]"; then
        # Update documentation with tag
        sed -i "/^# .*{{recipe}}/s/^# /# [${RECIPE_TYPE}] /" "{{justfile}}"
        echo "Added [${RECIPE_TYPE}] tag"
    fi
    
    # Fix 3: Add @ to echo commands
    sed -i "/^{{recipe}}[[:space:]]*[:+*]/,/^[a-zA-Z0-9_-][a-zA-Z0-9_-]*[:+*]/s/^\([[:space:]]*\)echo/\1@echo/g" "{{justfile}}"
    echo "Added @ to echo commands if needed"
    
    echo "Recipe fixed successfully!"

# [F] Fix common issues in a justfile
#
# Usage: just fix-file JUSTFILE
fix-file justfile:
    #!/usr/bin/env bash
    # Validate parameters
    [ -z "{{justfile}}" ] && echo "Error: justfile required" && exit 1
    
    echo "Fixing all recipes in {{justfile}}..."
    
    # Check if justfile exists
    [ ! -f "{{justfile}}" ] && echo "Error: justfile not found: {{justfile}}" && exit 1
    
    # Create backup
    cp "{{justfile}}" "{{justfile}}.bak"
    
    # Extract all recipe names
    RECIPES=$(grep -E "^[a-zA-Z0-9_-]+[ ]*[\:\+\*]" "{{justfile}}" | sed -E 's/^([a-zA-Z0-9_-]+)[ ]*[\:\+\*].*/\1/')
    
    # Fix each recipe
    for recipe in $RECIPES; do
        echo "Fixing recipe: $recipe"
        just fix-recipe "{{justfile}}" "$recipe"
    done
    
    echo "All recipes fixed in {{justfile}}"