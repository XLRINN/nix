# Zellij configuration
{ config, pkgs, lib, ... }:

{
  programs.zellij = {
    enable = true;
    settings = {
      default_layout = "compact";
      pane_frames = false;
      theme = "ansi";
      simplified_ui = true;
      hide_session_name = true;
    };
  };

  home.file.".config/zellij" = {
    source = ../../config/zellij;
    recursive = true;
  };
}
