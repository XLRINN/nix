{ config, pkgs, lib, ... }:

let 
  name = "david";
  user = "david";
  email = "xlrin.morgan@gmail.com"; 
  nvimPath = ./config/nvim/default.nix;
/*
  lzvim = pkgs.callPackage nvimPath {
    name = "lzvim";
    conf-repo-url = "https://github.com/LazyVim/starter.git";
  };
*/

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
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    cdpath = [ "~/.local/share/src" ];
    plugins = [ {
          name = "powerlevel10k";
          src = pkgs.zsh-powerlevel10k;
          file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
          name = "powerlevel10k-config";
          src = lib.cleanSource ./config;
          file = "p10k.zsh";
      }];
    shellAliases = {
      pf = "pfetch";
      bs = "nix run .#build-switch";
      bss = "nix run .#build-switch && source ~/.zshrc";
      fmu = "clear && nix run .#build-switch && source ~/.zshrc";
      sauce = "source ~/.zshrc";
      addcask = "nvim ~/nix/modules/darwin/casks.nix";
      cbs = "clear && bs";
      gc = "nix-collect-garbage -d";
      p10k =  "cp ~/.p10k.zsh nix/modules/shared/config/p10k.zsh";
    };
    initExtra = ''
      if [ -z "$ZELLIJ" ] && [ -z "$ZELLIJ_RUNNING" ]; then
        export ZELLIJ_RUNNING=1
        zellij
      fi
    '';
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

  zellij = {
    enable = true;
    settings = {
      pane_frames = false;
      #default_layout = "compact";
      theme = "nord";
    };
  };

  neovim = {
    enable = true;
    plugins = with pkgs.vimPlugins; [
      vim-airline
      vim-airline-themes
      nerdtree
      coc-nvim
      vim-fugitive
    ];
    extraConfig = ''
      if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
        silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs
          \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
      endif

      lua << EOF
      vim.cmd [[
        call plug#begin('~/.local/share/nvim/plugged')
        Plug 'vim-airline/vim-airline'
        Plug 'vim-airline/vim-airline-themes'
        Plug 'preservim/nerdtree'
        Plug 'neoclide/coc.nvim', {'branch': 'release'}
        Plug 'tpope/vim-fugitive'
        call plug#end()
      ]]
      EOF
    '';
  };
}
