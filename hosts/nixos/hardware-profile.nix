{ lib, inputs ? null, ... }:
let
	# Default to Framework 13 Intel module; change to framework-13-7040-amd for AMD 7040
	mod = if inputs == null then null else inputs.nixos-hardware.nixosModules.framework-13-intel;
in
{
	imports = lib.optionals (mod != null) [ mod ];
}
