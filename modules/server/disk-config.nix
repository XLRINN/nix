# Single partition configuration (alternative)
# Uncomment this and comment out the multi-partition config below for simple setup
# {
#   disko.devices = {
#     disk = {
#       sda = {
#         device = "/dev/sda";
#         type = "disk";
#         content = {
#           type = "msdos";
#           partitions = {
#             root = {
#               size = "100%";
#               content = {
#                 type = "filesystem";
#                 format = "ext4";
#                 mountpoint = "/";
#               };
#             };
#           };
#         };
#       };
#     };
#   };
# }

# Multi-partition configuration (current)
{
  disko.devices = {
    disk = {
      sda = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "msdos";  # Use MBR for BIOS compatibility
          partitions = {
            # Boot partition for GRUB
            boot = {
              size = "512M";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/boot";
                mountOptions = [ "defaults" ];
              };
            };
            # Root filesystem
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [ "defaults" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
