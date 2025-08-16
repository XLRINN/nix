{ pkgs, config, ... }:

let
  user = "david";
  xdg_configHome = "/home/${user}/.config";
  xdg_dataHome = "/home/${user}/.local/share";
  xdg_stateHome = "/home/${user}/.local/state";
in
{
  # Copy configuration files to user's home directory
  ".config/nvim/init.lua".source = ./config/nvim/init.lua;
  ".config/nvim/default.nix".source = ./config/nvim/default.nix;
  
  ".config/yazi/yazi.toml".source = ./config/yazi/yazi.toml;
  
  ".config/alacritty/alacritty.toml".source = ./config/alacritty/alacritty.toml;
  
  ".config/ranger/rifle.conf".source = ./config/ranger/rifle.conf;
  
  ".config/ghostty/config".source = ./config/ghostty/config;
  
  ".config/tmux/tmux.conf".source = ./config/tmux/tmux.conf;
  
  ".config/btop/btop.conf".source = ./config/btop/btop.conf;
  
  ".config/htop/htoprc".source = ./config/htop/htoprc;
  
  ".config/neofetch/config.conf".source = ./config/neofetch/config.conf;
  
  ".config/lua/init.lua".source = ./config/lua/init.lua;
  ".config/lua/plugins.lua".source = ./config/lua/plugins.lua;
  
  ".config/shell/p10k.zsh".source = ./config/shell/p10k.zsh;
  
  ".config/power10k/p10k.zsh".source = ./config/power10k/p10k.zsh;
  
  # Copy zellij configuration
  ".config/zellij/config.kdl".source = ./config/zellij.nix;
  
  # Copy Oh My Posh themes
  ".config/posh/".source = ./config/posh;
}
