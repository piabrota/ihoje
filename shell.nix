{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # Node.js (Latest LTS version)
    nodejs_22
    # For latest stable, uncomment the line below and comment out the LTS version above
    # nodejs # Latest stable

    # Package managers
    nodePackages.npm
    yarn

    # Development tools
    busybox
    lsof
    git

    # Dependencies for Puppeteer (browser automation)
    chromium # The actual browser binary
    xorg.libX11
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXi
    xorg.libXrandr
    xorg.libXScrnSaver
    xorg.libXtst
    pango
    cairo
    cups.lib
    dbus
    expat
    fontconfig
    freetype
    libpng
    nspr
    nss
    xorg.libxcb
    atk
    gdk-pixbuf
    gtk3
    alsa-lib

    # For file watchers
    inotify-tools
  ];

  shellHook = ''
    # Set npm to install global packages in a writable location
    export npm_config_prefix=$HOME/.npm-global
    mkdir -p $HOME/.npm-global/bin
    export PATH=$HOME/.npm-global/bin:$PATH
    
    export PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=1
    
    # Use system chromium for Puppeteer
    export PUPPETEER_EXECUTABLE_PATH=${pkgs.chromium}/bin/chromium
    
    # Install Claude Code CLI globally
    echo "Installing @anthropic-ai/claude-code globally..."
    npm install -g @anthropic-ai/claude-code
    
    echo "Node.js development environment ready!"
    echo "Node.js version: $(node -v)"
    echo "npm version: $(npm -v)"
    
    # Check if Node.js version meets requirements
    NODE_VERSION=$(node -v | cut -d 'v' -f 2 | cut -d '.' -f 1)
    if [ "$NODE_VERSION" -lt "18" ]; then
      echo "Warning: This project requires Node.js version 18 or higher"
      echo "Current version: $(node -v)"
    fi
    
    # Create temporary directories needed by Puppeteer
    export XDG_RUNTIME_DIR="$PWD/.xdg-runtime-dir"
    mkdir -p "$XDG_RUNTIME_DIR"
    
    # Create a .env file if it doesn't exist
    if [ ! -f .env ]; then
      if [ -f .env.example ]; then
        cp .env.example .env
        echo "Created .env file from .env.example"
        echo "Please update the .env file with your credentials"
      fi
    fi
  '';
}
