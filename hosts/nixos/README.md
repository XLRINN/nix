# NixOS host configs

This directory holds the NixOS system modules that are wired into the flake outputs. Each
file is documented so you can quickly see which profile is active and why.

- `./default.nix` — workstation profile imported by `flake.nix` for the `x86_64-linux` and
  `aarch64-linux` configurations. It defines the shared desktop stack (GDM + GNOME +
  COSMIC with Hyprland available), filesystem labels expected by the installer, common
  networking defaults, and the primary user account scaffolding.
- `./server/default.nix` — used when the `profile = "server"` flake output is selected
  (`server-x86_64-linux` and `server-aarch64-linux`). That module trims the desktop pieces
  in favor of headless-friendly defaults.
- `./desktop/default.nix` — legacy workstation copy kept for manual experimentation. It is
  **not** referenced by `flake.nix` unless you explicitly swap the module path in the flake
  outputs (replace `hosts/nixos/default.nix` with this file in `modules`).

Use the workstation profile unless you explicitly swap the module path in `flake.nix` or
create a host-specific override that picks a different module.
