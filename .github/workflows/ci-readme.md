# CI/CD Workflows

This directory contains GitHub Actions workflows for CI/CD automation of the iHoje project.

## Component-Specific Workflows

### 1. Sharingan CI (`sharingan-ci.yml`)

**Purpose**: Handles CI/CD for the Sharingan event scraper component.

**Triggers**:
- Pushes to `main` that change `sharingan/**`, `pokeball/**`, or Cargo files
- Pull requests to `main` that change the same paths
- Manual workflow dispatch

**Jobs**:
- `build-and-test`: Lints, builds, and tests the Sharingan component
- `deploy`: Builds release binaries and Docker images (only on main branch)

### 2. Tobira CI (`tobira-ci.yml`)

**Purpose**: Handles CI/CD for the Tobira frontend web application.

**Triggers**:
- Pushes to `main` that change `tobira/**`, `pokeball/**`, `sharingan/**`, or Cargo files
- Pull requests to `main` that change the same paths
- Manual workflow dispatch

**Jobs**:
- `build-and-test`: Lints, builds (with Trunk), and tests the WebAssembly frontend
- `deploy`: Deploys the frontend to Docker and optionally to GitHub Pages

### 3. Gugu CI (`gugu-ci.yml`)

**Purpose**: Handles CI/CD for the Gugu infrastructure component.

**Triggers**:
- Pushes to `main` that change `gugu/**`
- Pull requests to `main` that change `gugu/**`
- Manual workflow dispatch

**Jobs**:
- `build-and-test`: Compiles and tests the Scala application
- `preview-infrastructure`: Runs a Pulumi preview of infrastructure changes (on PRs)
- `deploy`: Deploys infrastructure changes to production (only on main branch)

## General Workflows

### Rust CI Master (`rust.yml`)

**Purpose**: Handles CI for common Rust code that doesn't belong to specific components.

**Triggers**:
- Pushes to `main` (excluding component-specific directories)
- Pull requests to `main` (excluding component-specific directories)
- Manual workflow dispatch

**Jobs**:
- `build`: Lints, builds, and tests the Rust code
- `workflow-overview`: Provides an overview of all available workflows

## Setting Up Required Secrets

Some workflows require GitHub secrets to be set up:

1. `PULUMI_ACCESS_TOKEN`: For Pulumi infrastructure operations
2. `GOOGLE_APPLICATION_CREDENTIALS`: For GCP access from Gugu

Set these up in your repository settings under Settings > Secrets and variables > Actions.

## Local Testing

You can test these workflows locally using [act](https://github.com/nektos/act):

```bash
# Test the Sharingan workflow
act -j build-and-test -W .github/workflows/sharingan-ci.yml

# Test the Tobira workflow
act -j build-and-test -W .github/workflows/tobira-ci.yml

# Test the Gugu workflow
act -j build-and-test -W .github/workflows/gugu-ci.yml
```