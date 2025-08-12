# Terminal multiplexer configurations (tmux and zellij)
{ config, pkgs, lib, ... }:

{
  programs = {
    tmux = {
      enable = true;
      extraConfig = builtins.readFile ../../config/tmux/tmux.conf;
    };

    zellij = {
      enable = true;
      settings = {
        default_layout = "compact";
        pane_frames = false;
        theme = "ansi";
        simplified_ui = true;
        hide_session_name = true;
      };
    };
  };

  # Link configuration files
  home.file = {
    ".config/tmux".source = ../../config/tmux;
    ".config/zellij".source = ../../config/zellij;
  };
}
