{ config, inputs, pkgs, lib, secrets, ... }:

# Main workstation-oriented NixOS host module.
# This file is wired directly into `flake.nix` for both x86_64-linux and aarch64-linux
# outputs. All core choices (bootloader, filesystem labels, networking defaults, desktop
# environments, and user setup) live here with explanatory comments for quick orientation.
let
  # Primary login user and their SSH keys. Tokens get replaced by installer tooling.
  user = "david";
  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p"
  ];
  # Example sopswarden location for secrets (left commented until configured).
  # sopsFile = "/var/lib/sopswarden/secrets.yaml";

  # Dynamically pick the most appropriate Framework hardware module to avoid evaluation
  # failures when a specific generation is missing from the nixos-hardware input.
  fwMods = inputs.nixos-hardware.nixosModules or {};
  fwCandidates = [
    "framework-11th-gen-intel"  # closest match for older Intel machines
    "framework-13th-gen-intel"
    "framework-12th-gen-intel"
  ];
  availableFw = builtins.filter (name: builtins.hasAttr name fwMods) fwCandidates;
  fwModule =
    if availableFw == []
    then null
    else (builtins.getAttr (builtins.head availableFw) fwMods);
in
{
  # Core module imports shared by all workstation builds plus the optional Framework profile.
  imports =
    [
      ../../modules/nixos/disk-config.nix
      ../../modules/nixos/hardware.nix
      ../../modules/shared
    ]
    ++ lib.optionals (fwModule != null) [ fwModule ];

  # Bootloader and kernel behavior.
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10; # Keep a small set of boot entries to reduce clutter.
      };
      efi.canTouchEfiVariables = true;
      timeout = 1; # Faster boot by shortening the boot menu delay.
    };

    # Initrd support for typical laptops/VMs plus virtio for guests.
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
    initrd.kernelModules = [ "virtio_blk" "virtio_console" "virtio_pci" "virtio_scsi" ];

    # Kernel drivers always loaded in the running system.
    kernelModules = [ "uinput" "virtio_balloon" "virtio_net" "virtio_rng" ];

    # Debug-friendly boot parameters plus an i915 quirk to avoid panel self-refresh issues.
    kernelParams = [ "loglevel=4" "i915.enable_psr=0" ];

    # Hibernation resume target goes here once a swap PARTUUID is known post-install.
    # boot.resumeDevice = "/dev/disk/by-partuuid/<uuid>";
  };

  # Local timezone for the workstation.
  time.timeZone = "America/New_York";

  # Filesystem layout: force labels expected by the installer helpers.
  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-label/NIXOS_ROOT";
    fsType = "ext4";
  };
  fileSystems."/boot" = lib.mkForce {
    device = "/dev/disk/by-label/NIXOS_BOOT";
    fsType = "vfat";
  };

  # Hostname and networking defaults with installer tokens for later replacement.
  networking =
    let HN = "%HOST%"; in
    ({
      hostName = lib.mkDefault "nixos"; # Safe default during evaluation.
      useDHCP = lib.mkDefault true;
      networkmanager.enable = true; # Prefer NetworkManager over wpa_supplicant.
      firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ]; # Keep SSH reachable.
      };
      wireless.enable = false; # Ensure NetworkManager owns Wi‑Fi management.
      interfaces.${config.networking.primaryInterface or ""} =
        lib.mkIf (config.networking.useDHCP != false) {};
    }
    // lib.mkIf (HN != "%HOST%") { hostName = HN; });

  # Hardware tuning and firmware availability for Wayland/X11 and Ledger devices.
  hardware = {
    enableAllFirmware = true;
    graphics.enable = true; # Wayland/X11 GL stack
    opengl.enable = true; # Keep classic OpenGL toggle for broader compatibility.
    opengl.extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
    ledger.enable = true;
  };

  # Optional per-device hints for downstream modules (e.g., laptop-specific tweaks).
  my.hardware = {
    isLaptop = true;
    profilePath = lib.mkDefault null;
  };

  # Developer-friendly defaults: Docker, Zsh, and Hyprland alongside GNOME/COSMIC.
  virtualisation.docker.enable = true;
  programs.zsh.enable = true;
  programs.hyprland.enable = true; # Keep Hyprland available for Wayland testing.

  # User accounts with initial credentials and SSH keys (passwords should be changed ASAP).
  users.users = {
    "${user}" = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" "networkmanager" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = keys;
      initialPassword = "6!y2c87T"; # Replace after first login.
      createHome = true;
      home = "/home/${user}";
    };

    root = {
      openssh.authorizedKeys.keys = keys;
      initialPassword = "6!y2c87T"; # Replace after first login.
    };
  };

  # Passwordless sudo for the wheel group plus a few explicitly whitelisted commands.
  security.sudo = {
    enable = true;
    extraRules = [{
      commands = [
        { command = "${pkgs.systemd}/bin/reboot"; options = [ "NOPASSWD" ]; }
        { command = "${pkgs.nixos-rebuild}/bin/nixos-rebuild"; options = [ "NOPASSWD" ]; }
        { command = "${pkgs.nix}/bin/nix-collect-garbage"; options = [ "NOPASSWD" ]; }
        { command = "ALL"; options = [ "NOPASSWD" ]; }
      ];
      groups = [ "wheel" ];
    }];
  };

  # Display and input stack: GDM + GNOME primary, COSMIC beta enabled, Plasma removed.
  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
      xkb.options = "ctrl:nocaps";
      videoDrivers = [ "modesetting" ];
    };

    displayManager.gdm.enable = true; # GNOME's greeter/session chooser.

    desktopManager = {
      gnome.enable = true; # Primary desktop.
      cosmic.enable = true; # COSMIC beta for evaluation.
      plasma6.enable = false; # Avoid pulling KDE back in.
    };

    libinput.enable = true; # Modern touchpad/mouse stack (Wayland + X11).

    qemuGuest.enable = lib.mkDefault true; # Light VM guest integration.

    gvfs.enable = true; # GNOME virtual filesystem helpers (gphoto2, MTP, SMB, etc.).
    tumbler.enable = true; # Thumbnailing backend for file managers.

    # Power handling: prefer hibernate on lid close to preserve sessions.
    logind = {
      lidSwitch = "hibernate";
      lidSwitchDocked = "ignore"; # Do not hibernate when docked with externals.
      settings.Login = { HandleLidSwitchExternalPower = "hibernate"; };
    };
  };

  # Secure SSH defaults while still allowing key-based root access for recovery.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  services.spice-vdagentd.enable = lib.mkDefault true; # Clipboard/display sync for SPICE guests.

  # Font set chosen to cover Latin, CJK, emoji, and developer-friendly monospace options.
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

  # Nix daemon configuration tuned for developer experience and faster downloads.
  nix = {
    nixPath = [ "nixos-config=/home/${user}/nix:/etc/nixos" ];
    settings = {
      allowed-users = [ "${user}" ];
      trusted-users = [ "@admin" "${user}" ];
      substituters = [ "https://nix-community.cachix.org" "https://cache.nixos.org" ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
      max-jobs = "auto"; # Use all available cores for builds.
      cores = 0; # Allow the daemon to decide based on hardware.
      builders-use-substitutes = true; # Prefer binaries when available.
      download-buffer-size = 268435456; # 256MiB for smoother large downloads.
    };

    package = pkgs.nix; # Stay aligned with the pinned Nix version from inputs.
    # experimental-features set globally via modules/shared/default.nix

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
  };

  # Program-level helpers and configuration backends used by desktops.
  programs = {
    gnupg.agent.enable = true; # GPG agent for signing and SSH.
    dconf.enable = true; # Required by GNOME/COSMIC for settings storage.
  };

  # Always-available CLI tools for rescue and development.
  environment.systemPackages = with pkgs; [
    gitAndTools.gitFull
    inetutils
    neovim
    noto-fonts-emoji
    pciutils # Provides lspci for hardware diagnostics.
  ];

  # Prefer high-performance CPU governor on AC power; tweak if battery life matters more.
  powerManagement.cpuFreqGovernor = "performance";

  # Build parallelism hints for imperative installs (nixos-rebuild switch).
  environment.variables = {
    NIX_BUILD_CORES = "0";
    NIX_OPTIONS = "--cores 0";
  };

  # Home Manager safety: keep backups of files it overwrites.
  home-manager.backupFileExtension = "backup";

  # Example secrets wiring (disabled until sopswarden/sops are configured in the environment).
  # services.sopswarden = {
  #   enable = true;
  #   secrets = {
  #     tailscale-auth-key = { name = "Tailscale"; field = "auth-key"; };
  #     openrouter-api-key = { name = "OpenRouter API"; field = "api-key"; };
  #     github-token = { name = "GitHub Token"; field = "token"; };
  #     github-ssh-key = { name = "GitHub SSH Key"; field = "private-key"; type = "note"; };
  #   };
  # };

  # sops.secrets = {
  #   tailscale-auth-key = { owner = "root"; group = "root"; mode = "0600"; path = "/run/secrets/tailscale-auth-key"; };
  #   openrouter-api-key = { owner = user; group = "users"; mode = "0400"; path = "/run/secrets/openrouter-api-key"; };
  #   github-token = { owner = user; group = "users"; mode = "0400"; path = "/run/secrets/github-token"; };
  #   github-ssh-key = { owner = user; group = "users"; mode = "0600"; path = "/home/${user}/.ssh/id_ed25519"; };
  # };

  # sops = {
  #   defaultSopsFile = lib.mkDefault sopsFile;
  #   validateSopsFiles = lib.mkDefault false;
  # };

  # Ensure the SSH directory exists with correct permissions on first boot.
  systemd.tmpfiles.rules = [ "d /home/${user}/.ssh 0700 ${user} users -" ];

  system.stateVersion = "21.05"; # DO NOT change; preserves compatibility with existing state.
}
