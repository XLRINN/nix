{ pkgs, config ? null }:

let
  # Detect if this is a server environment
  isServer = if config != null then 
    let
      hostName = config.networking.hostName or "unknown";
    in (hostName == "loki" || hostName == "server")
  else false;
  
  # GUI-specific packages (desktop only)
  guiPackages = with pkgs; [
    alacritty
    kitty
    # fonts
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
    fira-code
    inconsolata
    dejavu_fonts
    jetbrains-mono
    font-awesome
    nerd-fonts.fira-code
    meslo-lgs-nf
  ];
  
  # Shared packages for all environments
  sharedPackages = with pkgs; [
    #ghostty
    aspell
    aspellDicts.en
    bash-completion
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
    #oh-my-posh
    #synergy
    ripgrep   
    fd 
    lua
    #ranger
    lynx
    ueberzug
    # Development tools (shared)
    colima
    docker
    docker-compose
    nodejs
    # Terminal multiplexer (shared)
    zellij
  ];
in
  sharedPackages ++ (if isServer then [] else guiPackages)
