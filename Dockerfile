# Base image with cargo-chef and sccache
FROM rust:1.84-slim AS base
RUN apt-get update && \
    apt-get install -y pkg-config libssl-dev && \
    cargo install cargo-chef --version ^0.1 && \
    cargo install sccache --version ^0.7 && \
    rm -rf /var/lib/apt/lists/*
ENV RUSTC_WRAPPER=sccache SCCACHE_DIR=/sccache

# Planner stage - create the recipe
FROM base AS planner
WORKDIR /app
COPY . .
# Create the dependency recipe
RUN cargo chef prepare --recipe-path recipe.json

# Builder stage - build dependencies and app
FROM base AS builder
WORKDIR /app
# Build dependencies
COPY --from=planner /app/recipe.json recipe.json
# Use BuildKit cache if available, fallback to standard build
RUN --mount=type=cache,target=/usr/local/cargo/registry,sharing=locked \
    --mount=type=cache,target=$SCCACHE_DIR,sharing=locked \
    cargo chef cook --release --recipe-path recipe.json || \
    cargo chef cook --release --recipe-path recipe.json
# Build application
COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry,sharing=locked \
    --mount=type=cache,target=$SCCACHE_DIR,sharing=locked \
    cargo build --release || \
    cargo build --release

# Runtime stage - minimal image with just what's needed
FROM debian:12-slim AS runtime
RUN apt-get update && \
    apt-get install -y ca-certificates && \
    rm -rf /var/lib/apt/lists/*
WORKDIR /app
# Copy binary from builder stage - using correct binary name
COPY --from=builder /app/target/release/rust-scraper /app/rust-scraper
# Create output directories
RUN mkdir -p /app/tests /app/output
# Set environment variables
ENV RUST_LOG=info
# Command to run
ENTRYPOINT ["/app/rust-scraper"]