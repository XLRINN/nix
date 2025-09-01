{ inputs, lib, ... }:
let
	# Default to Framework 13 Intel profile; set to null on non-Framework machines
	path = "framework/13-inch/intel";
in
{
	imports = lib.optionals (path != null) [ (inputs.nixos-hardware + "/" + path) ];
}
