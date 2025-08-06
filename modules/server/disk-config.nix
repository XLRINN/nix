_: {
  # Server disk configuration with BIOS Boot Partition for GRUB
  disko.devices = {
    disk = {
      vdb = {
        device = "/dev/%DISK%";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            bios = {
              type = "EF02";
              size = "1M";
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = ["noatime" "nodiratime"];
              };
            };
          };
        };
      };
    };
  };
}
