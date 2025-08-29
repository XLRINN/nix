# Quick syntax test for home-manager configuration
let
  pkgs = import <nixpkgs> {};
  lib = pkgs.lib;
  config = {};
in
import ./modules/shared/home-manager.nix { inherit config pkgs lib; }
