# justfile for Toji system doctor
# Toji is inspired by Toji Fushiguro from Jujutsu Kaisen

# Run the system doctor to check dependencies
toji-check *COMPONENT:
    @echo "Running Toji system doctor..."
    @echo "Checking system components..."
    @echo "🔍 Checking Docker..."
    @which docker >/dev/null 2>&1 && echo "  ✅ Docker is available" || echo "  ❌ Docker is missing"
    @echo "🔍 Checking curl..."
    @which curl >/dev/null 2>&1 && echo "  ✅ curl is available" || echo "  ❌ curl is missing"
    @echo "🔍 Checking Google Cloud CLI..."
    @which gcloud >/dev/null 2>&1 && echo "  ✅ Google Cloud CLI is available" || echo "  ❌ Google Cloud CLI is missing"
    @echo "🔍 Checking PostgreSQL..."
    @if which psql >/dev/null 2>&1; then \
      if ps aux | grep 'postgres' | grep -v grep >/dev/null 2>&1; then \
        if psql -h localhost -U postgres -c '\l' -t >/dev/null 2>&1; then \
          echo "  ✅ PostgreSQL server is running and accepting connections"; \
        else \
          echo "  ⚠️ PostgreSQL server is running but connection failed (auth/config issue)"; \
        fi; \
      else \
        echo "  ⚠️ PostgreSQL client is installed but server is not running"; \
      fi; \
    else \
      echo "  ❌ PostgreSQL client is missing"; \
    fi
    @echo "🔍 Checking Brave API Key..."
    @[ -n "$BRAVE_API_KEY" ] && echo "  ✅ Brave API Key is available" || echo "  ❌ Brave API Key is missing"
    @echo "🔍 Checking Hadolint (Docker Linter)..."
    @if which hadolint >/dev/null 2>&1; then echo "  ✅ Hadolint is available"; \
    elif which docker >/dev/null 2>&1; then \
      echo "  ⚠️ Hadolint is not installed locally, but can use Docker image as fallback"; \
      echo "     Run: docker run --rm -i hadolint/hadolint < Dockerfile"; \
    else echo "  ❌ Hadolint is missing and Docker is not available to run it as a container"; fi

# Install Gleam if not already installed
install-gleam:
    @echo "Installing Gleam..."
    curl -sSL https://raw.githubusercontent.com/gleam-lang/gleam/main/install.sh | sh

# Install Hadolint docker linter
install-hadolint:
    @echo "Installing Hadolint..."
    @echo "Detecting OS and architecture..."
    @ARCH=$(uname -m); OS=$(uname -s); \
    echo "OS: $OS, Architecture: $ARCH"; \
    if [ "$OS" = "Linux" ] && [ "$ARCH" = "x86_64" ]; then \
        sudo wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64; \
    elif [ "$OS" = "Darwin" ] && [ "$ARCH" = "x86_64" ]; then \
        sudo wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Darwin-x86_64; \
    elif [ "$OS" = "Darwin" ] && [ "$ARCH" = "arm64" ]; then \
        sudo wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Darwin-arm64; \
    else \
        echo "Unsupported OS/architecture. Please install hadolint manually or use Docker:"; \
        echo "docker pull hadolint/hadolint"; \
        exit 1; \
    fi; \
    sudo chmod +x /usr/local/bin/hadolint; \
    echo "Hadolint installed successfully to /usr/local/bin/hadolint"

# Build Toji binary
build-toji:
    @echo "Building Toji binary..."
    cd /home/h0ffmann/Code/ihoje/toji && gleam export erlang-cli
    @echo "Toji binary built at toji/build/erlang-cli/toji"

# Test Toji
test-toji:
    @echo "Testing Toji..."
    cd /home/h0ffmann/Code/ihoje/toji && gleam test
    
# Lint all Dockerfiles in the project
lint-dockerfiles:
    @echo "Linting all Dockerfiles in the project..."
    @if which hadolint >/dev/null 2>&1; then find /home/h0ffmann/Code/ihoje -name "Dockerfile*" -not -path "*/\.*" | xargs --max-lines=1 hadolint; \
    elif which docker >/dev/null 2>&1; then find /home/h0ffmann/Code/ihoje -name "Dockerfile*" -not -path "*/\.*" | xargs -I{} sh -c 'echo "Linting {}:"; cat {} | docker run --rm -i hadolint/hadolint'; \
    else echo "Error: Neither hadolint nor Docker is available. Please install one of them to lint Dockerfiles."; exit 1; fi