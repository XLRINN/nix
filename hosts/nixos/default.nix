{ config, inputs, pkgs, lib, secrets, ... }:

let
  user = "david";
  keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p" ];

  # Probe for available Framework modules to avoid version-specific errors and deprecations.
  fwMods = inputs.nixos-hardware.nixosModules or {};
  # For 10th-gen Intel, try 11th-gen as closest match, then fallbacks
  fwCandidates = [
    "framework-11th-gen-intel"
    "framework-13th-gen-intel"
    "framework-12th-gen-intel"
  ];
  availableFw = builtins.filter (name: builtins.hasAttr name fwMods) fwCandidates;
  fwModule = if availableFw == [] then null else (builtins.getAttr (builtins.head availableFw) fwMods);
  # Cosmic temporarily removed.
in
{
  imports = [
  ../../modules/nixos/disk-config.nix
    ../../modules/nixos/hardware.nix
    ../../modules/shared
  ]
  ++ lib.optionals (fwModule != null) [ fwModule ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;  # Keep fewer boot entries
      };
      efi.canTouchEfiVariables = true;
      # Faster boot
      timeout = 1;
    };
    initrd.availableKernelModules = [
      "xhci_pci"
      "ahci"
      "nvme"
      "usbhid"
      "usb_storage"
      "sd_mod"
      "virtio_blk"
      "virtio_pci"
      "virtio_scsi"
      "virtio_net"
    ];
    initrd.kernelModules = [
      "virtio_blk"
      "virtio_console"
      "virtio_pci"
      "virtio_scsi"
    ];
    kernelModules = [ "uinput" "virtio_balloon" "virtio_net" "virtio_rng" ];
  # Kernel params: remove 'quiet' for debugging; add i915 quirk to mitigate black screen (Panel Self Refresh off)
  kernelParams = [ "loglevel=4" "i915.enable_psr=0" ];
  # Enable hibernation: set after install with the actual PARTUUID of the swap partition, e.g.
  # lsblk -no PARTUUID /dev/yourdisk2
  # boot.resumeDevice = "/dev/disk/by-partuuid/<uuid>";
  # (Temporarily unset due to swap label removal.)
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  networking = {
    hostName = "hodr"; # Define your hostname.
    useDHCP = lib.mkDefault true;
    networkmanager.enable = true; # Enable NetworkManager
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
    wireless.enable = false; # Make sure NetworkManager is managing wifi, not wpa_supplicant
  # If %IP% token replaced with 'dhcp' keep defaults, else set static /24
  interfaces.${config.networking.primaryInterface or ""} = lib.mkIf (config.networking.useDHCP != false) {};
  };

  hardware = {
    enableAllFirmware = true; # Enable all firmware
    graphics.enable = true;   # Wayland/X11 GL stack
    # Ensure classic option for wider compatibility (kept alongside graphics.enable)
    opengl.enable = true;
    opengl.extraPackages = with pkgs; [ intel-media-driver intel-vaapi-driver vaapiVdpau libvdpau-va-gl ];
    ledger.enable = true;
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
        {
          command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild";
          options = [ "NOPASSWD" ];
        }
        {
          command = "${pkgs.nix}/bin/nix-collect-garbage";
          options = [ "NOPASSWD" ];
        }
        {
          command = "ALL";
          options = [ "NOPASSWD" ];
        }
      ];
      groups = [ "wheel" ];
    }];
  };

  # Enable Hyprland (alongside GNOME; choose session at GDM login)
  programs.hyprland.enable = true;

  services = { 
    xserver = {
      enable = true;
      xkb.layout = "us"; # Update from layout to xkb.layout
      xkb.options = "ctrl:nocaps"; # Update from xkbOptions to xkb.options
    };
    displayManager.gdm = {
      enable = true;
      wayland = true; # Enable Wayland so Hyprland session appears
    };
    desktopManager.gnome.enable = true;
    xserver.videoDrivers = [ "modesetting" ];
  # cosmic desktop disabled
    libinput.enable = true; # Move from xserver.libinput.enable to services.libinput.enable
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = false;
      };
    };

    qemuGuest.enable = true;

    gvfs.enable = true;
    tumbler.enable = true;
    # Hibernate instead of suspend on lid close (overrides default from hardware module)
    logind = {
      lidSwitch = "hibernate";
      lidSwitchDocked = "ignore"; # don't hibernate when docked/externals attached
      # Updated from deprecated extraConfig to settings.Login
      settings.Login = {
        HandleLidSwitchExternalPower = "hibernate";
      };
    };
  };

  services."spice-vdagentd".enable = lib.mkDefault true;

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
      dates = "daily";
      options = "--delete-older-than 7d";
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
    pciutils  # Provides lspci for hardware diagnostics
  ];



  # Performance optimizations
  powerManagement.cpuFreqGovernor = "performance";
  
  # Faster package installation
  environment.variables = {
    NIX_BUILD_CORES = "0";
    NIX_OPTIONS = "--cores 0";
  };

  # Home Manager configuration
  home-manager.backupFileExtension = "backup";

  # Sopswarden secrets configuration (recommended secrets management)
  # Temporarily disabled sopswarden to allow system to build without Bitwarden secrets
  # Uncomment and configure when ready for secrets integration again.
  # services.sopswarden = {
  #   enable = true;
  #   secrets = {
  #     tailscale-auth-key = { name = "Tailscale"; field = "auth-key"; };
  #     openrouter-api-key = { name = "OpenRouter API"; field = "api-key"; };
  #     github-token = { name = "GitHub Token"; field = "token"; };
  #   };
  # };

  system.stateVersion = "21.05"; # Don't change this
}
