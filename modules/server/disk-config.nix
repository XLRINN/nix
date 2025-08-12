# Simple GPT with BIOS boot partition - explicit labels
{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02";  # BIOS boot partition for GPT on BIOS systems
              priority = 1;
            };
            root = {
              size = "100%";
              priority = 2;
              label = "nixos-root";  # Explicit label for the root partition
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [ "defaults" ];
              };
            };
          };
        };
      };
    };
  };

  # Explicit fileSystems configuration to ensure proper mounting
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos-root";
    fsType = "ext4";
  };
}
