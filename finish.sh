#!/usr/bin/env bash

# Sync master branch and make it current
# This script pulls from master and updates the current branch

set -e

echo "🔄 Syncing with master branch..."

# Get the current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo "❌ Error: Not in a git repository"
    echo "Please run this script from your nix directory"
    exit 1
fi

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "📍 Current branch: $CURRENT_BRANCH"

# Check authentication
echo "🔐 Checking git authentication..."
if ! git ls-remote origin > /dev/null 2>&1; then
    echo "❌ Error: Cannot access remote repository. Please ensure you're authenticated:"
    echo "   git config --global user.name 'your-name'"
    echo "   git config --global user.email 'your-email'"
    echo "   # Or set up SSH keys / GitHub CLI"
    exit 1
fi

# Fetch latest changes from remote
echo "📥 Fetching latest changes from remote..."
git fetch origin

# Show available branches
echo "🌿 Available branches:"
git branch -r

# Ask user what they want to do
echo ""
echo "What would you like to do?"
echo "1) Switch to master and pull latest"
echo "2) Merge master into current branch"
echo "3) Just fetch (no changes)"
echo "4) Setup authentication (Bitwarden, GitHub, Firefox)"
read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo "🔄 Switching to master and pulling latest..."
        git checkout master 2>/dev/null || git checkout -b master origin/master
        git pull origin master
        echo "✅ Now on master with latest changes"
        ;;
    2)
        echo "🔄 Merging master into $CURRENT_BRANCH..."
        git checkout master 2>/dev/null || git checkout -b master origin/master
        git pull origin master
        git checkout "$CURRENT_BRANCH"
        git merge master --no-edit
        echo "✅ Successfully merged master into $CURRENT_BRANCH"
        ;;
    3)
        echo "✅ Just fetched, no changes made"
        ;;
    4)
        echo "🔐 Setting up authentication..."
        
        # GitHub CLI authentication (FIRST - handles git auth)
        echo "📋 Setting up GitHub CLI (FIRST - handles git authentication)..."
        if command -v gh &> /dev/null; then
            echo "GitHub CLI found. Running authentication..."
            echo "This will set up git authentication for all future operations."
            gh auth login
        else
            echo "❌ GitHub CLI not found. Please install it first."
        fi
        
        # Bitwarden CLI authentication (SECOND - contains all passkeys)
        echo "🔑 Setting up Bitwarden CLI (SECOND - contains all your passkeys)..."
        if command -v bw &> /dev/null; then
            echo "Bitwarden CLI found. Please login:"
            echo "1. Run: bw login"
            echo "2. Enter your Bitwarden email and master password"
            echo "3. Run: bw unlock (when prompted)"
            echo ""
            read -p "Press Enter when ready to continue..."
            
            # Try to run bw login automatically
            echo "Attempting to run bw login..."
            bw login
            echo ""
            echo "Now unlock your vault:"
            bw unlock
        else
            echo "❌ Bitwarden CLI not found. Please install it first."
        fi
        
        # Firefox setup (THIRD - can use passkeys from Bitwarden)
        echo "🦊 Setting up Firefox (can use passkeys from Bitwarden)..."
        if command -v firefox &> /dev/null; then
            echo "Firefox found. Setup options:"
            echo "1. Firefox Sync (recommended):"
            echo "   - Open Firefox"
            echo "   - Sign in to Firefox account"
            echo "   - Sync will restore your saved passwords"
            echo ""
            echo "2. Import existing profile:"
            echo "   - Copy ~/.mozilla/firefox/ from another system"
            echo ""
            echo "3. Manual setup with Bitwarden passkeys:"
            echo "   - Open Firefox and login to sites manually"
            echo "   - Use Bitwarden passkeys for authentication"
            echo ""
            read -p "Press Enter when ready to continue..."
        else
            echo "❌ Firefox not found. Please install it first."
        fi
        
        echo "✅ Authentication setup complete!"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo "🎉 Sync complete! Current branch is up to date with master." 