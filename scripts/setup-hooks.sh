#!/bin/bash
# Script to set up basic pre-commit hooks

echo "Setting up pre-commit hooks..."
if ! command -v pre-commit &> /dev/null; then
    echo "Installing pre-commit..."
    pip install pre-commit
fi
pre-commit install

# Install custom provider leak check hook if exists
if [ -f ".github/hooks/pre-commit" ]; then
    mkdir -p .git/hooks
    cp .github/hooks/pre-commit .git/hooks/
    chmod +x .git/hooks/pre-commit
    echo "Provider leak check hook installed"
fi

echo "Pre-commit hooks installed successfully"