#!/usr/bin/env bash
# Bitwarden token preparation disabled; original script commented out below.
: <<'BITWARDEN_DISABLED'
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

say() { echo -e "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

if ! have age; then
  say "${RED}age is required. Run 'nix run .#build-switch' to install dependencies, then re-run.${NC}"
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "$script_dir/.." && pwd)"
out_dir="$repo_dir/secrets"
out_file="$out_dir/bws.token.age"
mkdir -p "$out_dir"

token="${BWS_ACCESS_TOKEN:-}"
if [ -z "$token" ]; then
  read -r -p "Paste your BWS access token: " token
fi

pass="${BWS_TOKEN_PASSPHRASE:-}"
if [ -z "$pass" ]; then
  read -r -s -p "Choose a passphrase to encrypt the token: " pass; echo
  read -r -s -p "Confirm passphrase: " pass2; echo
  if [ "$pass" != "$pass2" ]; then
    say "${RED}Passphrases do not match.${NC}"
    exit 2
  fi
fi

export AGE_PASSPHRASE="$pass"
printf '%s' "$token" | age -p -o "$out_file"
chmod 600 "$out_file"
say "${GREEN}Encrypted token saved to: $out_file${NC}"
say "${YELLOW}You may commit this encrypted file to the repo. Keep the passphrase private.${NC}"
BITWARDEN_DISABLED
