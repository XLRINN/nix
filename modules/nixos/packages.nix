{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [

  # Security and authentication
  bitwarden

  # App and package management
  appimage-run
  gnumake
  cmake
  home-manager

  # Media and design tools
  vlc
  fontconfig
  font-manager

  # Productivity tools
  bc # old school calculator
  galculator

  # Audio tools
  cava # Terminal audio visualizer
  pavucontrol # Pulse audio controls
  pulseaudio # Sound server

  # Testing and development tools
  
  visual-studio-code
  vlc
  rectangle
  alacritty
  kitty


  termius
  zoom
  microsoft-remote-desktop

  vnc-viewer
  
  # Browsers
  google-chrome
  duckduckgo
  firefox
]

  # Screenshot and recording tools
  flameshot

  # Text and terminal utilities


  tree
  unixtools.ifconfig
  unixtools.netstat
  xclip # For the org-download package in Emacs
  xorg.xwininfo # Provides a cursor to click and learn about windows
  xorg.xrandr

  # File and system utilities
  pcmanfm # File browser
  sqlite
  xdg-utils
  xdotool
  google-chrome
  firefox
  # PDF viewer
  zathura

]
