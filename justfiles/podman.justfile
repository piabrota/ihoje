# Podman Container Management Recipes
# This file contains all Podman-related commands

# Load .env file if present
set dotenv-load

# Show available recipes
default:
    @just --list

# Show podman commands help
help:
    @echo "======= Podman Container Commands ======="
    @echo ""
    @echo "Build Commands:"
    @echo "  just build-image           - Build main application image"
    @echo "  just build-lambda          - Build Lambda application image"
    @echo "  just list-images           - List all container images"
    @echo ""
    @echo "Run Commands:"
    @echo "  just run [ARGS]            - Run container locally"
    @echo "  just compose ARGS          - Run podman-compose commands"
    @echo ""
    @echo "Registry Commands:"
    @echo "  just login REGISTRY USER   - Login to container registry"
    @echo "  just push REGISTRY [TAG]   - Push image to registry"
    @echo "  just push-lambda REG [TAG] - Push Lambda image to registry"
    @echo ""
    @echo "System Commands:"
    @echo "  just info                  - Display podman system information"
    @echo "  just prune                 - Clean up podman system"
    @echo "  just volumes               - List all podman volumes"
    @echo "  just inspect VOL           - Inspect volume details"
    @echo "  just clean-volumes         - Clean all volumes (danger!)"

# Build container image using podman
build-image:
    podman build -t ihoje:latest .
    
# Build lambda container image using podman
build-lambda:
    podman build -t ihoje-lambda:latest -f Dockerfile.lambda .

# Tag and push container image to registry
push registry tag="latest":
    #!/usr/bin/env bash
    echo "Tagging and pushing image to registry: {{registry}}"
    podman tag ihoje:latest {{registry}}/ihoje:{{tag}}
    podman push {{registry}}/ihoje:{{tag}}
    
# Tag and push lambda container image to registry
push-lambda registry tag="latest":
    #!/usr/bin/env bash
    echo "Tagging and pushing lambda image to registry: {{registry}}"
    podman tag ihoje-lambda:latest {{registry}}/ihoje-lambda:{{tag}}
    podman push {{registry}}/ihoje-lambda:{{tag}}

# Run container locally
run +ARGS="":
    podman run --rm -it -p 8080:8080 ihoje:latest {{ARGS}}

# List all container images
list-images:
    podman images | grep -E 'ihoje|REPOSITORY'

# Podman compose wrapper
compose +ARGS="":
    #!/usr/bin/env bash
    echo "Running podman-compose {{ARGS}}..."
    podman-compose {{ARGS}}

# Login to container registry
login registry username:
    #!/usr/bin/env bash
    echo "Logging in to {{registry}} as {{username}}"
    # This will prompt for password
    podman login --username {{username}} {{registry}}

# Display podman system information
info:
    podman info

# Clean up podman system
prune:
    #!/usr/bin/env bash
    echo "Pruning unused podman resources..."
    podman system prune -f
    echo "Containers pruned"

# List all podman volumes
volumes:
    podman volume ls | grep -E 'ihoje|VOLUME NAME'

# Inspect volume details
inspect volume="ihoje-postgres-data":
    podman volume inspect {{volume}}

# Clean all podman volumes (danger!)
clean-volumes:
    #!/usr/bin/env bash
    echo "WARNING: This will remove all ihoje-related volumes!"
    echo "This action cannot be undone and will result in DATA LOSS."
    read -p "Are you sure? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        podman volume rm $(podman volume ls -q | grep ihoje)
        echo "Volumes removed"
    else
        echo "Operation cancelled"
    fi