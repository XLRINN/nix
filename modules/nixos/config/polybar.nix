{ config, pkgs, lib, ... }:

let
  user = "david";
  xdg_configHome = "/home/${user}/.config";

  polybar-user_modules = builtins.readFile (pkgs.substituteAll {
    src = ./polybar/user_modules.ini;
    packages = "${xdg_configHome}/polybar/bin/check-nixos-updates.sh";
    searchpkgs = "${xdg_configHome}/polybar/bin/search-nixos-updates.sh";
    launcher = "${xdg_configHome}/polybar/bin/launcher.sh";
    powermenu = "${xdg_configHome}/rofi/bin/powermenu.sh";
    calendar = "${xdg_configHome}/polybar/bin/popup-calendar.sh";
  });

  polybar-config = pkgs.substituteAll {
    src = ./polybar/config.ini;
    font0 = "DejaVu Sans:size=12;3";
    font1 = "feather:size=12;3"; # from overlay
  };

  polybar-modules = builtins.readFile ./polybar/modules.ini;
  polybar-bars = builtins.readFile ./polybar/bars.ini;
  polybar-colors = builtins.readFile ./polybar/colors.ini;

in
{
  services.polybar = {
    enable = true;
    config = polybar-config;
    extraConfig = polybar-bars + polybar-colors + polybar-modules + polybar-user_modules;
    package = pkgs.polybarFull;
    script = "polybar main &";
  };
}
