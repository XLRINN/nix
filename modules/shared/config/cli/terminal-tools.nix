{config, pkgs, lib, ...}: {
  programs = {
    tmux = {
      enable = true;
      extraConfig = builtins.readFile ../../config/tmux/tmux.conf;
    };

    neovim = {
      enable = true;
      defaultEditor = true;
      extraPackages = with pkgs; [
        stylua
        ripgrep
        curl
      ];
      extraLuaConfig = builtins.readFile ../../config/nvim/init.lua;
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

    htop.enable = true;
    btop.enable = true;
  };

  home.file = {
    ".config/zellij".source = ../../config/zellij;
    ".config/nvim".source = ../../config/nvim;
    ".config/htop".source = ../../config/htop;
    ".config/btop".source = ../../config/btop;
    ".config/tmux".source = ../../config/tmux;
  };
}
