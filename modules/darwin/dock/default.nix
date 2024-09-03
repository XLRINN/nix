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
      example = false;
    };

    local.dock.entries = mkOption
      {
        description = "Entries on the Dock";
        type = with types; listOf (submodule {
          options = {
            path = lib.mkOption { type = str; };
            section = lib.mkOption {
              type = str;
              default = "apps";
            };
            options = lib.mkOption {
              type = str;
              default = "";
            };
          };
        });
        readOnly = true;
      };
    local.dock.autoHide = mkOption {
      type = types.bool;
      default = true;
      description = "Enable or disable auto-hide for the dock.";
    };

    local.dock.position = mkOption {
      type = types.str;
      default = "bottom";
      description = "Position of the dock (left, bottom, right).";
    };
  };

  config =
    mkIf cfg.enable
      (
        let

          normalize = path: if hasSuffix ".app" path then path + "/" else path;
          entryURI = path: "file://" + (builtins.replaceStrings
            [" "   "!"   "\""  "#"   "$"   "%"   "&"   "'"   "("   ")"]
            ["%20" "%21" "%22" "%23" "%24" "%25" "%26" "%27" "%28" "%29"]
            (normalize path)
          );
          wantURIs = concatMapStrings
            (entry: "${entryURI entry.path}\n")
            cfg.entries;
          createEntries = concatMapStrings
            (entry: "${dockutil}/bin/dockutil --no-restart --add '${entry.path}' --section ${entry.section} ${entry.options}\n")
            cfg.entries;
        in
        {
          
  system.activationScripts.postUserActivation.text = ''
    echo >&2 "Setting up the dock with the following configuration:"
    echo >&2 "AutoHide: ${toString cfg.autoHide}"
    echo >&2 "Position: ${cfg.position}"

    # Set the auto-hide and position settings using defaults command
    defaults write com.apple.dock autohide -bool ${toString cfg.autoHide}
    defaults write com.apple.dock orientation -string ${cfg.position}

    haveURIs="$(${dockutil}/bin/dockutil --list | ${pkgs.coreutils}/bin/cut -f2)"
    if ! diff -wu <(echo -n "$haveURIs") <(echo -n '${wantURIs}') >&2 ; then
      echo >&2 "Resetting Dock."
      ${dockutil}/bin/dockutil --no-restart --remove all
      ${createEntries}
      killall Dock
    else
      echo >&2 "Dock setup complete."
    fi
    killall Dock # Ensure the Dock restarts with the new settings
  '';

}
      );
}
