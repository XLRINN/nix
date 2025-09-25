# Proxmox VM Setup for NixOS

This document explains how to properly set up NixOS on a Proxmox VM and troubleshoot common issues like blank screens.

## Common Issue: Blank Screen After Installation

### Problem
After installing NixOS on a Proxmox VM, you may encounter a blank screen instead of a desktop environment. This happens because the base NixOS configuration doesn't include a display manager or desktop environment.

### Root Cause
The issue occurs when the NixOS configuration lacks:
1. X11 server configuration (`services.xserver`)
2. Display manager (GDM, LightDM, etc.)
3. Desktop environment or window manager
4. Proper graphics drivers for VM environment

### Solution
The configuration in `hosts/nixos/default.nix` has been updated to include:

```nix
services = {
  # X11 and desktop environment configuration
  xserver = {
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome.enable = true;
    xkb.layout = "us";
    xkb.options = "ctrl:nocaps";
    
    # VM-specific video driver configuration
    videoDrivers = lib.mkDefault [ "qxl" "virtio" "cirrus" "vesa" ];
  };

  # Better support for input devices (important for VMs)
  libinput.enable = true;

  # SPICE agent for better VM integration
  spice-vdagentd.enable = true;

  # QEMU Guest Agent - essential for Proxmox VM management
  qemuGuest.enable = true;
};
```

## Proxmox VM Configuration Recommendations

### VM Settings
- **Display**: Use VirtIO-GPU or Standard VGA for best compatibility
- **Machine Type**: Use `q35` for better hardware support
- **BIOS**: Use OVMF (UEFI) for modern boot process
- **Agent**: Enable QEMU Guest Agent for better integration

### Network
- Use VirtIO network adapter for best performance
- Configure firewall rules as needed

### Storage
- Use VirtIO SCSI or SATA for disk controllers
- Consider using SSDs for better performance

## Troubleshooting

### Still Getting Blank Screen?
1. Check Proxmox console - switch between different display types (VNC, SPICE, etc.)
2. Try connecting via SSH and checking system logs:
   ```bash
   journalctl -xeu gdm
   journalctl -xeu display-manager
   ```
3. Verify X11 is starting:
   ```bash
   systemctl status display-manager
   ```

### Performance Issues
1. Ensure VirtIO drivers are being used
2. Allocate sufficient RAM (at least 2GB, preferably 4GB+ for GNOME)
3. Enable hardware acceleration if supported

### Alternative Desktop Environments
If GNOME is too heavy for your VM, you can switch to lighter alternatives:

- **XFCE**: Replace `desktopManager.gnome.enable = true;` with `desktopManager.xfce.enable = true;`
- **LXQt**: Use `desktopManager.lxqt.enable = true;`
- **Tiling WM**: Use configurations from templates (bspwm + LightDM)

## VM-Specific Packages Included
- `spice-vdagent`: Better mouse and display integration
- `qemu-guest-agent`: Communication with Proxmox host
- `xorg.xf86videoqxl`: QXL graphics driver

## Post-Installation Steps
1. Change default passwords (`6!y2c87T` for both user and root)
2. Update the system: `sudo nixos-rebuild switch`
3. Install additional software as needed
4. Configure networking if using static IPs

## References
- [NixOS Manual - X11](https://nixos.org/manual/nixos/stable/index.html#sec-x11)
- [Proxmox VE Documentation](https://pve.proxmox.com/wiki/Main_Page)
- [QEMU Guest Agent](https://pve.proxmox.com/wiki/Qemu-guest-agent)