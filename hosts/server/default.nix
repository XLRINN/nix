{ config, inputs, pkgs, lib, ... }:

let user = "david";
  keys = [ 
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p"
    # Add your SSH public key here
    # "ssh-ed25519 YOUR_PUBLIC_KEY_HERE"
  ]; in
{
  # No imports - we'll handle everything manually

  # Manual filesystem configuration using device path (not label)
  fileSystems."/" = {
    device = "/dev/sda2";  # Root partition will be sda2 (after BIOS boot partition)
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # GRUB configuration for BIOS-only systems
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";  # Install to MBR
        useOSProber = false;
        efiSupport = false;  # Explicitly disable EFI for BIOS systems
      };
    };
    kernelPackages = pkgs.linuxPackages;  # Use stable kernel
    initrd.availableKernelModules = [ "ahci" "sd_mod" "virtio" "virtio_pci" "virtio_blk" ];
    kernelModules = [ ];
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  networking = {
    hostName = "loki"; # Define your hostname.
    useDHCP = lib.mkForce true;  # Use DHCP for simplicity
    networkmanager.enable = false; # Disable NetworkManager for server
    # Generic server firewall
    firewall.enable = true;
    firewall.allowedTCPPorts = [ 22 80 443 ]; # SSH, HTTP, HTTPS
  };

  hardware = {
    enableAllFirmware = false; # Minimal firmware for resource efficiency
  };

  # virtualisation.docker.enable = true; # Disable Docker for minimal install

  # programs.zsh.enable = true; # Disable zsh to reduce memory usage

  users.users = {
    "${user}" = {
      isNormalUser = true;
      extraGroups = [
        "wheel" # Enable 'sudo' for the user.
        "networkmanager"
      ];
      shell = pkgs.bash;
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

  # Minimal programs
  programs = {
    # gnupg.agent.enable = true; # Disable to reduce memory usage
  };

  environment.systemPackages = with pkgs; [
    # Minimum required packages for initial setup
    git
    openssh
    vim
    htop
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



  # Minimal activation scripts
  system.activationScripts = {
    setupNixDir = ''
      mkdir -p /home/${user}
      chown ${user}:users /home/${user}
    '';
  };

  system.stateVersion = "24.05"; # Updated to current version
}
