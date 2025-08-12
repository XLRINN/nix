{ config, pkgs, ... }:

{
  # Minimal server configuration for initial installation
  imports = [ ];

  # Basic system configuration
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  # Minimal networking
  networking = {
    hostName = "server";
    useDHCP = true;
  };

  # Basic user setup
  users.users.david = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p"
    ];
  };

  # Essential services
  services.openssh.enable = true;
  
  # Basic packages
  environment.systemPackages = with pkgs; [
    git
    vim
  ];

  system.stateVersion = "23.11";
}
