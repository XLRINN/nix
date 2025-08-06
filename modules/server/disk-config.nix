_: {
  # Server disk configuration - BIOS compatible (MBR)
  disko.devices = {
    disk = {
      vdb = {
        device = "/dev/%DISK%";
        type = "disk";
        content = {
          type = "mbr";
          partitions = {
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
