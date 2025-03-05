
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
source /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/local/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Powerlevel10k theme
source /Users/david/nix/modules/shared/config/shell/p10k.zsh

# Aliases
alias pf="pfetch"
alias bs="nix run .#build-switch"
alias bss="nix run .#build-switch && source ~/.zshrc"
alias fmu="clear && nix run .#build-switch && source ~/.zshrc"
alias sauce="source ~/.zshrc"
alias addcask="nvim ~/nix/modules/darwin/casks.nix"
alias cbs="clear && bs"
alias gc="nix-collect-garbage -d"
alias pretty="POWERLEVEL9K_CONFIG_FILE=/tmp/p10k.zsh p10k configure && cp ~/.p10k.zsh nix/modules/shared/shell/p10k.zsh"

# Zellij integration
if [ -z "$ZELLIJ" ] && [ -z "$ZELLIJ_RUNNING" ]; then
  export ZELLIJ_RUNNING=1
  zellij
fi
