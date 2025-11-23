{ config, lib, pkgs, ... }:

let
  # Prefer a runtime secret if present (e.g., provisioned by sops or your installer)
  secretKeyFile = "/run/secrets/tailscale-auth-key";
  hasSecret = builtins.pathExists secretKeyFile;
in
{
  services.tailscale =
    {
      enable = true;
      useRoutingFeatures = "client";
      extraUpFlags = [ "--ssh" ];
    }
    // lib.optionalAttrs hasSecret { authKeyFile = secretKeyFile; }
    // lib.optionalAttrs pkgs.stdenv.isLinux { openFirewall = true; };
}
