{ config, inputs, pkgs, lib, ... }:

let user = "david";
  keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p" ]; in
{
  imports = [
    ../../modules/nixos/disk-config.nix
  ../../modules/nixos/hardware.nix
  ./hardware-profile.nix
    ../../modules/shared
  ];

  # Use the systemd-boot EFI boot loader.
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
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "iwlwifi" ];
    kernelModules = [ "uinput" "iwlwifi" ];
    # Speed optimizations
    kernelParams = [ "quiet" "loglevel=3" "console=ttyS0" ];
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  networking = {
    hostName = "hodr"; # Define your hostname.
    useDHCP = false;
    networkmanager.enable = true; # Enable NetworkManager
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  hardware = {
    enableAllFirmware = true; # Enable all firmware
    graphics.enable = true; # Update from opengl.enable to graphics.enable
    ledger.enable = true;
    firmware = [ pkgs.linux-firmware ]; # Include firmware
  };

  # Optional: nixos-hardware profile for specific machines.
  # For Framework laptops examples:
  #  - my.hardware.profilePath = "framework/13-inch/intel";
  #  - my.hardware.profilePath = "framework/13-inch/amd/7040";
  my.hardware = {
    isLaptop = true;
    profilePath = lib.mkDefault null;
  };

  virtualisation.docker.enable = true;

  programs.zsh.enable = true; # Enable zsh

  users.users = {
    "${user}" = {
      isNormalUser = true;
      extraGroups = [
        "wheel" # Enable ‘sudo’ for the user.
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

  # Enable Hyprland
  programs.hyprland.enable = true;

  services = { 
    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      xkb.layout = "us"; # Update from layout to xkb.layout
      xkb.options = "ctrl:nocaps"; # Update from xkbOptions to xkb.options
    };
    libinput.enable = true; # Move from xserver.libinput.enable to services.libinput.enable
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = false;
      };
    };

    gvfs.enable = true;
    tumbler.enable = true;
  };

  fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      fira-code
      inconsolata
      dejavu_fonts
      feather-font
      jetbrains-mono
      font-awesome
      nerd-fonts.fira-code
  ];

  # Turn on flag for proprietary software
  nix = {
    nixPath = [ "nixos-config=/home/${user}/nix:/etc/nixos" ];
    settings = {
      allowed-users = [ "${user}" ];
      trusted-users = [ "@admin" "${user}" ];
      substituters = [ "https://nix-community.cachix.org" "https://cache.nixos.org" ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
      # Speed optimizations
      max-jobs = "auto";
      cores = 0;
      builders-use-substitutes = true;
        # Increase download buffer for faster downloads
      # increased from 128MiB to 256MiB to improve large substitute fetches
      download-buffer-size = 268435456;
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

    # Needed for anything GTK related
    dconf.enable = true;
  };

  environment.systemPackages = with pkgs; [
    gitAndTools.gitFull
    inetutils
    neovim
    noto-fonts-emoji
  ];



  # Performance optimizations
  powerManagement.cpuFreqGovernor = "performance";
  
  # Faster package installation
  environment.variables = {
    NIX_BUILD_CORES = "0";
    NIX_OPTIONS = "--cores 0";
  };

  system.stateVersion = "21.05"; # Don't change this
}
