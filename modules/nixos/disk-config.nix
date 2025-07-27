_: {
  # Btrfs configuration with hibernation support
  disko.devices = {
    disk = {
      vdb = {
        device = "/dev/%DISK%";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "100M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                mountpoint = "/";
                mountOptions = [
                  "defaults"
                  "noatime"
                  "compress=zstd"
                  "space_cache=v2"
                  "subvol=@"
                ];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [
                      "defaults"
                      "noatime"
                      "compress=zstd"
                      "space_cache=v2"
                    ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [
                      "defaults"
                      "noatime"
                      "compress=zstd"
                      "space_cache=v2"
                    ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "defaults"
                      "noatime"
                      "compress=zstd"
                      "space_cache=v2"
                    ];
                  };
                  "@var" = {
                    mountpoint = "/var";
                    mountOptions = [
                      "defaults"
                      "noatime"
                      "compress=zstd"
                      "space_cache=v2"
                    ];
                  };
                  "@tmp" = {
                    mountpoint = "/tmp";
                    mountOptions = [
                      "defaults"
                      "noatime"
                      "compress=zstd"
                      "space_cache=v2"
                    ];
                  };
                  "@swap" = {
                    mountpoint = "/swap";
                    mountOptions = [
                      "defaults"
                      "noatime"
                      "compress=zstd"
                      "space_cache=v2"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
