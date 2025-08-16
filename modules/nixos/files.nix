{ user, ... }:

let
  home           = builtins.getEnv "HOME";
  xdg_configHome = "${home}/.config";
  xdg_dataHome   = "${home}/.local/share";
  xdg_stateHome  = "${home}/.local/state";
in
{
  "${xdg_dataHome}/bin/movesinks" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      pacmd set-default-sink "$1"
      pacmd list-sink-inputs | grep index | while read -r line
      do
        pacmd move-sink-input "$(echo "$line" | cut -f2 -d' ')" "$1"
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
        echo "Sink $SINK_NAME not found."
        exit 1
      fi
    '';
  };

  # Copy the Nix repository to the user's home directory
  "/home/${user}/nix".source = ../../../;
}

