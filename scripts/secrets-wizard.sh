#!/usr/bin/env bash

# Non-interactive Secrets Setup for Bitwarden + sopswarden (NixOS) and Home-Manager (macOS/Linux)
# - Offers choice between machine token (bws) or personal credentials on startup
# - Runs rbw login/unlock/sync (may prompt for credentials)
# - NixOS: runs sopswarden sync if available
# - macOS/others: generates keys.env directly using rbw (no dependency on `bw` CLI)
# - Verifies availability and prints concise next steps

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

say() { echo -e "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

# Docker/bws helpers
have_docker() { command -v docker >/dev/null 2>&1; }
bws_cmd() {
  if have bws; then
    BWS_ACCESS_TOKEN="$BWS_ACCESS_TOKEN" bws "$@"
  elif have_docker; then
    docker run --rm -e BWS_ACCESS_TOKEN="$BWS_ACCESS_TOKEN" bitwarden/bws "$@"
  else
    return 127
  fi
}

ensure_bws() {
  if have bws || have_docker; then
    return 0
  fi
  # Attempt to install bws to ~/.local/bin using the helper script if available
  local helper="$HOME/nix/scripts/install-bws.sh"
  if [ -x "$helper" ]; then
    bash "$helper" || true
  fi
}

ensure_token_from_age() {
  # If BWS_ACCESS_TOKEN is unset, try decrypting an age-encrypted token file in repo
  if [ -n "${BWS_ACCESS_TOKEN:-}" ]; then
    return 0
  fi
  local script_dir repo_dir enc
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo_dir="$(cd "$script_dir/.." && pwd)"
  enc="$repo_dir/secrets/bws.token.age"
  if [ ! -f "$enc" ]; then
    return 0
  fi
  if ! have age; then
    say "${YELLOW}age not found; run 'nix run .#build-switch' to install dependencies, then re-run 'unlock'.${NC}"
    return 1
  fi
  # Use BWS_TOKEN_PASSPHRASE if provided; otherwise age will prompt
  if [ -n "${BWS_TOKEN_PASSPHRASE:-}" ]; then
    export AGE_PASSPHRASE="$BWS_TOKEN_PASSPHRASE"
  fi
  local token
  # Decrypt passphrase-protected file; do NOT pass -p with -d
  if token=$(age -d "$enc" 2>/dev/null); then
    export BWS_ACCESS_TOKEN="$token"
    return 0
  fi
  # Fallback to interactive prompt via age if passphrase wasn't set
  token=$(AGE_PASSPHRASE="" age -d "$enc") || return 1
  export BWS_ACCESS_TOKEN="$token"
}

detect_platform() {
  local os="$(uname -s)"
  case "$os" in
    Linux)
      if [ -f /etc/os-release ] && grep -qi nixos /etc/os-release; then
        echo "nixos"
      else
        echo "linux"
      fi
      ;;
    Darwin) echo "darwin" ;;
    *) echo "unknown" ;;
  esac
}

verify_rbw() {
  if ! have rbw; then
    say "${RED}rbw not found in PATH.${NC}"
    say "Install it via Home Manager or nixpkgs, then re-run."
    exit 1
  fi
}

verify_bw() {
  if ! have bw; then
    say "${YELLOW}bitwarden-cli (bw) not found; skipping bw unlock path.${NC}"
    return 1
  fi
}

step_bw_login_unlock() {
  say "${BLUE}Step 1:${NC} bw login/unlock (interactive; prompts for master password and 2FA)"
  # Login (no-op if already logged in)
  if ! bw login; then
    say "${YELLOW}bw login returned non-zero (may already be logged in). Continuing.${NC}"
  fi
  # Unlock and capture session token
  local session
  if ! session=$(bw unlock --raw); then
    say "${RED}bw unlock failed. Check your master password/2FA and try again.${NC}"
    exit 1
  fi
  export BW_SESSION="$session"
  mkdir -p "$HOME/.cache"
  printf '%s' "$session" > "$HOME/.cache/bw-session"
  bw sync >/dev/null 2>&1 || true
}

step_bw_envfile() {
  say "${BLUE}Step 2:${NC} Generate per-user env file (keys.env) via bw"
  if ! have jq; then
    say "${YELLOW}jq not found; proceeding without JSON parsing (password-only fetch).${NC}"
  fi
  local api_config_dir="$HOME/.local/share/src/nixos-config/modules/shared/config/api-keys"
  mkdir -p "$api_config_dir"

  get_from_bw_password() {
    local name="$1"
    bw get password "$name" 2>/dev/null || true
  }
  get_from_bw_item_field() {
    local name="$1" field="$2"
    if have jq; then
      bw get item "$name" 2>/dev/null | jq -r --arg F "$field" '
        (.fields[]? | select((.name|ascii_downcase)==($F|ascii_downcase)) | .value) //
        (.login.password // empty) //
        (.notes // empty)
      ' | awk 'NF{print; exit}'
    else
      printf ''
    fi
  }

  # Try password first, then fall back to common field names or notes
  local openai_key openrouter_key github_token
  openai_key=$(get_from_bw_password "OpenAI")
  if [ -z "${openai_key//[\n\r\t\ ]/}" ]; then
    openai_key=$(get_from_bw_item_field "OpenAI" "OPENAI_API_KEY")
  fi

  openrouter_key=$(get_from_bw_password "openrouter")
  if [ -z "${openrouter_key//[\n\r\t\ ]/}" ]; then
    openrouter_key=$(get_from_bw_item_field "openrouter" "OPENROUTER_API_KEY")
  fi

  github_token=$(get_from_bw_password "GitHub Token")
  if [ -z "${github_token//[\n\r\t\ ]/}" ]; then
    github_token=$(get_from_bw_password "github-token")
  fi
  if [ -z "${github_token//[\n\r\t\ ]/}" ]; then
    github_token=$(get_from_bw_item_field "GitHub Token" "GITHUB_TOKEN")
  fi

  cat > "$api_config_dir/keys.env" << EOF
# API Keys fetched from Bitwarden (bw)
# This file is gitignored and regenerated
OPENAI_API_KEY="${openai_key}"
OPENROUTER_API_KEY="${openrouter_key}"
GITHUB_TOKEN="${github_token}"
EOF
  chmod 600 "$api_config_dir/keys.env"
}

configure_rbw() {
  # Ensure rbw has at least 'email' configured. Support optional base/identity URLs via env.
  local os="$(uname -s)"
  local cfg
  if [ "$os" = "Darwin" ]; then
    cfg="$HOME/Library/Application Support/rbw/config.json"
  else
    cfg="${XDG_CONFIG_HOME:-$HOME/.config}/rbw/config.json"
  fi

  # Determine email
  local email="${RBW_EMAIL:-}"
  if [ -z "$email" ]; then
    email="$(git config --global user.email 2>/dev/null || true)"
  fi
  if [ -z "$email" ] && [ -f "modules/shared/home-manager.nix" ]; then
    email="$(sed -n '1,120p' modules/shared/home-manager.nix | awk -F'"' '/^\s*email\s*=\s*"/ { print $2; exit }')"
  fi

  if [ ! -f "$cfg" ]; then
    if [ -z "$email" ]; then
      say "${RED}rbw is not configured and no email could be determined.${NC}"
      say "Set RBW_EMAIL=<your-email> and re-run 'unlock'."
      exit 1
    fi
    say "Configuring rbw with email: ${BLUE}$email${NC}"
    rbw config set email "$email" || true
    # Sensible defaults for convenience
    rbw config set lock_timeout 43200 >/dev/null 2>&1 || true   # 12h
    rbw config set sync_interval 3600 >/dev/null 2>&1 || true   # 1h
    # Optional overrides for self-hosted setups
    if [ -n "${RBW_BASE_URL:-}" ]; then
      rbw config set base_url "$RBW_BASE_URL" || true
    fi
    if [ -n "${RBW_IDENTITY_URL:-}" ]; then
      rbw config set identity_url "$RBW_IDENTITY_URL" || true
    fi
  fi
}

configure_pinentry() {
  # Ensure rbw points to an available pinentry program
  local chosen=""
  if have pinentry-mac; then
    chosen="pinentry-mac"
  elif have pinentry-curses; then
    chosen="pinentry-curses"
  elif have pinentry-tty; then
    chosen="pinentry-tty"
  elif have pinentry; then
    chosen="pinentry"
  fi

  if [ -n "$chosen" ]; then
    rbw config set pinentry "$chosen" >/dev/null 2>&1 || true
    say "Using pinentry program: ${BLUE}$chosen${NC}"
  else
    say "${YELLOW}No pinentry program found. Install 'pinentry' (and/or 'pinentry-mac' on macOS) and re-run 'unlock'.${NC}"
  fi
}

step_login_unlock() {
  say "${BLUE}Step 1:${NC} rbw login/unlock/sync"
  # These commands may prompt for credentials; we don't add our own prompts
  if ! rbw login; then
    say "${YELLOW}rbw login returned non-zero (may already be logged in). Continuing.${NC}"
  fi
  if ! rbw unlock; then
    say "${RED}rbw unlock failed. Ensure your vault is initialized, then re-run 'unlock'.${NC}"
    exit 1
  fi
  rbw sync || true
}

step_nixos_sync() {
  say "${BLUE}Step 2:${NC} Sync secrets to SOPS via sopswarden"
  if ! have sopswarden-sync; then
    say "${YELLOW}Skipping: 'sopswarden-sync' not found in PATH.${NC}"
    return 0
  fi
  rbw sync || true
  sopswarden-sync || true
  # Do not force a rebuild here; user can run their usual switch command
}

step_macos_envfile() {
  say "${BLUE}Step 2:${NC} Generate per-user env file (keys.env) via rbw"
  local api_config_dir="$HOME/.local/share/src/nixos-config/modules/shared/config/api-keys"
  mkdir -p "$api_config_dir"

  # Helper: get value for an item, prefer custom field, fallback to password
  # Items are expected under a folder (default: 'nyx'). You can override with RBW_FOLDER.
  get_secret() {
    local item="$1"
    local val folder
    folder="${RBW_FOLDER:-nyx}"
    # First try the password field within the configured folder
    val=$(rbw get --folder "$folder" "$item" 2>/dev/null || true)
    # If empty, try including notes; pick first non-empty line
    if [ -z "${val//[\n\r\t\ ]/}" ]; then
      val=$(rbw get --full --folder "$folder" "$item" 2>/dev/null || true)
    fi
    # If still empty, fall back to a global search (no folder restriction)
    if [ -z "${val//[\n\r\t\ ]/}" ]; then
      val=$(rbw get "$item" 2>/dev/null || true)
      if [ -z "${val//[\n\r\t\ ]/}" ]; then
        val=$(rbw get --full "$item" 2>/dev/null || true)
      fi
    fi
    # Trim to first non-empty line
    val=$(printf "%s" "$val" | awk 'NF{print; exit}')
    printf "%s" "$val"
  }

  # Fetch secrets with multiple common names
  # OpenAI for Codex
  openai_key=$(get_secret "OPENAI_API_KEY")
  if [ -z "${openai_key//[\n\r\t\ ]/}" ]; then openai_key=$(get_secret "OpenAI"); fi
  if [ -z "${openai_key//[\n\r\t\ ]/}" ]; then openai_key=$(get_secret "openai"); fi
  if [ -z "${openai_key//[\n\r\t\ ]/}" ]; then openai_key=$(get_secret "OpenAI API"); fi
  # OpenRouter for Avante
  openrouter_key=$(get_secret "OPENROUTER_API_KEY")
  if [ -z "${openrouter_key//[\n\r\t\ ]/}" ]; then openrouter_key=$(get_secret "openrouter"); fi
  if [ -z "${openrouter_key//[\n\r\t\ ]/}" ]; then openrouter_key=$(get_secret "OpenRouter"); fi
  if [ -z "${openrouter_key//[\n\r\t\ ]/}" ]; then openrouter_key=$(get_secret "OpenRouter API"); fi
  # GitHub PAT (accept many common names)
  github_token=$(get_secret "GITHUB_TOKEN")
  if [ -z "${github_token//[\n\r\t\ ]/}" ]; then github_token=$(get_secret "GitHub Token"); fi
  if [ -z "${github_token//[\n\r\t\ ]/}" ]; then github_token=$(get_secret "github-token"); fi
  if [ -z "${github_token//[\n\r\t\ ]/}" ]; then github_token=$(get_secret "GitHub"); fi
  if [ -z "${github_token//[\n\r\t\ ]/}" ]; then github_token=$(get_secret "github"); fi
  if [ -z "${github_token//[\n\r\t\ ]/}" ]; then github_token=$(get_secret "gh-token"); fi
  if [ -z "${github_token//[\n\r\t\ ]/}" ]; then github_token=$(get_secret "GH_TOKEN"); fi

  # Write keys.env
  # Compute mirrored values for convenience
  local out_openai="$openai_key"
  if [ -z "${out_openai//[\n\r\t\ ]/}" ] && [ -n "${openrouter_key//[\n\r\t\ ]/}" ]; then
    out_openai="$openrouter_key"
  fi

  cat > "$api_config_dir/keys.env" << EOF
# API Keys fetched from Bitwarden via rbw
# This file is gitignored and regenerated
OPENAI_API_KEY="$out_openai"
OPENROUTER_API_KEY="$openrouter_key"
GITHUB_TOKEN="${github_token}"
GH_TOKEN="${github_token}"
EOF
  chmod 600 "$api_config_dir/keys.env"

  # Tailscale intentionally left untouched per user request
}

verify_nixos() {
  say "${BLUE}Verify:${NC} checking /run/secrets"
  if [ -d /run/secrets ]; then
    ls -l /run/secrets || true
  else
    say "${YELLOW}/run/secrets not found (expected on NixOS).${NC}"
  fi
}

prompt_auth_method() {
  case "${UNLOCK_MODE:-}" in
    machine|MACHINE)
      AUTH_METHOD="machine"
      return
      ;;
    personal|PERSONAL)
      AUTH_METHOD="personal"
      return
      ;;
  esac

  local have_machine=0 default_choice=2
  if [ -n "${BWS_ACCESS_TOKEN:-}" ]; then
    have_machine=1
  fi
  if [ "$have_machine" -eq 1 ] && ( have bws || have_docker ); then
    default_choice=1
  fi

  if ! [ -t 0 ]; then
    if [ "$default_choice" -eq 1 ]; then
      AUTH_METHOD="machine"
    else
      AUTH_METHOD="personal"
    fi
    return
  fi

  say ""
  say "${BLUE}Choose how to authenticate with Bitwarden:${NC}"
  say "  ${GREEN}1${NC}) Machine token (Bitwarden Secrets Manager via bws)"
  say "  ${GREEN}2${NC}) Personal credentials (rbw/bw login)"
  local choice
  read -r -p "Enter choice [${default_choice}]: " choice || true
  choice="${choice:-$default_choice}"
  case "$choice" in
    1) AUTH_METHOD="machine" ;;
    2) AUTH_METHOD="personal" ;;
    *)
      say "${YELLOW}Unrecognized option '${choice}'. Defaulting to option ${default_choice}.${NC}"
      if [ "$default_choice" -eq 1 ]; then
        AUTH_METHOD="machine"
      else
        AUTH_METHOD="personal"
      fi
      ;;
  esac
}

step_bws_envfile() {
  say "${BLUE}BWS:${NC} Generating keys.env from Secrets Manager"
  if ! have jq; then
    say "${RED}jq is required to parse bws output. Install jq and re-run.${NC}"
    return 1
  fi
  local api_config_dir="$HOME/.local/share/src/nixos-config/modules/shared/config/api-keys"
  mkdir -p "$api_config_dir"

  # Fetch list of secrets (optionally by project)
  local json
  local proj_id="${BWS_PROJECT_ID:-}"
  # Resolve project id by name if not provided
  if [ -z "$proj_id" ] && [ -n "${BWS_PROJECT_NAME:-}" ]; then
    local projects
    projects=$(bws_cmd project list --output json 2>/dev/null || true)
    if [ -n "$projects" ]; then
      proj_id=$(printf '%s' "$projects" | jq -r --arg NAME "${BWS_PROJECT_NAME}" '.[] | select(.name==$NAME) | .id' | head -n1)
    fi
  fi
  if [ -n "$proj_id" ]; then
    json=$(bws_cmd secret list --output json --project-id "$proj_id" 2>/dev/null || true)
  else
    json=$(bws_cmd secret list --output json 2>/dev/null || true)
  fi
  if [ -z "$json" ]; then
    say "${RED}bws returned no data. Check BWS_ACCESS_TOKEN (and optional BWS_PROJECT_ID).${NC}"
    return 1
  fi

  # Pull keys by common names (support your naming: OpenAI, OpenAI API; openrouter, OpenRouter API; GitHub Token)
  local openai_key openrouter_key github_token
  openai_key=$(printf '%s' "$json" | jq -r '[ .[] | select((.key=="OPENAI_API_KEY") or (.key=="OpenAI") or (.key=="openai")) | .value ][0]')
  if [ -z "${openai_key//[\n\r\t\ ]/}" ]; then
    openai_key=$(printf '%s' "$json" | jq -r '[ .[] | select((.key=="OpenAI API")) | .value ][0]')
  fi
  openrouter_key=$(printf '%s' "$json" | jq -r '[ .[] | select((.key=="OPENROUTER_API_KEY") or (.key=="openrouter") or (.key=="OpenRouter")) | .value ][0]')
  if [ -z "${openrouter_key//[\n\r\t\ ]/}" ]; then
    openrouter_key=$(printf '%s' "$json" | jq -r '[ .[] | select((.key=="OpenRouter API")) | .value ][0]')
  fi
  github_token=$(printf '%s' "$json" | jq -r '[ .[] | select((.key=="GITHUB_TOKEN") or (.key=="github-token") or (.key=="GitHub Token") or (.key=="GitHub") or (.key=="github") or (.key=="gh-token") or (.key=="GH_TOKEN")) | .value ][0]')

  # Compute mirrored values for convenience
  local out_openai
  out_openai="$openai_key"
  if [ -z "${out_openai//[\n\r\t\ ]/}" ] && [ -n "${openrouter_key//[\n\r\t\ ]/}" ]; then
    out_openai="$openrouter_key"
  fi

  cat > "$api_config_dir/keys.env" << EOF
# API Keys fetched from Bitwarden Secrets Manager (bws)
OPENAI_API_KEY="${out_openai:-}"
OPENROUTER_API_KEY="${openrouter_key:-}"
GITHUB_TOKEN="${github_token:-}"
GH_TOKEN="${github_token:-}"
EOF
  chmod 600 "$api_config_dir/keys.env"
}

verify_envfile() {
  local f="$HOME/.local/share/src/nixos-config/modules/shared/config/api-keys/keys.env"
  say "${BLUE}Verify:${NC} checking keys at $f"
  if [ -f "$f" ]; then
    grep -E 'OPENAI_API_KEY|OPENROUTER_API_KEY|GITHUB_TOKEN' -n "$f" || true
    if grep -qE 'OPENAI_API_KEY=""|OPENROUTER_API_KEY=""|GITHUB_TOKEN=""' "$f"; then
      say "${YELLOW}keys.env written but one or more values are empty. Check Bitwarden items in the 'nyx' folder (OpenAI, openrouter).${NC}"
    else
      say "${GREEN}✓ keys.env present. Open a new shell or run 'load-api-keys'.${NC}"
    fi
  else
    say "${YELLOW}keys.env not found. Re-run the fetch step or check Bitwarden items.${NC}"
  fi
}

post_notes_nixos() {
  cat <<'EON'

Next steps (NixOS):
- Use aliases: 'sops-sync', 'sops-deploy', 'sops-check'
- Secrets should be available at /run/secrets/{openrouter-api-key,github-token,openai-api-key}
- If a secret is missing, ensure Bitwarden items exist with correct names/fields, then re-sync
EON
}

post_notes_macos() {
  cat <<'EON'

Next steps (macOS/Home-Manager):
- New shells auto-load keys.env; to load now, run: load-api-keys
- Verify: check-keys
- Neovim/CLI tools will read env vars directly
EON
}

main() {
  say "${GREEN}Secrets Setup Wizard${NC}"
  say "Running non-interactive setup for Bitwarden-backed secrets."

  # Avoid running as root; re-run as invoking user if possible
  if [ "$(id -u)" -eq 0 ]; then
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
      say "${YELLOW}Detected root execution; re-running as ${SUDO_USER}.${NC}"
      exec sudo -u "$SUDO_USER" -E bash "$0"
    else
      say "${RED}Do not run this script as root. Run 'unlock' as your normal user.${NC}"
      exit 1
    fi
  fi

  # Prepare optional machine token flow
  ensure_bws || true
  ensure_token_from_age || true
  prompt_auth_method

  if [ "${AUTH_METHOD}" = "machine" ]; then
    if [ -z "${BWS_ACCESS_TOKEN:-}" ]; then
      if [ -t 0 ]; then
        say "${CYAN}Paste your Bitwarden Secrets Manager machine token (input hidden):${NC}"
        read -r -s BWS_ACCESS_TOKEN || true
        echo
      fi
    fi
    if [ -z "${BWS_ACCESS_TOKEN:-}" ]; then
      say "${YELLOW}No machine token available; falling back to personal credentials.${NC}"
      AUTH_METHOD="personal"
    elif ! ( have bws || have_docker ); then
      say "${YELLOW}Bitwarden Secrets Manager CLI (bws) not available; falling back to personal credentials.${NC}"
      AUTH_METHOD="personal"
    elif [ "${FORCE_BW:-0}" = "1" ]; then
      AUTH_METHOD="personal"
    else
      export BWS_ACCESS_TOKEN
      if step_bws_envfile; then
        verify_envfile
        post_notes_macos
        say "\n${GREEN}All done.${NC}"
        exit 0
      else
        say "${YELLOW}Machine token flow failed; falling back to personal credentials.${NC}"
        AUTH_METHOD="personal"
      fi
    fi
  fi

  # Prefer the official bw unlocker if available or if forced
  if [ "${AUTH_METHOD}" = "personal" ] && verify_bw; then
    step_bw_login_unlock
    step_bw_envfile
    verify_envfile
    post_notes_macos
    say "\n${GREEN}All done.${NC}"
    exit 0
  fi

  # Fallback to personal vault via rbw
  verify_rbw
  configure_rbw
  configure_pinentry
  local plat
  plat="$(detect_platform)"
  say "Detected platform: ${BLUE}${plat}${NC}"

  step_login_unlock

  case "$plat" in
    nixos)
      step_nixos_sync
      verify_nixos
      post_notes_nixos
      ;;
    darwin|linux|unknown)
      step_macos_envfile
      verify_envfile
      post_notes_macos
      ;;
  esac

  say "\n${GREEN}All done.${NC}"
}

main "$@"
