{ inputs, lib, ... }:
let
	# Set by installer or manually edited. Keep null to disable.
	path = null;
in
{
	imports = lib.optionals (path != null) [ (inputs.nixos-hardware + "/" + path) ];
}
