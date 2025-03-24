# iHoje Dependency Updates

## Rust Updates

### Core Libraries
- Updated tokio-util from 0.7.0 to 0.7.10
- Updated scraper from 0.17.1 to 0.18.1
- Updated serde from 1.0.193 to 1.0.197
- Updated serde_json from 1.0.108 to 1.0.114
- Updated log from 0.4 to 0.4.20
- Updated simplelog from 0.12 to 0.12.1
- Updated anyhow from 1.0.80 to 1.0.81
- Updated chrono from 0.4.34 to 0.4.35
- Updated uuid from 1.6.1 to 1.7.0
- Updated rusqlite from 0.30.0 to 0.31.0
- Updated tokio-postgres from 0.7 to 0.7.10
- Updated postgres-types from 0.2 to 0.2.6
- Updated clap from 4.5.2 to 4.5.3

### New Libraries Added
- axum 0.7.4 - Modern web framework for building APIs
- reqwest 0.12.0 - HTTP client for making requests
- language-tags 0.3.2 - Language detection and processing
- tracing 0.1.40 - Improved logging and tracing infrastructure
- polars 0.38.1 - Fast DataFrame library for efficient data processing

### Toolchain Update
- Added rust-toolchain.toml to specifically target Rust 1.84.0

## Python Updates

### mangekyou-mcp
- Updated fastapi from 0.103.1 to 0.114.0
- Updated uvicorn from 0.23.2 to 0.27.1
- Updated pydantic from 2.4.2 to 2.6.4
- Updated httpx from 0.25.0 to 0.27.0
- Updated python-dotenv from 1.0.0 to 1.0.1

### Added New Python Libraries
- langdetect 1.0.9 - Language detection for Python
- tqdm 4.66.2 - Fast, extensible progress bar
- pandera 0.18.0 - Data validation and testing
- nltk 3.8.1 - Natural language toolkit
- langchain 0.2.10 - Framework for LLM applications
- openai 1.32.0 - Official OpenAI API client

## CI/CD Improvements

### GitHub Actions Workflows
- Added .github/workflows/rust.yml for Rust CI pipeline
- Added .github/workflows/python.yml for Python CI pipeline

### Dependency Management
- Added scripts/update-dependencies.sh to easily update all dependencies
- Added 'update-deps' and 'outdated' recipes to the justfile

## Benefits of These Updates

1. **Performance Improvements**:
   - Polars provides faster data processing than pandas
   - Updated Rust libraries contain performance optimizations

2. **Security Enhancements**:
   - Updated dependencies have the latest security patches

3. **New Features**:
   - Modern async-first web framework with axum
   - Better error handling with latest anyhow
   - Improved language detection capabilities
   - LLM integration possibilities with langchain and OpenAI

4. **Developer Experience**:
   - Improved CI/CD workflow
   - Easier dependency management
   - Better async code in Rust with latest tokio ecosystem

5. **Cutting-Edge Functionality**:
   - Latest Rust 1.84 features available
   - Modern Python libraries for AI/ML integration

## Next Steps

1. Consider migrating to more modern async patterns using the latest Rust features
2. Explore integration with LLMs using the new Python libraries
3. Set up regular dependency updates using the new scripts
4. Add benchmarks to measure performance improvements