{ config, inputs, pkgs, ... }:

let user = "david";
  keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCcl9C9zuGLD3fVf1QOxfs8GodjyZF79lY1IXAiFbzRDBnvIT0YfpNjMlGP9PB1CvQIpfR4RCs5LNfSBL1B8czU8zJF7sCvQWYdvBLPNP92w6TyyKyRmBPbUrMeRrdAZXpXafM21Z6LA5FzY60nDmkZQIcse+Hjy23eRHN9ca3qkuUvjx/pRKZ9EAbvz3VvUny74tWcUjP+kkRr54aXcNAfL9Mf4dtHdyyJ34rqA/yanyteDIhucLxungfos8IP7sP5TC6XY1VbVoMzE4SlyHTLHnlxRBOE0NB0j+SEXM7E6aOGwvXyRvrPatIODqyKUUMIiteGuxxh49Gu6I1NBuz7NsWBcr1tGRA90/6IeeJTRISTESWf59kBgelUr80hm7sN3bp02Fa+zIB+rq1De2lcdEqO9tzenl0ZlA6a8CNTPkNE5PH0bKRXWIx7zxX+rcfMKnAPe2lQPp0ZpkLsDrx9btxQ5bcbvRddDGgQI2Wu8lJnohakrH/jf/fDNJoe6FBNVVfVsOgJ38P4nqswhZlL1zMDewXlj8PYK83kFC8PJOO7YOAem1Y/0lM/bKO4Rkwr8Zjm/wdkZf9WMZVJkWjZKGKaeDPuxPo38FPvQoM95Px1obV01px0KQVNDs10auEj68v/uzF22BKibREgvOci8MBiKXowUJFaCg9ScIgGlQ== xlrin.morgan@gmail.com
" ]; in
{
  imports = [
    ../../modules/nixos/disk-config.nix
    ../../modules/shared
    ../../modules/shared/cachix
  ];

  # Use the systemd-boot EFI boot loader.
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 42;
      };
      efi.canTouchEfiVariables = true;
    };
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
    # Uncomment for AMD GPU
    # initrd.kernelModules = [ "amdgpu" ];
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = [ "uinput" ];
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  networking = {
    hostName = "HOD"; # Define your hostname.
    useDHCP = false;
    interfaces."%INTERFACE%".useDHCP = false;
    interfaces."%INTERFACE%".ipv4.addresses = [
      {
        address = "192.168.69.10";
        prefixLength = 24;
      }
    ];
    defaultGateway = "192.168.1.1";
    nameservers = [ "8.8.8.8" "8.8.4.4" ];
  };

  # Turn on flag for proprietary software
  nix = {
    nixPath = [ "nixos-config=/home/${user}/.local/share/src/nixos-config:/etc/nixos" ];
    settings.allowed-users = [ "${user}" ];
    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Manages keys and such
  programs = {
    gnupg.agent.enable = true;

    # Needed for anything GTK related
    dconf.enable = true;

    # My shell
    zsh.enable = true;
  };

  # Turn Caps Lock into Ctrl
  layout = "us";
  xkbOptions = "ctrl:nocaps";

  # Better support for general peripherals
  libinput.enable = true;

  # Let's be able to SSH into this machine
  openssh.enable = true;

  gvfs.enable = true; # Mount, trash, and other functionalities
  tumbler.enable = true; # Thumbnail support for images

  # Add docker daemon
  virtualisation = {
    docker = {
      enable = true;
      logDriver = "json-file";
    };
  };

  # It's me, it's you, it's everyone
  users.users = {
    ${user} = {
      isNormalUser = true;
      extraGroups = [
        "wheel" # Enable ‘sudo’ for the user.
        "docker"
      ];
      shell = pkgs.zsh;
      openssh.authorizedKeys.keys = keys;
    };

    root = {
      openssh.authorizedKeys.keys = keys;
    };
  };

  # Don't require password for users in `wheel` group for these commands
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

  fonts.packages = with pkgs; [
    dejavu_fonts
    emacs-all-the-icons-fonts
    feather-font # from overlay
    jetbrains-mono
    font-awesome
    noto-fonts
    noto-fonts-emoji
  ];

  environment.systemPackages = with pkgs; [
    gitAndTools.gitFull
    inetutils
    vscode # Add VSCode to system packages
  ];

  # NFS client configuration
  fileSystems."/media" = {
    device = "192.168.69.5:/mnt/Alexandria/PlexiusMaxius";
    fsType = "nfs";
    options = [ "rw" "sync" ];
  };

  /*
  fileSystems."/alexandria" = {
    device = "192.168.69.5:/mnt/Alexandria/Alexander";
    fsType = "nfs";
    options = [ "rw" "sync" ];
  };
  */

  # VSCode server configuration
  services.vscode-server = {
    enable = true;
    user = user;
  };

  system.stateVersion = "21.05"; # Don't change this
}
