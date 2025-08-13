_: {
  # BIOS disk configuration with MBR partition table
  # Reference: https://github.com/nix-community/disko/tree/master/example
  disko.devices = {
    disk = {
      main = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "table";
          format = "mbr";
          partitions = [
            {
              name = "boot";
              start = "1MiB";
              end = "100MiB";
              fs-type = "fat32";
              bootable = true;
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "defaults" ];
              };
            }
            {
              name = "root";
              start = "100MiB";
              end = "100%";
              part-type = "primary";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [ "defaults" ];
              };
            }
          ];
        };
      };
    };
  };
}

