{ config, lib, pkgs, ... }:

{
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client"; # or "both" for subnet routing
    extraUpFlags = [ "--ssh" ];
  };

  networking.firewall.allowedUDPPorts = [ 41641 ];
}
