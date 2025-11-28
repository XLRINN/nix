{ pkgs }:

with pkgs;
let
  shared-packages = import ../shared/packages.nix { inherit pkgs; };
  # Ensure Termius bundles libsqlite3 for NSS (libsoftokn3.so)
  termiusFixed = pkgs.termius.overrideAttrs (old: {
    buildInputs = (old.buildInputs or []) ++ [ pkgs.sqlite ];
  });
in
shared-packages ++ [

  # Security and authentication
  yubikey-agent
  keepassxc
  vscode
  bitwarden
  termiusFixed
  firefox
  alacritty
  
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
  barrier
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

  # File and system utilities
 # inotify-tools # inotifywait, inotifywatch - For file system events
 # i3lock-fancy-rapid
 # libnotify
 # pcmanfm # File browser
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

  # Gaming-centric tools
  steam
  steam-run
  lutris
  heroic-games-launcher
  protonup-qt
  gamemode
  mangohud
  wine
  vkd3d-proton
  vulkan-tools
]
