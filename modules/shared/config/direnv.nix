{ config, pkgs, lib, ... }:

{
  enable = true;
  enableZshIntegration = true;
  nix-direnv.enable = true;
} 