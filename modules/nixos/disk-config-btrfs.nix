_: {
  # Btrfs layout with subvolumes for root, home, nix store, logs, and snapshots
  # Uses GPT with a separate EFI System Partition.
  # Adjust device path (/dev/sda) as needed for your target system (e.g., /dev/nvme0n1).
  # Reverted to a simple ext4 layout (ESP + swap + root) per request.
  # Partitions (in order):
  #  - ESP   (500M, vfat)  -> /boot
  #  - swap  (16G, swap)   -> enabled as system swap
  #  - root  (rest, ext4)  -> /
  # Adjust swap size as needed (e.g., match RAM for hibernation).
  disko.devices = {
    disk.main = {
      device = "/dev/sda"; # Replaced by installer apply script; prefer /dev/disk/by-id for stability.
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
          swap = {
            size = "16G"; # Patched dynamically by apply script; should be >= RAM for hibernation
            content = {
              type = "swap";
            };
          };
          root = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
              mountOptions = [ "noatime" "discard" ];
            };
          };
        };
      };
    };
  };
}
