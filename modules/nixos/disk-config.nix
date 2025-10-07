_: {
  disko.enableConfig = true;
  # This formats the disk with the ext4 filesystem
  # Other examples found here: https://github.com/nix-community/disko/tree/master/example
  disko.devices = {
    disk = {
      main = {
        # Support both SCSI and VirtIO devices in Proxmox
        device = "/dev/disk/by-path/pci-*";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            # Small BIOS boot partition so images work on BIOS and UEFI
            bios = {
              name = "disk-main-bios";
              type = "EF02"; # BIOS boot partition for GRUB on GPT
              size = "1M";
            };
            ESP = {
              name = "disk-main-ESP";
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                extraArgs = [ "-n" "NIXOS_BOOT" ];
                mountpoint = "/boot";
                mountOptions = [
                  "uid=0" "gid=0"
                  "umask=0077"
                  "shortname=winnt"
                  "nodev" "nosuid" "noexec"
                ];
              };
            };
            swap = {
              name = "disk-main-swap";
              size = "16G"; # Patched dynamically by apply script (accepts number or number+G)
              content = {
                type = "swap";
                extraArgs = [ "--label" "NIXOS_SWAP" ];
              };
            };
            root = {
              name = "disk-main-root";
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                extraArgs = [ "-L" "NIXOS_ROOT" ];
                mountpoint = "/";
                mountOptions = [ "defaults" ];
              };
            };
          };
        };
      };
    };
  };
}
