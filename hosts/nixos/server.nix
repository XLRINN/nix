{ config, inputs, pkgs, ... }:

let user = "david";
    keys = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ2RS6TW8svjJHpr0dwZAw+xPex0r1EY6GSHPwlUOsGD xlrin.morgan@gmail.com"
    ]; 
in
{
  imports = [
    ../../modules/nixos/disk-config.nix
  ];

  # Basic system configuration
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
  };

  # Network configuration
  networking = {
    hostName = "loki";
    useDHCP = false;
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  # Time zone and locale
  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  # User configuration
  users.users = {
    "${user}" = {
      isNormalUser = true;
      extraGroups = [ "wheel" "networkmanager" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = keys;
      createHome = true;
      home = "/home/${user}";
    };
  };

  # Sudo configuration
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

  # Minimal SSH service
  services.openssh = {
    enable = true;
    settings = {
      PubkeyAuthentication = true;
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  # Nix configuration
  nix = {
    settings = {
      allowed-users = [ "${user}" ];
      trusted-users = [ "@admin" "${user}" ];
      substituters = [ "https://nix-community.cachix.org" "https://cache.nixos.org" ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
    };
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      dates = "14d";
      options = "--delete-older-than 30d";
    };
  };

  # Enable zsh at system level
  programs.zsh.enable = true;

  # Minimal packages - just essentials
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    htop
    tree
  ];

  system.stateVersion = "21.05";
} 