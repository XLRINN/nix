# Simple manual partition configuration without disko
{ lib, ... }:
{
  # Don't use disko at all - just define the filesystems directly
  fileSystems."/" = {
    device = "/dev/sda2";  # Root partition will be sda2 (after BIOS boot partition)
    fsType = "ext4";
    options = [ "defaults" "noatime" ];
  };

  # GRUB configuration for BIOS boot
  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
    useOSProber = false;
    efiSupport = false;  # Explicitly disable EFI for BIOS systems
  };
}
