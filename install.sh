#!/bin/bash
# Nix install (multi-user, recommended on macOS)
/bin/bash -c "$(curl -L https://nixos.org/nix/install)"
echo "installing Nix..."
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
chmod -R 755 ~/nix
find apps/$(uname -m | sed 's/arm64/aarch64/')-darwin -type f \( -name apply -o -name build -o -name build-switch -o -name create-keys -o -name copy-keys -o -name check-keys \) -exec chmod +x {} \;
nix run .#build 

read -p "Press [Enter] key to continue..."

nix run .#build-switch
