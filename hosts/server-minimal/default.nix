{ config, pkgs, lib, ... }:

{
  # Minimal server configuration for initial installation
  imports = [ ];

  # Basic system configuration - matches server install script
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    efiSupport = false;  # BIOS boot
  };

  # Use label-based filesystem (matches server script)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos-root";
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # Minimal networking
  networking = {
    hostName = "server";
    useDHCP = lib.mkForce false;
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];  # SSH only
    };
  };

  # Basic user setup
  users.users.david = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p"
    ];
    createHome = true;
    home = "/home/david";
  };

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YCAerNVka1ZFJxhnU4G74TmS+p"
    ];
  };

  # Essential services
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";  # Allow root login with key
      PasswordAuthentication = false;
    };
  };
  
  # Enable sudo
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
  
  # Basic packages
  environment.systemPackages = with pkgs; [
    git
    vim
    nano
    curl
    wget
    htop
  ];

  # Nix configuration
  nix = {
    settings = {
      allowed-users = [ "david" ];
      trusted-users = [ "david" ];
    };
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  system.stateVersion = "23.11";
}
