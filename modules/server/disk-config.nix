<<<<<<< HEAD
# Example to create a bios compatible gpt partition
{
  disko.devices = {
    disk = {
      main = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            boot = {
              size = "1M";
              type = "EF02"; # for grub MBR
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
=======
# BIOS-only configuration matching the install script's partitioning
{
  disko.devices.disk.main = {
    device = "/dev/sda";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        bios = {
          size = "1M";
          type = "EF02";  # BIOS boot partition for GPT
        };
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/";
            # Add label to match what the install script creates
            extraArgs = [ "-L" "nixos-root" ];
>>>>>>> 0253090 (refactor: remove finish.sh script and enhance server configuration in default.nix, disk-config.nix, home-manager.nix, and packages.nix for improved clarity and functionality)
          };
        };
      };
    };
  };
}

