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
  # bitwarden-cli removed (fails to build on Darwin due to argon2/node-gyp); use rbw instead
  rbw  # Rust Bitwarden client for sopswarden
  # bws (Bitwarden Secrets Manager CLI) is required for secrets automation
  # Not yet in nixpkgs; install manually in installer scripts:
  # curl -L https://github.com/bitwarden/sdk/releases/latest/download/bws-x86_64-unknown-linux-gnu.zip -o bws.zip && unzip bws.zip && sudo mv bws /usr/local/bin/
  # bws # Uncomment when available in nixpkgs
  coreutils
  codex
  killall
  pfetch
  neofetch
  yazi
  lf
  nnn
  openssh
  sqlite
  wget
  curl
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
  age
  # ueberzug (Linux-only) removed: fails to build on Darwin (X11 dependency, upstream #error OS unsupported)
  # If needed on Linux only, re-add via: (pkgs.lib.optionals pkgs.stdenv.isLinux [ pkgs.ueberzug ]) in a separate attr
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
  # jetbrains-mono already included above; avoid duplicate
  font-awesome
  nerd-fonts.fira-code
  meslo-lgs-nf
] ++ (if stdenv.isDarwin then [ pinentry_mac ] else [ pinentry-curses ])
