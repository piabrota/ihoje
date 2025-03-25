# Podman Container Management Recipes
# This file contains all Podman-related commands

# Build container image using podman
build-image:
    podman build -t ihoje:latest .
    
# Build lambda container image using podman
build-lambda-image:
    podman build -t ihoje-lambda:latest -f Dockerfile.lambda .

# Tag and push container image to registry
push-image registry tag="latest":
    #!/usr/bin/env bash
    echo "Tagging and pushing image to registry: {{registry}}"
    podman tag ihoje:latest {{registry}}/ihoje:{{tag}}
    podman push {{registry}}/ihoje:{{tag}}
    
# Tag and push lambda container image to registry
push-lambda-image registry tag="latest":
    #!/usr/bin/env bash
    echo "Tagging and pushing lambda image to registry: {{registry}}"
    podman tag ihoje-lambda:latest {{registry}}/ihoje-lambda:{{tag}}
    podman push {{registry}}/ihoje-lambda:{{tag}}

# Run container locally
run-container +ARGS="":
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
registry-login registry username:
    #!/usr/bin/env bash
    echo "Logging in to {{registry}} as {{username}}"
    # This will prompt for password
    podman login --username {{username}} {{registry}}

# Display podman system information
podman-info:
    podman info

# Clean up podman system
podman-prune:
    #!/usr/bin/env bash
    echo "Pruning unused podman resources..."
    podman system prune -f
    echo "Containers pruned"

# List all podman volumes
list-volumes:
    podman volume ls | grep -E 'ihoje|VOLUME NAME'

# Inspect volume details
inspect-volume volume="ihoje-postgres-data":
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

# Show all podman-related commands
podman-help:
    @echo "======= Podman Commands ======="
    @echo ""
    @echo "Container Management:"
    @echo "  just build-image           - Build main application image"
    @echo "  just build-lambda-image    - Build Lambda application image"
    @echo "  just run-container [ARGS]  - Run container locally"
    @echo "  just list-images           - List all container images"
    @echo "  just podman-prune          - Clean up podman system"
    @echo "  just podman-info           - Display podman system information"
    @echo ""
    @echo "Registry Operations:"
    @echo "  just registry-login REGISTRY USERNAME  - Login to container registry"
    @echo "  just push-image REGISTRY [TAG]         - Push image to registry"
    @echo "  just push-lambda-image REGISTRY [TAG]  - Push Lambda image to registry"
    @echo ""
    @echo "Volumes:"
    @echo "  just list-volumes                      - List all podman volumes"
    @echo "  just inspect-volume [VOLUME]           - Inspect volume details"
    @echo "  just clean-volumes                     - Clean all volumes (danger!)"
    @echo ""
    @echo "Compose:"
    @echo "  just compose ARGS                      - Run podman-compose commands"