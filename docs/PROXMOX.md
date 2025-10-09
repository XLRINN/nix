# Proxmox Setup Notes

These steps ensure the `@desktop` installer works smoothly in Proxmox VE. See also the upstream guide:
https://nixos.wiki/wiki/Proxmox_Virtual_Environment

- VM firmware: OVMF (UEFI)
- EFI Disk: add an EFI Disk (e.g., Storage: `local-lvm`, Size: 1–2 GiB)
- SCSI Controller: VirtIO SCSI (single) recommended; SATA also works
- Disk BUS: SCSI or VirtIO, any size you prefer
- Display: Default is fine; SPICE display works best with `spice-vdagent`
- Network Device: VirtIO (paravirtualized)
- QEMU Guest Agent: Enable in VM Options (the OS enables the agent service automatically)
- Serial Console: Add a serial device (e.g. `ttyS0`) if you want to use the Proxmox console; the NixOS config already exposes `console=ttyS0,115200n8` and spawns a `getty` on that TTY.

Boot the NixOS ISO, open a shell, and run the installer directly from GitHub (no local checkout needed):

```
# Use the installer app that auto-downloads this repo's config
nix run github:xlrinn/nix#desktop
```

Notes
- The installer is UEFI-only (systemd-boot). If the VM uses BIOS/SeaBIOS, the installer exits with a friendly hint to switch to UEFI and add an EFI disk. If you prefer BIOS, tell me and I can add a GRUB-on-BIOS fallback.
- VirtIO/QEMU guest modules and agents are enabled by default in the NixOS host configuration.
- The Disko layout includes a small BIOS boot partition for cross-compatibility, alongside the EFI system partition.

## Cloud-Init (Optional)

If you want to use Proxmox Cloud-Init to inject users, SSH keys, and network configuration (e.g., for templates), enable the optional Proxmox module:

```
# In your host imports or a profile module
imports = [
  ../../modules/nixos/proxmox.nix
];

my.proxmox.cloudInit.enable = true;
```

What it does:
- Enables `services.cloud-init` and switches networking to `systemd-networkd` for compatibility with Cloud-Init’s network configuration.
- Ensures `openssh` is enabled and password logins are off by default.

Proxmox template flow:
- Build a base VM with this repo and `my.proxmox.cloudInit.enable = true`.
- In Proxmox, convert the VM to a template and provision new VMs with Cloud-Init user-data (SSH keys, hostname, etc.).
- See: https://nixos.wiki/wiki/Proxmox_Virtual_Environment and https://mtlynch.io/notes/nixos-proxmox/

## VirtIO-FS Shared Folders (Optional)

To mount Proxmox host shares via VirtIO-FS inside the guest, enable support in the module:

```
imports = [ ../../modules/nixos/proxmox.nix ];
my.proxmox.virtiofs.enable = true;
```

Then in your VM hardware, add a `VirtIO FS` device (e.g., tag `hostshare`), and mount it in your NixOS config or at runtime, for example:

```
fileSystems."/mnt/hostshare" = {
  device = "hostshare";  # the VirtIO-FS tag set in Proxmox
  fsType = "virtiofs";
  options = [ "rw" "nofail" ];
};
```

Tip: SPICE works best with the `spice-vdagent` enabled (already on by default here). For headless/server use, you can omit graphics entirely and use only the serial console over `ttyS0`.
