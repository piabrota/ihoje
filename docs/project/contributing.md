# Contributing to iHoje

Thank you for your interest in contributing to iHoje! This document provides guidelines for contributing to the project.

## Code of Conduct

Please be respectful and considerate of others when contributing to this project. We value a positive and inclusive community.

## Getting Started

### Prerequisites

- Rust and Cargo (latest stable version)
- Node.js and npm (for some scripts)
- PostgreSQL (for database functionality)
- Justfile (for running project commands)

### Setup

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/ihoje.git`
3. Install dependencies: `cargo build`
4. Setup the development environment: `just setup-dev`

## Development Workflow

### Branches

- `main`: The main development branch
- Create feature branches named `feature/your-feature`
- Create bugfix branches named `fix/bug-description`

### Commits

- Use meaningful commit messages
- Reference issue numbers when applicable
- Keep commits focused and atomic

### Testing

- Write tests for new features and bug fixes
- Run tests before submitting: `just test`
- See [Testing Guide](testing.md) for more details

### Pull Requests

1. Create a pull request to the `main` branch
2. Provide a clear description of the changes
3. Reference any related issues
4. Make sure CI checks pass
5. Wait for a maintainer review

## Code Guidelines

### Rust Style

- Follow the standard Rust style guide
- Run `rustfmt` before committing: `just fmt`
- Run `clippy` to check for common issues: `just lint`
- Keep files under 100 lines when possible

### Documentation

- Document all public functions and structs
- Add inline comments for complex logic
- Update README.md when adding new features
- Use consistent documentation style

### Error Handling

- Use `anyhow::Result` for fallible functions
- Provide context with `.context()` or `.with_context()`
- Avoid panics in production code

## Provider Guidelines

### Adding a New Provider

1. Create a new file in `src/providers/`
2. Implement the `Provider` trait
3. Add the provider to the module in `src/providers/mod.rs`
4. Add tests for the provider
5. Document the provider

### Provider Security

- Use codenames for all providers (pikachu, charmander, etc.)
- Never include provider names directly in the code
- Run `just scrub-providers` to check for leaks
- Follow rate limiting best practices

## Justfile Commands

The project uses Justfile for common tasks. Here are the most useful commands:

```
just build                # Build the project
just test                 # Run all tests
just lint                 # Run clippy linting
just fmt                  # Format code with rustfmt
just run                  # Run the application
just add-provider NAME    # Create a new provider template
```

See the full Justfile for more commands.

## Communication

- Use GitHub Issues for bug reports and feature requests
- Use Pull Requests for code contributions
- Be clear and respectful in all communications

## License

By contributing to this project, you agree that your contributions will be licensed under the project's license.