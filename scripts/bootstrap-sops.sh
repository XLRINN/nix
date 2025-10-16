#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
say() { echo -e "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOPS_FILE="${ROOT}/secrets/common.yaml"
SOPS_DIR="${ROOT}/secrets"
AGE_DIR="${HOME}/.config/sops/age"
AGE_KEY_FILE="${AGE_DIR}/keys.txt"

# Resolve Git email if available
GIT_EMAIL="$(git -C "$HOME/nix" config user.email 2>/dev/null || git config --global user.email 2>/dev/null || true)"

require_tools() {
  local missing=()
  for t in sops age-keygen ssh-keygen; do
    if ! have "$t"; then missing+=("$t"); fi
  done
  if (( ${#missing[@]} )); then
    say "${YELLOW}Missing tools: ${missing[*]}${NC}"
    say "Install them (e.g., nix shell nixpkgs#{sops,age,openssh}) or rerun inside your dev shell (nix develop)."
    exit 1
  fi
}

ensure_age_key() {
  # If a key exists, keep it. Otherwise generate one.
  if [[ -s "$AGE_KEY_FILE" ]]; then
    say "${CYAN}Using existing Age key at ${AGE_KEY_FILE}${NC}"
  else
    say "${CYAN}Generating a new Age key at ${AGE_KEY_FILE}${NC}"
    mkdir -p "$AGE_DIR"
    umask 0077
    age-keygen -o "$AGE_KEY_FILE" >/dev/null
  fi
  local RECIPIENT
  RECIPIENT=$(age-keygen -y "$AGE_KEY_FILE")
  say "${GREEN}✓ Age recipient:${NC} ${RECIPIENT}"
  # Deterministically write .sops.yaml for this repo
  local SOPS_YAML
  SOPS_YAML="$ROOT/.sops.yaml"
  if [[ -f "$SOPS_YAML" ]]; then
    cp "$SOPS_YAML" "$SOPS_YAML.bak.$(date +%s)" >/dev/null 2>&1 || true
  fi
  say "${CYAN}Writing ${SOPS_YAML} with your Age recipient...${NC}"
  cat > "$SOPS_YAML" <<YAML
creation_rules:
  - path_regex: secrets/common.yaml$
    key_groups:
      - age:
          - $RECIPIENT
YAML
} 

prompt_github_key() {
  say "${CYAN}Do you want to paste an existing GitHub SSH private key, or generate a new one?${NC}"
  select choice in "Paste existing" "Generate new"; do
    case $REPLY in
      1)
        say "${YELLOW}Paste your OpenSSH private key (end with EOF on an empty line):${NC}"
        local key_lines line
        key_lines=""
        while IFS= read -r line; do
          [[ -z "$line" ]] && break
          key_lines+="$line\n"
        done
        if [[ -z "${key_lines//\n/}" ]]; then
          say "${RED}No key provided. Aborting.${NC}"; exit 1
        fi
        SSH_PRIV="$key_lines"
        SSH_PUB=""
        break
        ;;
      2)
        local tmpdir
        tmpdir="$(mktemp -d)"
        local email; email="${GIT_EMAIL:-github-key}" 
        say "${CYAN}Generating ed25519 key pair (no passphrase)${NC}"
        ssh-keygen -t ed25519 -C "$email" -N "" -f "$tmpdir/id_ed25519" >/dev/null
        SSH_PRIV="$(cat "$tmpdir/id_ed25519")"
        SSH_PUB="$(cat "$tmpdir/id_ed25519.pub")"
        rm -rf "$tmpdir"
        say "${GREEN}✓ Public key (add to GitHub):${NC}\n$SSH_PUB"
        break
        ;;
      *) say "${YELLOW}Choose 1 or 2.${NC}";;
    esac
  done
}

write_sops_common() {
  mkdir -p "$SOPS_DIR"
  say "${CYAN}Creating ${SOPS_FILE} (encrypted) with your SSH key...${NC}"
  (
    cd "$ROOT"
    # Write plaintext YAML at the target relative path so creation_rules match
    {
      echo "ssh_private_key: |"
      printf "%s\n" "$SSH_PRIV" | sed 's/^/  /'
    } > "secrets/common.yaml"
    # Encrypt in-place so .sops.yaml creation rule is applied
    sops -e -i "secrets/common.yaml"
  )
  say "${GREEN}✓ Stored SSH private key in ${SOPS_FILE} (encrypted).${NC}"
}

post_notes() {
  cat <<EOF

Next steps:
- During install, provide the Age private key (env AGE_PRIVATE_KEY or file path in Apply).
- After first boot, verify:
  - ~/.ssh/id_ed25519 exists (600)
  - ssh -T git@github.com works
- Optional system secrets can be added to ${SOPS_FILE} later (tailscale-auth-key, openrouter-api-key, github-token).
EOF
}

main() {
  require_tools
  ensure_age_key
  prompt_github_key
  write_sops_common
  post_notes
}

main "$@"
