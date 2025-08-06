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

  # Import home-manager for user configuration
  home-manager.users.${user} = import ../../modules/server/home-manager.nix;

  # Full system configuration with GRUB bootloader for BIOS - optimized
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
    # Full kernel modules for all hardware
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "iwlwifi" "virtio_blk" "virtio_pci" "virtio_net" ];
    kernelModules = [ "uinput" "iwlwifi" "virtio_blk" "virtio_pci" "virtio_net" ];
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

  # System optimizations for faster performance
  powerManagement.cpuFreqGovernor = "performance";
  
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

  # Nix configuration - optimized for faster builds
  nix = {
    settings = {
      allowed-users = [ "${user}" ];
      trusted-users = [ "@admin" "${user}" ];
      # Multiple substituters for faster downloads
      substituters = [
        "https://nix-community.cachix.org"
        "https://cache.nixos.org"
        "https://nixpkgs-wayland.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf7dCedXfElpDXJmpnNR7e1yR4a7e+jQppM="
        "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
      ];
      # Parallel builds and downloads
      max-jobs = "auto";
      cores = 0;
      # Faster evaluation
      auto-optimise-store = true;
      # Use binary caches more aggressively
      builders-use-substitutes = true;
    };
    extraOptions = ''
      experimental-features = nix-command flakes
      accept-flake-config = true
    '';
    gc = {
      automatic = true;
      dates = "14d";
      options = "--delete-older-than 30d";
    };
  };

  # Enable zsh at system level
  programs.zsh.enable = true;

  # Full packages - all essentials
  environment.systemPackages = with pkgs; [
    git
    vim
    wget
    curl
    htop
    tree
    tmux
    ripgrep
    fd
    bat
    eza
    fzf
    jq
    ncdu
    rsync
    unzip
    zip
  ];

  system.stateVersion = "21.05";
} 