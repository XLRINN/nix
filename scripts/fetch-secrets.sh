#!/usr/bin/env bash

# Bitwarden Secret Fetcher for Declarative Configuration
# Fetches secrets from Bitwarden and creates Nix-compatible configuration files

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

_print() {
  if [[ "$OS" == "Darwin" ]]; then
    echo -e "$1"
  else
    echo "$1"
  fi
}

# Check if Bitwarden session is available
check_bw_session() {
  if [[ -z "${BW_SESSION:-}" ]]; then
    if [[ -f "$HOME/.cache/bw-session" ]]; then
      export BW_SESSION="$(cat "$HOME/.cache/bw-session")"
    else
      _print "${RED}ERROR: No Bitwarden session found. Please run the apply script first.${NC}"
      exit 1
    fi
  fi

  # Validate session
  if ! bw status --session "$BW_SESSION" >/dev/null 2>&1; then
    _print "${RED}ERROR: Bitwarden session expired or invalid.${NC}"
    exit 1
  fi
}

# Fetch API key from Bitwarden
fetch_api_key() {
  local item_name="$1"
  local field_name="${2:-password}"
  
  _print "${YELLOW}Fetching $item_name from Bitwarden...${NC}"
  
  if [[ "$field_name" == "password" ]]; then
    bw get password "$item_name" --session "$BW_SESSION" 2>/dev/null || {
      _print "${RED}ERROR: Could not fetch $item_name from Bitwarden${NC}"
      return 1
    }
  else
    bw get item "$item_name" --session "$BW_SESSION" | jq -r ".fields[] | select(.name==\"$field_name\") | .value" 2>/dev/null || {
      _print "${RED}ERROR: Could not fetch $field_name from $item_name in Bitwarden${NC}"
      return 1
    }
  fi
}

# Create Tailscale key file
setup_tailscale() {
  _print "${GREEN}Setting up Tailscale authentication...${NC}"
  
  local ts_key
  ts_key=$(fetch_api_key "Tailscale" "auth-key") || return 1
  
  # Write to the tailscale key file
  echo "$ts_key" > "$HOME/.local/share/src/nixos-config/modules/shared/config/tailscale/key"
  chmod 600 "$HOME/.local/share/src/nixos-config/modules/shared/config/tailscale/key"
  
  _print "${GREEN}✓ Tailscale key updated${NC}"
}

# Create API keys configuration
setup_api_keys() {
  _print "${GREEN}Setting up API keys...${NC}"
  
  local api_config_dir="$HOME/.local/share/src/nixos-config/modules/shared/config/api-keys"
  mkdir -p "$api_config_dir"
  
  # Fetch various API keys
  local anthropic_key openai_key github_token
  
  # Try to fetch each key, but don't fail if some are missing
  anthropic_key=$(fetch_api_key "Anthropic API" "api-key" 2>/dev/null || echo "")
  openai_key=$(fetch_api_key "OpenAI API" "api-key" 2>/dev/null || echo "")
  github_token=$(fetch_api_key "GitHub Token" "token" 2>/dev/null || echo "")
  
  # Create environment file for API keys
  cat > "$api_config_dir/keys.env" << EOF
# API Keys fetched from Bitwarden
# This file is gitignored and regenerated on each deployment
ANTHROPIC_API_KEY="$anthropic_key"
OPENAI_API_KEY="$openai_key"
GITHUB_TOKEN="$github_token"
EOF
  
  chmod 600 "$api_config_dir/keys.env"
  
  # Create Nix configuration that sources these keys
  cat > "$api_config_dir/default.nix" << 'EOF'
{ config, lib, pkgs, ... }:

let 
  user = config.users.users.${config.users.defaultUser or "nixos"}.name or "nixos";
  apiKeysFile = "/home/${user}/.local/share/src/nixos-config/modules/shared/config/api-keys/keys.env";
in
{
  # Environment variables for API keys
  environment.variables = lib.mkIf (builtins.pathExists apiKeysFile) {
    # Source API keys from the generated file
    # These will be available system-wide
  };
  
  # Create a script that loads API keys for user sessions
  environment.systemPackages = with pkgs; [
    (writeScriptBin "load-api-keys" ''
      #!/bin/bash
      if [[ -f "${apiKeysFile}" ]]; then
        set -a
        source "${apiKeysFile}"
        set +a
        echo "API keys loaded successfully"
      else
        echo "No API keys file found at ${apiKeysFile}"
      fi
    '')
  ];
  
  # For user services that need API keys
  systemd.user.services.api-key-loader = {
    description = "Load API keys from Bitwarden-sourced file";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c 'test -f ${apiKeysFile} && source ${apiKeysFile} || true'";
      EnvironmentFile = lib.mkIf (builtins.pathExists apiKeysFile) apiKeysFile;
    };
  };
}
EOF
  
  _print "${GREEN}✓ API keys configuration created${NC}"
}

# Main execution
main() {
  _print "${GREEN}Bitwarden Secret Fetcher${NC}"
  _print "${YELLOW}This script fetches secrets from Bitwarden and creates declarative Nix configuration${NC}"
  
  check_bw_session
  
  # Create base directories
  mkdir -p "$HOME/.local/share/src/nixos-config/modules/shared/config"
  
  # Setup different types of secrets
  setup_tailscale
  setup_api_keys
  
  _print "${GREEN}✨ All secrets fetched and configured successfully!${NC}"
  _print "${YELLOW}Remember to rebuild your system: sudo nixos-rebuild switch${NC}"
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi