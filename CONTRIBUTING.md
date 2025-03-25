# Contributing to Rust Event Scraper

Thank you for your interest in contributing to this project! Here are some guidelines to help you get started.

## Provider Reference Guidelines

This project uses a provider system with codenames inspired by Pokémon:

- **Pikachu Provider**: The main events provider
- **Charmander Provider**: The secondary provider

### Site Provider Name Security

To maintain provider neutrality and avoid exposing site names in the repository, follow these rules:

1. **Never commit site-specific URLs** in source code - use environment variables only
2. **Use codenames** (Pikachu, Charmander) instead of provider names in all code and comments
3. **The .env file** is the ONLY place where actual provider URLs should exist (not versioned)
4. **Check for leaks** before committing (see procedure below)

## Code of Conduct

This project adheres to the [Rust Code of Conduct](https://www.rust-lang.org/policies/code-of-conduct). By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

- Check if the bug has already been reported
- Use the bug report template
- Include as much detail as possible
- Include steps to reproduce

### Suggesting Enhancements

- Use the feature request template
- Describe the enhancement in detail
- Explain why this would be useful

### Pull Requests

1. Fork the repository
2. Create a new branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run the tests (`just test`)
5. Run code quality checks (`just check-all`)
6. Commit your changes (`git commit -m 'Add some amazing feature'`)
7. Push to the branch (`git push origin feature/amazing-feature`)
8. Open a Pull Request

## Development Environment Setup

1. Install Rust (1.60+)
2. Install the Just command runner
3. Clone the repository
4. Setup environment variables:
   ```bash
   just init-env
   # Edit .env with your API keys and provider URLs
   ```
5. Install pre-commit hooks:
   ```bash
   just setup-hooks
   ```
6. Update .gitignore if needed:
   ```bash
   # Ensure provider-specific files are ignored
   echo "*provider-name*" >> .gitignore
   ```

## Code Style

This project follows the Rust style guidelines and uses:

- `rustfmt` for code formatting
- `clippy` for linting
- Documentation comments for public APIs

Run code quality checks with:

```bash
just check-all
```

## Testing

The project includes:

- Unit tests
- Integration tests
- Blackbox tests for event scraping

Run tests with:

```bash
just test
# or for specific tests:
just test-events
```

## Documentation

Please document your code:

- Add doc comments for public APIs
- Update README.md for user-facing changes
- Add comments for complex algorithms
- Use codenames instead of actual provider names

## Provider Name Leak Prevention

Before committing, check for provider name leaks:

```bash
# Check for provider name instances
grep -r "provider-name" --include="*.rs" --include="*.md" --include="*.toml" .

# Ensure .env.example doesn't contain real provider URLs
grep -r "provider-domain.com" .env.example

# Only .env should contain actual provider URLs (not versioned)
```

## Commit Messages

Follow these guidelines for commit messages:

- Use the present tense ("Add feature" not "Added feature")
- Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
- Limit the first line to 72 characters
- Reference issues and pull requests after the first line

## Licensing

By contributing, you agree that your contributions will be licensed under the project's MIT License.