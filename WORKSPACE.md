# iHoje Rust Workspace

This project has been reorganized as a Rust workspace to improve dependency management, build efficiency, and project organization.

## Workspace Structure

The workspace consists of three main crates:

1. **ihoje_core** - The main application code
   - Contains the event scraper, database integrations, and API server
   - Located in `/ihoje_core`

2. **ihoje_models** - Shared data models
   - Contains models used by both core and frontend
   - Located in `/ihoje_models`

3. **tobira** - WebAssembly frontend
   - Contains the Yew-based frontend application
   - Located in `/tobira`

## Benefits of Workspace Structure

- **Single Cargo.lock file** - Ensures consistent dependency versions across all crates
- **Shared build artifacts** - Faster compilation through shared build directory
- **Workspace dependencies** - Common dependencies can be specified at the workspace level
- **Modular organization** - Clear separation of concerns between components
- **Simplified CI/CD** - Build, test, and deploy workflows are more straightforward

## Common Commands

### Building

```bash
# Build everything
cargo build --workspace

# Build specific crates
cargo build -p ihoje_core
cargo build -p ihoje_models
cargo build -p ihoje_tobira

# Build with Just
just build        # Build all
just build-core   # Build core only
just build-tobira # Build Tobira only
```

### Running

```bash
# Run the main application
cargo run -p ihoje_core

# Run with Just
just run          # Run core application
just run-api      # Run API server
just run-city RJ  # Run with specific city
```

### Testing

```bash
# Test everything
cargo test --workspace

# Test specific crates
cargo test -p ihoje_core

# Test with Just
just test         # Test all
just test-core    # Test core only
```

## Best Practices for This Workspace

1. **Keep models crate small and focused** - Only shared data structures and simple validation logic
2. **Cross-crate dependencies** - Use the explicit path syntax: `ihoje_models = { path = "../ihoje_models" }`
3. **Workspace dependencies** - For common dependencies, use: `serde = { workspace = true }`
4. **Features** - Use feature flags for optional functionality across crates
5. **Documentation** - Document interfaces between crates clearly