_: {
  # Btrfs layout with subvolumes for root, home, nix store, logs, and snapshots
  # Uses GPT with a separate EFI System Partition.
  # Adjust device path (/dev/sda) as needed for your target system (e.g., /dev/nvme0n1).
  disko.devices = {
    disk = {
      main = {
        device = "/dev/sda";  # CHANGE if installing to a different drive
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              type = "EF00";
              size = "500M";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "uid=0" "gid=0"
                  "umask=0077"
                  "shortname=winnt"
                  "nodev" "nosuid" "noexec"
                ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                # Force create if partition previously had a filesystem
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "ssd" "noatime" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "ssd" "noatime" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "ssd" "noatime" ];
                  };
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "ssd" "noatime" ];
                  };
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = [ "compress=zstd" "ssd" "noatime" ];
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
