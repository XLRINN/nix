{ config, pkgs, lib, ... }:

{
  # User configuration
  home.username = "david";
  home.homeDirectory = "/home/david";
  home.stateVersion = "23.11";

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Basic shell configuration
  programs.bash = {
    enable = true;
    bashrcExtra = ''
      # Basic aliases
      alias ll='ls -alF'
      alias la='ls -A'
      alias l='ls -CF'
      alias ..='cd ..'
      alias ...='cd ../..'
      
      # System shortcuts
      alias reboot='sudo systemctl reboot'
      alias shutdown='sudo systemctl poweroff'
      alias logs='journalctl -f'
    '';
  };

  # Git configuration
  programs.git = {
    enable = true;
    userName = "david";
    userEmail = "xlrin.morgan@gmail.com";
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
    };
  };

  # Basic packages for server environment
  home.packages = with pkgs; [
    # Text editors
    vim
    nano
    
    # System monitoring
    htop
    btop
    
    # Network utilities
    curl
    wget
    
    # File utilities
    tree
    rsync
    
    # Development basics
    git
  ];
}
