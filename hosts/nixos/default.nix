{ config, inputs, pkgs, ... }:

let user = "david";
  keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOk8iAnIaa1deoc7jw8YACPNVka1ZFJxhnU4G74TmS+p" ]; in
{
  imports = [
    ../../modules/nixos/disk-config.nix
    ../../modules/shared
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
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" "iwlwifi" ];
    kernelModules = [ "uinput" "iwlwifi" ];
    
      # Hibernation support (commented out to avoid conflicts)
  # resumeDevice = "/dev/disk/by-label/swap";
  # kernelParams = [ "resume_offset=0" ];
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  networking = {
    hostName = "hodr"; # Define your hostname.
    useDHCP = false;
    networkmanager.enable = true; # Enable NetworkManager
  };

  # WiFi profile configuration
  environment.etc."NetworkManager/system-connections/home-wifi.nmconnection" = {
    text = ''
      [connection]
      id=home-wifi
      type=wifi
      interface-name=wlan0

      [wifi]
      mode=infrastructure
      ssid=o:::()====>

      [wifi-security]
      auth-alg=open
      key-mgmt=wpa-psk
      psk=K!ngKunt@

      [ipv4]
      method=auto

      [ipv6]
      method=auto
    '';
    mode = "0600";
  };

  hardware = {
    enableAllFirmware = true; # Enable all firmware
    graphics.enable = true; # Update from opengl.enable to graphics.enable
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
      # Set initial password (change this after first login)
      initialPassword = "6!y2c87T";
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
      ];
      groups = [ "wheel" ];
    }];
  };

   programs.hyprland.enable = true;
  services = { 
    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
      desktopManager.gnome.enable = true;
      xkb.layout = "us"; # Update from layout to xkb.layout
      xkb.options = "ctrl:nocaps"; # Update from xkbOptions to xkb.options
    };
    libinput.enable = true; # Move from xserver.libinput.enable to services.libinput.enable
    openssh.enable = true;

    gvfs.enable = true;
    tumbler.enable = true;
  };

  # Swap partition configuration
  swapDevices = [{
    device = "/dev/disk/by-partlabel/swap";
    size = 0; # Will be set to RAM size during installation
  }];

  fonts.packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      fira-code
      inconsolata
      dejavu_fonts
      jetbrains-mono
      font-awesome
      nerd-fonts.fira-code
      # Icon fonts alternatives to feather-font:
      material-icons
      material-design-icons
      nerd-fonts.jetbrains-mono
      nerd-fonts.hack
  ];

  # Turn on flag for proprietary software
  nix = {
    nixPath = [ "nixos-config=/home/${user}/.local/share/src/nix:/etc/nixos" ];
    settings = {
      allowed-users = [ "${user}" ];
      trusted-users = [ "@admin" "${user}" ];
      substituters = [ "https://nix-community.cachix.org" "https://cache.nixos.org" ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
      download-buffer-size = 1048576; # 1MB buffer size
    };

    package = pkgs.nix;
    extraOptions = ''
      experimental-features = nix-command flakes
    '';

    gc = {
      automatic = true;
      dates = "14d";
      options = "--delete-older-than 30d";
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
  ];

  # Set up nix directory and remote
  system.activationScripts = {
    setupNixDir = ''
      # Create nix directory in home
      mkdir -p /home/${user}/nix
      chown ${user}:users /home/${user}/nix
      
      # Copy current nix config to home directory
      if [ ! -d /home/${user}/nix/.git ]; then
        cp -r /etc/nixos/* /home/${user}/nix/
        chown -R ${user}:users /home/${user}/nix
        
        cd /home/${user}/nix
        sudo -u ${user} git init
        sudo -u ${user} git add .
        sudo -u ${user} git commit -m "Initial commit from installation"
        
        # Add remote with your actual repo URL
        sudo -u ${user} git remote add origin https://github.com/xlrinn/nix.git
        # Note: git push will require authentication - run manually after login:
        # cd ~/nix && git push -u origin master
      fi
    '';
  };

  system.stateVersion = "21.05"; # Don't change this
}
