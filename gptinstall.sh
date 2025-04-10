#!/bin/bash

set -e

# Enable flakes
echo "Enabling Nix flakes support..."
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf

# Permissions for nix folder
chmod -R 755 ~/nix

# Make app binaries executable
echo "Making app scripts executable..."
find apps/$(uname -m | sed 's/arm64/aarch64/')-darwin -type f \
  \( -name apply -o -name build -o -name build-switch -o -name create-keys -o -name copy-keys -o -name check-keys \) \
  -exec chmod +x {} \;

# Run Nix build
echo "Running nix build..."
nix run .#build
nix run .#build-switch

# Create download directory
DOWNLOAD_DIR=~/Downloads/tools
mkdir -p "$DOWNLOAD_DIR"

#################################
# Download DMGs
#################################

# Download Synergy
echo "Downloading Synergy..."
wget -O "$DOWNLOAD_DIR/synergy.dmg" https://symless.com/synergy/download/direct/mac

# Download Nebula
echo "Downloading Nebula..."
wget -O "$DOWNLOAD_DIR/nebula.zip" https://github.com/slackhq/nebula/releases/latest/download/nebula-darwin-amd64.zip

# Download ChatGPT
echo "Downloading ChatGPT..."
CHATGPT_DMG_URL="https://chat.openai.com/apps/mac/latest"
CHATGPT_DMG_PATH="$DOWNLOAD_DIR/ChatGPT.dmg"
wget -O "$CHATGPT_DMG_PATH" "$CHATGPT_DMG_URL"

# Install ChatGPT
echo "Mounting ChatGPT.dmg..."
MOUNT_DIR=$(hdiutil attach "$CHATGPT_DMG_PATH" | grep "/Volumes/" | awk '{print $3}')

if [ -d "$MOUNT_DIR" ]; then
  echo "Installing ChatGPT to /Applications..."
  cp -R "$MOUNT_DIR/ChatGPT.app" /Applications/
  echo "Unmounting ChatGPT.dmg..."
  hdiutil detach "$MOUNT_DIR"
else
  echo "❌ Failed to mount ChatGPT.dmg"
fi

echo "✅ Install script complete."
