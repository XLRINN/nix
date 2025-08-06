{
  description = "Starter Configuration for MacOS and NixOS";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
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
    claude-desktop = {
      url = "github:k3d3/claude-desktop-linux-flake";
      inputs = { 
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, darwin, nix-homebrew, homebrew-bundle, homebrew-core, homebrew-cask, home-manager, nixpkgs, disko, oh-my-posh, stylix, hyprland, nvf, nixvim, claude-desktop, flake-utils } @inputs:
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
        program = "${(nixpkgs.legacyPackages.${system}.writeShellScriptBin scriptName (builtins.readFile ./apps/${system}/${scriptName}))}/bin/${scriptName}";
      };
      mkLinuxApps = system: {
        "apply" = mkApp "apply" system;
        "build-switch" = mkApp "build-switch" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "install" = mkApp "install" system;
        "server" = mkApp "server" system;
        "sync-master" = mkApp "sync-master" system;
      };
      mkDarwinApps = system: {
        "apply" = mkApp "apply" system;
        "build" = mkApp "build" system;
        "build-switch" = mkApp "build-switch" system;
        "copy-keys" = mkApp "copy-keys" system;
        "create-keys" = mkApp "create-keys" system;
        "check-keys" = mkApp "check-keys" system;
        "rollback" = mkApp "rollback" system;
      };
    in
    {
      devShells = forAllSystems devShell;
      apps = nixpkgs.lib.genAttrs linuxSystems mkLinuxApps // nixpkgs.lib.genAttrs darwinSystems mkDarwinApps;

      darwinConfigurations = nixpkgs.lib.genAttrs darwinSystems (system: let
        user = "david";
      in
        darwin.lib.darwinSystem {
          inherit system;
          specialArgs = inputs;
          modules = [
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

      nixosConfigurations = nixpkgs.lib.genAttrs linuxSystems (system: nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs claude-desktop; };
        modules = [
          disko.nixosModules.disko
          home-manager.nixosModules.home-manager {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.${user} = import ./modules/nixos/home-manager.nix;
            };
          }
          ./hosts/nixos
        ];
#        environment.variables = {
#          EDITOR = "nvim";
#        };
     }) // {
       # Server configuration (consolidated CLI-only functionality)
       "x86_64-linux-server" = nixpkgs.lib.nixosSystem {
         system = "x86_64-linux";
         specialArgs = { inherit inputs claude-desktop; };
         modules = [
           disko.nixosModules.disko
           home-manager.nixosModules.home-manager {
             home-manager = {
               useGlobalPkgs = true;
               useUserPackages = true;
               users.${user} = import ./modules/shared/home-manager.nix;
             };
           }
           ./hosts/nixos/server.nix
         ];
       };
       "aarch64-linux-server" = nixpkgs.lib.nixosSystem {
         system = "aarch64-linux";
         specialArgs = { inherit inputs claude-desktop; };
         modules = [
           disko.nixosModules.disko
           home-manager.nixosModules.home-manager {
             home-manager = {
               useGlobalPkgs = true;
               useUserPackages = true;
               users.${user} = import ./modules/shared/home-manager.nix;
             };
           }
           ./hosts/nixos/server.nix
         ];
       };
     };
  };
}
