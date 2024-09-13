{ user, ... }:

let
  home           = builtins.getEnv "HOME";
  xdg_configHome = "${home}/.config";
  xdg_dataHome   = "${home}/.local/share";
  xdg_stateHome  = "${home}/.local/state"; in
{

  # Enable GNOME desktop environment with Wayland
  services.xserver = {
    enable = true;
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };
    desktopManager.gnome3 = {
      enable = true;
      wayland = true;
    };
  };

  # Enable COSMIC desktop environment with Wayland
  services.xserver.desktopManager.cosmic = {
    enable = true;
    wayland = true;
  };

  # Additional GNOME and COSMIC packages
  environment.systemPackages = with pkgs; [
    gnome3.gnome-tweaks
    gnome3.dconf-editor
    gnome3.gnome-terminal
    gnome3.nautilus
    cosmic
  ];

  "${xdg_configHome}/gnome/gnomerc" = {
    executable = true;
    text = ''
      #! /bin/sh
      #
      # Start GNOME session
      exec gnome-session
    '';
  };

}