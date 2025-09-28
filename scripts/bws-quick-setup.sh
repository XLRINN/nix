#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

say() { echo -e "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "$script_dir/.." && pwd)"

if ! have age; then
  say "${RED}Missing 'age'. Run 'nix run .#build-switch' first, then re-run this script.${NC}"
  exit 1
fi

say "${BLUE}Bitwarden Secrets Manager: Quick Token Setup${NC}"
say "This will encrypt your BWS access token into ${repo_dir}/secrets/bws.token.age"

read -r -p "Paste your BWS access token: " token
if [ -z "$token" ]; then
  say "${RED}No token provided. Aborting.${NC}"
  exit 2
fi

read -r -s -p "Choose an encryption passphrase: " pass; echo
read -r -s -p "Confirm passphrase: " pass2; echo
if [ "$pass" != "$pass2" ]; then
  say "${RED}Passphrases do not match. Aborting.${NC}"
  exit 3
fi

say "Encrypting token..."
BWS_ACCESS_TOKEN="$token" BWS_TOKEN_PASSPHRASE="$pass" bash "$script_dir/prepare-bws-token.sh"

say "${GREEN}✓ Token encrypted.${NC}"
say "Next steps:" 
say "  - Commit the encrypted file: git add secrets/bws.token.age && git commit -m 'Add encrypted BWS token'"
say "  - On new machines: export BWS_TOKEN_PASSPHRASE='<your pass>' && nix run .#secrets"

