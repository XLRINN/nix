{ lib, config, pkgs, ... }:

let
  cfg = config.my.proxmox;
in
{
  options.my.proxmox = {
    cloudInit.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Cloud-Init integration for Proxmox templates (switches to systemd-networkd).";
    };

    virtiofs.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Include VirtIO-FS support (for host shared folders via virtiofs).";
    };
  };

  config = lib.mkMerge [
    # Optional Cloud-Init integration (useful when building Proxmox templates)
    (lib.mkIf cfg.cloudInit.enable {
      services.cloud-init.enable = true;

      # Cloud-Init commonly manages networking; prefer systemd-networkd over NetworkManager
      networking.useNetworkd = lib.mkDefault true;
      networking.networkmanager.enable = lib.mkForce false;

      # Ensure SSH is available early in templated boots
      services.openssh.enable = lib.mkDefault true;
      services.openssh.settings = {
        PasswordAuthentication = lib.mkDefault false;
        KbdInteractiveAuthentication = lib.mkDefault false;
      };
    })

    # Optional VirtIO-FS support for host<->guest shared folders
    (lib.mkIf cfg.virtiofs.enable {
      boot.supportedFilesystems = lib.mkBefore (config.boot.supportedFilesystems or []) ++ [ "virtiofs" ];
      boot.initrd.availableKernelModules = (config.boot.initrd.availableKernelModules or []) ++ [ "virtiofs" ];
      boot.kernelModules = (config.boot.kernelModules or []) ++ [ "virtiofs" ];
    })
  ];
}

