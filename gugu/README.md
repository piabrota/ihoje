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

## Just Commands

```bash
# Install dependencies
just gugu install

# Check dependencies
just gugu check-deps

# Deploy infrastructure
just gugu up

# Sync with current GCP state
just gugu sync
```

## Example Usage

```scala
import dev.gugu.compute.VirtualMachine
import dev.gugu.compute.VirtualMachineConfig
import dev.gugu.storage.Bucket
import dev.gugu.storage.BucketConfig

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
│       └── dev/gugu/    # Main source code
│           ├── Main.scala           # Entry point
│           ├── compute/             # Compute resources
│           ├── storage/             # Storage resources
│           ├── network/             # Network resources
│           ├── iam/                 # IAM resources
│           └── util/                # Utilities
└── docs/                # Documentation
```