{
  description = "Minimal NixOS server configuration template";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # sopswarden.url = "github:pfassina/sopswarden/main";
  };

  outputs = { nixpkgs
    # , sopswarden
    , ...
  }:
    let
      system = "%SYSTEM%";
    in {
      nixosConfigurations = {
        "%HOST%" = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            # sopswarden.nixosModules.default
            ./hosts/nixos/server.nix
          ];
        };
      };
    };
}
