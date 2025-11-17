{
  description = "Server-only NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    nixos-anywhere.url = "github:nix-community/nixos-anywhere";
  # Legacy nixpkgs for an older bitwarden-cli that builds (argon2/node-gyp regression in newer revs)
  # Using the 24.05 stable channel (adjust to a specific commit later if needed):
  legacy-nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  # Hardware-specific modules for NixOS machines (e.g., Framework laptops)
  nixos-hardware.url = "github:NixOS/nixos-hardware";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    oh-my-posh = {
      url = "github:JanDeDobbeleer/oh-my-posh";
      flake = false;
    };

    stylix = {
      url = "github:danth/stylix";
      flake = false;
    };

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvf = { 
      url = "github:notashelf/nvf";
      flake = false;
    };

      nixvim= {
        url = "github:dc-tec/nixvim";
        flake = false;
      };
  };

  outputs = { self, home-manager, nixpkgs, disko, oh-my-posh, stylix, hyprland, nvf, nixvim, nixos-hardware, nixos-anywhere, ... } @inputs:
    let
      user = "david";
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = f: nixpkgs.lib.genAttrs linuxSystems f;
      devShell = system: let pkgs = nixpkgs.legacyPackages.${system}; in {
        default = with pkgs; mkShell {
          nativeBuildInputs = with pkgs; [ bashInteractive git ];
          shellHook = with pkgs; ''
              export EDITOR="nvim"
          '';
        };
      };
      mkApp = scriptName: system: {
        type = "app";
        program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin scriptName ''
          #!/usr/bin/env bash
          PATH=${nixpkgs.legacyPackages.${system}.git}/bin:$PATH
          echo "Running ${scriptName} for ${system}"
          exec ${self}/apps/${system}/${scriptName}
        '')}/bin/${scriptName}";
      };
      # Standard app builder referencing files in repo
      mkLinuxApps = system: {
        "apply" = mkApp "apply" system;
        "build-switch" = mkApp "build-switch" system;
        # Server installer: delegate to nixos-anywhere so the
        # system is built locally and streamed to the target.
        "server" = {
          type = "app";
          program = "${nixos-anywhere.packages.${system}.default}/bin/nixos-anywhere";
        };
      };
    in
    {
      devShells = forAllSystems devShell;
      apps = nixpkgs.lib.genAttrs linuxSystems mkLinuxApps;

      # Expose legacy bitwarden-cli for systems where it still builds
      packages = let
        legacyFor = system: (import inputs.legacy-nixpkgs { system = system; }).bitwarden-cli or null;
      in nixpkgs.lib.genAttrs linuxSystems (system: {
        inherit (nixpkgs.legacyPackages.${system}) git;
        bitwarden-cli-legacy = legacyFor system;
      });

  nixosConfigurations =
    let
      user = "david";
      mkHost = modules:
        { system, profile ? null }:
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = { inherit inputs; };
            modules = [ disko.nixosModules.disko ] ++ (modules profile);
          };

      serverModules = _: [
        home-manager.nixosModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${user} = import ./modules/home-manager.nix;
          };
        }
        ./hosts
      ];

    in {
      x86_64-linux = mkHost serverModules { system = "x86_64-linux"; profile = "server"; };
      aarch64-linux = mkHost serverModules { system = "aarch64-linux"; profile = "server"; };
    };
  };
}
