{ config, inputs, lib, ... }:
let
	path = config.my.hardware.profilePath;
in
{
	imports = lib.optionals (path != null) [ (inputs.nixos-hardware + "/" + path) ];
}
