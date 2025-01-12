# Import the necessary modules
let
    pkgs = import <nixpkgs> {};
    home = pkgs.homeManager.lib;
in

# Define the oh-my-posh configuration
{
    programs.ohMyPosh = {
        enable = true;
        theme = ./config/posh/slim.omp.json;
        shell = "zsh";
    };

    home.file.".oh-my-poshrc" = {
        text = ''
            # Add any additional configuration here
        '';
        owner = "david";
        group = "users";
        mode = "0644";
    };
}