# Dependency Update Guide

## Overview

This document provides guidance on updating dependencies in the iHoje project, which includes Rust crates and Node.js packages.

## Scheduled Updates

Dependency updates should be performed according to this schedule:

- **Security updates**: Immediately when available
- **Major version updates**: After thorough evaluation
- **Minor version updates**: Monthly
- **Patch version updates**: Bi-weekly

## Update Process

### Rust Dependencies

1. **Check for updates**:
   ```bash
   just check-updates
   ```

2. **Update dependencies**:
   ```bash
   just update-deps
   ```
   This uses the update script that handles both Cargo.toml files and ensures compatibility.

3. **Test after updates**:
   ```bash
   just test-all
   ```

4. **Review changes**:
   ```bash
   git diff Cargo.toml ihoje_models/Cargo.toml
   ```

### Node.js Dependencies

Some utility scripts use Node.js packages. To update them:

1. **Check for updates**:
   ```bash
   npm outdated
   ```

2. **Update packages**:
   ```bash
   npm update
   ```

3. **For major version updates**:
   ```bash
   npm install package@latest
   ```

## Version Pinning Strategy

### Rust Crates

- **Core libraries**: Pin to specific versions (e.g., `reqwest = "0.11.14"`) to ensure stability
- **Utility libraries**: Use compatible version ranges (e.g., `anyhow = "~1.0.68"`) to allow patch updates
- **Development dependencies**: Use more relaxed versioning (e.g., `pretty_assertions = "^1.3.0"`) to get improvements

### Node.js Packages

- **All packages**: Pin to specific versions in package.json to ensure reproducible builds

## Handling Breaking Changes

1. **Read release notes** before applying major version updates
2. **Update one major dependency at a time** to isolate changes
3. **Check for deprecation warnings** and update code accordingly
4. **Create a dedicated branch** for significant dependency updates

## Testing Updates

After updating dependencies, run the full test suite:

```bash
just test-all
```

This includes:
- Unit tests
- Integration tests
- Building the WebAssembly frontend
- Running the backend with test data

## Rollback Procedure

If problems occur after dependency updates:

1. Revert the Cargo.toml and package.json changes:
   ```bash
   git checkout -- Cargo.toml ihoje_models/Cargo.toml package.json
   ```

2. Clean build artifacts:
   ```bash
   just clean-all
   ```

3. Rebuild with previous dependencies:
   ```bash
   just build-all
   ```

## Documentation

When updating dependencies with significant changes:

1. Update this document if the update process changes
2. Note any API changes in code comments
3. Update README.md if user-facing features are affected

## Specific Dependency Notes

### reqwest

The HTTP client library used for scraping:
- Check TLS backend compatibility when updating
- Test with all providers after updates

### yew (Frontend)

The WebAssembly framework:
- Major version updates often require component API changes
- Check for new hook patterns and component lifecycle changes

### sqlx (Database)

The database library:
- Test all database queries after updates
- Check for macro syntax changes

## Dependency Update Scripts

The project includes scripts to help with dependency management:

- `scripts/update-dependencies.sh`: Automated dependency update script
- `scripts/check-versions.sh`: Reports outdated dependencies

These scripts can be run via the justfile commands mentioned above.