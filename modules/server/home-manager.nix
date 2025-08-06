{ config, pkgs, lib, ... }:

let
  user = "david";
  shared-files = import ../shared/files.nix { inherit config pkgs; };
in
{
  # Import shared CLI configurations
  imports = [ ../shared/home-manager.nix ];

  # Server-specific home configuration
  home = {
    enableNixpkgsReleaseCheck = false;
    username = "${user}";
    homeDirectory = "/home/${user}";
    packages = pkgs.callPackage ./packages.nix {};
    file = shared-files // import ./files.nix { inherit user; };
    stateVersion = "23.11";
  };
}
