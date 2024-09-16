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
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
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
          file = ".p10k.zsh";
      }
    ];

    shellAliases = {
      pf = "pfetch";
      bs = "nix run .#build-switch";
      bss = "nix run .#build-switch && source ~/.zshrc";
      fmu = "clear && nix run .#build-switch && source ~/.zshrc";
      sauce = "source ~/.zshrc";
      };


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
    theme = "gruvbox-dark";
    themes = {
      gruvbox-dark = {
        fg = [213 196 161];
        bg = [40 40 40];
        black = [60 56 54];
        red = [204 36 29];
        green = [152 151 26];
        yellow = [215 153 33];
        blue = [69 133 136];
        magenta = [177 98 134];
        cyan = [104 157 106];
        white = [251 241 199];
        orange = [214 93 14];
      };
    };
  };
};


  }