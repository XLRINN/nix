{ config, pkgs, lib, ... }:

{
  home.file = {
    ".config/hypr/hyprland.conf" = {
      text = ''
        # Custom Hyprland Configuration for XLIN
        # =====================================

        # Monitor Configuration
        monitor=,preferred,auto,auto

        # Auto-start applications
        exec-once = polybar
        exec-once = dunst
        exec-once = wl-paste --watch cliphist store
        exec-once = systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland
        exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=Hyprland

        # Application variables
        $terminal = kitty
        $menu = wofi --show drun
        $browser = firefox
        $fileManager = dolphin
        $editor = nvim

        # Environment variables
        env = XCURSOR_SIZE,24
        env = QT_QPA_PLATFORMTHEME,qt5ct
        env = XDG_CURRENT_DESKTOP,Hyprland

        # Input configuration
        input {
            kb_layout = us
            kb_options = ctrl:nocaps
            follow_mouse = 1
            touchpad {
                natural_scroll = no
                scroll_factor = 0.5
            }
            sensitivity = 0
        }

        # General window settings
        general {
            gaps_in = 8
            gaps_out = 16
            border_size = 2
            col.active_border = rgba(7aa2f7ff) rgba(bb9af7ff) 45deg
            col.inactive_border = rgba(414868aa)
            layout = dwindle
            allow_tearing = false
        }

        # Window decoration
        decoration {
            rounding = 12
            blur = yes
            blur_size = 4
            blur_passes = 2
            blur_new_optimizations = on
            drop_shadow = yes
            shadow_range = 6
            shadow_render_power = 3
            col.shadow = rgba(00000044)
        }

        # Animations
        animations {
            enabled = yes
            bezier = myBezier, 0.05, 0.9, 0.1, 1.05
            animation = windows, 1, 7, myBezier
            animation = windowsOut, 1, 7, default, popin 80%
            animation = border, 1, 10, default
            animation = borderangle, 1, 8, default
            animation = fade, 1, 7, default
            animation = workspaces, 1, 6, default
        }

        # Dwindle layout settings
        dwindle {
            pseudotile = yes
            preserve_split = yes
            smart_split = yes
            smart_resizing = yes
        }

        # Master layout settings
        master {
            new_is_master = true
            new_on_top = true
            mfact = 0.55
        }

        # Gestures
        gestures {
            workspace_swipe = off
        }

        # Window rules
        windowrulev2 = suppressevent maximize, class:.*
        windowrulev2 = float, class:^(kitty)$
        windowrulev2 = float, class:^(wofi)$
        windowrulev2 = float, class:^(dunst)$

        # Keybindings
        # Main modifier
        $mainMod = SUPER

        # Application launchers
        bind = $mainMod, RETURN, exec, $terminal
        bind = $mainMod, Q, killactive,
        bind = $mainMod, M, exit,
        bind = $mainMod, E, exec, $fileManager
        bind = $mainMod, V, togglefloating,
        bind = $mainMod, R, exec, $menu
        bind = $mainMod, B, exec, $browser
        bind = $mainMod, N, exec, $editor

        # Layout controls
        bind = $mainMod, P, pseudo, # dwindle
        bind = $mainMod, J, togglesplit, # dwindle
        bind = $mainMod, S, swapnext,

        # Focus controls
        bind = $mainMod, left, movefocus, l
        bind = $mainMod, right, movefocus, r
        bind = $mainMod, up, movefocus, u
        bind = $mainMod, down, movefocus, d

        # Workspace management
        bind = $mainMod, 1, workspace, 1
        bind = $mainMod, 2, workspace, 2
        bind = $mainMod, 3, workspace, 3
        bind = $mainMod, 4, workspace, 4
        bind = $mainMod, 5, workspace, 5
        bind = $mainMod, 6, workspace, 6
        bind = $mainMod, 7, workspace, 7
        bind = $mainMod, 8, workspace, 8
        bind = $mainMod, 9, workspace, 9
        bind = $mainMod, 0, workspace, 10

        # Move windows to workspaces
        bind = $mainMod SHIFT, 1, movetoworkspace, 1
        bind = $mainMod SHIFT, 2, movetoworkspace, 2
        bind = $mainMod SHIFT, 3, movetoworkspace, 3
        bind = $mainMod SHIFT, 4, movetoworkspace, 4
        bind = $mainMod SHIFT, 5, movetoworkspace, 5
        bind = $mainMod SHIFT, 6, movetoworkspace, 6
        bind = $mainMod SHIFT, 7, movetoworkspace, 7
        bind = $mainMod SHIFT, 8, movetoworkspace, 8
        bind = $mainMod SHIFT, 9, movetoworkspace, 9
        bind = $mainMod SHIFT, 0, movetoworkspace, 10

        # Special workspace (scratchpad)
        bind = $mainMod, minus, togglespecialworkspace, magic
        bind = $mainMod SHIFT, minus, movetoworkspace, special:magic

        # Mouse controls
        bindm = $mainMod, mouse:272, movewindow
        bindm = $mainMod, mouse:273, resizewindow

        # Function keys
        bind = , XF86MonBrightnessUp, exec, brightnessctl set +5%
        bind = , XF86MonBrightnessDown, exec, brightnessctl set 5%-
        bind = , XF86AudioRaiseVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ +5%
        bind = , XF86AudioLowerVolume, exec, pactl set-sink-volume @DEFAULT_SINK@ -5%
        bind = , XF86AudioMute, exec, pactl set-sink-mute @DEFAULT_SINK@ toggle
        bind = , XF86AudioPlay, exec, playerctl play-pause
        bind = , XF86AudioNext, exec, playerctl next
        bind = , XF86AudioPrev, exec, playerctl previous

        # Screenshot
        bind = $mainMod, Print, exec, grim -g "$(slurp)" - | wl-copy
        bind = $mainMod SHIFT, Print, exec, grim -g "$(slurp)" ~/Pictures/screenshot-$(date +%Y%m%d_%H%M%S).png

        # Lock screen
        bind = $mainMod, L, exec, swaylock

        # Reload Hyprland
        bind = $mainMod SHIFT, R, exec, hyprctl reload
      '';
    };
  };
}
