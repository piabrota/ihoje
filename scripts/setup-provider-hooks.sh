#!/bin/bash
# Script to set up provider security hooks and scripts

echo "Setting up provider security hooks and scripts..."

# Create necessary directories
mkdir -p .github/hooks

# Create pre-commit hook for provider leak checking
cat > .github/hooks/pre-commit << 'EOF'
#!/bin/bash
# Pre-commit hook to check for provider name leaks

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo "Running provider leak check..."

# List of provider names to check for (case insensitive)
PROVIDER_NAMES=("sympla" "shotgun" "www.sympla.com" "sympla.com.br" "shotgun.live")

# Files to exclude from checking
EXCLUDE=(
  ".env"          # Actual environment variables file
  "docs/claude/core/cache.md"  # Claude cache file
  ".github/hooks/pre-commit"  # This script
  "*.log"         # Log files
  "*.csv"         # Data export files
)

# Build exclude pattern for grep
EXCLUDE_PATTERN=""
for pattern in "${EXCLUDE[@]}"; do
  EXCLUDE_PATTERN="$EXCLUDE_PATTERN --exclude=$pattern"
done

# Check for provider names in repository
FOUND_LEAKS=0

for name in "${PROVIDER_NAMES[@]}"; do
  echo -e "${YELLOW}Checking for '$name' references...${NC}"
  
  # Use grep to find references, excluding specified files
  RESULTS=$(grep -r -i "$name" $EXCLUDE_PATTERN --include="*.rs" --include="*.md" \
    --include="*.toml" --include="*.json" --include="*.js" --include="*.yml" \
    --include="Dockerfile*" . || true)
  
  if [ -n "$RESULTS" ]; then
    echo -e "${RED}Found '$name' references in the following files:${NC}"
    echo "$RESULTS"
    FOUND_LEAKS=1
  else
    echo -e "${GREEN}No '$name' references found.${NC}"
  fi
done

# Check .env.example specifically
echo -e "${YELLOW}Checking .env.example for provider URLs...${NC}"
ENV_EXAMPLE_LEAKS=$(grep -i -E "http[s]?://(www\.)?[a-zA-Z0-9-]+\.(com|org|net)" .env.example || true)

if [ -n "$ENV_EXAMPLE_LEAKS" ]; then
  echo -e "${RED}Found URL(s) in .env.example:${NC}"
  echo "$ENV_EXAMPLE_LEAKS"
  if [[ "$ENV_EXAMPLE_LEAKS" != *"example.com"* ]]; then
    FOUND_LEAKS=1
  else
    echo -e "${GREEN}URL appears to be a placeholder (example.com). This is OK.${NC}"
  fi
else
  echo -e "${GREEN}No URLs found in .env.example.${NC}"
fi

# Final result
if [ $FOUND_LEAKS -eq 1 ]; then
  echo -e "${RED}❌ Provider name leaks detected! Please fix before committing.${NC}"
  echo "Tip: Use codenames (Pikachu, Charmander) instead of actual provider names."
  echo "     Only .env should contain actual provider URLs (not versioned)."
  exit 1
else
  echo -e "${GREEN}✅ No provider name leaks detected.${NC}"
  exit 0
fi
EOF

# Create provider scrubbing script
cat > .github/hooks/scrub-providers.sh << 'EOF'
#!/bin/bash
# Script to scrub provider names and URLs from the codebase

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}==== Provider Reference Scrubbing Tool ====${NC}"
echo -e "This tool removes direct references to provider names and URLs from the codebase."
echo -e "${YELLOW}WARNING: This will modify files in your repository!${NC}"
read -p "Continue? (y/n): " confirm
if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
    echo "Operation cancelled."
    exit 1
fi

echo -e "\n${BLUE}Step 1: Finding provider references in source code...${NC}"

# List of provider names to check for (case insensitive)
PROVIDER_NAMES=(
    "sympla" 
    "shotgun" 
    "www.sympla.com" 
    "sympla.com.br" 
    "shotgun.live"
)

# Files to exclude
EXCLUDE=(
    ".env"
    "docs/claude/core/cache.md"
    ".github/hooks/scrub-providers.sh"
    "*.log"
    "*.csv"
)

# Build exclude pattern for grep
EXCLUDE_PATTERN=""
for pattern in "${EXCLUDE[@]}"; do
    EXCLUDE_PATTERN="$EXCLUDE_PATTERN --exclude=$pattern"
done

# Check for provider names in repository
FOUND_REFERENCES=0

for name in "${PROVIDER_NAMES[@]}"; do
    echo -e "${YELLOW}Checking for '$name' references...${NC}"
    
    # Use grep to find references, excluding specified files
    RESULTS=$(grep -r -i "$name" $EXCLUDE_PATTERN --include="*.rs" --include="*.md" \
        --include="*.toml" --include="*.json" --include="*.js" --include="*.yml" \
        --include="Dockerfile*" . || true)
    
    if [ -n "$RESULTS" ]; then
        echo -e "${RED}Found '$name' references:${NC}"
        echo "$RESULTS"
        FOUND_REFERENCES=1
    else
        echo -e "${GREEN}No '$name' references found.${NC}"
    fi
done

echo -e "\n${BLUE}Step 2: Checking .env.example for provider URLs...${NC}"
ENV_EXAMPLE_PATH=".env.example"

if [ -f "$ENV_EXAMPLE_PATH" ]; then
    ENV_EXAMPLE_URLS=$(grep -i -E "http[s]?://(www\.)?[a-zA-Z0-9-]+\.(com|org|net|io)" "$ENV_EXAMPLE_PATH" || true)
    
    if [ -n "$ENV_EXAMPLE_URLS" ]; then
        echo -e "${YELLOW}Found URL(s) in .env.example:${NC}"
        echo "$ENV_EXAMPLE_URLS"
        
        # Check if it's example.com
        if [[ "$ENV_EXAMPLE_URLS" != *"example.com"* ]]; then
            echo -e "${RED}URLs should use example.com as a placeholder.${NC}"
            echo -e "${YELLOW}Replacing provider URLs with example.com...${NC}"
            
            # Replace specific provider domains with example.com
            sed -i 's|https://www\..*\.com\.br|https://example.com|g' "$ENV_EXAMPLE_PATH"
            sed -i 's|https://.*\.live|https://example.com|g' "$ENV_EXAMPLE_PATH"
            
            echo -e "${GREEN}Replaced provider URLs in .env.example${NC}"
        else
            echo -e "${GREEN}URLs already use example.com. No changes needed.${NC}"
        fi
    else
        echo -e "${GREEN}No URLs found in .env.example.${NC}"
    fi
else
    echo -e "${RED}.env.example not found!${NC}"
fi

echo -e "\n${BLUE}Step 3: Updating .gitignore to exclude provider files...${NC}"
GITIGNORE_PATH=".gitignore"

if [ -f "$GITIGNORE_PATH" ]; then
    # Check if provider patterns already exist
    SYMPLA_PATTERN=$(grep -i "*sympla*" "$GITIGNORE_PATH" || true)
    SHOTGUN_PATTERN=$(grep -i "*shotgun*" "$GITIGNORE_PATH" || true)
    
    # Add patterns if they don't exist
    if [ -z "$SYMPLA_PATTERN" ]; then
        echo -e "${YELLOW}Adding *sympla* pattern to .gitignore...${NC}"
        echo "*sympla*" >> "$GITIGNORE_PATH"
    fi
    
    if [ -z "$SHOTGUN_PATTERN" ]; then
        echo -e "${YELLOW}Adding *shotgun* pattern to .gitignore...${NC}"
        echo "*shotgun*" >> "$GITIGNORE_PATH"
    fi
    
    echo -e "${GREEN}Updated .gitignore with provider exclusion patterns.${NC}"
else
    echo -e "${RED}.gitignore not found!${NC}"
fi

echo -e "\n${BLUE}Step 4: Checking README.md for provider references...${NC}"
README_PATH="README.md"

if [ -f "$README_PATH" ]; then
    README_REFS=$(grep -i -E "sympla|shotgun" "$README_PATH" || true)
    
    if [ -n "$README_REFS" ]; then
        echo -e "${YELLOW}Found provider references in README.md:${NC}"
        echo "$README_REFS"
        echo -e "${YELLOW}Please manually update README.md to use codenames (Pikachu, Charmander)${NC}"
    else
        echo -e "${GREEN}No direct provider references found in README.md.${NC}"
    fi
else
    echo -e "${RED}README.md not found!${NC}"
fi

echo -e "\n${BLUE}Step 5: Final checkup...${NC}"
echo -e "${YELLOW}Running provider leak check...${NC}"

# Reuse check from pre-commit
if [ -f ".github/hooks/pre-commit" ]; then
    bash .github/hooks/pre-commit
    CHECK_RESULT=$?
    
    if [ $CHECK_RESULT -eq 0 ]; then
        echo -e "${GREEN}All provider references have been successfully scrubbed!${NC}"
    else
        echo -e "${RED}Some provider references may still exist. Please check manually.${NC}"
    fi
else
    echo -e "${RED}Pre-commit hook not found for final check!${NC}"
    echo -e "${YELLOW}Please run a manual check for remaining provider references.${NC}"
fi

echo -e "\n${BLUE}Provider scrubbing procedure complete!${NC}"
echo -e "Remember to review changes before committing."
EOF

# Make scripts executable
chmod +x .github/hooks/pre-commit
chmod +x .github/hooks/scrub-providers.sh

# Install pre-commit hook to git
cp .github/hooks/pre-commit .git/hooks/

echo "Provider security hooks and scripts installed successfully"
echo "You can now run 'just provider scrub' to remove provider references"