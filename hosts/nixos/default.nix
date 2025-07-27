{ config, inputs, pkgs, ... }:

let user = "david";
  keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p" ]; in
{
  imports = [
    ../../modules/nixos/disk-config.nix
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
    };
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "iwlwifi" ];
    kernelModules = [ "uinput" "iwlwifi" ];
    
    # Hibernation support
    resumeDevice = "/dev/disk/by-label/swap";
    kernelParams = [ "resume_offset=0" ];
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  networking = {
    hostName = "hodr"; # Define your hostname.
    useDHCP = false;
    networkmanager.enable = true; # Enable NetworkManager
  };

  hardware = {
    # enableAllFirmware = true; # Enable all firmware - DISABLED FOR TESTING
    # graphics.enable = true; # Update from opengl.enable to graphics.enable - DISABLED FOR TESTING
    # ledger.enable = true; # DISABLED FOR TESTING
    # firmware = [ pkgs.linux-firmware ]; # Include firmware - DISABLED FOR TESTING
  };

  # virtualisation.docker.enable = true; # DISABLED FOR TESTING

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

   # programs.hyprland.enable = true; # DISABLED FOR TESTING
  services = { 
    # xserver = {
    #   enable = true;
    #   displayManager.gdm.enable = true;
    #   desktopManager.gnome.enable = true;
    #   xkb.layout = "us"; # Update from layout to xkb.layout
    #   xkb.options = "ctrl:nocaps"; # Update from xkbOptions to xkb.options
    # }; # DISABLED FOR TESTING
    # libinput.enable = true; # Move from xserver.libinput.enable to services.libinput.enable - DISABLED FOR TESTING
    openssh.enable = true;

    # gvfs.enable = true; # DISABLED FOR TESTING
    # tumbler.enable = true; # DISABLED FOR TESTING
  };

  # Swap file configuration for hibernation - DISABLED FOR TESTING
  # swapDevices = [{
  #   device = "/swap/swapfile";
  #   size = 0; # Will be set to RAM size during installation
  # }];

  # fonts.packages = with pkgs; [
  #     noto-fonts
  #     noto-fonts-cjk-sans
  #     noto-fonts-emoji
  #     fira-code
  #     inconsolata
  #     dejavu_fonts
  #     feather-font
  #     jetbrains-mono
  #     font-awesome
  #     nerd-fonts.fira-code
  # ]; # DISABLED FOR TESTING

  # Turn on flag for proprietary software
  nix = {
    nixPath = [ "nixos-config=/home/${user}/.local/share/src/nix:/etc/nixos" ];
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

  system.stateVersion = "21.05"; # Don't change this
}
