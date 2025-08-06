_: {
  # Simple server disk configuration
  disko.devices = {
    disk = {
      vdb = {
        device = "/dev/%DISK%";
        type = "disk";
        content = {
          type = "gpt";
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
  
  # GRUB bootloader for BIOS compatibility
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/%DISK%";
}
