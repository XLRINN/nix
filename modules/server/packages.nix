{ pkgs, config ? null }:

<<<<<<< HEAD
let
  # Server-specific CLI packages - minimal for basic installation
  serverPackages = with pkgs; [
    # Basic CLI tools only
    coreutils
    wget
    curl
    vim
    git
    zsh
    htop
    tmux
  ];
in
  serverPackages
=======
with pkgs;
let 
  shared-packages = import ../shared/packages.nix { inherit pkgs; };
  server-specific-packages = with pkgs; [
    # Server management tools
    docker-compose
    tmux
    screen
    
    # Network diagnostics
    nettools
    iproute2
    iotop
    iftop
    tcpdump
    
    # System monitoring and management
    lsof
    psmisc
    procps
    ncdu  # disk usage analyzer
    
    # File and text processing
    rsync
    jq
    yq
    
    # Security tools
    openssh
    gnupg
  ];
in
shared-packages ++ server-specific-packages
>>>>>>> 0253090 (refactor: remove finish.sh script and enhance server configuration in default.nix, disk-config.nix, home-manager.nix, and packages.nix for improved clarity and functionality)
