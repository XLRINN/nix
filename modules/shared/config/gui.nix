# GUI applications configuration
{ config, pkgs, lib, ... }:

let
  # Detect if this is a server environment
  isServer = let
    hostName = config.networking.hostName or "unknown";
  in hostName == "loki" || hostName == "server";
in

lib.mkIf (!isServer) {
  programs.alacritty = {
    enable = true;
    settings = builtins.fromTOML (builtins.readFile ../config/alacritty/alacritty.toml);
  };

  # Link configuration files
  home.file.".config/alacritty" = {
    source = ../config/alacritty;
    recursive = true;
  };
}
