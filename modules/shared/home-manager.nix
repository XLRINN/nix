{ config, pkgs, lib, ... }:

let 
  name = "david";
  user = "david";
  email = "xlrin.morgan@gmail.com"; 
    
    in
{

  direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };

  zsh = {
    enable = true;
    autocd = false;
    cdpath = [ "~/.local/share/src" ];
    plugins = [
      {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
          name = "powerlevel10k-config";
          src = lib.cleanSource ./config;
          file = "p10k.zsh";
      }
    ];
  };

  git = {
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
	    editor = "vim";
        autocrlf = "input";
      };
      commit.gpgsign = false;
      pull.rebase = true;
      rebase.autoStash = true;
    };
  };

/*
   neovim = {
        enable = true;
        defaultEditor = true;
        extraConfig = ''
          let g:config_home = "${lib.cleanSource ./config/nvim}"
          source $g:config_home/init.vim
        '';
        plugins = with pkgs.vimPlugins; [
          lazy-nvim
        ];
      };

*/

  }