#!/usr/bin/env bash
# install-nix.sh
# Installs Nix and applies Home Manager config on any Linux distro.
# Handles both regular and atomic/immutable distros (Fedora Silverblue, etc.)
#
# Usage (run from the repo root):
#   bash scripts/install-nix.sh
#
# Or as a one-liner from anywhere:
#   bash <(curl -fsSL https://raw.githubusercontent.com/XLRINN/nix/main/scripts/install-nix.sh)

set -euo pipefail

# ── Colors & symbols ────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

CHECK="✅"
INFO="ℹ️"
WARNING="⚠️"
ERROR="❌"
ROCKET="🚀"
GEAR="⚙️"
PARTY="🎉"

_print() { echo -e "$1"; }
_info()  { _print "${CYAN}${INFO}  $*${NC}"; }
_ok()    { _print "${GREEN}${CHECK} $*${NC}"; }
_warn()  { _print "${YELLOW}${WARNING}  $*${NC}"; }
_die()   { _print "${RED}${ERROR} $*${NC}"; exit 1; }

# ── Detect distro type ──────────────────────────────────────────────────────
is_atomic() {
  # Fedora Silverblue / Kinoite / Sericea / uBlue and other ostree-based systems
  if [ -f /run/ostree-booted ] || \
     { command -v rpm-ostree &>/dev/null && rpm-ostree status &>/dev/null 2>&1; }; then
    return 0
  fi
  return 1
}

detect_arch() {
  local machine
  machine=$(uname -m)
  case "$machine" in
    x86_64)  echo "x86_64-linux" ;;
    aarch64) echo "aarch64-linux" ;;
    *) _die "Unsupported architecture: $machine" ;;
  esac
}

# ── Check if Nix is already installed ──────────────────────────────────────
nix_installed() {
  command -v nix &>/dev/null || [ -e /nix/store ]
}

# ── Install Nix ─────────────────────────────────────────────────────────────
install_nix() {
  if nix_installed; then
    _ok "Nix is already installed — skipping."
    return
  fi

  _print "\n${BLUE}${GEAR} Installing Nix...${NC}"

  if is_atomic; then
    _warn "Atomic/immutable distro detected (ostree-based)."
    _info "Using the Determinate Systems installer (handles immutable root + SELinux)."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
      | sh -s -- install --no-confirm
  else
    _info "Using the Determinate Systems installer (recommended for all Linux)."
    curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
      | sh -s -- install --no-confirm
  fi

  # Source Nix into the current shell session
  if [ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
    # shellcheck source=/dev/null
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  elif [ -e "$HOME/.nix-profile/etc/profile.d/nix.sh" ]; then
    # shellcheck source=/dev/null
    . "$HOME/.nix-profile/etc/profile.d/nix.sh"
  fi

  _ok "Nix installed successfully."
}

# ── Ensure flakes + nix-command are enabled ─────────────────────────────────
enable_flakes() {
  local cfg="$HOME/.config/nix/nix.conf"
  local needed="experimental-features = nix-command flakes"

  if grep -q "experimental-features" "$cfg" 2>/dev/null; then
    _ok "Flakes already enabled in $cfg."
    return
  fi

  _info "Enabling nix-command and flakes in $cfg"
  mkdir -p "$(dirname "$cfg")"
  echo "$needed" >> "$cfg"
  _ok "Flakes enabled."
}

# ── Clone or locate the repo ────────────────────────────────────────────────
locate_repo() {
  # If we're already inside the repo, use it
  if [ -f "$(git rev-parse --show-toplevel 2>/dev/null)/flake.nix" ] 2>/dev/null; then
    REPO_DIR="$(git rev-parse --show-toplevel)"
    _ok "Using existing repo at $REPO_DIR"
    return
  fi

  local default_dest="$HOME/nix"

  if [ -f "$default_dest/flake.nix" ]; then
    REPO_DIR="$default_dest"
    _ok "Found repo at $REPO_DIR"
    return
  fi

  _info "Cloning XLRINN/nix into $default_dest ..."
  git clone https://github.com/XLRINN/nix "$default_dest"
  REPO_DIR="$default_dest"
  _ok "Repo cloned to $REPO_DIR"
}

# ── Set up nix-ld (dynamic linker shim for third-party binaries) ────────────
# nix-ld intercepts calls to /lib64/ld-linux-x86-64.so.2 and redirects them
# through the Nix store, so pre-compiled binaries (e.g. downloaded CLIs,
# VSCode extensions, game launchers) work without manual patching.
#
# Skipped on NixOS (handled by the nixos module) and on atomic distros
# (ostree makes /lib64 read-only; nix-ld there needs a different setup).
setup_nix_ld() {
  if [ -f /etc/NIXOS ]; then
    _info "NixOS detected — nix-ld is managed by the NixOS module, skipping."
    return
  fi

  if is_atomic; then
    _warn "Atomic distro detected — skipping automatic nix-ld setup."
    _warn "Third-party binaries may need 'steam-run <binary>' to work."
    return
  fi

  if ! command -v systemd-tmpfiles &>/dev/null; then
    _warn "systemd-tmpfiles not found — skipping nix-ld setup."
    return
  fi

  _print "\n${BLUE}${GEAR} Setting up nix-ld (dynamic linker shim)...${NC}"

  local nix_ld_path
  nix_ld_path=$(nix build --no-link --print-out-paths nixpkgs#nix-ld \
    --extra-experimental-features "nix-command flakes" 2>/dev/null)/libexec/nix-ld

  if [ ! -f "$nix_ld_path" ]; then
    _warn "Could not build nix-ld — skipping. Third-party binaries may not run."
    return
  fi

  # Write a systemd-tmpfiles rule that creates the ld-linux stub at boot
  # (and immediately via --create). Re-running this script will update the path
  # when nixpkgs bumps nix-ld.
  local tmpfiles_conf="/etc/tmpfiles.d/nix-ld.conf"
  echo "L+ /lib64/ld-linux-x86-64.so.2 - - - - ${nix_ld_path}" \
    | sudo tee "$tmpfiles_conf" > /dev/null
  sudo systemd-tmpfiles --create "$tmpfiles_conf"

  _ok "nix-ld installed. Pre-compiled binaries will now work out of the box."
}

# ── Apply Home Manager ───────────────────────────────────────────────────────
apply_home_manager() {
  local arch
  arch=$(detect_arch)

  # Pick the right flake target
  local flake_target
  case "$arch" in
    x86_64-linux)  flake_target="david" ;;
    aarch64-linux) flake_target="david-aarch64" ;;
  esac

  _print "\n${BLUE}${ROCKET} Applying Home Manager config for ${flake_target}...${NC}"

  cd "$REPO_DIR"

  # Use `nix run` so home-manager doesn't need to be pre-installed
  nix run nixpkgs#home-manager -- switch \
    --flake ".#${flake_target}" \
    --extra-experimental-features "nix-command flakes" \
    -b backup

  _print "\n${GREEN}${PARTY} Home Manager applied!${NC}"
  _print "${CYAN}Your shell, tools, and dotfiles are now managed by Nix.${NC}"
  _print "${YELLOW}Restart your shell or run: source ~/.zshrc${NC}"
}

# ── Main ────────────────────────────────────────────────────────────────────
main() {
  clear
  _print "
    ███╗   ██╗██╗   ██╗██╗  ██╗
    ████╗  ██║╚██╗ ██╔╝╚██╗██╔╝
    ██╔██╗ ██║ ╚████╔╝  ╚███╔╝
    ██║╚██╗██║  ╚██╔╝   ██╔██╗
    ██║ ╚████║   ██║   ██╔╝ ██╗
    ╚═╝  ╚═══╝   ╚═╝   ╚═╝  ╚═╝
            --XLRINN--
  "
  _print "═══════════════════════════════════════"
  _print "  Nix + Home Manager bootstrap script  "
  _print "═══════════════════════════════════════"
  echo

  if [[ "$(uname)" == "Darwin" ]]; then
    _die "This script is for Linux only. For macOS, use the darwin apply script."
  fi

  install_nix
  enable_flakes
  setup_nix_ld
  locate_repo
  apply_home_manager
}

main "$@"
