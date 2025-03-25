#!/bin/bash
# Script for tracking and optimizing Claude token usage

# Check if wc is available
if ! command -v wc &> /dev/null; then
    echo "Error: wc command not found"
    exit 1
fi

# Function to estimate tokens from text
# Uses approximation: tokens ≈ 4/3 * word count
estimate_tokens() {
    local text="$1"
    local word_count=$(echo "$text" | wc -w)
    echo $(( word_count * 4 / 3 ))
}

# Function to analyze a file for token usage
analyze_file() {
    local file="$1"
    
    if [ ! -f "$file" ]; then
        echo "File not found: $file"
        return 1
    fi
    
    local tokens=$(estimate_tokens "$(cat "$file")")
    local lines=$(wc -l < "$file")
    local chars=$(wc -c < "$file")
    
    echo "File: $file"
    echo "  Estimated tokens: $tokens"
    echo "  Lines: $lines"
    echo "  Characters: $chars"
    echo "  Token density: $(echo "scale=2; $tokens / $lines" | bc) tokens/line"
    
    return 0
}

# Function to analyze context combinations
analyze_context_combination() {
    local name="$1"
    shift
    local files=("$@")
    
    # Create temporary concatenated file
    local temp_file=$(mktemp)
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            cat "$file" >> "$temp_file"
        fi
    done
    
    local tokens=$(estimate_tokens "$(cat "$temp_file")")
    
    echo "Context: $name"
    echo "  Files: ${files[*]}"
    echo "  Total estimated tokens: $tokens"
    
    # Cleanup
    rm "$temp_file"
}

# Main script execution

# Default to analyzing all context files if no arguments
if [ $# -eq 0 ]; then
    echo "=== Token Usage Analysis ==="
    
    # Analyze individual files
    echo -e "\n--- Individual Files ---"
    for file in docs/claude/core/guidelines.md docs/claude/core/bootstrap.md docs/claude/domain/sharingan.md docs/claude/domain/tobira.md docs/claude/domain/mangekyou.md; do
        if [ -f "$file" ]; then
            analyze_file "$file"
            echo ""
        fi
    done
    
    # Analyze standard context combinations
    echo -e "\n--- Context Combinations ---"
    analyze_context_combination "Micro" "docs/claude/core/bootstrap.md"
    analyze_context_combination "Minimal" "docs/claude/core/bootstrap.md" "docs/claude/core/cache.md"
    analyze_context_combination "Standard" "docs/claude/core/bootstrap.md" "docs/claude/core/guidelines.md" "docs/claude/core/cache.md"
    analyze_context_combination "Sharingan" "docs/claude/core/bootstrap.md" "docs/claude/domain/sharingan.md" "docs/claude/core/cache.md"
    analyze_context_combination "Frontend" "docs/claude/core/bootstrap.md" "docs/claude/domain/tobira.md" "docs/claude/core/cache.md"
    analyze_context_combination "Mangekyou" "docs/claude/core/bootstrap.md" "docs/claude/domain/mangekyou.md" "docs/claude/core/cache.md"
    analyze_context_combination "Full" "docs/claude/core/bootstrap.md" "docs/claude/core/guidelines.md" "docs/claude/domain/sharingan.md" "docs/claude/domain/tobira.md" "docs/claude/domain/mangekyou.md" "docs/claude/core/cache.md"
    
    echo -e "\n--- Optimization Suggestions ---"
    echo "1. Prefer domain-specific contexts over full context"
    echo "2. Use claude-micro for simple queries"
    echo "3. Break complex tasks into sequential steps"
    echo "4. Use checkpoints to maintain state between sessions"
    
else
    # Analyze specific files provided as arguments
    echo "=== Token Usage Analysis ==="
    
    for file in "$@"; do
        if [ -f "$file" ]; then
            analyze_file "$file"
            echo ""
        else
            echo "File not found: $file"
        fi
    done
fi

exit 0