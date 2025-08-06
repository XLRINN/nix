{ config, inputs, pkgs, ... }:

let user = "david";
    keys = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ2RS6TW8svjJHpr0dwZAw+xPex0r1EY6GSHPwlUOsGD xlrin.morgan@gmail.com"
    ]; 
in
{
  imports = [
    ../../modules/server/disk-config.nix
  ];

  # Basic system configuration with GRUB bootloader for BIOS - optimized
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/%DISK%";
        forceInstall = true;
        efiSupport = false;
        useOSProber = false;
        # Faster boot
        splashImage = null;
        gfxmodeBios = "text";
      };
      efi.canTouchEfiVariables = false;
    };
    # Use stable kernel for faster boot
    kernelPackages = pkgs.linuxPackages;
    # Essential kernel modules for disk access
    initrd.availableKernelModules = [ "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "virtio_blk" "virtio_pci" "virtio_net" ];
    kernelModules = [ "virtio_blk" "virtio_pci" "virtio_net" ];
    # Faster boot options
    kernelParams = [ "quiet" "loglevel=3" "console=tty0" "console=ttyS0,115200" ];
    # Disable unnecessary services during boot
    initrd.systemd.enable = false;
    # Clean tmp on boot
    tmp.cleanOnBoot = true;
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
      createHome = true;
      home = "/home/${user}";
      initialPassword = "nixos123";  # Set initial password
    };

    root = {
      initialPassword = "nixos123";  # Set initial password
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

  # Conservative settings for Hetzner
  powerManagement.cpuFreqGovernor = "ondemand";
  
  # Disable unnecessary services for faster boot
  services = {
    openssh = {
      enable = true;
      settings = {
        PubkeyAuthentication = false;  # Disable SSH keys
        PasswordAuthentication = true;  # Enable password authentication
        PermitRootLogin = "yes";  # Allow root login with password
      };
    };
  };

  # Disable emergency console to prevent "root account locked" prompt
  systemd.enableEmergencyMode = false;

  # Reduce swappiness for better performance
  boot.kernel.sysctl."vm.swappiness" = 10;

  # Nix configuration - optimized for low-resource systems
  nix = {
    settings = {
      allowed-users = [ "${user}" ];
      trusted-users = [ "@admin" "${user}" ];
      # Single substituter for Hetzner
      substituters = [
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      # Conservative resource usage for Hetzner
      max-jobs = 2;
      cores = 2;
      # Disable aggressive optimizations
      auto-optimise-store = false;
      builders-use-substitutes = false;
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      accept-flake-config = true
    '';
    gc = {
      automatic = true;
      dates = "7d";
      options = "--delete-older-than 14d";
    };
  };

  # Enable zsh at system level
  programs.zsh.enable = true;

  # Ultra-minimal packages for Hetzner
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
  ];

  system.stateVersion = "21.05";
} 