# Enable Zsh features
autoload -Uz compinit
compinit
autoload -Uz vcs_info
vcs_info

# Set options
setopt autocd
setopt complete_in_word
setopt correct
setopt correct_all

# Enable plugins
#source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
#source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Powerlevel10k theme
source /Users/david/nix/modules/shared/config/shell/p10k.zsh

# Bitwarden session helper
bw_session() {
  local f="$HOME/.cache/bw-session"
  if command -v bw >/dev/null 2>&1 && [ -f "$f" ]; then
    export BW_SESSION="$(cat "$f")"
    # Validate session silently; if invalid, unset
    if ! bw sync >/dev/null 2>&1; then
      unset BW_SESSION
    fi
  fi
}
bw_session

alias bw-unlock='unset BW_SESSION; BW_PASSWORD="$(read -s -p "Master password: " pw; echo; printf %s "$pw")" bw unlock --raw | tee "$HOME/.cache/bw-session" >/dev/null'


# Aliases
alias pf="pfetch"
alias bs="nix run .#build-switch"
alias bss="nix run .#build-switch && source ~/.zshrc"
alias fmu="clear && nix run .#build-switch && source ~/.zshrc"
alias sauce="source ~/.zshrc"
alias addcask="nvim ~/nix/modules/darwin/casks.nix"
alias cbs="clear && bs"
alias gc="nix-collect-garbage -d"
alias pretty="POWERLEVEL9K_CONFIG_FILE=/tmp/p10k.zsh p10k configure && cp ~/.p10k.zsh nix/modules/shared/config/shell/p10k.zsh"
alias pretty2="cp ~/.p10k.zsh nix/modules/shared/config/shell/p10k.zsh"

# Zellij integration
if [ -z "$ZELLIJ" ] && [ -z "$ZELLIJ_RUNNING" ]; then
  export ZELLIJ_RUNNING=1
  zellij
fi
