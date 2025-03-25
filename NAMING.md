# iHoje Crate Naming Conventions

This project follows anime-inspired naming conventions for its Rust crates:

## Core Crates

| Crate Name | Original Name | Description | Inspiration |
|------------|---------------|-------------|------------|
| **sharingan** | ihoje_core | Core event scraping engine | Naruto - Eye ability for pattern recognition and copying |
| **pokeball** | ihoje_models | Shared data models | Pokémon - Device for capturing and storing data |
| **tobira** | ihoje_tobira | WebAssembly frontend | Fullmetal Alchemist - "Gate of Truth" |

## Rationale

### Sharingan (Core Engine)
The sharingan is a powerful eye ability in Naruto that allows the user to:
- See through illusions
- Recognize patterns 
- Copy techniques
- Predict movements

As our core engine performs pattern recognition for event data extraction, the name "sharingan" represents the ability to perceive and analyze structured data from various sources.

### Pokeball (Shared Models)
In Pokémon, pokeballs are used for:
- Capturing Pokémon
- Storing them safely
- Transporting them between locations

Our shared models crate contains the data structures that "capture" event information and allow it to be transported between the different parts of the application.

### Tobira (Frontend)
In Fullmetal Alchemist, "Shinri no Tobira" (Gate of Truth) is:
- A gateway between dimensions
- The boundary between the physical and metaphysical worlds
- A source of knowledge and understanding

Our WebAssembly frontend serves as the "gate" through which users interact with the application.

## Usage in Code

```rust
// In sharingan code, import models from pokeball:
use pokeball::{Event, EventQuery};

// In tobira code, import models from pokeball:
use pokeball::{Event, EventQuery}; 

// Optional tobira imports from sharingan:
use sharingan::some_feature;
```

## Build Commands

```bash
# Build the entire workspace
just build

# Build individual crates
just build-sharingan
just build-pokeball
just build-tobira
```