{ config, pkgs, lib, ... }:

let
  user = "david";
  xdg_configHome  = "/home/${user}/.config";
  shared_programs = import ../shared/home-manager.nix { inherit config pkgs lib; };
  shared_files = import ../shared/files.nix { inherit config pkgs; };
  wallpaperPath = "/home/${user}/.local/share/backgrounds/login-wallpaper.png";



in
{
  imports = [
    ./config/polybar.nix
    ./config/hyprland.nix
  ];

  home = {
    enableNixpkgsReleaseCheck = false;
    username = "${user}";
    homeDirectory = "/home/${user}";
    packages = pkgs.callPackage ./packages.nix {};
    file = shared_files // import ./files.nix { inherit user; };
    stateVersion = "21.05";
  };

  # Ensure wallpaper file is present in the user's home
  home.file.".local/share/backgrounds/login-wallpaper.png".source = ./config/login-wallpaper.png;

  # Configure GNOME to use the wallpaper
  dconf.settings = {
    "org/gnome/desktop/background" = {
      picture-uri = "file://${wallpaperPath}";
      picture-uri-dark = "file://${wallpaperPath}";
      picture-options = "zoom";
    };
    "org/gnome/desktop/screensaver" = {
      picture-uri = "file://${wallpaperPath}";
    };
  };

  # Use a dark theme
  gtk = {
    enable = true;
    iconTheme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
    theme = {
      name = "Adwaita-dark";
      package = pkgs.adwaita-icon-theme;
    };
  };

  # Screen lock
  services = {
    screen-locker = {
      enable = true;
      inactiveInterval = 10;
      lockCmd = "${pkgs.i3lock-fancy-rapid}/bin/i3lock-fancy-rapid 10 15";
    };

    # Auto mount devices
    udiskie = {
      enable = false;
      tray = false; # Disable tray functionality to avoid the error
    };



    dunst = {
      enable = true;
      package = pkgs.dunst;
      settings = {
        global = {
          monitor = 0;
          follow = "mouse";
          border = 0;
          height = 400;
          width = 320;
          offset = "33x65";
          indicate_hidden = "yes";
          shrink = "no";
          separator_height = 0;
          padding = 32;
          horizontal_padding = 32;
          frame_width = 0;
          sort = "no";
          idle_threshold = 120;
          font = "Noto Sans";
          line_height = 4;
          markup = "full";
          format = "<b>%s</b>\n%b";
          alignment = "left";
          transparency = 10;
          show_age_threshold = 60;
          word_wrap = "yes";
          ignore_newline = "no";
          stack_duplicates = false;
          hide_duplicate_count = "yes";
          show_indicators = "no";
          icon_position = "left";
          icon_theme = "Adwaita-dark";
          sticky_history = "yes";
          history_length = 20;
          history = "ctrl+grave";
          browser = "google-chrome-stable";
          always_run_script = true;
          title = "Dunst";
          class = "Dunst";
          max_icon_size = 64;
        };
      };
    };
  };

  # Import shared programs directly from the programs attribute
  programs = shared_programs.programs;

}
