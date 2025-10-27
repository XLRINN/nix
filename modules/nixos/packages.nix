{ pkgs }:

with pkgs;
let shared-packages = import ../shared/packages.nix { inherit pkgs; }; in
shared-packages ++ [

  #Terminal emulators
  alacritty
  termius
  wezterm

  kitty
  ghostty
  tilix


  # Security and authentication
  yubikey-agent
  keepassxc
  vscode
  bitwarden
  
  firefox
 

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
  pavucontrol # Pulse audio controls

  # Testing and development tools
  direnv
  rofi
  rofi-calc
  postgresql


  # Screenshot and recording tools
  flameshot

  # Text and terminal utilities
  feh # Manage wallpapers
  swaybg
  screenkey
  tree
  unixtools.ifconfig
  unixtools.netstat
  xclip # For clipboard operations
  xorg.xwininfo # Provides a cursor to click and learn about windows
  xorg.xrandr

 # sqlite
  xdg-utils

  # Other utilities
  yad # yad-calendar is used with polybar
  #xdotool
  #google-chrome

  # PDF viewer
  # zathura  # Temporarily disabled - was causing installation hangs

  # Music and entertainment
  #spotify

  # Wireless in GNOME
  #networkmanager
  #networkmanagerapplet

  waynergy
]
