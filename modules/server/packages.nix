{ pkgs, config ? null }:

let
  # Server-specific CLI packages
  serverPackages = with pkgs; [
    # Basic CLI tools
    bat
    btop
    coreutils
    killall
    pfetch
    neofetch
    yazi
    lf
    nnn
    sqlite
    wget
    zip
    zsh
    lazygit
    fzf
    ddgr
    zoxide
    htop
    hunspell
    iftop
    jetbrains-mono
    jq
    ripgrep
    tree
    unrar
    unzip
    zsh-powerlevel10k
    fd 
    lua
    lynx
    ueberzug
    # Development tools
    docker
    docker-compose
    nodejs
    # Terminal multiplexer
    zellij
    # Development tools
    direnv
    nix-direnv
    git
    # Neovim dependencies
    stylua
    curl
    # Server-specific tools
    nginx
    certbot
    # Monitoring tools
    iotop
    nethogs
    # Network tools
    nmap
    tcpdump
    # Additional CLI tools
    exa
    tmux
    vim
    # Python for scripting
    python3
    python3Packages.pip
  ];
in
  serverPackages
