{
  enable = true;

  settings = {
    # Make zellij UI more compact
    pane_frames = false;
    default_layout = "compact";

    theme = "dark-modern";

    # Disable startup tips
    show_startup_tips = false;

    themes = {
      "dark-modern" = {
        fg = [204 204 204];
        bg = [31 31 31];
        black = [39 39 39];
        red = [247 73 73];
        green = [46 160 67];
        yellow = [158 106 3];
        blue = [0 120 212];
        magenta = [208 18 115];
        cyan = [29 180 214];
        white = [204 204 204];
        orange = [158 106 3];
      };
    };
  };
}
