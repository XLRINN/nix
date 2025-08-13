{ config, inputs, pkgs, ... }:

let user = "david";
  keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p" ]; in
{
  imports = [
    ./disk-config.nix
    ../shared
  ];

  # Use GRUB boot loader for BIOS.
  boot = {
    loader = {
      grub = {
        enable = true;
        device = "/dev/sda";
        useOSProber = false;
      };
      # Faster boot
      timeout = 1;
    };
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    kernelModules = [ "uinput" ];
    # Speed optimizations - Serial console for Proxmox
    kernelParams = [ "console=ttyS0,115200" "console=ttyS0" "vga=normal" "nomodeset" ];
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  networking = {
    hostName = "loki"; # Define your hostname.
    #useDHCP = true; # Enable DHCP for automatic IP assignment
    networkmanager.enable = true; # Enable NetworkManager
  };

  hardware = {
    enableAllFirmware = true; # Enable all firmware
    graphics.enable = false; # Disable graphics for server
    ledger.enable = true;
    firmware = [ pkgs.linux-firmware ]; # Include firmware
  };

  virtualisation.docker.enable = true;

  programs.zsh.enable = true; # Enable zsh

  users.users = {
    "${user}" = {
      isNormalUser = true;
      extraGroups = [
        "wheel" # Enable 'sudo' for the user.
        "docker"
        "networkmanager"
      ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = keys;
      # Set initial password to your user password
      initialPassword = "david";
      # Create user directories with proper permissions
      createHome = true;
      home = "/home/${user}";
    };

    root = {
      openssh.authorizedKeys.keys = keys;
      # Set initial root password to your user password
      initialPassword = "david";
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

  # Disable GUI components for server
  services = { 
    # Disable X server for server environment
    xserver.enable = false;
    
    # Enable SSH for remote access
    openssh = {
      enable = true;
      settings = {
        # Security settings
        PasswordAuthentication = true;  # Allow password auth for initial setup
        PermitRootLogin = "no";        # Disable root login
        PubkeyAuthentication = true;   # Enable key-based auth
        AuthorizedKeysFile = ".ssh/authorized_keys";
        # Performance settings
        UseDNS = false;                # Faster connections
        GSSAPIAuthentication = false;  # Disable GSSAPI
        # Connection settings
        ClientAliveInterval = 60;      # Keep connections alive
        ClientAliveCountMax = 3;
        MaxStartups = "10:30:60";      # Limit concurrent connections
      };
    };
    
    # Enable getty for console access (TTY1-TTY6)
    getty = {
      enable = true;
    };
    
    # Enable fail2ban for security
    # fail2ban.enable = true;
  };

  # Firewall disabled for live environment compatibility
  # networking.firewall = {
  #   enable = true;
  #   allowedTCPPorts = [ 22 ];  # SSH only for now
  #   allowedUDPPorts = [ ];
  # };

  # Turn on flag for proprietary software
  nix = {
    # nixPath = [ "nixos-config=/home/${user}/.local/share/src/nix:/etc/nixos" ];
    settings = {
      allowed-users = [ "${user}" ];
      trusted-users = [ "@admin" "${user}" ];
      # substituters = [ "https://nix-community.cachix.org" "https://cache.nixos.org" ];
      # trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
      # Speed optimizations
      max-jobs = "auto";
      cores = 0;
      builders-use-substitutes = true;
      # Increase download buffer for faster downloads
      download-buffer-size = 134217728;
    };

    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    # gc = {
    #   automatic = true;
    #   dates = "14d";
    #   options = "--delete-older-than 30d";
    # };
  };

  # Manages keys and such
  # programs = {
  #   gnupg.agent.enable = true;
  # };

  environment.systemPackages = with pkgs; [
    gitAndTools.gitFull
    vim
    wget
    curl
    htop
    tmux
    # Server-specific packages
    # nginx
    # certbot
    # Monitoring tools
    # iotop
    # nethogs
    # Network tools
    # nmap
    # tcpdump
    # Development tools
    # nodejs
    # python3
    # Container tools
    # docker-compose
    # Basic CLI tools
    # ripgrep
    # fd
    # bat
    # exa
    # fzf
    # zoxide
    # Terminal multiplexer
    # zellij
    # Development tools
    # direnv
    # nix-direnv
  ];

  # System optimizations for server
  # powerManagement.cpuFreqGovernor = "performance";
  
  # Enable automatic security updates
  # system.autoUpgrade = {
  #   enable = true;
  #   channel = "https://nixos.org/channels/nixos-unstable";
  # };


}
