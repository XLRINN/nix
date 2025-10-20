#!/usr/bin/env bash
# Bitwarden CLI installer disabled; original script commented out below.
: <<'BITWARDEN_DISABLED'
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

say() { echo -e "$1"; }
have() { command -v "$1" >/dev/null 2>&1; }

if have bws; then
  say "${GREEN}bws already installed at $(command -v bws)${NC}"
  exit 0
fi

if ! have curl; then
  say "${RED}curl is required to download bws. Please install curl and re-run.${NC}"
  exit 1
fi

os=$(uname -s)
arch=$(uname -m)
case "$os" in
  Darwin)
    case "$arch" in
      arm64|aarch64) asset="bws-aarch64-apple-darwin.zip" ;;
      x86_64) asset="bws-x86_64-apple-darwin.zip" ;;
      *) say "${RED}Unsupported macOS arch: $arch${NC}"; exit 2 ;;
    esac
    ;;
  Linux)
    case "$arch" in
      x86_64|amd64) asset="bws-x86_64-unknown-linux-gnu.zip" ;;
      aarch64|arm64) asset="bws-aarch64-unknown-linux-gnu.zip" ;;
      *) say "${RED}Unsupported Linux arch: $arch${NC}"; exit 2 ;;
    esac
    ;;
  *)
    say "${RED}Unsupported OS: $os${NC}"
    exit 2
    ;;
esac

url="https://github.com/bitwarden/sdk/releases/latest/download/${asset}"
dest_dir="$HOME/.local/bin"
mkdir -p "$dest_dir"

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT
say "${YELLOW}Downloading bws from ${url}${NC}"
curl -fsSL "$url" -o "$tmpdir/bws.zip"

if have unzip; then
  unzip -o "$tmpdir/bws.zip" -d "$tmpdir" >/dev/null
else
  say "${YELLOW}unzip not found; attempting to extract without it (if the asset is not zipped this will still work).${NC}"
fi

if [ -f "$tmpdir/bws" ]; then
  install -m 0755 "$tmpdir/bws" "$dest_dir/bws"
else
  # Some assets may unpack to a directory
  found="$(find "$tmpdir" -maxdepth 2 -type f -name bws | head -n1 || true)"
  if [ -n "$found" ]; then
    install -m 0755 "$found" "$dest_dir/bws"
  else
    # As a fallback, try to treat the download as the binary
    if file "$tmpdir/bws.zip" | grep -qi 'executable'; then
      install -m 0755 "$tmpdir/bws.zip" "$dest_dir/bws"
    else
      say "${RED}Failed to extract bws binary from the downloaded asset.${NC}"
      exit 3
    fi
  fi
fi

say "${GREEN}Installed bws to ${dest_dir}/bws${NC}"
BITWARDEN_DISABLED
