{ config, inputs, pkgs, lib, ... }:

let user = "david";
  keys = [ 
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p"
    # Add your SSH public key here
    # "ssh-ed25519 YOUR_PUBLIC_KEY_HERE"
  ]; in
{
  imports = [
    ../../modules/server/disk-config.nix
  ];

  # Use GRUB boot loader for MBR/BIOS
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";  # Install GRUB to MBR
        useOSProber = false;
        efiSupport = false;
        gfxmodeBios = "text";
        splashImage = null;
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
    useDHCP = lib.mkForce false;  # Force false when using NetworkManager
    networkmanager.enable = true; # Enable NetworkManager
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

  system.stateVersion = "21.05"; # Don't change this
}
