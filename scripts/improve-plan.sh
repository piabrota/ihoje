#!/usr/bin/env bash
# improve-plan.sh - Creates a research-based improvement plan without executing changes

# Check if arguments were provided
if [ $# -lt 2 ]; then
  echo "Usage: $0 <task-name> <description>"
  exit 1
fi

TASK="$1"
DESCRIPTION="$2"

echo "Creating improvement plan for: ${TASK}" 
echo "- Description: ${DESCRIPTION}"

# Create plan output file
cd "$(dirname "$0")/.." || exit 1
PLAN_FILE="reports/plans/${TASK}_implementation_plan.md"
mkdir -p "reports/plans"

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

# Create plan header
echo "# ${TASK} Implementation Plan" > "${PLAN_FILE}"
echo "" >> "${PLAN_FILE}"
echo "## Overview" >> "${PLAN_FILE}"
echo "${DESCRIPTION}" >> "${PLAN_FILE}"
echo "" >> "${PLAN_FILE}"
echo "## Research Sources" >> "${PLAN_FILE}"
echo "" >> "${PLAN_FILE}"

# Use just and claude-minimal for simple interface
just claude-minimal "$(cat ${PROMPT_FILE})" > "${PLAN_FILE}.tmp"

# Extract claude's response and append to plan file
sed '1,/^$/d' "${PLAN_FILE}.tmp" >> "${PLAN_FILE}"
rm "${PROMPT_FILE}" "${PLAN_FILE}.tmp"

echo "✅ Plan created: ${PLAN_FILE}"