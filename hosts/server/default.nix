{ config, inputs, pkgs, lib, ... }:

let user = "david";
  keys = [ 
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p"
    # Add your SSH public key here
    # "ssh-ed25519 YOUR_PUBLIC_KEY_HERE"
  ]; in
{
  imports = [
    ../../modules/server/disk-config.nix # Use server-specific disk config
    ../../modules/shared
  ];

  # Use GRUB boot loader for legacy BIOS
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";
        useOSProber = false;
        forceInstall = true;
        # BIOS-specific settings for single partition
        efiSupport = false;
        gfxmodeBios = "text";
        splashImage = null;
      };
    };
    kernelPackages = pkgs.linuxPackages;  # Use stable kernel instead of latest
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "virtio" "virtio_pci" "virtio_net" "virtio_blk" ];
    kernelModules = [ "uinput" ];  # Remove iwlwifi (no WiFi on servers)
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  networking = {
    hostName = "loki"; # Define your hostname.
    useDHCP = lib.mkForce false;  # Force false when using NetworkManager
    networkmanager.enable = true; # Enable NetworkManager
    # Generic server firewall
    firewall.enable = true;
    firewall.allowedTCPPorts = [ 22 80 443 ]; # SSH, HTTP, HTTPS
  };

  hardware = {
    enableAllFirmware = true; # Enable for broad hardware compatibility
    firmware = [ pkgs.linux-firmware ]; # Include firmware for various server hardware
  };

  virtualisation.docker.enable = true;

  programs.zsh.enable = true; # Enable zsh

  users.users = {
    "${user}" = {
      isNormalUser = true;
      extraGroups = [
        "wheel" # Enable 'sudo' for the user.
        "admin" # Admin group for additional privileges
        "docker"
        "networkmanager"
      ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = keys;
      # Create user directories with proper permissions
      createHome = true;
      home = "/home/${user}";
    };

    root = {
      openssh.authorizedKeys.keys = keys;
    };
  };

  security.sudo = {
    enable = true;
    extraRules = [{
      commands = [
        {
          command = "${pkgs.systemd}/bin/reboot";
          options = [ "NOPASSWD" ];
        }
      ];
      groups = [ "wheel" ];
    }];
  };

  services = { 
    openssh.enable = true;
    # Essential system services
    dbus.enable = true;
    # System utilities
    udev.enable = true;
  };



  # Turn on flag for proprietary software
  nix = {
    nixPath = [ "nixos-config=/home/${user}/.local/share/src/nix:/etc/nixos" ];
    settings = {
      allowed-users = [ "${user}" ];
      trusted-users = [ "@admin" "${user}" ];
      substituters = [ "https://nix-community.cachix.org" "https://cache.nixos.org" ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
      download-buffer-size = 16777216; # 16MB buffer size
    };

    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    gc = {
      automatic = true;
      dates = "14d";
      options = "--delete-older-than 30d";
    };
  };

  # Manages keys and such
  programs = {
    gnupg.agent.enable = true;
  };

  environment.systemPackages = with pkgs; [
    # Minimum required packages for initial setup
    git
    openssh
  ];

  # Environment variables for API keys
  environment.variables = {
    # Add your API keys here
    # GITHUB_TOKEN = "your-github-token";
    # DOCKER_API_KEY = "your-docker-key";
    # CUSTOM_API_KEY = "your-api-key";
    # GitHub CLI configuration
    GH_CONFIG_DIR = "/home/${user}/.config/gh";
  };



  # Set up nix directory and remote
  system.activationScripts = {
    setupNixDir = ''
      # Create nix directory in home
      mkdir -p /home/${user}/nix
      chown ${user}:users /home/${user}/nix
      
      # Copy current nix config to home directory
      if [ ! -d /home/${user}/nix/.git ]; then
        cp -r /etc/nixos/* /home/${user}/nix/
        chown -R ${user}:users /home/${user}/nix
        
        cd /home/${user}/nix
        git init
        git add .
        git commit -m "Initial commit from installation"
        
        # Add remote with your actual repo URL
        git remote add origin https://github.com/xlrinn/nix.git
        
        # Set up git configuration for the user
        git config --global user.name "david"
        git config --global user.email "xlrin.morgan@gmail.com"
        
        # Note: GitHub CLI will handle authentication automatically
        # No manual SSH key setup needed!
      fi
    '';
  };

  system.stateVersion = "21.05"; # Don't change this
}
