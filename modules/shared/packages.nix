{ pkgs }:

with pkgs; [
  # General packages for development and system management
 # alacritty
  #ghostty
  aspell
  aspellDicts.en
  bash-completion
  bat
  btop
  bitwarden-cli
  rbw  # Rust Bitwarden client for sopswarden
  # Note: bws (Bitwarden Secrets Manager CLI) might not be in nixpkgs yet
  # You can install it manually: curl -L https://github.com/bitwarden/sdk/releases/latest/download/bws-x86_64-unknown-linux-gnu.zip
  coreutils
  killall
  pfetch
  neofetch
  yazi
  lf
  nnn
  openssh
  sqlite
  wget
  zip
  kitty
  oh-my-zsh 
  zsh
  lazygit
  fzf
  colima
  chatgpt-cli
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
  tmux
  unrar
  unzip
  zsh-powerlevel10k
  oh-my-posh
  synergy
  nodejs
  ripgrep   
  fd 
  lua
  ranger
  lynx
  ueberzug
  tmux
  powershell

  # fonts
  noto-fonts
  noto-fonts-cjk-sans
  noto-fonts-emoji
  fira-code
  inconsolata
  dejavu_fonts

  feather-font
  jetbrains-mono
  font-awesome
  nerd-fonts.fira-code
  meslo-lgs-nf
]
