_: {
  # Server disk configuration - BIOS compatible with GRUB on GPT
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
                mountOptions = [ "noatime" "nodiratime" ];
                # Explicitly set partition name to avoid label issues
                extraArgs = [ "-n" "root" ];
              };
            };
          };
        };
      };
    };
  };
}
