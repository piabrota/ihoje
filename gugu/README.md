# Gugu: GCP Infrastructure as Code

[![Scala Version](https://img.shields.io/badge/Scala-3.3.1-blue.svg)](https://www.scala-lang.org/)
[![Pulumi Version](https://img.shields.io/badge/Pulumi-3.91.1-blueviolet.svg)](https://www.pulumi.com/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A powerful infrastructure-as-code toolkit for managing Google Cloud Platform resources using Scala 3 and Pulumi.

## About the Name

The tool is named after **Gugu** from the anime "To Your Eternity" (不滅のあなたへ, _Fumetsu no Anata e_).

In the series, Gugu is considered one of the strongest characters due to:

- His extraordinary physical strength, developed through intensive training
- His unique ability to breathe fire through his mask
- His unwavering courage and loyalty, especially to his sworn brother Fushi
- His resilience in overcoming a tragic accident that disfigured his face
- His selfless willingness to protect others at any cost

Similarly, this toolkit aims to provide extraordinary strength, resilience, and reliability for managing cloud infrastructure.

## Features

- **Type-Safe Infrastructure**: Leverage Scala 3's powerful type system
- **Idiomatic Scala**: Use functional programming patterns for infrastructure definition
- **Comprehensive GCP Support**: Manage Compute, Storage, Networking, IAM, and more
- **Testable**: Unit test your infrastructure with ScalaTest
- **Integration Ready**: Seamlessly integrate with CI/CD pipelines

## Prerequisites

- [Scala CLI](https://scala-cli.virtuslab.org/) (1.0.0+)
- [Pulumi CLI](https://www.pulumi.com/docs/install/) (3.0.0+)
- [Google Cloud SDK](https://cloud.google.com/sdk/docs/install)
- [Just](https://github.com/casey/just) command runner

## Getting Started

### Local Development Setup

1. **Install Dependencies**:
   ```bash
   just gugu install
   ```

2. **Check Dependencies**:
   ```bash
   just gugu check-deps
   ```

3. **Set Up GCP Credentials**:
   ```bash
   just gugu gcp-creds
   ```
   This command will:
   - Launch the Google OAuth flow in your browser
   - Create application default credentials
   - Copy them to the `.gugu/gcp-credentials.json` file

4. **Create Your First Stack**:
   ```bash
   just gugu new dev
   ```
   This creates a Pulumi stack named "dev" for development purposes.

### Integrating With Existing GCP Projects

Gugu can manage resources in your existing GCP projects by following these steps:

#### 1. Configure Project Access

You can connect to an existing GCP project using one of these methods:

**Method A: Using Application Default Credentials (ADC)**
```bash
# Login and generate credentials
just gugu gcp-creds

# Configure the target project
gcloud config set project YOUR_PROJECT_ID
```

**Method B: Using Service Account Key**
```bash
# Create a dedicated service account (recommended for CI/CD)
gcloud iam service-accounts create gugu-deployer \
  --display-name="Gugu Infrastructure Deployer"

# Grant necessary permissions (customize based on resources you'll manage)
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:gugu-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/editor"

# Create and download key (secure this carefully!)
gcloud iam service-accounts keys create .gugu/service-account-key.json \
  --iam-account=gugu-deployer@YOUR_PROJECT_ID.iam.gserviceaccount.com
```

#### 2. Configure Pulumi Stack

Create a Pulumi stack configuration file:

```bash
# Create the stack
just gugu new prod

# Configure project ID
pulumi config set gcp:project YOUR_PROJECT_ID

# Configure region (optional)
pulumi config set gcp:region us-central1

# If using service account (Method B)
pulumi config set gcp:serviceAccountKeyFile .gugu/service-account-key.json
```

#### 3. Import Existing Resources (Optional)

If you want to bring existing GCP resources under Gugu's management:

```bash
# For example, to import an existing VM:
pulumi import gcp:compute/instance:Instance existing-vm VM_NAME

# For a storage bucket:
pulumi import gcp:storage/bucket:Bucket existing-bucket BUCKET_NAME
```

After importing, Gugu will generate code to match the imported resource's current state.

### GitHub Actions Integration

To automate infrastructure deployments with CI/CD, create a GitHub Actions workflow file:

1. Create `.github/workflows/gugu-infrastructure.yml`:

```yaml
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
      
    steps:
      - uses: actions/checkout@v3
      
      - name: Set up Scala
        uses: VirtusLab/scala-cli-setup@v1.0
        
      - name: Set up Pulumi
        uses: pulumi/actions@v4

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
          stack-name: prod
          work-dir: ./gugu
          comment-on-pr: true
        if: github.event_name == 'pull_request'
      
      - name: Deploy Infrastructure
        uses: pulumi/actions@v4
        with:
          command: up
          stack-name: prod
          work-dir: ./gugu
        if: github.event_name == 'push' || github.event_name == 'workflow_dispatch'
```

2. Configure GitHub Repository Secrets:
   - For Workload Identity Federation:
     - `WORKLOAD_IDENTITY_PROVIDER`: Your GCP Workload Identity Provider
     - `GCP_SERVICE_ACCOUNT`: Service account email
   - For service account key:
     - `GCP_CREDENTIALS`: Contents of service account key JSON file

3. Configure Pulumi Cloud (Optional):
   ```bash
   pulumi login
   # Follow prompts to create a Pulumi account and organization
   ```

   Then, in GitHub Actions, add:
   ```yaml
   env:
     PULUMI_ACCESS_TOKEN: ${{ secrets.PULUMI_ACCESS_TOKEN }}
   ```

## Just Commands

```bash
# Install dependencies
just gugu install

# Check dependencies
just gugu check-deps

# Configure GCP credentials
just gugu gcp-creds

# Create a new stack
just gugu new [stack-name]

# Preview infrastructure changes
just gugu preview [stack-name]

# Deploy infrastructure
just gugu up [stack-name]

# Destroy infrastructure
just gugu down [stack-name]

# Sync with current GCP state
just gugu sync [stack-name]
```

## Example Usage

```scala
import ihoje.gugu.compute.VirtualMachine
import ihoje.gugu.compute.VirtualMachineConfig
import ihoje.gugu.storage.Bucket
import ihoje.gugu.storage.BucketConfig

// Create a virtual machine
val webServer = VirtualMachine.create(
  name = "web-server",
  config = VirtualMachineConfig(
    machineType = "e2-medium",
    zone = "us-central1-a",
    image = "debian-cloud/debian-11",
    tags = List("http-server")
  )
)

// Create a storage bucket
val assetsBucket = Bucket.create(
  name = "app-assets",
  config = BucketConfig(
    location = "US",
    versioning = true,
    uniformAccess = true
  )
)

// Export outputs
export("serverIp", webServer.publicIp)
export("bucketUrl", assetsBucket.url)
```

## Project Structure

```
gugu/
├── build.scala          # Scala-CLI build definition
├── justfile             # Just commands
├── src/
│   └── main/scala/
│       └── ihoje/gugu/  # Main source code
│           ├── Main.scala           # Entry point
│           ├── compute/             # Compute resources
│           ├── storage/             # Storage resources
│           ├── network/             # Network resources
│           ├── iam/                 # IAM resources
│           └── util/                # Utilities
└── docs/                # Documentation
```

## Common Patterns

### Creating Infrastructure Modules

Organize related resources in modular functions:

```scala
def createWebInfrastructure(name: String, region: String): WebInfrastructure = {
  // Create VPC
  val vpc = Network.create(s"${name}-vpc", NetworkConfig(region = region))
  
  // Create VM instances
  val instances = (1 to 3).map { i =>
    VirtualMachine.create(
      s"${name}-vm-${i}",
      VirtualMachineConfig(
        machineType = "e2-medium",
        zone = s"${region}-a",
        network = vpc.selfLink
      )
    )
  }
  
  // Create load balancer
  val lb = LoadBalancer.create(s"${name}-lb", LoadBalancerConfig(
    instances = instances.map(_.selfLink),
    region = region
  ))
  
  WebInfrastructure(vpc, instances, lb)
}
```

### Managing Multiple Environments

Use stack configurations to manage different environments:

```scala
// Read stack-specific configuration
val config = new Config()
val environment = config.require("environment")
val instanceCount = config.getInt("instanceCount").getOrElse(1)

// Create environment-appropriate resources
val instances = (1 to instanceCount).map { i =>
  VirtualMachine.create(
    s"${environment}-vm-${i}",
    VirtualMachineConfig(
      machineType = if (environment == "prod") "e2-standard-4" else "e2-small",
      zone = "us-central1-a",
      preemptible = environment != "prod"
    )
  )
}
```

## Best Practices

1. **Resource Naming**: Use consistent naming conventions with prefixes for environment/project
2. **Modularization**: Group related resources in reusable functions
3. **Configuration**: Use Pulumi config instead of hardcoding values
4. **State Management**: Commit to using a single state management strategy (local or remote)
5. **Least Privilege**: Use minimal IAM permissions for service accounts
6. **Secret Management**: Never hardcode secrets, use Pulumi's secret management
7. **Testing**: Write unit tests for complex infrastructure modules

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for guidelines on contributing to Gugu.

## License

This project is licensed under the MIT License - see the LICENSE file for details.