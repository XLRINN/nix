_: {
  # Server disk configuration - BIOS boot following official Disko pattern
  disko.devices = {
    disk = {
      my-disk = {
        device = "/dev/%DISK%";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            grub = {
              size = "1M";
              type = "ef02";
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
