{ config, pkgs, lib, ... }:

# Original source: https://gist.github.com/antifuchs/10138c4d838a63c0a05e725ccd7bccdd

with lib;
let
  cfg = config.local.dock;
  inherit (pkgs) stdenv dockutil;
in
{
  options = {
    local.dock.enable = mkOption {
      description = "Enable dock";
      default = stdenv.isDarwin;
    };

    local.dock.autohide = mkOption {
      description = "Autohide dock";
      type = types.bool;
      default = true;
    };

    local.dock.position = mkOption {
      description = "Dock position";
      type = types.str;
      default = "bottom";
    };

        local.dock.size = mkOption {
      description = "Dock size (1 to 128)";
      type = types.int;
      default = 1; 
    };

    local.dock.magnification = mkOption {
      description = "Enable magnification";
      type = types.bool;
      default = true;
    };

    local.dock.magnificationSize = mkOption {
      description = "Magnification size (1 to 128)";
      type = types.int;
      default = 128; 
    };
  };

  config =
    mkIf cfg.enable
      (
        let
          normalize = path: if hasSuffix ".app" path then path + "/" else path;
        in
        {
          system.activationScripts.postUserActivation.text = ''
            echo >&2 "Setting up the Dock..."
            haveURIs="$(${dockutil}/bin/dockutil --list | ${pkgs.coreutils}/bin/cut -f2)"
             # Apply autohide setting
      defaults write com.apple.dock autohide -bool ${if cfg.autohide then "true" else "false"}

      # Apply Dock position setting
      defaults write com.apple.dock orientation -string "${cfg.position}"

      # Apply Dock size setting
      defaults write com.apple.dock tilesize -int ${toString cfg.size}

      # Apply Dock magnification settings
      defaults write com.apple.dock magnification -bool ${if cfg.magnification then "true" else "false"}
      defaults write com.apple.dock largesize -int ${toString cfg.magnificationSize}

            if [ -n "$haveURIs" ]; then
              echo >&2 "Resetting Dock."
              ${dockutil}/bin/dockutil --no-restart --remove all
              killall Dock
            else
              echo >&2 "Dock might be complete."
            fi
          '';
        }
      );
}