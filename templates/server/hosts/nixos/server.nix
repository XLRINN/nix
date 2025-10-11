{ config, lib, pkgs, ... }:

let
  user = "%USER%";
  keys = [
    "%SSH_PUBLIC_KEY%"
  ];
  sopsFile = "/var/lib/sopswarden/secrets.yaml";
in
{
  imports = [ ];

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
    ];
    initrd.kernelModules = [
      "virtio_blk"
      "virtio_console"
      "virtio_pci"
      "virtio_scsi"
    ];
    kernelModules = [
      "uinput"
      "virtio_balloon"
      "virtio_net"
      "virtio_rng"
    ];
  };

  networking = {
    hostName = "%HOST%";
    useDHCP = true;
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22
        80
        443
      ];
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

  services.qemuGuest.enable = lib.mkDefault true;

  users.users = {
    "${user}" = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
      ];
      openssh.authorizedKeys.keys = keys;
      initialPassword = "%INITIAL_PASSWORD%"; # rotate post-install
    };
    root = {
      openssh.authorizedKeys.keys = keys;
      initialPassword = "%INITIAL_PASSWORD%";
    };
  };

  security.sudo = {
    enable = true;
    wheelNeedsPassword = false;
  };

  services.sopswarden = {
    enable = true;
    secrets = {
      "tailscale-auth-key" = {
        name = "Tailscale";
        field = "auth-key";
      };
      "openrouter-api-key" = {
        name = "OpenRouter API";
        field = "api-key";
      };
      "github-token" = {
        name = "GitHub Token";
        field = "token";
      };
      "github-ssh-key" = {
        name = "GitHub SSH Key";
        field = "private-key";
        type = "note";
      };
    };
  };

  sops.secrets = {
    "tailscale-auth-key" = {
      owner = "root";
      group = "root";
      mode = "0600";
      path = "/run/secrets/tailscale-auth-key";
    };
    "openrouter-api-key" = {
      owner = user;
      group = "users";
      mode = "0400";
      path = "/run/secrets/openrouter-api-key";
    };
    "github-token" = {
      owner = user;
      group = "users";
      mode = "0400";
      path = "/run/secrets/github-token";
    };
    "github-ssh-key" = {
      owner = user;
      group = "users";
      mode = "0600";
      path = "/home/${user}/.ssh/id_ed25519";
    };
  };

  sops = {
    defaultSopsFile = lib.mkDefault sopsFile;
    validateSopsFiles = lib.mkDefault false;
  };

  systemd.tmpfiles.rules = [
    "d /home/${user}/.ssh 0700 ${user} users -"
  ];

  services.getty.autologinUser = null;
  system.stateVersion = "24.05";
}
