# Gugu: GCP Infrastructure Management with Scala 3 and Pulumi
# 
# This justfile provides commands for managing GCP infrastructure using 
# the Gugu toolkit built on Scala 3, scala-cli, and Pulumi.
# 
# Named after the strongest character from "To Your Eternity" anime.

# Default command shows help
default:
    @just --list

# Show help
help:
    @echo "=== Gugu GCP Infrastructure Commands ==="
    @echo ""
    @echo "Installation:"
    @echo "  install              - Install all dependencies"
    @echo "  check-deps           - Check dependencies"
    @echo ""
    @echo "Authentication:"
    @echo "  gcp-login            - Login to GCP"
    @echo "  gcp-creds            - Generate GCP credentials"
    @echo "  gcp-setup-service-account - Create and configure service account"
    @echo ""
    @echo "Stack Management:"
    @echo "  new STACK            - Create new stack"
    @echo "  list-stacks          - List available stacks"
    @echo "  select STACK         - Select stack"
    @echo "  preview [STACK]      - Preview changes"
    @echo "  up [STACK]           - Deploy infrastructure"
    @echo "  down [STACK]         - Destroy infrastructure"
    @echo "  sync [STACK]         - Sync with GCP state"
    @echo ""
    @echo "Import Existing Resources:"
    @echo "  import TYPE NAME     - Import existing resource"
    @echo "  import-vm NAME       - Import VM instance"
    @echo "  import-bucket NAME   - Import storage bucket"
    @echo ""
    @echo "GitHub Actions:"
    @echo "  setup-github-actions - Setup GitHub Actions for CI/CD"
    @echo ""
    @echo "Advanced:"
    @echo "  pulumi COMMAND       - Run pulumi command"
    @echo "  scala-cli COMMAND    - Run scala-cli command"
    @echo ""
    @echo "For detailed documentation, see /home/h0ffmann/Code/ihoje/gugu/README.md"

# Install all required dependencies
install:
    @echo "🏗️  Installing Gugu dependencies..."
    @mkdir -p .gugu
    @command -v scala-cli >/dev/null 2>&1 || { echo "Installing scala-cli..."; curl -sSLf https://scala-cli.virtuslab.org/get | sh; }
    @command -v pulumi >/dev/null 2>&1 || { echo "Installing Pulumi..."; curl -fsSL https://get.pulumi.com | sh; }
    @echo "📦 Installing Scala dependencies..."
    @scala-cli setup-ide .
    @scala-cli compile .
    @echo "✅ Dependencies installed successfully!"

# Create a new Pulumi stack
new stack="dev":
    @echo "🌱 Creating new Gugu stack: {{stack}}..."
    @mkdir -p .gugu/stacks/{{stack}}
    @pulumi stack init {{stack}}
    @echo "✅ Stack {{stack}} created successfully!"

# List available stacks
list-stacks:
    @echo "📋 Available Gugu stacks:"
    @pulumi stack ls

# Select a stack
select stack="dev":
    @echo "🔄 Selecting stack: {{stack}}..."
    @pulumi stack select {{stack}}
    @echo "✅ Stack {{stack}} selected!"

# Preview infrastructure changes without applying
preview stack="dev":
    @echo "🔍 Previewing changes for stack {{stack}}..."
    @pulumi preview --stack {{stack}}

# Deploy infrastructure
up stack="dev":
    @echo "🚀 Deploying infrastructure for stack {{stack}}..."
    @scala-cli run --main-class ihoje.gugu.Main .
    @pulumi up --stack {{stack}} --yes
    @echo "✅ Infrastructure deployed successfully!"

# Destroy infrastructure
down stack="dev":
    @echo "💥 Destroying infrastructure for stack {{stack}}..."
    @pulumi destroy --stack {{stack}} --yes
    @echo "✅ Infrastructure destroyed successfully!"

# Sync with current GCP state 
sync stack="dev":
    @echo "🔄 Syncing with current GCP state for stack {{stack}}..."
    @pulumi refresh --stack {{stack}} --yes
    @echo "✅ Infrastructure state synchronized!"

# Check system dependencies
check-deps:
    @echo "🔍 Checking Gugu dependencies..."
    @command -v scala-cli >/dev/null 2>&1 || { echo "❌ scala-cli not found"; exit 1; }
    @command -v pulumi >/dev/null 2>&1 || { echo "❌ Pulumi not found"; exit 1; }
    @command -v gcloud >/dev/null 2>&1 || { echo "❌ Google Cloud SDK not found"; exit 1; }
    @echo "✅ All dependencies are installed!"
    @echo "📊 Versions:"
    @echo "Scala CLI: $(scala-cli version)"
    @echo "Pulumi: $(pulumi version)"
    @echo "Google Cloud SDK: $(gcloud --version | head -n 1)"

# Login to GCP
gcp-login:
    @echo "🔑 Logging in to Google Cloud..."
    @gcloud auth login
    @echo "✅ Login successful!"

# Generate credential file for GCP
gcp-creds output_file=".gugu/gcp-credentials.json":
    @echo "🔑 Generating GCP credentials..."
    @mkdir -p .gugu
    @gcloud auth application-default login
    @cp "$(gcloud info --format='value(config.paths.global_config_dir)')/application_default_credentials.json" "{{output_file}}"
    @echo "✅ Credentials saved to {{output_file}}"

# Setup service account for GCP
gcp-setup-service-account name="gugu-deployer" project_id="" roles="roles/editor":
    #!/usr/bin/env bash
    if [ -z "{{project_id}}" ]; then
        project_id=$(gcloud config get-value project)
        if [ -z "$project_id" ]; then
            echo "❌ No project ID specified and no default project configured"
            echo "Usage: just gugu gcp-setup-service-account gugu-deployer YOUR-PROJECT-ID"
            exit 1
        fi
    else
        project_id="{{project_id}}"
    fi
    
    echo "🔑 Setting up service account {{name}} for project $project_id..."
    
    # Create service account if it doesn't exist
    if ! gcloud iam service-accounts describe {{name}}@$project_id.iam.gserviceaccount.com >/dev/null 2>&1; then
        echo "Creating service account {{name}}..."
        gcloud iam service-accounts create {{name}} \
            --display-name="Gugu Infrastructure Deployer"
    fi
    
    # Grant permissions
    echo "Granting {{roles}} role to service account..."
    gcloud projects add-iam-policy-binding $project_id \
        --member="serviceAccount:{{name}}@$project_id.iam.gserviceaccount.com" \
        --role="{{roles}}"
    
    # Create key file
    mkdir -p .gugu
    key_file=".gugu/{{name}}-$project_id.json"
    echo "Creating key file at $key_file..."
    gcloud iam service-accounts keys create "$key_file" \
        --iam-account={{name}}@$project_id.iam.gserviceaccount.com
    
    echo "✅ Service account setup complete!"
    echo "Key file location: $key_file"
    echo ""
    echo "To use this service account with Pulumi:"
    echo "pulumi config set gcp:project $project_id"
    echo "pulumi config set gcp:serviceAccountKeyFile $key_file"

# Import existing GCP resource into Pulumi
import type name resource_id="":
    #!/usr/bin/env bash
    if [ -z "{{resource_id}}" ]; then
        resource_id="{{name}}"
    fi
    
    echo "🔄 Importing existing resource..."
    pulumi import gcp:{{type}} {{name}} {{resource_id}}
    
    echo "✅ Resource imported! Update your Scala code to match the imported resource."

# Import VM instance
import-vm name:
    @just import "compute/instance:Instance" {{name}} {{name}}

# Import storage bucket
import-bucket name:
    @just import "storage/bucket:Bucket" {{name}} {{name}}

# Setup GitHub Actions for CI/CD
setup-github-actions:
    #!/usr/bin/env bash
    mkdir -p ../../.github/workflows
    workflow_file="../../.github/workflows/gugu-infrastructure.yml"
    
    if [ -f "$workflow_file" ]; then
        read -p "GitHub Actions workflow already exists. Overwrite? (y/n): " overwrite
        if [ "$overwrite" != "y" ]; then
            echo "Aborted."
            exit 0
        fi
    fi
    
    cat > "$workflow_file" << 'EOF'
name: GCP Infrastructure CI/CD

on:
  push:
    branches: [main]
    paths:
      - 'gugu/**'
  pull_request:
    branches: [main]
    paths:
      - 'gugu/**'
  workflow_dispatch:

jobs:
  infrastructure:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      id-token: write # Needed for GCP workload identity federation
      pull-requests: write # Needed for PR comments
      
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Scala
        uses: VirtusLab/scala-cli-setup@v1.0
        
      - name: Set up Pulumi
        uses: pulumi/actions@v4

      # Install the "just" command runner
      - name: Install Just
        uses: extractions/setup-just@v1
        with:
          just-version: 1.13.0

      - name: Check Dependencies
        run: |
          just gugu check-deps
        working-directory: ./gugu

      - name: Authenticate to Google Cloud
        id: auth
        uses: google-github-actions/auth@v1
        with:
          # Option 1: Workload Identity Federation (recommended for production)
          workload_identity_provider: ${{ secrets.WORKLOAD_IDENTITY_PROVIDER }}
          service_account: ${{ secrets.GCP_SERVICE_ACCOUNT }}
          # Option 2: Service account key (simpler but less secure)
          # credentials_json: ${{ secrets.GCP_CREDENTIALS }}
      
      - name: Preview Infrastructure Changes
        uses: pulumi/actions@v4
        with:
          command: preview
          stack-name: ${{ github.event.pull_request.base.ref == 'main' && 'prod' || 'dev' }}
          work-dir: ./gugu
          comment-on-pr: true
        if: github.event_name == 'pull_request'
        env:
          PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}
      
      - name: Deploy Infrastructure
        uses: pulumi/actions@v4
        with:
          command: up
          stack-name: ${{ github.ref == 'refs/heads/main' && 'prod' || 'dev' }}
          work-dir: ./gugu
        if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'
        env:
          PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}
EOF

    echo "✅ GitHub Actions workflow created at $workflow_file"
    echo ""
    echo "To use this workflow, you need to add the following repository secrets:"
    echo "- WORKLOAD_IDENTITY_PROVIDER: Your GCP Workload Identity Provider"
    echo "- GCP_SERVICE_ACCOUNT: Service account email"
    echo "- PULUMI_ACCESS_TOKEN: Pulumi access token (if using Pulumi Cloud)"
    echo ""
    echo "Or alternatively, you can use a service account key with:"
    echo "- GCP_CREDENTIALS: Contents of service account key JSON file"

# Run Pulumi command directly
pulumi +ARGS:
    @echo "Running: pulumi {{ARGS}}"
    @cd ../gugu && pulumi {{ARGS}}

# Run scala-cli command directly
scala-cli +ARGS:
    @echo "Running: scala-cli {{ARGS}}"
    @cd ../gugu && scala-cli {{ARGS}}