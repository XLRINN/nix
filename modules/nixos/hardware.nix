{ lib, inputs, config, pkgs, ... }:

{
  options.my.hardware = {
    # Toggle generic laptop niceties
    isLaptop = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable general laptop optimizations (touchpad, power, battery).";
    };

    # Import any nixos-hardware profile by relative path within the repo, e.g.:
    #   "framework/13-inch/amd/7040" or "framework/13-inch/intel"
    profilePath = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "framework/13-inch/amd/7040";
      description = ''
        Relative path inside nixos-hardware to import. Useful for Framework laptops and
        other vendors. Leave null to skip. See:
        https://github.com/NixOS/nixos-hardware/tree/master
      '';
    };

    # Simpler selection for Framework laptops when you don't want to look up paths
    vendor = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "framework" ]);
      default = null;
      description = "Optional vendor selector; currently supports 'framework'. Ignored if profilePath is set.";
    };
    model = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "common" "amd-7040" "intel-13" ]);
      default = null;
      example = "amd-7040";
      description = "Model hint for vendor selector (e.g., 'amd-7040' or 'intel-13'). Ignored if profilePath is set.";
    };
  };

  config =
    let
      # Highest priority: explicit profilePath string
      chosenProfile = lib.mkIf (config.my.hardware.profilePath != null) {
        imports = [ (inputs.nixos-hardware + "/" + config.my.hardware.profilePath) ];
      };

      # Fallback: vendor/model mapping for Framework
      frameworkProfile =
        let m = config.my.hardware.model or "common"; in
        lib.mkIf (config.my.hardware.profilePath == null && config.my.hardware.vendor == "framework") {
          imports = [
            (if m == "amd-7040" then inputs.nixos-hardware.nixosModules.framework-13-7040-amd
             else if m == "intel-13" then inputs.nixos-hardware.nixosModules.framework-13-intel
             else inputs.nixos-hardware.nixosModules.framework)
          ];
        };

      laptopDefaults = lib.mkIf config.my.hardware.isLaptop {
        services.fwupd.enable = true;
        powerManagement.powertop.enable = true;
        services.tlp.enable = lib.mkDefault true;
        services.logind.lidSwitch = lib.mkDefault "suspend";
      };

      ssdDefaults = {
        # Reasonable defaults for SSDs
        services.fstrim.enable = lib.mkDefault true;
        boot.initrd.checkJournalingFS = false;
      };
    in
  lib.mkMerge [ chosenProfile frameworkProfile laptopDefaults ssdDefaults ];
}
