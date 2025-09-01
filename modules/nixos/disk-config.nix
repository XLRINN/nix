_: {
  # This formats the disk with the ext4 filesystem
  # Other examples found here: https://github.com/nix-community/disko/tree/master/example
  disko.devices = {
    disk = {
      main = {
        device = "/dev/sda";
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
                # Secure the ESP so systemd-boot random seed isn't world-accessible
                # On vfat, permissions are emulated; set root ownership and 0700 perms
                mountOptions = [
                  "uid=0" "gid=0"    # root owns files
                  "umask=0077"        # files/dirs mode 0700
                  "shortname=winnt"   # sane 8.3 handling
                  "nodev" "nosuid" "noexec"
                ];
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [ "defaults" ];
              };
            };
          };
        };
      };
    };
  };
}
