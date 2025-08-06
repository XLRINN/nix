_: {
  # This formats the disk with the ext4 filesystem - optimized for space efficiency
  # Other examples found here: https://github.com/nix-community/disko/tree/master/example
  disko.devices = {
    disk = {
      vdb = {
        device = "/dev/%DISK%";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "256M";  # Reduced from 500M to save space
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            swap = {
              size = "2G";  # Add swap for memory management
              content = {
                type = "swap";
                resumeDevice = true;
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = ["noatime" "nodiratime"];  # Space optimization
              };
            };
          };
        };
      };
    };
  };
}
