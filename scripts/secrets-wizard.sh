#!/usr/bin/env bash
set -euo pipefail

BLUE='\033[1;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

say() {
  echo -e "$1"
}

have() {
  command -v "$1" >/dev/null 2>&1
}

main() {
  say "${BLUE}Bitwarden Secrets Sync${NC}"
  say "${YELLOW}This helper logs into rbw and runs sopswarden-sync.${NC}"

  if ! have rbw; then
    say "${RED}rbw is not installed or not in PATH.${NC}"
    exit 1
  fi

  say "${BLUE}Step 1:${NC} rbw login/unlock"
  if ! rbw login; then
    say "${YELLOW}rbw login returned non-zero (already logged in?). Continuing.${NC}"
  fi
  if ! rbw unlock; then
    say "${RED}rbw unlock failed. Ensure your vault credentials are correct and retry.${NC}"
    exit 1
  fi
  rbw sync || true

  say "${BLUE}Step 2:${NC} sopswarden sync"
  if have sopswarden-sync; then
    if sopswarden-sync; then
      say "${GREEN}✓ Secrets synchronized into /run/secrets.${NC}"
    else
      say "${YELLOW}sopswarden-sync exited with an error; check the logs above.${NC}"
    fi
  else
    say "${YELLOW}sopswarden-sync not found. Install sopswarden to populate /run/secrets.${NC}"
  fi

  say "${GREEN}Done. Rebuild with 'sudo nixos-rebuild switch' if needed.${NC}"
}

main "$@"
