{ config, lib, pkgs, ... }:

let
  user = config.users.users.${config.users.defaultUser or "nixos"}.name or "nixos";
  # Use sopswarden secret if available, fallback to local key file
  keyFile = "/home/${user}/.local/share/src/nixos-config/modules/shared/config/tailscale/key";
  # secretKeyFile = "/run/secrets/tailscale-auth-key";
  # useSecret = builtins.pathExists secretKeyFile;
in
{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client"; # or "both" for subnet routing
    extraUpFlags = [ "--ssh" ];
    # # Prefer sopswarden secret, fallback to local key file
    # authKeyFile = 
    #   if useSecret then secretKeyFile
    #   else if (builtins.pathExists keyFile) then keyFile
    #   else null;
  };

  # Allow Tailscale through firewall
  networking.firewall = {
    allowedUDPPorts = [ 41641 ];
    trustedInterfaces = [ "tailscale0" ];
  };

  # Helper scripts for Tailscale management
  # environment.systemPackages = with pkgs; [
  #   (writeScriptBin "tailscale-refresh-key" ''
  #     #!/bin/bash
  #     echo "Refreshing Tailscale key from Bitwarden..."
  #     if [[ -f "$HOME/.cache/bw-session" ]]; then
  #       export BW_SESSION="$(cat "$HOME/.cache/bw-session")"
  #       if TS_KEY=$(bw get item "Tailscale" --session "$BW_SESSION" 2>/dev/null | jq -r '.fields[] | select(.name=="auth-key") | .value' 2>/dev/null); then
  #         echo "$TS_KEY" > "${keyFile}"
  #         chmod 600 "${keyFile}"
  #         echo "✓ Tailscale key updated"
  #         echo "Run 'sudo tailscale up --ssh' to reconnect"
  #       else
  #         echo "❌ Could not fetch Tailscale key from Bitwarden"
  #       fi
  #     else
  #       echo "❌ No Bitwarden session found. Run the apply script first."
  #     fi
  #   '')
  # ];

  # Ensure key file has correct permissions on activation
  system.activationScripts.tailscale-key-permissions = lib.mkIf (builtins.pathExists keyFile) ''
    if [[ -f "${keyFile}" ]]; then
      chmod 600 "${keyFile}"
      chown ${user}:users "${keyFile}" 2>/dev/null || true
    fi
  '';
}
