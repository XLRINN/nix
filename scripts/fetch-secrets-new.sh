#!/usr/bin/env bash

# Bitwarden Secret Fetcher for Declarative Configuration
# Supports both Bitwarden Password Manager and Bitwarden Secrets Manager
# Fetches secrets from Bitwarden and creates Nix-compatible configuration files

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

_print() {
  if [[ "${OS:-}" == "Darwin" ]]; then
    echo -e "$1"
  else
    echo "$1"
  fi
}

# Check if Bitwarden Secrets Manager CLI is available
check_bws_available() {
  command -v bws >/dev/null 2>&1
}

# Check if regular Bitwarden CLI is available
check_bw_available() {
  command -v bw >/dev/null 2>&1
}

# Check if Bitwarden session is available (regular BW)
check_bw_session() {
  if [[ -z "${BW_SESSION:-}" ]]; then
    if [[ -f "$HOME/.cache/bw-session" ]]; then
      export BW_SESSION="$(cat "$HOME/.cache/bw-session")"
    else
      return 1
    fi
  fi

  # Validate session
  if ! bw status --session "$BW_SESSION" >/dev/null 2>&1; then
    return 1
  fi
  return 0
}

# Check if BWS access token is available
check_bws_token() {
  [[ -n "${BWS_ACCESS_TOKEN:-}" ]] || [[ -f "$HOME/.bws-token" ]]
}

# Determine which Bitwarden method to use
determine_bw_method() {
  if check_bws_available && check_bws_token; then
    echo "bws"
  elif check_bw_available && check_bw_session; then
    echo "bw"
  else
    echo "none"
  fi
}

# Fetch secret using Bitwarden Secrets Manager
fetch_secret_bws() {
  local secret_id="$1"
  
  # Load BWS token if from file
  if [[ -z "${BWS_ACCESS_TOKEN:-}" ]] && [[ -f "$HOME/.bws-token" ]]; then
    export BWS_ACCESS_TOKEN="$(cat "$HOME/.bws-token")"
  fi
  
  _print "${BLUE}Fetching secret $secret_id from Bitwarden Secrets Manager...${NC}"
  
  bws secret get "$secret_id" --access-token "$BWS_ACCESS_TOKEN" 2>/dev/null | jq -r '.value' || {
    _print "${RED}ERROR: Could not fetch secret $secret_id from Bitwarden Secrets Manager${NC}"
    return 1
  }
}

# Fetch API key from regular Bitwarden
fetch_api_key_bw() {
  local item_name="$1"
  local field_name="${2:-password}"
  
  _print "${BLUE}Fetching $item_name from Bitwarden Password Manager...${NC}"
  
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

# Generic fetch function that tries both methods
fetch_secret() {
  local secret_name="$1"
  local secret_id="${2:-}"
  local field_name="${3:-password}"
  
  local method
  method=$(determine_bw_method)
  
  case "$method" in
    "bws")
      if [[ -n "$secret_id" ]]; then
        fetch_secret_bws "$secret_id"
      else
        _print "${YELLOW}WARNING: Secret ID not provided for BWS, skipping $secret_name${NC}"
        return 1
      fi
      ;;
    "bw")
      fetch_api_key_bw "$secret_name" "$field_name"
      ;;
    "none")
      _print "${RED}ERROR: No valid Bitwarden authentication found${NC}"
      _print "${YELLOW}Either set up BWS_ACCESS_TOKEN or ensure BW_SESSION is valid${NC}"
      return 1
      ;;
  esac
}

# Create Tailscale key file
setup_tailscale() {
  _print "${GREEN}Setting up Tailscale authentication...${NC}"
  
  local ts_key
  # Try BWS first (with secret ID), then BW (with item name)
  ts_key=$(fetch_secret "Tailscale" "${TAILSCALE_SECRET_ID:-}" "auth-key") || return 1
  
  # Create directory and write key
  mkdir -p "$HOME/.local/share/src/nixos-config/modules/shared/config/tailscale"
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
  anthropic_key=$(fetch_secret "Anthropic API" "${ANTHROPIC_SECRET_ID:-}" "api-key" 2>/dev/null || echo "")
  openai_key=$(fetch_secret "OpenAI API" "${OPENAI_SECRET_ID:-}" "api-key" 2>/dev/null || echo "")
  github_token=$(fetch_secret "GitHub Token" "${GITHUB_SECRET_ID:-}" "token" 2>/dev/null || echo "")
  
  # Create environment file for API keys
  cat > "$api_config_dir/keys.env" << EOF
# API Keys fetched from Bitwarden
# This file is gitignored and regenerated on each deployment
ANTHROPIC_API_KEY="$anthropic_key"
OPENAI_API_KEY="$openai_key"
GITHUB_TOKEN="$github_token"
EOF
  
  chmod 600 "$api_config_dir/keys.env"
  
  # Report what was found
  [[ -n "$anthropic_key" ]] && _print "${GREEN}✓ Anthropic API key fetched${NC}" || _print "${YELLOW}⚠ Anthropic API key not found${NC}"
  [[ -n "$openai_key" ]] && _print "${GREEN}✓ OpenAI API key fetched${NC}" || _print "${YELLOW}⚠ OpenAI API key not found${NC}"
  [[ -n "$github_token" ]] && _print "${GREEN}✓ GitHub token fetched${NC}" || _print "${YELLOW}⚠ GitHub token not found${NC}"
  
  _print "${GREEN}✓ API keys configuration created${NC}"
}

# Main execution
main() {
  _print "${GREEN}Bitwarden Secret Fetcher${NC}"
  
  local method
  method=$(determine_bw_method)
  
  case "$method" in
    "bws")
      _print "${BLUE}Using Bitwarden Secrets Manager${NC}"
      ;;
    "bw")
      _print "${BLUE}Using Bitwarden Password Manager${NC}"
      ;;
    "none")
      _print "${RED}No Bitwarden authentication available!${NC}"
      _print "${YELLOW}Setup options:${NC}"
      _print "${YELLOW}1. For Secrets Manager: Set BWS_ACCESS_TOKEN or create ~/.bws-token${NC}"
      _print "${YELLOW}2. For Password Manager: Run the apply script to authenticate${NC}"
      exit 1
      ;;
  esac
  
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