{ config, pkgs, ... }:

{
  imports = [
    # ./config/tailscale/tailscale.nix  # Disabled - causes networking.firewall errors on Darwin
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };

    
    overlays =
      # Apply each overlay found in the ./overlays directory at the repo root.
      # Use a path relative to this file so it evaluates correctly inside the
      # flake source in /nix/store (../../overlays would escape the store).
      let path = ../overlays; in with builtins;
      map (n: import (path + ("/" + n)))
          (filter (n: match ".*\\.nix" n != null ||
                      pathExists (path + ("/" + n + "/default.nix")))
                  (attrNames (readDir path)));

  };
}
