#!/usr/bin/env bash
set -e

# Script to perform security checks on the tobira code
echo "Running security scan on tobira code..."

# Check for hardcoded API URLs
echo "Checking for hardcoded API URLs..."
if grep -r --include="*.rs" --include="*.toml" "http://" . | grep -v "localhost"; then
  echo "⚠️ WARNING: Hardcoded non-localhost HTTP URLs found in code."
  echo "These should be replaced with configuration values."
fi

# Check for dependencies with security issues
echo "Checking dependencies for security issues..."
cargo audit

# Check for outdated dependencies
echo "Checking for outdated dependencies..."
cargo outdated

# Code quality checks with clippy
echo "Running clippy for code quality checks..."
cargo clippy -- -D warnings

# Ensure no sensitive data is checked in
echo "Checking for potentially sensitive files..."
SENSITIVE_PATTERNS=("\.env$" "token" "key" "secret" "password" "credential")

for pattern in "${SENSITIVE_PATTERNS[@]}"; do
  echo "Checking for pattern: $pattern"
  results=$(grep -r -l -i "$pattern" --include="*.rs" --include="*.toml" . || true)
  if [ -n "$results" ]; then
    echo "⚠️ Potential sensitive data found in files containing pattern '$pattern':"
    echo "$results"
    echo "Please review these files to ensure no credentials are hardcoded."
  fi
done

# Check for proper CORS and security headers
echo "Checking for proper security headers in HTML..."
HEADERS=("Content-Security-Policy" "X-Content-Type-Options" "Strict-Transport-Security")

for header in "${HEADERS[@]}"; do
  if ! grep -q "$header" index.html; then
    echo "⚠️ WARNING: Security header '$header' not found in index.html"
  else
    echo "✅ Security header '$header' found."
  fi
done

echo "Security scan complete"