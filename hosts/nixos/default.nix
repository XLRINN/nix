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
  cosmicModules =
    if builtins.hasAttr "nixos-cosmic" inputs && builtins.hasAttr "nixosModules" inputs.nixos-cosmic then
      let nm = inputs.nixos-cosmic.nixosModules; in
      lib.flatten [
        (if builtins.hasAttr "cosmic" nm then [ nm.cosmic ] else [])
        (if builtins.hasAttr "cosmic-desktop" nm then [ nm."cosmic-desktop" ] else [])
        (if builtins.hasAttr "default" nm then [ nm.default ] else [])
      ]
    else [];
  cosmicAvailable = (builtins.length cosmicModules) > 0;
in
{
  imports = [
    ../../modules/nixos/disk-config.nix
    ../../modules/nixos/hardware.nix
    ../../modules/shared
  ]
  ++ cosmicModules
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
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    kernelModules = [ "uinput" ];
    # Speed optimizations
    kernelParams = [ "quiet" "loglevel=3" "console=ttyS0" ];
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
    graphics.enable = true; # Update from opengl.enable to graphics.enable
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

  # Enable Hyprland
  programs.hyprland.enable = true;

  services = { 
    xserver = {
      enable = true;
      xkb.layout = "us"; # Update from layout to xkb.layout
      xkb.options = "ctrl:nocaps"; # Update from xkbOptions to xkb.options
    };
    displayManager.gdm.enable = true;
  desktopManager.gnome.enable = true;
  # Enable Cosmic only if its module exists in the flake inputs.
  desktopManager.cosmic.enable = lib.mkIf cosmicAvailable true;
    libinput.enable = true; # Move from xserver.libinput.enable to services.libinput.enable
    openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = true;
        KbdInteractiveAuthentication = false;
      };
    };

    gvfs.enable = true;
    tumbler.enable = true;
  };

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
