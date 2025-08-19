{ config, pkgs, lib, ... }:

let
  user = "david";
  shared-files = import ../shared/files.nix { inherit config pkgs; };
in
{
  home = {
    enableNixpkgsReleaseCheck = false;
    username = "${user}";
    homeDirectory = "/home/${user}";
    packages = pkgs.callPackage ./packages.nix {};
    file = shared-files // import ./files.nix { inherit user; };
    stateVersion = "21.05";
  };

<<<<<<< HEAD
  # Only CLI imports - no GUI components
  imports = [
    # CLI tools
    # ../shared/config/terminal/git.nix
    # ../shared/config/terminal/zsh.nix
    # ../shared/config/terminal/neovim.nix
    # ../shared/config/terminal/tmux.nix
    # ../shared/config/terminal/zellij.nix
    # ../shared/config/terminal/direnv.nix
    # ../shared/config/terminal/monitoring.nix
=======
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
>>>>>>> 0253090 (refactor: remove finish.sh script and enhance server configuration in default.nix, disk-config.nix, home-manager.nix, and packages.nix for improved clarity and functionality)
  ];
}
