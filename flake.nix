{
  description = "Starter Configuration for MacOS and NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    # Add sopswarden for Bitwarden secrets management
    sopswarden.url = "github:pfassina/sopswarden/main";
  # Legacy nixpkgs for an older bitwarden-cli that builds (argon2/node-gyp regression in newer revs)
  # Using the 24.05 stable channel (adjust to a specific commit later if needed):
  legacy-nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
  # Hardware-specific modules for NixOS machines (e.g., Framework laptops)
  nixos-hardware.url = "github:NixOS/nixos-hardware";
    darwin = {
      url = "github:LnL7/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-homebrew = {
      url = "github:zhaofengli-wip/nix-homebrew";
    };
    homebrew-bundle = {
      url = "github:homebrew/homebrew-bundle";
      flake = false;
    };
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
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

  outputs = { self, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, home-manager, nixpkgs, disko, oh-my-posh, stylix, hyprland, nvf, nixvim, nixos-hardware, sopswarden, ... } @inputs:
    let
      user = "david";
      linuxSystems = [ "x86_64-linux" "aarch64-linux" ];
      darwinSystems = [ "aarch64-darwin" "x86_64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) f;
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
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "desktop" = mkApp "desktop" system;
        # Secrets: run the wizard directly from the user's checkout to avoid
        # depending on repo files being in the flake source when the tree is dirty.
        "secrets" = {
          type = "app";
          program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "secrets" ''
            #!/usr/bin/env bash
            exec bash ~/nix/scripts/secrets-wizard.sh "$@"
          '')}/bin/secrets";
        };
      };
      mkDarwinApps = system: {
        "apply" = mkApp "apply" system;
        "build" = mkApp "build" system;
        "build-switch" = mkApp "build-switch" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "rollback" = mkApp "rollback" system;
        "secrets" = {
          type = "app";
          program = "${(nixpkgs.legacyPackages.${system}.writeScriptBin "secrets" ''
            #!/usr/bin/env bash
            exec bash ~/nix/scripts/secrets-wizard.sh "$@"
          '')}/bin/secrets";
        };
      };
    in
    {
      devShells = forAllSystems devShell;
      apps = nixpkgs.lib.genAttrs linuxSystems mkLinuxApps // nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;

      # Expose legacy bitwarden-cli for systems where it still builds
      packages = let
        legacyFor = system: (import inputs.legacy-nixpkgs { system = system; }).bitwarden-cli or null;
      in nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) (system: {
        inherit (nixpkgs.legacyPackages.${system}) git;
        bitwarden-cli-legacy = legacyFor system;
      });

      darwinConfigurations = nixpkgs.lib.genAttrs darwinSystems (system: let
        user = "david";
      in
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = { 
            inherit inputs; 
            # Note: sopswarden may not support Darwin, commenting out for now
            # secrets = sopswarden.secrets.${system};
          };
          modules = [
            # sopswarden.darwinModules.default  # Commenting out until we confirm Darwin support
            home-manager.darwinModules.home-manager
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                inherit user;
                enable = true;
                taps = {
                  "homebrew/homebrew-core" = homebrew-core;
                  "homebrew/homebrew-cask" = homebrew-cask;
                  "homebrew/homebrew-bundle" = homebrew-bundle;
                };
                mutableTaps = false;
                autoMigrate = true;

              };
            }
            ./hosts/darwin
          ];
        }
      );

  nixosConfigurations = nixpkgs.lib.genAttrs linuxSystems (system: let
        user = "david";
      in 
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { 
    inherit inputs; 
    # secrets integration disabled for now; re-enable later
    # secrets = sopswarden.secrets.${system};
          };
          modules = [
            disko.nixosModules.disko
    # sopswarden.nixosModules.default  # disabled for initial build
            home-manager.nixosModules.home-manager {
              home-manager = {
                useGlobalPkgs = true;
                useUserPackages = true;
                users.${user} = import ./modules/nixos/home-manager.nix;
              };
            }
            ./hosts/nixos
          ];
        }
      );
  };
}
