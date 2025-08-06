{ pkgs, config ? null }:

let
  # Detect if this is a server environment
  isServer = if config != null then 
    let
      hostName = config.networking.hostName or "unknown";
    in (hostName == "loki" || hostName == "server")
  else false;
  
  # Desktop-specific packages (GUI environments)
  desktopPackages = with pkgs; [
    alacritty
    kitty
  ] ++ desktopFonts ++ desktopAdditionalPackages;
  
  # Server-specific packages (SSH environments)
  serverPackages = with pkgs; [
    zellij
  ];
  
  # Common packages for all environments
  commonPackages = with pkgs; [
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
  ];
  
  # Desktop-specific additional packages
  desktopAdditionalPackages = with pkgs; [
    colima
    docker
    docker-compose
    nodejs
  ];
  

  
  # Desktop-specific packages (GUI environments)
  desktopFonts = with pkgs; [
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
in
  commonPackages ++ (if isServer then serverPackages else desktopPackages)
