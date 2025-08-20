{ config, inputs, pkgs, lib, ... }:

let user = "david";
  keys = [ 
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p"
    # Add your SSH public key here
    # "ssh-ed25519 YOUR_PUBLIC_KEY_HERE"
  ]; in
{
  imports = [
    ../../modules/nixos/disk-config.nix  # Use same EFI disk config as desktop
    ../../modules/shared  # Only shared terminal configs, no desktop stuff
  ];

  # Use the systemd-boot EFI boot loader (same as desktop)
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 42;
      };
      efi.canTouchEfiVariables = true;
      # Faster boot
      timeout = 1;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    kernelModules = [ ];
    # Speed optimizations
    kernelParams = [ "quiet" "loglevel=3" ];
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
    enableAllFirmware = true; # Enable firmware for better hardware compatibility
  };

  # Enable Docker for server workloads
  virtualisation.docker.enable = true;

  # Enable zsh for better shell experience
  programs.zsh.enable = true;

  # programs.zsh.enable = true; # Disable zsh to reduce memory usage

  users.users = {
    "${user}" = {
      isNormalUser = true;
      extraGroups = [
        "wheel" # Enable 'sudo' for the user.
        "networkmanager"
        "docker" # Add docker group access
      ];
      shell = pkgs.zsh; # Use zsh instead of bash
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
    settings = {
      allowed-users = [ "${user}" ];
      trusted-users = [ "${user}" ];
    };
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Enable useful programs for server environment
  programs = {
    gnupg.agent.enable = true; # Enable GPG agent for security
    git.enable = true; # Enable git globally
  };

  environment.systemPackages = (import ../../modules/server/packages.nix { inherit pkgs; });

  # Environment variables for API keys
  environment.variables = {
    # Add your API keys here
    # GITHUB_TOKEN = "your-github-token";
    # DOCKER_API_KEY = "your-docker-key";
    # CUSTOM_API_KEY = "your-api-key";
    # GitHub CLI configuration
    GH_CONFIG_DIR = "/home/${user}/.config/gh";
  };



  # Minimal activation scripts
  system.activationScripts = {
    setupNixDir = ''
      mkdir -p /home/${user}
      chown ${user}:users /home/${user}
    '';
  };

  system.stateVersion = "21.05"; # Don't change this
}
