{ pkgs, config ? null }:

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
