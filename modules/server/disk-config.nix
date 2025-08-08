{
  disko.devices = {
    disk = {
      sda = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "msdos";  # Use msdos for legacy BIOS systems
          partitions = {
            # Boot partition for GRUB
            boot = {
              size = "512M";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/boot";
                mountOptions = [ "defaults" ];
              };
            };
            # Root filesystem
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [ "defaults" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
