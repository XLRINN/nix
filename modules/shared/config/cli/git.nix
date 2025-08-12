{config, pkgs, lib, ...}: {
  programs.git = {
    enable = true;
    ignores = [ "*.swp" ];
    userName = "david";
    userEmail = "xlrin.morgan@gmail.com";
    lfs.enable = true;
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
  };
}
