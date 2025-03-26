# Simplified base image with wasm tools
FROM rust:1.84-slim AS base
RUN apt-get update && \
    apt-get install -y pkg-config libssl-dev python3 python3-pip lsof sed nodejs npm \
    curl net-tools netcat-openbsd procps iproute2 iputils-ping && \
    rustup target add wasm32-unknown-unknown && \
    cargo install wasm-bindgen-cli && \
    rm -rf /var/lib/apt/lists/*

# Set environment variable to ensure proper MIME type handling
ENV MIMETYPES_FORCE_PYTHON_WASM=true

# Builder stage - build the WebAssembly app directly
FROM base AS builder
WORKDIR /app
# Copy models and tobira code
COPY pokeball/ /app/pokeball/
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
# Generate bootstrap.js for WebAssembly initialization with better error handling and file name mapping
RUN echo 'console.log("Bootstrap initializing WASM...");' > dist/bootstrap.js && \
    echo 'try {' >> dist/bootstrap.js && \
    echo '    import("./ihoje-tobira.js")' >> dist/bootstrap.js && \
    echo '        .then(module => {' >> dist/bootstrap.js && \
    echo '            console.log("WASM module loaded, initializing...");' >> dist/bootstrap.js && \
    echo '            return module.default();' >> dist/bootstrap.js && \
    echo '        })' >> dist/bootstrap.js && \
    echo '        .then(wasm => {' >> dist/bootstrap.js && \
    echo '            console.log("WASM initialized successfully");' >> dist/bootstrap.js && \
    echo '            // Check if we can enable mock data' >> dist/bootstrap.js && \
    echo '            if (typeof wasm.enable_mock_data === "function") {' >> dist/bootstrap.js && \
    echo '                wasm.enable_mock_data();' >> dist/bootstrap.js && \
    echo '                console.log("✅ Mock data enabled");' >> dist/bootstrap.js && \
    echo '            }' >> dist/bootstrap.js && \
    echo '        })' >> dist/bootstrap.js && \
    echo '        .catch(error => {' >> dist/bootstrap.js && \
    echo '            console.error("Failed to initialize WASM:", error);' >> dist/bootstrap.js && \
    echo '            // Show error on page' >> dist/bootstrap.js && \
    echo '            document.body.innerHTML += `' >> dist/bootstrap.js && \
    echo '                <div style="background: #ffeeee; border: 1px solid #ff0000; padding: 20px; margin: 20px; border-radius: 5px;">' >> dist/bootstrap.js && \
    echo '                    <h3>WebAssembly Error</h3>' >> dist/bootstrap.js && \
    echo '                    <p>${error.message || error}</p>' >> dist/bootstrap.js && \
    echo '                </div>' >> dist/bootstrap.js && \
    echo '            `;' >> dist/bootstrap.js && \
    echo '        });' >> dist/bootstrap.js && \
    echo '} catch (e) {' >> dist/bootstrap.js && \
    echo '    console.error("Error in WASM bootstrap process:", e);' >> dist/bootstrap.js && \
    echo '}' >> dist/bootstrap.js
# Create env.js with Supabase config and WASM MIME type fix
RUN echo 'window.ihoje_env = { ' > dist/env.js && \
    echo '  IHOJE_ENVIRONMENT: "development", ' >> dist/env.js && \
    echo '  IHOJE_API_URL: "http://localhost:8080/api", ' >> dist/env.js && \
    echo '  IHOJE_USE_MOCK_DATA: "true",' >> dist/env.js && \
    echo '  IHOJE_SUPABASE_URL: "https://ihoje-supabase.supabase.co",' >> dist/env.js && \
    echo '  IHOJE_SUPABASE_ANON_KEY: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRlc3QiLCJyb2xlIjoiYW5vbiIsImlhdCI6MTY3MDc2OTQ5OSwiZXhwIjoxOTg2MzQ1NDk5fQ.example_test_key"' >> dist/env.js && \
    echo '}; ' >> dist/env.js && \
    echo 'window.get_env_var = function(name) { ' >> dist/env.js && \
    echo '  return (window.ihoje_env && window.ihoje_env[name]) || ""; ' >> dist/env.js && \
    echo '}; ' >> dist/env.js && \
    echo '' >> dist/env.js && \
    echo '// Add WebAssembly MIME type fix' >> dist/env.js && \
    echo 'console.log("Adding WebAssembly MIME type fix"); ' >> dist/env.js && \
    echo 'const originalFetch = window.fetch; ' >> dist/env.js && \
    echo 'window.fetch = function(input, init) { ' >> dist/env.js && \
    echo '  // Handle WASM file name mismatch' >> dist/env.js && \
    echo '  if (typeof input === "string" && input.endsWith("ihoje_frontend_bg.wasm")) {' >> dist/env.js && \
    echo '    console.log("Fixing WASM file name reference:", input);' >> dist/env.js && \
    echo '    input = input.replace("ihoje_frontend_bg.wasm", "ihoje-tobira_bg.wasm");' >> dist/env.js && \
    echo '  }' >> dist/env.js && \
    echo '  ' >> dist/env.js && \
    echo '  return originalFetch(input, init).then(response => { ' >> dist/env.js && \
    echo '    if (typeof input === "string" && input.endsWith(".wasm")) { ' >> dist/env.js && \
    echo '      return response.clone().blob().then(blob => { ' >> dist/env.js && \
    echo '        return new Response(blob, { ' >> dist/env.js && \
    echo '          status: response.status, ' >> dist/env.js && \
    echo '          statusText: response.statusText, ' >> dist/env.js && \
    echo '          headers: new Headers({ "Content-Type": "application/wasm" }) ' >> dist/env.js && \
    echo '        }); ' >> dist/env.js && \
    echo '      }); ' >> dist/env.js && \
    echo '    } ' >> dist/env.js && \
    echo '    return response; ' >> dist/env.js && \
    echo '  }); ' >> dist/env.js && \
    echo '};' >> dist/env.js
# Update index.html to include bootstrap.js and Supabase client with SRI
RUN sed -i 's|</body>|<script type="module" src="./bootstrap.js"></script><script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.38.4/dist/umd/supabase.min.js" integrity="sha384-SatV4JcpRktkhj9NnfYS8mBNBEiI+mTgYX/yMLvOpbnFhUfLVQJeXBFsXXvnJTmz" crossorigin="anonymous"></script></body>|' dist/index.html

# Development stage
FROM env-setup AS dev
WORKDIR /app/tobira
# Fix timestamp issue by setting a current date
RUN date > /build_time.txt
# Use port 8080 as per docker-restart.sh mapping
EXPOSE 8080

# Copy the enhanced security server
COPY tobira/spa_server.py /app/

# Make log directories 
RUN mkdir -p /app/logs

# Create directories for authentication
RUN mkdir -p /app/tobira/dist/auth

# Set development environment variable if not already set
ENV IHOJE_ENVIRONMENT=development

# Add a debug script
RUN echo '#!/bin/bash\nps -ef\nnetstat -tuln\ncurl -v http://localhost:8080\necho "Server logs:"\ncat /app/logs/*.log 2>/dev/null || echo "No log files found"' > /app/debug.sh && \
    chmod +x /app/debug.sh

# Create a health check script
RUN echo '#!/bin/bash\n\
response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)\n\
if [ "$response" = "200" ]; then\n\
    exit 0\n\
else\n\
    echo "Health check failed with status: $response"\n\
    exit 1\n\
fi' > /app/health-check.sh && chmod +x /app/health-check.sh

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV TOBIRA_ENV=development
ENV MIMETYPES_FORCE_PYTHON_WASM=true

# Use the health check
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 \
  CMD ["/app/health-check.sh"]

# Run the server with security enhancements - matching exposed port 8080
CMD ["python3", "/app/spa_server.py", "8080", "/app/tobira/dist"]

# Mock data stage
FROM env-setup AS mock
WORKDIR /app/tobira
# Update index.html to include Supabase client with SRI
RUN sed -i 's|</body>|<script src="https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.38.4/dist/umd/supabase.min.js" integrity="sha384-SatV4JcpRktkhj9NnfYS8mBNBEiI+mTgYX/yMLvOpbnFhUfLVQJeXBFsXXvnJTmz" crossorigin="anonymous"></script></body>|' dist/index.html
# Enable mock data mode with improved error handling
RUN echo 'console.log("Bootstrap initializing WASM with mock data mode...");' > dist/bootstrap.js && \
    echo 'try {' >> dist/bootstrap.js && \
    echo '    import("./ihoje-tobira.js")' >> dist/bootstrap.js && \
    echo '        .then(module => {' >> dist/bootstrap.js && \
    echo '            console.log("WASM module loaded, initializing with mock data...");' >> dist/bootstrap.js && \
    echo '            return module.default();' >> dist/bootstrap.js && \
    echo '        })' >> dist/bootstrap.js && \
    echo '        .then(wasm => {' >> dist/bootstrap.js && \
    echo '            console.log("WASM initialized successfully");' >> dist/bootstrap.js && \
    echo '            // Enable mock data' >> dist/bootstrap.js && \
    echo '            if (typeof wasm.enable_mock_data === "function") {' >> dist/bootstrap.js && \
    echo '                wasm.enable_mock_data();' >> dist/bootstrap.js && \
    echo '                console.log("✅ Mock data mode enabled");' >> dist/bootstrap.js && \
    echo '            } else {' >> dist/bootstrap.js && \
    echo '                console.error("❌ enable_mock_data function not found!");' >> dist/bootstrap.js && \
    echo '            }' >> dist/bootstrap.js && \
    echo '        })' >> dist/bootstrap.js && \
    echo '        .catch(error => {' >> dist/bootstrap.js && \
    echo '            console.error("Failed to initialize WASM:", error);' >> dist/bootstrap.js && \
    echo '            // Show error on page' >> dist/bootstrap.js && \
    echo '            document.body.innerHTML += `' >> dist/bootstrap.js && \
    echo '                <div style="background: #ffeeee; border: 1px solid #ff0000; padding: 20px; margin: 20px; border-radius: 5px;">' >> dist/bootstrap.js && \
    echo '                    <h3>WebAssembly Error</h3>' >> dist/bootstrap.js && \
    echo '                    <p>${error.message || error}</p>' >> dist/bootstrap.js && \
    echo '                </div>' >> dist/bootstrap.js && \
    echo '            `;' >> dist/bootstrap.js && \
    echo '        });' >> dist/bootstrap.js && \
    echo '} catch (e) {' >> dist/bootstrap.js && \
    echo '    console.error("Error in WASM bootstrap process:", e);' >> dist/bootstrap.js && \
    echo '}' >> dist/bootstrap.js
# Fix timestamp issue by setting a current date
RUN date > /build_time.txt
# Use port 8080 as per docker-restart.sh mapping
EXPOSE 8080

# Copy the enhanced security server
COPY tobira/spa_server.py /app/

# Make log directories 
RUN mkdir -p /app/logs

# Create directories for authentication
RUN mkdir -p /app/tobira/dist/auth

# Set development environment variable if not already set
ENV IHOJE_ENVIRONMENT=development

# Add a debug script
RUN echo '#!/bin/bash\nps -ef\nnetstat -tuln\ncurl -v http://localhost:8080\necho "Server logs:"\ncat /app/logs/*.log 2>/dev/null || echo "No log files found"' > /app/debug.sh && \
    chmod +x /app/debug.sh

# Run the server with security enhancements - matching exposed port 8080
CMD ["python3", "/app/spa_server.py", "8080", "/app/tobira/dist"]

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