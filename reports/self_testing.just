# Self-Testing Justfile
# This justfile provides self-testing capabilities for justfiles

# Load .env file if present
set dotenv-load

# [L] List self-testing recipes
default:
    @just --list

# [H] Show self-testing help
help:
    @echo "=== Justfile Self-Testing Tools ==="
    @echo ""
    @echo "Usage:"
    @echo "  just test-recipe JUSTFILE RECIPE     - Test a specific recipe"
    @echo "  just test-file JUSTFILE              - Test all recipes in a justfile"
    @echo "  just test-all                        - Test all justfiles"
    @echo "  just generate-test JUSTFILE RECIPE   - Generate test for a recipe"
    @echo ""
    @echo "Examples:"
    @echo "  just test-recipe run.justfile run-city"
    @echo "  just test-file db.justfile"
    @echo "  just test-all"

# [T] Test a specific recipe
#
# Usage: just test-recipe JUSTFILE RECIPE
test-recipe justfile recipe:
    #!/usr/bin/env bash
    # Validate parameters
    [ -z "{{justfile}}" ] && echo "Error: justfile required" && exit 1
    [ -z "{{recipe}}" ] && echo "Error: recipe required" && exit 1
    
    echo "Testing recipe '{{recipe}}' in {{justfile}}..."
    
    # Check if justfile exists
    [ ! -f "{{justfile}}" ] && echo "Error: justfile not found: {{justfile}}" && exit 1
    
    # Check if test file exists
    TEST_FILE="tests/just/$(basename {{justfile}} .justfile)_{{recipe}}_test.sh"
    if [ -f "$TEST_FILE" ]; then
        echo "Found test file: $TEST_FILE"
        
        # Make test file executable
        chmod +x "$TEST_FILE"
        
        # Run test
        echo "Running test..."
        if $TEST_FILE; then
            echo "✅ Test passed!"
            exit 0
        else
            echo "❌ Test failed!"
            exit 1
        fi
    else
        # Try to run recipe with --dry-run if available
        echo "No test file found, trying dry run..."
        if just --justfile "{{justfile}}" --dry-run {{recipe}}; then
            echo "✅ Dry run syntax check passed!"
            
            # For simple recipes, try to extract help text
            if grep -q "^{{recipe}}:" "{{justfile}}" && ! grep -q "^{{recipe}}.*:" "{{justfile}}"; then
                echo "Simple recipe detected, checking for documentation..."
                if grep -q "^# .*{{recipe}}" "{{justfile}}"; then
                    echo "✅ Documentation found"
                    exit 0
                else
                    echo "⚠️ No documentation found for recipe"
                    exit 0
                fi
            else
                echo "⚠️ Complex recipe detected, recommended to create test file:"
                echo "$TEST_FILE"
                exit 0
            fi
        else
            echo "❌ Dry run syntax check failed!"
            exit 1
        fi
    fi

# [T] Test all recipes in a justfile
#
# Usage: just test-file JUSTFILE
test-file justfile:
    #!/usr/bin/env bash
    # Validate parameters
    [ -z "{{justfile}}" ] && echo "Error: justfile required" && exit 1
    
    echo "Testing all recipes in {{justfile}}..."
    
    # Check if justfile exists
    [ ! -f "{{justfile}}" ] && echo "Error: justfile not found: {{justfile}}" && exit 1
    
    # Extract all recipe names (excluding default and help)
    RECIPES=$(grep -E "^[a-zA-Z0-9_-]+[ ]*[\:\+\*]" "{{justfile}}" | sed -E 's/^([a-zA-Z0-9_-]+)[ ]*[\:\+\*].*/\1/' | grep -v "^default$" | grep -v "^help$")
    
    # Initialize counters
    TOTAL=0
    PASSED=0
    FAILED=0
    
    # Test each recipe
    for recipe in $RECIPES; do
        echo "Testing recipe: $recipe"
        if just test-recipe "{{justfile}}" "$recipe"; then
            ((PASSED++))
        else
            ((FAILED++))
        fi
        ((TOTAL++))
    done
    
    # Report results
    echo ""
    echo "Testing Summary for {{justfile}}:"
    echo "Total recipes: $TOTAL"
    echo "Passed: $PASSED"
    echo "Failed: $FAILED"
    
    # Exit with failure if any recipe failed
    [ $FAILED -gt 0 ] && exit 1 || exit 0

# [T] Test all justfiles
test-all:
    #!/usr/bin/env bash
    echo "Testing all justfiles..."
    
    # Ensure test directory exists
    mkdir -p tests/just
    
    # Find all justfiles
    JUSTFILES=$(find justfiles -name "*.justfile")
    
    # Add main justfile
    JUSTFILES="$JUSTFILES justfile"
    
    # Initialize counters
    TOTAL_FILES=0
    PASSED_FILES=0
    FAILED_FILES=0
    
    # Test each justfile
    for justfile in $JUSTFILES; do
        echo "Testing justfile: $justfile"
        if just test-file "$justfile"; then
            ((PASSED_FILES++))
        else
            ((FAILED_FILES++))
        fi
        ((TOTAL_FILES++))
    done
    
    # Report results
    echo ""
    echo "Testing Summary:"
    echo "Total justfiles: $TOTAL_FILES"
    echo "Passed: $PASSED_FILES"
    echo "Failed: $FAILED_FILES"
    
    # Exit with failure if any justfile failed
    [ $FAILED_FILES -gt 0 ] && exit 1 || exit 0

# [C] Generate test for a recipe
#
# Usage: just generate-test JUSTFILE RECIPE
generate-test justfile recipe:
    #!/usr/bin/env bash
    # Validate parameters
    [ -z "{{justfile}}" ] && echo "Error: justfile required" && exit 1
    [ -z "{{recipe}}" ] && echo "Error: recipe required" && exit 1
    
    echo "Generating test for recipe '{{recipe}}' in {{justfile}}..."
    
    # Check if justfile exists
    [ ! -f "{{justfile}}" ] && echo "Error: justfile not found: {{justfile}}" && exit 1
    
    # Create test directory
    mkdir -p tests/just
    
    # Create test file
    TEST_FILE="tests/just/$(basename {{justfile}} .justfile)_{{recipe}}_test.sh"
    
    # Extract recipe content to analyze
    RECIPE_CONTENT=$(sed -n "/^{{recipe}}[[:space:]]*[:+*]/,/^[a-zA-Z0-9_-][a-zA-Z0-9_-]*[:+*]/p" "{{justfile}}" | sed '$d')
    
    # Create test file
    cat > "$TEST_FILE" << EOF
#!/usr/bin/env bash
# Test for {{recipe}} in {{justfile}}

# Set -e to exit on error
set -e

echo "Testing {{recipe}} from $(basename {{justfile}})..."

# Setup test environment
TEST_DIR=\$(mktemp -d)
trap "rm -rf \$TEST_DIR" EXIT

# Change to test directory
cd \$TEST_DIR

# Copy necessary files for testing
cp $(pwd)/{{justfile}} ./

EOF
    
    # Add specific test based on recipe content
    if echo "$RECIPE_CONTENT" | grep -q "cargo run"; then
        # Recipe runs cargo, create mock
        cat >> "$TEST_FILE" << EOF
# Mock cargo command
mkdir -p bin
cat > bin/cargo << 'MOCK'
#!/bin/bash
echo "Mock cargo called with: \$@"
exit 0
MOCK
chmod +x bin/cargo
export PATH="\$TEST_DIR/bin:\$PATH"

EOF
    fi
    
    # Complete test file
    cat >> "$TEST_FILE" << EOF
# Test execution
just --justfile $(basename {{justfile}}) {{recipe}} --dry-run test-args

# Verify test (add specific checks here)
# For example:
# [ -f "expected_output_file.txt" ] || { echo "Expected output file not created"; exit 1; }

echo "Test passed!"
exit 0
EOF
    
    # Make test file executable
    chmod +x "$TEST_FILE"
    
    echo "Test generated: $TEST_FILE"
    echo "Review and customize the test for specific validations"