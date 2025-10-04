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

Boot the NixOS ISO, open a shell, and run the installer directly from GitHub (no local checkout needed):

```
# Use the installer app that auto-downloads this repo's config
nix run github:xlrinn/nix#desktop
```

Notes
- The installer is UEFI-only (systemd-boot). If the VM uses BIOS/SeaBIOS, the installer exits with a friendly hint to switch to UEFI and add an EFI disk. If you prefer BIOS, tell me and I can add a GRUB-on-BIOS fallback.
- VirtIO/QEMU guest modules and agents are enabled by default in the NixOS host configuration.
- The Disko layout includes a small BIOS boot partition for cross-compatibility, alongside the EFI system partition.
