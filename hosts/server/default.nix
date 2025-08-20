{ config, inputs, pkgs, ... }:

let user = "david";
  keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p" ]; in
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
    useDHCP = false;
    networkmanager.enable = true; # Enable NetworkManager
  };

  hardware = {
    enableAllFirmware = true; # Enable all firmware
    firmware = [ pkgs.linux-firmware ]; # Include firmware
  };

  virtualisation.docker.enable = true;

  programs.zsh.enable = true; # Enable zsh

  users.users = {
    "${user}" = {
      isNormalUser = true;
      extraGroups = [
        "wheel" # Enable 'sudo' for the user.
        "docker"
        "networkmanager"
      ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = keys;
      # Set initial password (change this after first login)
      initialPassword = "6!y2c87T";
      # Create user directories with proper permissions
      createHome = true;
      home = "/home/${user}";
    };

    root = {
      openssh.authorizedKeys.keys = keys;
      # Set initial root password (change this after first login)
      initialPassword = "6!y2c87T";
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

  # Server services (no desktop environment)
  services = { 
    openssh.enable = true;
    # Essential system services
    dbus.enable = true;
    # System utilities
    udev.enable = true;
  };



  # Turn on flag for proprietary software
  nix = {
    nixPath = [ "nixos-config=/home/${user}/.local/share/src/nixos-config:/etc/nixos" ];
    settings = {
      allowed-users = [ "${user}" ];
      trusted-users = [ "@admin" "${user}" ];
      substituters = [ "https://nix-community.cachix.org" "https://cache.nixos.org" ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
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

  # Enable useful programs for server environment
  programs = {
    gnupg.agent.enable = true; # Enable GPG agent for security
    git.enable = true; # Enable git globally
  };

  environment.systemPackages = (import ../../modules/server/packages.nix { inherit pkgs; });

  system.stateVersion = "21.05"; # Don't change this
}
