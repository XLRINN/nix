{ config, inputs, pkgs, ... }:

let user = "david";
    keys = [ 
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ2RS6TW8svjJHpr0dwZAw+xPex0r1EY6GSHPwlUOsGD xlrin.morgan@gmail.com"
    ]; in
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
  };

  # Set your time zone.
  time.timeZone = "America/New_York";

  networking = {
    hostName = "loki"; # Server hostname
    useDHCP = false;
    networkmanager.enable = true;
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
    enableAllFirmware = true;
    graphics.enable = true;
    ledger.enable = true;
    firmware = [ pkgs.linux-firmware ];
  };

  virtualisation.docker.enable = true;

  programs.zsh.enable = true;

  users.users = {
    "${user}" = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "docker"
        "networkmanager"
      ];
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
       {
         command = "${pkgs.systemd}/bin/reboot";
         options = [ "NOPASSWD" ];
        }
       ];
      groups = [ "wheel" ];
    }];
  };

  # Server services (no desktop)
  services = { 
    openssh = {
      enable = true;
      settings = {
        PubkeyAuthentication = true;
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
        KexAlgorithms = [ "curve25519-sha256@libssh.org" "diffie-hellman-group16-sha512" ];
        Ciphers = [ "chacha20-poly1305@openssh.com" "aes256-gcm@openssh.com" ];
        MACs = "hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com";
      };
    };
  };

  # Turn on flag for proprietary software
  nix = {
    nixPath = [ "nixos-config=/home/${user}/.local/share/src/nix:/etc/nixos" ];
    settings = {
      allowed-users = [ "${user}" ];
      trusted-users = [ "@admin" "${user}" ];
      substituters = [ "https://nix-community.cachix.org" "https://cache.nixos.org" ];
      trusted-public-keys = [ "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY=" ];
      download-buffer-size = 1048576;
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
    dconf.enable = true;
  };

  # Server packages - only shared packages
  environment.systemPackages = with pkgs; [
    (import ../../modules/shared/packages.nix { inherit pkgs config; })
    gitAndTools.gitFull
    inetutils
    neovim
    gh  # GitHub CLI
    inputs.claude-desktop.packages.${pkgs.system}.claude-desktop
  ];

  # GitHub CLI configuration
  environment.variables = {
    GH_CONFIG_DIR = "/home/${user}/.config/gh";
  };

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
        sudo -u ${user} git commit -m "Initial commit from server installation"
        
        # Add remote with your actual repo URL
        sudo -u ${user} git remote add origin https://github.com/dmorgan/nix.git
        
        # Set up git configuration for the user
        sudo -u ${user} git config --global user.name "david"
        sudo -u ${user} git config --global user.email "xlrin.morgan@gmail.com"
      fi
    '';
  };

  system.stateVersion = "21.05";
} 