# Single partition configuration (simpler and more reliable)
{
  disko.devices = {
    disk = {
      sda = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "msdos";  # Use MBR for BIOS compatibility
          partitions = {
            # Single root partition (simpler)
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [ "defaults" "noatime" ];
                # Add partition label to match what the boot process expects
                label = "disk-sda-root";
              };
            };
          };
        };
      };
    };
  };
}
