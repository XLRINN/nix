{ config, pkgs, ... }:

{
  # Minimal server configuration for initial installation
  imports = [ ];

  # Basic system configuration
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    efiSupport = false;  # Explicitly disable EFI for BIOS systems
  };

  fileSystems."/" = {
    device = "/dev/sda2";  # Root partition will be sda2 (after BIOS boot partition)
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
    htop
  ];

  system.stateVersion = "24.05";
}
