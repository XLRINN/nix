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
    # Minimal kernel modules for server-only
    initrd.availableKernelModules = [ "ahci" "nvme" "sd_mod" "virtio_blk" "virtio_pci" "virtio_net" ];
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

  # Performance settings for maximum compatibility
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

  # Server-specific optimizations
  boot.kernel.sysctl = {
    "vm.swappiness" = 10;
    "net.core.rmem_max" = 134217728;
    "net.core.wmem_max" = 134217728;
    "net.ipv4.tcp_rmem" = "4096 87380 134217728";
    "net.ipv4.tcp_wmem" = "4096 65536 134217728";
    "net.ipv4.tcp_congestion_control" = "bbr";
    "net.core.default_qdisc" = "fq";
  };

  # Nix configuration - optimized for low-resource Hetzner
  nix = {
    settings = {
      allowed-users = [ "${user}" ];
      trusted-users = [ "@admin" "${user}" ];
      # Conservative settings for 4GB RAM
      max-jobs = 1;
      cores = 1;
      # Use binary caches aggressively to avoid builds
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nix-community.cachix.org-1:mB9FSh9qf7dCedXfElpDXJmpnNR7e1yR4a7e+jQppM="
      ];
      # Conservative memory settings
      builders-use-substitutes = true;
      auto-optimise-store = true;
      # Reduce memory usage
      max-silent-time = 3600;
      build-timeout = 7200;
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

  # Minimal CLI packages for server-only Hetzner
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
    fzf
    jq
    ncdu
    rsync
    unzip
    # CLI-only tools - no GUI dependencies
    micro  # Lightweight editor
    neofetch  # System info
    glances  # System monitoring
    iftop  # Network monitoring
    iotop  # I/O monitoring
  ];

  system.stateVersion = "21.05";
} 