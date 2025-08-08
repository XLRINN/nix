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
              };
            };
          };
        };
      };
    };
  };
}
