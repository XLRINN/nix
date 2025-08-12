# Single partition configuration (simpler and more reliable)
{
  disko.devices = {
    disk = {
      sda = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = [
            {
              name = "root";
              start = "1MiB";
              end = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [ "defaults" "noatime" ];
                # Add partition label to match what the boot process expects
                label = "disk-sda-root";
              };
            }
          ];
        };
      };
    };
  };
}
