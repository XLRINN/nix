{ user, ... }:

let
  home           = builtins.getEnv "HOME";
  xdg_configHome = "${home}/.config";
  xdg_dataHome   = "${home}/.local/share";
  xdg_stateHome  = "${home}/.local/state"; in
{

  "${xdg_dataHome}/bin/movesinks" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      pacmd set-default-sink $1
      pacmd list-sink-inputs | grep index | while read line
      do
        pacmd move-sink-input `echo $line | cut -f2 -d' '` $1
      done
    '';
  };

  "${xdg_dataHome}/bin/speakers" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Script to change audio format to headphones and check if the sink exists

      # Define the sink name
      SINK_NAME="alsa_output.usb-Audioengine_Audioengine_2_-00.analog-stereo"

      # Check if the sink exists
      if pactl list short sinks | grep -q "$SINK_NAME"; then
        # Sink exists, set it as the default
        pacmd set-default-sink "$SINK_NAME"
        movesinks "$SINK_NAME"
      else
        # Sink does not exist, print message
        echo "Turn on your speakers, stupid."
      fi
    '';
  };

  "${xdg_dataHome}/bin/headphones" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      # Changes audio format to headphones
      pacmd set-default-sink alsa_output.pci-0000_00_1f.3.analog-stereo
      movesinks alsa_output.pci-0000_00_1f.3.analog-stereo 
    '';
  };



 "${xdg_configHome}/hypr/hyprland.conf" = {
    executable = true;
    text = ''




  "${xdg_configHome}/rofi/colors.rasi".text = builtins.readFile ./config/rofi/colors.rasi;
  "${xdg_configHome}/rofi/confirm.rasi".text = builtins.readFile ./config/rofi/confirm.rasi;
  "${xdg_configHome}/rofi/launcher.rasi".text = builtins.readFile ./config/rofi/launcher.rasi;
  "${xdg_configHome}/rofi/message.rasi".text = builtins.readFile ./config/rofi/message.rasi;
  "${xdg_configHome}/rofi/networkmenu.rasi".text = builtins.readFile ./config/rofi/networkmenu.rasi;
  "${xdg_configHome}/rofi/powermenu.rasi".text = builtins.readFile ./config/rofi/powermenu.rasi;
  "${xdg_configHome}/rofi/styles.rasi".text = builtins.readFile ./config/rofi/styles.rasi;

  "${xdg_configHome}/rofi/bin/launcher.sh" = {
    executable = true;
/*
text = ''      
      #      #!/bin/sh
      #
      #      rofi -no-config -no-lazy-grab -show drun -modi drun -theme ~/.config/rofi/launcher.#rasi
    '';
  };

  # @todo: Don't use hardcoded src paths
  "${xdg_configHome}/rofi/bin/powermenu.sh" = {
    executable = true;
    text = ''
      #!/bin/sh

      configDir="~${xdg_configHome}/rofi"
      uptime=$(uptime -p | sed -e 's/up //g')
      rofi_command="rofi -no-config -theme $configDir/powermenu.rasi"

      # Options
      shutdown=" Shutdown"
      reboot=" Restart"
      lock=" Lock"
      suspend=" Sleep"
      logout=" Logout"

      # Confirmation
      confirm_exit() {
	      rofi -dmenu\
              -no-config\
		      -i\
		      -no-fixed-num-lines\
		      -p "Are You Sure? : "\
		      -theme $configDir/confirm.rasi
      }

      # Message
      msg() {
	      rofi -no-config -theme "$configDir/message.rasi" -e "Available Options  -  yes / y / no / n"
      }

      # Variable passed to rofi
      options="$lock\n$suspend\n$logout\n$reboot\n$shutdown"
      chosen="$(echo -e "$options" | $rofi_command -p "Uptime: $uptime" -dmenu -selected-row 0)"
      case $chosen in
          $shutdown)
		      ans=$(confirm_exit &)
		      if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
			      systemctl poweroff
		      elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
			      exit 0
              else
			      msg
              fi
              ;;
          $reboot)
		      ans=$(confirm_exit &)
		      if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
			      systemctl reboot
		      elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
			      exit 0
              else
			      msg
              fi
              ;;
          $lock)
          betterlockscreen -l
              ;;
          $suspend)
		      ans=$(confirm_exit &)
		      if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
			      mpc -q pause
			      amixer set Master mute
			      systemctl suspend
		      elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
			      exit 0
              else
			      msg
              fi
              ;;
          $logout)
		      ans=$(confirm_exit &)
		      if [[ $ans == "yes" || $ans == "YES" || $ans == "y" || $ans == "Y" ]]; then
			      bspc quit
		      elif [[ $ans == "no" || $ans == "NO" || $ans == "n" || $ans == "N" ]]; then
			      exit 0
              else
			      msg
              fi
              ;;
      esac
   '';
  };
  #  
}
