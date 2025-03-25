# Tobira (Gate of Truth) - iHoje WebAssembly Interface

![Shinri no Tobira](https://i.pinimg.com/originals/24/72/1b/24721b17f758cd1e2dc3621d6d9b7814.jpg)

## 真理の扉 (Shinri no Tobira)

In Fullmetal Alchemist, the Gate of Truth (真理の扉, Shinri no Tobira) is a metaphysical gateway that contains all the knowledge of the universe. Similarly, this module serves as the gateway between users and the world of events, providing a portal to access the knowledge contained within our database.

## Overview

Tobira is a modern Rust WebAssembly interface for the iHoje event platform. It serves as the gateway (tobira) between users and the knowledge (shinri) contained in our event database, providing a seamless and responsive experience.

### Features

- **Alchemical Transformation**: Pure Rust code transmuted into WebAssembly
- **Universal Knowledge**: Complete event information, filtering, and details
- **Equivalent Exchange**: Clean, intuitive user interface for accessing data
- **Truth Visualization**: Responsive design for all device sizes
- **Transmutation Circle**: Built on the Yew framework's reactive components

## Project Structure

```
tobira/
├── src/
│   ├── api/         - Knowledge transmission protocols
│   ├── components/  - Elemental building blocks
│   ├── models/      - Alchemical formulas (data structures)
│   ├── pages/       - Complete transmutation circles
│   ├── static/      - Philosopher's stones (static assets)
│   ├── utils/       - Alchemical tools and utilities
│   ├── app.rs       - The primary transmutation circle
│   ├── lib.rs       - Core alchemical principles
│   └── router.rs    - Pathways between realms
├── index.html       - The initial gateway
├── Cargo.toml       - Material components
└── build.sh         - Transmutation activator
```

## Shinri no Tobira (The Real Thing)

The shinri-no-tobira Docker image is the true implementation of the Gateway, connecting to real event data rather than mock information. Like the Gate of Truth in Fullmetal Alchemist, it provides access to the real knowledge of events, not mere imitations.

```bash
# Build the real Shinri no Tobira image
docker build -t shinri-no-tobira:latest -f tobira/Dockerfile .

# Run the true Gate of Truth
docker run -p 8081:8081 shinri-no-tobira:latest
```

## Development

### Prerequisites

- Rust 1.84+ (The Philosopher's Stone)
- wasm-pack (The Transmutation Circle)
- trunk (The Alchemical Apparatus)

### Setup

1. Install wasm-pack:
   ```
   cargo install wasm-pack
   ```

2. Install trunk for development:
   ```
   cargo install trunk
   ```

### Opening the Gate

To build and open the Gate of Truth:

```bash
# Using just
just tobira-build

# Or directly
cd tobira
./build.sh
```

### Development Server (Docker-only)

Start a development server with auto-reload (using Docker):

```bash
# Using just
just tobira-dev

# Or with Docker directly
cd tobira
docker build -t shinri-no-tobira:dev -f Dockerfile --target dev .
docker run -p 8080:8081 --name ihoje-tobira shinri-no-tobira:dev
```

### Mock Knowledge (Testing Mode with Docker)

For development without accessing the true knowledge (backend), you can use mock data mode:

```bash
# Using just
just tobira-dev-mock

# Or with Docker directly
cd tobira
docker build -t shinri-no-tobira:mock -f Dockerfile --target mock .
docker run -p 8080:8081 --name ihoje-mock shinri-no-tobira:mock
```

Mock data mode generates imitation knowledge (fake events) and doesn't require a true connection to the source of all knowledge (backend API).

### Production Transmutation

Create an optimized production gateway:

```bash
# Using just
just tobira-release

# Or directly
cd tobira
wasm-pack build --target web --release
```

## The Universal Law of Equivalent Exchange

"Humankind cannot gain anything without first giving something in return. To obtain, something of equal value must be lost."

Our Tobira follows this principle - in exchange for your time viewing our interface, you receive knowledge of events happening around you, a fair and equivalent exchange.

## Browser Compatibility

- Chrome/Edge 79+
- Firefox 75+
- Safari 14+