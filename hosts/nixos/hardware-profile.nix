{ lib, inputs ? null, ... }:
{
	# Generic Framework module covers early 13" Intel; avoids version-specific attr differences
	imports = lib.optionals (inputs != null) [ inputs.nixos-hardware.nixosModules.framework ];
}
