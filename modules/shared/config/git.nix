{ config, pkgs, lib, ... }:

let 
  name = "david";
  email = "xlrin.morgan@gmail.com"; 
in
{
  enable = true;
  ignores = [ "*.swp" ];
  userName = name;
  userEmail = email;
  lfs = {
    enable = true;
  };
  extraConfig = {
    init.defaultBranch = "master";
    core = {
      editor = "nvim";
      autocrlf = "input";
    };
    commit.gpgsign = false;
    pull.rebase = true;
    rebase.autoStash = true;
  };
} 