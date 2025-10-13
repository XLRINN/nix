#!/usr/bin/env bash

# Non-interactive Secrets Setup for Bitwarden + sopswarden (NixOS) and Home-Manager (macOS/Linux)
# - Runs rbw login/unlock/sync (may prompt for credentials, but no Y/N prompts here)
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
  # Items are stored as notes under the 'nyx' folder. We fetch from that folder.
  get_secret() {
    local item="$1"
    local val
    # First try the password field within the nyx folder
    val=$(rbw get --folder "nyx" "$item" 2>/dev/null || true)
    # If empty, try including notes; pick first non-empty line
    if [ -z "${val//[\n\r\t\ ]/}" ]; then
      val=$(rbw get --full --folder "nyx" "$item" 2>/dev/null || true)
    fi
    # Trim to first non-empty line
    val=$(printf "%s" "$val" | awk 'NF{print; exit}')
    printf "%s" "$val"
  }

  # Fetch secrets
  # OpenAI for Codex
  openai_key=$(get_secret "OpenAI")
  # OpenRouter for Avante
  openrouter_key=$(get_secret "openrouter")

  # Write keys.env
  cat > "$api_config_dir/keys.env" << EOF
# API Keys fetched from Bitwarden via rbw
# This file is gitignored and regenerated
OPENAI_API_KEY="$openai_key"
OPENROUTER_API_KEY="$openrouter_key"
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

  # Pull keys by common names (support your naming: OpenAI, openrouter)
  local openai_key openrouter_key
  openai_key=$(printf '%s' "$json" | jq -r '[ .[] | select((.key=="OPENAI_API_KEY") or (.key=="OpenAI") or (.key=="openai")) | .value ][0]')
  openrouter_key=$(printf '%s' "$json" | jq -r '[ .[] | select((.key=="OPENROUTER_API_KEY") or (.key=="openrouter") or (.key=="OpenRouter")) | .value ][0]')

  cat > "$api_config_dir/keys.env" << EOF
# API Keys fetched from Bitwarden Secrets Manager (bws)
OPENAI_API_KEY="${openai_key:-}"
OPENROUTER_API_KEY="${openrouter_key:-}"
EOF
  chmod 600 "$api_config_dir/keys.env"
}

# Fetch GitHub SSH private key from Bitwarden Secrets Manager and write to ~/.ssh/id_ed25519
step_bws_sshkey() {
  say "${BLUE}BWS:${NC} Installing GitHub SSH key if available"
  if ! have jq; then
    say "${RED}jq is required for parsing BWS JSON.${NC}"
    return 1
  fi
  # Get secrets JSON, optionally filtered by project
  local json proj_id="${BWS_PROJECT_ID:-}"
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
    say "${YELLOW}No secrets returned from BWS; skipping SSH key install.${NC}"
    return 0
  fi
  # Try common keys for private key content (normalize key name by stripping non-alphanumerics)
  local pk
  pk=$(printf '%s' "$json" | jq -r '
    [ .[]
      | . as $s
      | ($s.key // "") as $k
      | ($k | ascii_downcase | gsub("[^a-z0-9]"; "")) as $norm
      | select($norm=="githubsshkey" or $norm=="githubprivatekey" or $norm=="ided25519github" or $norm=="ided25519")
      | .value
    ][0]')
  if [ -z "${pk:-}" ] || [ "$pk" = "null" ]; then
    say "${YELLOW}GitHub SSH key not found in BWS (expected key names like github-ssh-key).${NC}"
    return 0
  fi
  # Ensure .ssh directory and write the key
  local sshdir keyfile
  sshdir="${HOME}/.ssh"
  keyfile="${sshdir}/id_ed25519"
  mkdir -p "$sshdir"
  chmod 700 "$sshdir"
  printf "%s\n" "$pk" > "$keyfile"
  chmod 600 "$keyfile"
  say "${GREEN}✓ Installed SSH key at ${keyfile}${NC}"
}

verify_envfile() {
  local f="$HOME/.local/share/src/nixos-config/modules/shared/config/api-keys/keys.env"
  say "${BLUE}Verify:${NC} checking keys at $f"
  if [ -f "$f" ]; then
    grep -E 'OPENAI_API_KEY|OPENROUTER_API_KEY' -n "$f" || true
    if grep -qE 'OPENAI_API_KEY=""|OPENROUTER_API_KEY=""' "$f"; then
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

  # Prefer Bitwarden Secrets Manager (bws) if an access token is present
  ensure_bws || true
  ensure_token_from_age || true
  if [ -n "${BWS_ACCESS_TOKEN:-}" ] && ( have bws || have_docker ); then
    say "${BLUE}Detected BWS access token; using Secrets Manager for fetching keys.${NC}"
    step_bws_envfile || true
    # Attempt to place GitHub SSH key directly if present in BWS
    if have jq; then
      step_bws_sshkey || true
    else
      say "${YELLOW}jq not available; skipping SSH key fetch from BWS. Install jq and re-run 'secrets'.${NC}"
    fi
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
