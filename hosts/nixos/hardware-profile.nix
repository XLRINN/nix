{ lib, inputs ? null, ... }:
{
  # Use the common 13-inch module, which is the new standard for non-generation-specific profiles.
  imports = lib.optionals (inputs != null) [ inputs.nixos-hardware.nixosModules.framework-13-inch-common ];
}