{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Core tools
    just
    rustup
    cargo
    rustc
    clippy
    # WebAssembly support
    wasm-pack
    llvmPackages.lld
    
    # Python for Mangekyou and MCP tools
    python311
    python311Packages.pip
    python311Packages.virtualenv
    python311Packages.fastapi
    python311Packages.uvicorn
    python311Packages.pydantic
    
    # NodeJS for MCP tools
    nodejs_20
    
    # Database tools
    postgresql_15
    sqlite
    
    # Container tools
    podman
    podman-compose
  ];
  
  shellHook = ''
    # Set up environment variables
    export PYTHONPATH="$PYTHONPATH:$PWD/scripts/mangekyou-mcp"
    export MANGEKYO_SERVER_URL="http://localhost:17891"
    export PATH="$PATH:$PWD/scripts"
    
    # WebAssembly support
    export CARGO_TARGET_WASM32_UNKNOWN_UNKNOWN_LINKER=lld
    
    # Create a working directory for virtual environments
    mkdir -p ./.xdg-runtime-dir
    export XDG_RUNTIME_DIR="$PWD/.xdg-runtime-dir"
    
    # Prevent "externally-managed-environment" errors
    export PIP_BREAK_SYSTEM_PACKAGES=1
    
    echo "Nix development shell ready for iHoje with Mangekyou compatibility"
    echo "Run 'just help' to see available commands"
  '';
}