_: {
  # Server disk configuration - BIOS boot only
  disko.devices = {
    disk = {
      my-disk = {
        device = "/dev/%DISK%";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            "disk-my-disk-grub" = {
              size = "1M";
              type = "ef02";
            };
            "disk-my-disk-root" = {
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
