# Server Configuration

This directory contains the server-specific configuration for NixOS installations.

## Configuration Files

- `disk-config.nix` - Disko-based disk configuration (not used in current setup)
- `disk-config-simple.nix` - Simple manual disk configuration
- `home-manager.nix` - Home Manager configuration for the server user
- `files.nix` - File deployment configuration
- `packages.nix` - Package installation configuration

## Installation Process

The server installation uses manual partitioning with the following layout:

1. **BIOS Boot Partition** (1MB) - `/dev/sda1` - For GRUB bootloader
2. **Root Partition** (rest of disk) - `/dev/sda2` - Ext4 filesystem mounted at `/`

## Key Features

- **Minimal Configuration**: Optimized for server environments with minimal resource usage
- **BIOS Boot**: Configured for traditional BIOS systems (not UEFI)
- **DHCP Networking**: Simple network configuration using DHCP
- **SSH Access**: Pre-configured SSH access with authorized keys
- **Essential Packages**: Basic tools like git, vim, htop included

## Recent Fixes

The following issues have been resolved:

1. **Disk Configuration Mismatch**: Fixed device paths to use `/dev/sda2` instead of labels
2. **GRUB Configuration**: Removed disko conflicts and explicitly disabled EFI support
3. **Network Configuration**: Simplified to use DHCP instead of NetworkManager
4. **System State Version**: Updated to "24.05" for compatibility
5. **Installation Script**: Removed problematic GRUB configuration fixes
6. **Package Selection**: Added essential server packages

## Usage

To install the server configuration:

```bash
# From the NixOS installer
nix run github:xlrinn/nix#server
```

Or manually:

```bash
# Download and setup configuration
curl -LJ0 https://github.com/xlrinn/nix/archive/server.zip -o nixos-config.zip
unzip nixos-config.zip
cd nix-server

# Install
nixos-install --flake .#x86_64-linux-server --no-root-passwd
```
