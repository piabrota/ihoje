# Makefile for compatibility with standard build tools
# Most commands delegate to the justfile, which is the preferred way to run commands

# Default target
.PHONY: default
default:
	@just

# Build the application
.PHONY: build
build:
	@just build

# Run the application
.PHONY: run
run:
	@just run

# Run with a specific city
.PHONY: run-city
run-city:
	@just run-city $(CITY)

# Clean build artifacts
.PHONY: clean
clean:
	@just clean

# Run tests
.PHONY: test
test:
	@just test

# Format code
.PHONY: fmt
fmt:
	@just fmt

# Run linter
.PHONY: lint
lint:
	@just lint

# Run all checks
.PHONY: check
check:
	@just check-all

# Install pre-commit hooks
.PHONY: setup-hooks
setup-hooks:
	@just setup-hooks

# Help
.PHONY: help
help:
	@echo "This Makefile delegates to the justfile for better command organization."
	@echo "It's provided for compatibility with standard build tools."
	@echo "For the full list of available commands, run 'just' with no arguments."
	@just --list