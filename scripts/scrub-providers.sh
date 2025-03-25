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
    "scripts/scrub-providers.sh"
    ".github/hooks/pre-commit"
    ".github/hooks/scrub-providers.sh"
    "*.log"
    "*.csv"
    "*.html"
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
        --include="Dockerfile*" --include="*.sh" . || true)
    
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

echo -e "\n${BLUE}Step 3: Checking .env file for provider names...${NC}"
ENV_PATH=".env"

if [ -f "$ENV_PATH" ]; then
    # Don't replace the URLs in the .env file, but check for the right variable names
    ENV_PIKACHU=$(grep "PIKACHU_API_URL" "$ENV_PATH" || true)
    ENV_CHARMANDER=$(grep "CHARMANDER_API_URL" "$ENV_PATH" || true)
    
    if [ -z "$ENV_PIKACHU" ]; then
        echo -e "${RED}Missing PIKACHU_API_URL in .env${NC}"
        echo -e "${YELLOW}Ensure proper provider variables are set in .env${NC}"
    else
        echo -e "${GREEN}Found PIKACHU_API_URL in .env${NC}"
    fi
    
    # Check for old TARGET_URL
    OLD_TARGET=$(grep "TARGET_URL" "$ENV_PATH" || true)
    if [ -n "$OLD_TARGET" ]; then
        echo -e "${RED}Found deprecated TARGET_URL in .env. Please use PIKACHU_API_URL or CHARMANDER_API_URL instead.${NC}"
    fi
else
    echo -e "${RED}.env not found!${NC}"
fi

echo -e "\n${BLUE}Step 4: Updating .gitignore to exclude provider files...${NC}"
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

echo -e "\n${BLUE}Step 5: Checking source code for TARGET_URL references...${NC}"
TARGET_RESULTS=$(grep -r "TARGET_URL" $EXCLUDE_PATTERN --include="*.rs" --include="*.md" \
    --include="*.toml" --include="*.json" --include="*.js" --include="*.yml" \
    --include="Dockerfile*" --include="*.sh" . || true)

if [ -n "$TARGET_RESULTS" ]; then
    echo -e "${RED}Found TARGET_URL references that should be updated to PIKACHU_API_URL or CHARMANDER_API_URL:${NC}"
    echo "$TARGET_RESULTS"
else
    echo -e "${GREEN}No TARGET_URL references found.${NC}"
fi

echo -e "\n${BLUE}Step 6: Checking README.md for provider references...${NC}"
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

echo -e "\n${BLUE}Step 7: Final summary...${NC}"
if [ $FOUND_REFERENCES -eq 1 ]; then
    echo -e "${RED}Some provider references still exist in the codebase.${NC}"
    echo -e "${YELLOW}Please review and fix these manually.${NC}"
else
    echo -e "${GREEN}No provider references found in codebase.${NC}"
    echo -e "${GREEN}Provider security scrubbing completed successfully!${NC}"
fi

echo -e "\n${BLUE}Provider scrubbing procedure complete!${NC}"
echo -e "Remember to review changes before committing."