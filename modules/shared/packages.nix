{ pkgs, config ? null }:

let
  # Detect if this is a server environment
  isServer = if config != null then 
    (config.networking.hostName == "loki" || config.networking.hostName == "server")
  else false;
  
  # Desktop-specific packages (GUI environments)
  desktopPackages = with pkgs; [
    alacritty
    kitty
  ];
  
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
    colima
    ddgr
    zoxide
    docker
    docker-compose
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
    nodejs
    ripgrep   
    fd 
    lua
    #ranger
    lynx
    ueberzug
    powershell  
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
