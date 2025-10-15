#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

say() { echo -e "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<EOF
Repair secrets on an installed system (no reinstall).

Steps:
  1) Configure rbw email from git
  2) rbw login / unlock / sync
  3) sopswarden-sync
  4) nixos-rebuild switch (impure) for the correct flake target

Options:
  --target <flake-target>   Override flake target (e.g., server-x86_64-linux)
  --flake  <path>           Override flake path (default: /etc/nixos)
  -h, --help                Show help
EOF
}

FLAKE="/etc/nixos"
TARGET=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --flake)  FLAKE="$2";  shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) say "${YELLOW}Unknown arg: $1${NC}"; usage; exit 2 ;;
  esac
done

arch=$(uname -m)
case "$arch" in
  x86_64) base="x86_64-linux" ;;
  aarch64) base="aarch64-linux" ;;
  *) say "${RED}Unsupported arch: $arch${NC}"; exit 1 ;;
esac

# Pick target if not provided: prefer server-<base> if it evaluates
pick_target() {
  local t
  if [[ -n "$TARGET" ]]; then echo "$TARGET"; return; fi
  t="server-${base}"
  if have nix && nix eval "${FLAKE}#nixosConfigurations.${t}.config.system.stateVersion" >/dev/null 2>&1; then
    echo "$t"; return
  fi
  echo "${base}"
}

TARGET=$(pick_target)
say "${CYAN}Using flake: ${FLAKE}#${TARGET}${NC}"

# Configure rbw email from repo or global git
EMAIL="$(git -C "$HOME/nix" config user.email 2>/dev/null || git config --global user.email || true)"
if [[ -z "${EMAIL}" ]]; then
  say "${RED}Could not determine email from git. Set RBW_EMAIL or configure git user.email.${NC}"
  exit 1
fi
say "${CYAN}Configuring rbw email: ${EMAIL}${NC}"
rbw config set email "${EMAIL}"
rbw config set pinentry pinentry-curses >/dev/null 2>&1 || true

# Login/unlock/sync
say "${CYAN}Logging into Bitwarden (rbw)...${NC}"
rbw login
say "${CYAN}Unlocking vault...${NC}"
rbw unlock
rbw sync || true

# Sync sops and rebuild
if have sopswarden-sync; then
  say "${CYAN}Syncing SOPS secrets (root)...${NC}"
  # Ensure target directory exists; sopswarden-sync expects root privileges
  sudo mkdir -p /var/lib/sopswarden >/dev/null 2>&1 || true
  sudo sopswarden-sync
else
  say "${YELLOW}sopswarden-sync not found in PATH; skipping SOPS sync.${NC}"
fi

# If a BWS token is available, also install user-level secrets (SSH key, env)
if [[ -z "${BWS_ACCESS_TOKEN:-}" && -f "$HOME/.secrets/bws.env" ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.secrets/bws.env"
fi
if [[ -n "${BWS_ACCESS_TOKEN:-}" ]]; then
  say "${CYAN}Installing BWS-managed user secrets (SSH key, env)...${NC}"
  if have nix; then
    nix run "$HOME/nix#secrets" || bash "$HOME/nix/scripts/secrets-wizard.sh" || true
  else
    bash "$HOME/nix/scripts/secrets-wizard.sh" || true
  fi
fi

say "${CYAN}Rebuilding system (impure) to materialize secrets...${NC}"
sudo nixos-rebuild switch --impure --flake "${FLAKE}#${TARGET}"

# Verify
ok=0
if [[ -d /run/secrets ]]; then
  say "${GREEN}✓ /run/secrets exists${NC}"
  ls -l /run/secrets || true
else
  say "${YELLOW}✗ /run/secrets not found (check SOPS config).${NC}"
  ok=1
fi

if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  perms=$(stat -c '%a' "$HOME/.ssh/id_ed25519" 2>/dev/null || stat -f '%Lp' "$HOME/.ssh/id_ed25519")
  say "${GREEN}✓ SSH key present (~/.ssh/id_ed25519, mode ${perms})${NC}"
else
  say "${YELLOW}✗ SSH key not found at ~/.ssh/id_ed25519 (check sops.secrets mapping).${NC}"
  ok=1
fi

exit $ok
