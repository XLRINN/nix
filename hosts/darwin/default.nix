{ config, pkgs, ... }:

let user = "david"; in

{

  imports = [
    ../../modules/darwin/home-manager.nix
    ../../modules/shared
    ../../modules/shared/cachix
  ];

  # nix-daemon is now managed automatically; removed deprecated services.nix-daemon.enable
  # Touch ID auth option renamed in recent nix-darwin: migrate to new location
  security.pam.services.sudo_local.touchIdAuth = true;

  # Setup user, packages, programs
  nix = {
    package = pkgs.nix;
    settings.trusted-users = [ "@admin" "${user}" ];

    gc = {
      # Removed deprecated gc.user (GC always runs as root now)
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };

    # Turn this on to make command line easier
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

  # Turn off NIX_PATH warnings now that we're using flakes
  system.checks.verifyNixPath = false;


  system = {
    stateVersion = 4;
    # Required for per-user defaults & homebrew options after migration
    primaryUser = user;

    defaults = {
      NSGlobalDomain = {
        AppleShowAllExtensions = true;
        ApplePressAndHoldEnabled = false;

        # 120, 90, 60, 30, 12, 6, 2
        KeyRepeat = 2;

        # 120, 94, 68, 35, 25, 15
        InitialKeyRepeat = 15;

        "com.apple.mouse.tapBehavior" = 1;
        "com.apple.sound.beep.volume" = 0.0;
        "com.apple.sound.beep.feedback" = 0;
      };

      finder = {
        _FXShowPosixPathInTitle = false;
      };

      trackpad = {
        Clicking = true;
        TrackpadThreeFingerDrag = true;
      };
    };
  };

  # Fix activation error: nixbld group GID expected 30000 but actual is 350 on this system.
  # Correct placement (top-level, not under system.*) per nix-darwin module options.
  ids.gids.nixbld = 350;
}
