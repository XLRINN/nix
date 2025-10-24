{ config, pkgs, lib, ... }:

{
  options.programs.ghostly.enable = lib.mkEnableOption "Enable Ghostly";

  config = lib.mkIf config.programs.ghostly.enable {
    home.packages = [ pkgs.ghostly ];

    xdg.configFile."ghostly/config.toml".text = ''
      [theme]
      color_scheme = "Dracula"
      opacity = 0.3
    '';

    home.file.".config/ghostly/config.toml".force = true;

    systemd.user.services.ghostly = {
      enable = true;
      Service = {
        ExecStart = "${pkgs.ghostly}/bin/ghostly --config ~/.config/ghostly/config.toml";
        Restart = "always";
      };
      Install.WantedBy = [ "default.target" ];
    };

    home.activation.restartGhostly = {
      after = [ "writeBoundary" ];
      exec = "systemctl --user restart ghostly.service";
    };
  };
}
