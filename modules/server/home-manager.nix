{ config, pkgs, lib, ... }:

{
  home = {
    enableNixpkgsReleaseCheck = false;
    username = "david";
    homeDirectory = "/home/david";
    stateVersion = "23.11";
  };
}