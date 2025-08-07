{
  disko.devices = {
    disk = {
      sda = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "table";
          format = "msdos";  # MBR (for BIOS boot)
          partitions = [
            {
              name = "boot";
              start = "1MiB";
              end = "512MiB";
              bootable = true;
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/boot";
              };
            }
            {
              name = "root";
              start = "512MiB";
              end = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            }
          ];
        };
      };
    };
  };
}
