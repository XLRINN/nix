{
  description = "Starter Configuration for MacOS and NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";

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


    };



  };

  outputs =
    { self
    , darwin
    , nix-homebrew
    , homebrew-bundle
    , homebrew-core
    , homebrew-cask
    , home-manager
    , nixpkgs
    , disko
    , stylix
    , hyprland
    , nixos-hardware
    # , sopswarden
    , ...
    } @inputs:
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
        "server" = mkApp "server" system;
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

      # # Expose legacy bitwarden-cli for systems where it still builds
      # packages = let
      #   legacyFor = system: (import inputs.legacy-nixpkgs { system = system; }).bitwarden-cli or null;
      # in nixpkgs.lib.genAttrs (linuxSystems ++ darwinSystems) (system: {
      #   inherit (nixpkgs.legacyPackages.${system}) git;
      #   bitwarden-cli-legacy = legacyFor system;
      # });

      templates = {
        starter = {
          path = ./templates/starter;
          description = "Starter configuration template for workstations";
        };
        starter-with-secrets = {
          path = ./templates/starter-with-secrets;
          description = "Workstation starter template pre-wired for secrets";
        };
        server = {
          path = ./templates/server;
          description = "Minimal server configuration template";
        };
      };

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

  nixosConfigurations =
    let
      user = "david";
      mkHost = modules:
        { system, profile ? null }:
          nixpkgs.lib.nixosSystem {
            inherit system;
            specialArgs = { inherit inputs; };
            modules =
              [ disko.nixosModules.disko
              ]
              ++ (modules profile);
          };

      workstationModules = _: [
        home-manager.nixosModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${user} = import ./modules/nixos/home-manager.nix;
          };
        }
        ./hosts/nixos
      ];

      serverModules = _: [
        home-manager.nixosModules.home-manager {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.${user} = import ./modules/nixos/home-manager-server.nix;
          };
        }
        ./hosts/nixos/server
      ];

    in {
      x86_64-linux = mkHost workstationModules { system = "x86_64-linux"; };
      aarch64-linux = mkHost workstationModules { system = "aarch64-linux"; };
      server-x86_64-linux = mkHost serverModules { system = "x86_64-linux"; profile = "server"; };
      server-aarch64-linux = mkHost serverModules { system = "aarch64-linux"; profile = "server"; };
    };
  };
}
