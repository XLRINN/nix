_: {
  # Simple BIOS disk configuration with ext4
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        device = "/dev/%DISK%";
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
