_: {
  # Server disk configuration with bootloader
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
  
  # Let disko handle the bootloader
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/%DISK%";
}
