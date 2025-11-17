{ config, inputs, pkgs, lib, secrets, ... }:

# Legacy/alternate workstation profile. This mirrors the main `hosts/nixos/default.nix`
# configuration but is not referenced by `flake.nix` unless you explicitly swap it into the
# outputs. It remains for experimentation and is documented thoroughly for quick edits.
let
  user = "david"; # Primary login user replaced by installer tooling.
  keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p"
  ];
  # sopsFile = "/var/lib/sopswarden/secrets.yaml"; # Example secrets location.

  # Try to select a matching Framework hardware profile if present in nixos-hardware inputs.
  fwMods = inputs.nixos-hardware.nixosModules or {};
  fwCandidates = [
    "framework-11th-gen-intel"
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
  imports =
    [
      ../../modules/nixos/disk-config.nix
      ../../modules/nixos/hardware.nix
      ../../modules/shared
    ]
    ++ lib.optionals (fwModule != null) [ fwModule ];

  # Boot configuration identical to the main workstation profile.
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
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
    initrd.kernelModules = [ "virtio_blk" "virtio_console" "virtio_pci" "virtio_scsi" ];
    kernelModules = [ "uinput" "virtio_balloon" "virtio_net" "virtio_rng" ];
    kernelParams = [ "loglevel=4" "i915.enable_psr=0" ];
    # boot.resumeDevice = "/dev/disk/by-partuuid/<uuid>"; # Fill after install if hibernating.
  };

  time.timeZone = "America/New_York";

  fileSystems."/" = lib.mkForce {
    device = "/dev/disk/by-label/NIXOS_ROOT";
    fsType = "ext4";
  };
  fileSystems."/boot" = lib.mkForce {
    device = "/dev/disk/by-label/NIXOS_BOOT";
    fsType = "vfat";
  };

  networking =
    let HN = "%HOST%"; in
    ({
      hostName = lib.mkDefault "nixos";
      useDHCP = lib.mkDefault true;
      networkmanager.enable = true;
      firewall = {
        enable = true;
        allowedTCPPorts = [ 22 ];
      };
      wireless.enable = false;
      interfaces.${config.networking.primaryInterface or ""} =
        lib.mkIf (config.networking.useDHCP != false) {};
    }
    // lib.mkIf (HN != "%HOST%") { hostName = HN; });

  hardware = {
    enableAllFirmware = true;
    graphics.enable = true;
    opengl.enable = true;
    opengl.extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vaapiVdpau
      libvdpau-va-gl
    ];
    ledger.enable = true;
  };

  my.hardware = {
    isLaptop = true;
    profilePath = lib.mkDefault null;
  };

  virtualisation.docker.enable = true;
  programs.zsh.enable = true;
  programs.hyprland.enable = true; # Keep Hyprland enabled alongside GNOME/COSMIC sessions.

  users.users = {
    "${user}" = {
      isNormalUser = true;
      extraGroups = [ "wheel" "docker" "networkmanager" ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = keys;
      initialPassword = "6!y2c87T";
      createHome = true;
      home = "/home/${user}";
    };

    root = {
      openssh.authorizedKeys.keys = keys;
      initialPassword = "6!y2c87T";
    };
  };

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

  services = {
    xserver = {
      enable = true;
      xkb.layout = "us";
      xkb.options = "ctrl:nocaps";
      videoDrivers = [ "modesetting" ];
    };

    displayManager.gdm.enable = true; # GNOME display manager.

    desktopManager = {
      gnome.enable = true;
      cosmic.enable = true;
      plasma6.enable = false;
    };

    libinput.enable = true;
    qemuGuest.enable = lib.mkDefault true;
    gvfs.enable = true;
    tumbler.enable = true;

    logind = {
      lidSwitch = "hibernate";
      lidSwitchDocked = "ignore";
      settings.Login = { HandleLidSwitchExternalPower = "hibernate"; };
    };
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  services.spice-vdagentd.enable = lib.mkDefault true;

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

  nix = {
    nixPath = [ "nixos-config=/home/${user}/nix:/etc/nixos" ];
    settings = {
      allowed-users = [ "${user}" ];
      trusted-users = [ "@admin" "${user}" ];
      substituters = [ "https://nix-community.cachix.org" "https://cache.nixos.org" ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
      max-jobs = "auto";
      cores = 0;
      builders-use-substitutes = true;
      download-buffer-size = 268435456;
    };

    package = pkgs.nix;
    # experimental-features configured in modules/shared/default.nix

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
  };

  programs = {
    gnupg.agent.enable = true;
    dconf.enable = true;
  };

  environment.systemPackages = with pkgs; [
    gitAndTools.gitFull
    inetutils
    neovim
    noto-fonts-emoji
    pciutils
  ];

  powerManagement.cpuFreqGovernor = "performance";

  environment.variables = {
    NIX_BUILD_CORES = "0";
    NIX_OPTIONS = "--cores 0";
  };

  home-manager.backupFileExtension = "backup";

  # systemd.tmpfiles ensures ~/.ssh exists on first boot.
  systemd.tmpfiles.rules = [ "d /home/${user}/.ssh 0700 ${user} users -" ];

  system.stateVersion = "21.05";
}
