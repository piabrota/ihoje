# Simplified base image with wasm tools
FROM rust:1.84-slim AS base
RUN apt-get update && \
    apt-get install -y pkg-config libssl-dev python3 python3-pip lsof sed nodejs npm && \
    rustup target add wasm32-unknown-unknown && \
    cargo install wasm-bindgen-cli && \
    rm -rf /var/lib/apt/lists/*

# Builder stage - build the WebAssembly app directly
FROM base AS builder
WORKDIR /app
# Copy models and tobira code
COPY ihoje_models/ /app/ihoje_models/
COPY tobira/ /app/tobira/

# Skip the WebAssembly build due to current issues
WORKDIR /app/tobira

# Use pre-packaged WASM files instead of building them
RUN mkdir -p ./dist
COPY tobira/pkg/* ./dist/
# Rename the files to match expected names
RUN mv ./dist/ihoje_frontend.js ./dist/ihoje-tobira.js || true
RUN mv ./dist/ihoje_frontend_bg.wasm ./dist/ihoje-tobira_bg.wasm || true

# Set up the web app
RUN cp index.html dist/ && \
    mkdir -p dist/static && \
    cp -r src/static/* dist/static/

# Add sample images for local usage
FROM builder AS image-setup
WORKDIR /app/tobira
# Create directories for static assets
RUN mkdir -p /app/tobira/src/static/images

# Copy static image files from the host
COPY tobira/src/static/images/* /app/tobira/src/static/images/

# Ensure there are fallback images if the copy fails
RUN echo "Verifying image files exist..."
RUN for i in {1..4}; do \
    if [ ! -s "/app/tobira/src/static/images/event$i.svg" ]; then \
        echo "Creating fallback image event$i.svg"; \
        echo '<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"800\" height=\"450\" viewBox=\"0 0 800 450\"><rect width=\"800\" height=\"450\" fill=\"#7000ff\" /><text x=\"400\" y=\"225\" font-family=\"Arial\" font-size=\"48\" text-anchor=\"middle\" fill=\"white\">Shinri no Tobira '$i'</text></svg>' > "/app/tobira/src/static/images/event$i.svg"; \
    fi; \
done
RUN ls -la /app/tobira/src/static/images/

# Create environment script
FROM image-setup AS env-setup
WORKDIR /app/tobira
# Generate bootstrap.js for WebAssembly initialization
RUN echo 'import init from "./ihoje-tobira.js"; init().catch(e => console.error("Error initializing WASM:", e));' > dist/bootstrap.js
# Create env.js with default values and WASM MIME type fix
RUN echo 'window.ihoje_env = { IHOJE_ENVIRONMENT: "development", IHOJE_API_URL: "http://localhost:8080/api", IHOJE_USE_MOCK_DATA: "false" }; window.get_env_var = function(name) { return (window.ihoje_env && window.ihoje_env[name]) || ""; }; console.log("Adding WebAssembly MIME type fix"); const originalFetch = window.fetch; window.fetch = function(input, init) { return originalFetch(input, init).then(response => { if (typeof input === "string" && input.endsWith(".wasm")) { return response.clone().blob().then(blob => { return new Response(blob, { status: response.status, statusText: response.statusText, headers: new Headers({ "Content-Type": "application/wasm" }) }); }); } return response; }); };' > dist/env.js
# Update index.html to include bootstrap.js
RUN sed -i 's|</body>|<script type="module" src="./bootstrap.js"></script></body>|' dist/index.html

# Development stage
FROM env-setup AS dev
WORKDIR /app/tobira
# Fix timestamp issue by setting a current date
RUN date > /build_time.txt
EXPOSE 8081

# Copy the custom SPA server file
COPY tobira/spa_server.py /app/

# Run the custom SPA server
CMD ["python3", "/app/spa_server.py", "8081", "/app/tobira/dist"]

# Mock data stage
FROM env-setup AS mock
WORKDIR /app/tobira
# Enable mock data mode
RUN echo 'import init from "./ihoje-tobira.js"; init().then(wasm => { if (typeof wasm.enable_mock_data === "function") { wasm.enable_mock_data(); console.log("✅ Mock data mode enabled"); } else { console.error("❌ enable_mock_data function not found!"); } }).catch(e => console.error("Error initializing WASM:", e));' > dist/bootstrap.js
# Fix timestamp issue by setting a current date
RUN date > /build_time.txt
EXPOSE 8081
# Copy the custom SPA server file
COPY tobira/spa_server.py /app/
# Run the custom SPA server
CMD ["python3", "/app/spa_server.py", "8081", "/app/tobira/dist"]

# Add semantic versioning tag output
ARG VERSION=0.1.0
ARG BUILD_DATE
LABEL version=${VERSION}
LABEL org.opencontainers.image.created=${BUILD_DATE}

# Output image information at the end of the build
RUN echo "=========================================="
RUN echo "Shinri no Tobira image built successfully:"
RUN echo "Image: ihoje-tobira:${VERSION} (also tagged as ihoje-tobira:latest)"
RUN echo "==========================================="