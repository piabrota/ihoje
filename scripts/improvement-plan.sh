#!/usr/bin/env bash
# improvement-plan.sh - Creates a research-based improvement plan without executing changes

# Check if arguments were provided
if [ $# -lt 2 ]; then
  echo "Usage: $0 <task-name> <description>"
  exit 1
fi

TASK="$1"
DESCRIPTION="$2"

echo "Creating improvement plan for: ${TASK}" 
echo "- Description: ${DESCRIPTION}"

# Add task to tracking system
cd "$(dirname "$0")/.." || exit 1
echo "Adding task to tracking system..."
pwd
./justfile task add "${TASK}" "${DESCRIPTION}" || echo "Warning: Could not add task"

# Create plan output file
PLAN_FILE="reports/plans/${TASK}_implementation_plan.md"
mkdir -p "reports/plans"

# Create plan header
echo "# ${TASK} Implementation Plan" > "${PLAN_FILE}"
echo "" >> "${PLAN_FILE}"
echo "## Overview" >> "${PLAN_FILE}"
echo "${DESCRIPTION}" >> "${PLAN_FILE}"
echo "" >> "${PLAN_FILE}"
echo "## Research Sources" >> "${PLAN_FILE}"

# Create prompt file
PROMPT_FILE="reports/plans/prompt_${TASK}.md"
{
  echo "# Task: ${TASK}"
  echo "# Description: ${DESCRIPTION}"
  echo ""
  echo "Create a detailed implementation plan for '${TASK}'. Focus on:"
  echo "1. Researching best practices from GitHub/Medium/Stack Overflow/Reddit"
  echo "2. Creating a structured step-by-step plan"
  echo "3. Identifying potential challenges"
  echo "4. Proposing specific improvements"
  echo ""
  echo "DO NOT execute any code changes, only create the planning document."
  echo "All output should be in markdown format."
} > "${PROMPT_FILE}"

# Launch Claude with research context but don't execute changes
(cat docs/claude/core/bootstrap.md docs/claude/core/guidelines.md "${PROMPT_FILE}") | claude code > "${PLAN_FILE}.tmp"

# Extract claude's response and append to plan file
sed '1,/^$/d' "${PLAN_FILE}.tmp" >> "${PLAN_FILE}"
rm "${PLAN_FILE}.tmp"
rm "${PROMPT_FILE}"

echo "✅ Plan created: ${PLAN_FILE}"
echo "Run 'just task-status' to see your tasks"