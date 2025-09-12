# Bitwarden Secrets Integration

This configuration provides two approaches for integrating Bitwarden secrets with your Nix system:

1. **Sopswarden (Recommended)**: Uses SOPS + Bitwarden for declarative secret management
2. **Legacy Apply Script**: Fetches secrets during deployment

## Approach 1: Sopswarden (SOPS + Bitwarden)

**Sopswarden** is a mature tool that combines SOPS (Secrets OPerationS) with Bitwarden for secure, declarative secret management. This is the recommended approach for production use.

### How Sopswarden Works

1. **Vault Login**: Authenticate with Bitwarden using `rbw` (alternative CLI)
2. **Secret Sync**: `sopswarden-sync` fetches secrets from Bitwarden to SOPS files
3. **Declarative Deployment**: Secrets are automatically available at `/run/secrets/`
4. **System Integration**: NixOS natively supports SOPS-encrypted secrets

### Required Bitwarden Structure for Sopswarden

Sopswarden expects secrets to be organized in Bitwarden with specific paths:

- **tailscale/authkey** → Tailscale authentication key
- **openrouter/api-key** → OpenRouter API key (for Avante AI features)
- **github/token** → GitHub personal access token

**Note**: Since you're using OpenRouter, you only need one API key instead of separate Anthropic and OpenAI keys.

### Sopswarden Usage

```bash
# Initial setup (one time)
rbw-login          # Login to Bitwarden
rbw-unlock         # Unlock vault

# Sync and deploy secrets
sops-sync          # Sync from Bitwarden to SOPS files
sops-deploy        # Build system with secrets
sops-check         # Verify secrets are available

# Or combine sync + deploy in one command
sops-deploy
```

### Sopswarden Features

- ✅ **Production Ready**: Mature, tested solution
- ✅ **Truly Declarative**: Secrets defined in Nix configuration
- ✅ **Secure**: Age-encrypted SOPS files, secrets at `/run/secrets/`
- ✅ **Zero Git Exposure**: No secrets in git or Nix store
- ✅ **NixOS Native**: Built on NixOS secrets infrastructure
- ✅ **Automatic Permissions**: Proper file ownership and modes

## Approach 2: Legacy Apply Script (Bitwarden CLI)

This is the original implementation that fetches secrets during the apply script execution.

## How It Works

1. **Bootstrap**: The `apply` script prompts for your Bitwarden master password
2. **Authentication**: Creates a cached session at `~/.cache/bw-session`
3. **Secret Fetching**: Runs `fetch-secrets.sh` to pull secrets from Bitwarden
4. **Declarative Access**: Secrets are written to configuration files that Nix can read

## Required Bitwarden Items

### Tailscale
- **Name**: `Tailscale`
- **Field**: `auth-key` (custom field)
- **Value**: Your Tailscale auth key (e.g., `tskey-auth-...`)

### Anthropic (for Avante)
- **Name**: `Anthropic API`
- **Field**: `api-key` (custom field)
- **Value**: Your Anthropic API key (e.g., `sk-ant-...`)

### OpenAI (for Avante)
- **Name**: `OpenAI API`
- **Field**: `api-key` (custom field)
- **Value**: Your OpenAI API key (e.g., `sk-...`)

### GitHub Token
- **Name**: `GitHub Token`
- **Field**: `token` (custom field)
- **Value**: Your GitHub personal access token

## Usage

### Initial Setup
```bash
# Run the apply script (will prompt for Bitwarden password)
nix run .#apply

# This will:
# 1. Authenticate with Bitwarden
# 2. Fetch secrets and create configuration files
# 3. Set up Tailscale and API keys declaratively
```

### Managing Secrets

```bash
# Check which API keys are available
check-api-keys

# Refresh secrets from Bitwarden
refresh-secrets

# Load API keys into current shell
load-api-keys

# Setup Avante configuration
setup-avante
```

### Tailscale
After running the apply script, Tailscale will automatically use the auth key from Bitwarden:

```bash
# Check Tailscale status
sudo tailscale status

# If needed, manually connect
sudo tailscale up --ssh
```

### Avante.nvim
The configuration sets up environment variables for Avante to use Claude and OpenAI APIs:

1. Ensure API keys are in Bitwarden
2. Run `refresh-secrets`
3. API keys will be automatically available to Neovim

## File Structure

```
modules/shared/config/
├── api-keys/
│   ├── default.nix       # Nix configuration for API keys
│   └── keys.env          # Generated environment file (gitignored)
├── tailscale/
│   ├── tailscale.nix     # Tailscale configuration
│   └── key               # Auth key from Bitwarden (gitignored)
└── avante/
    └── default.nix       # Avante/Neovim configuration

scripts/
└── fetch-secrets.sh      # Script to pull secrets from Bitwarden
```

## Security Notes

- Secret files (`keys.env`, `tailscale/key`) are gitignored
- Files have restrictive permissions (600)
- Bitwarden session expires and needs re-authentication
- Secrets are only stored locally, not in the Nix store

## Troubleshooting

### Bitwarden Session Expired
```bash
# Re-authenticate
bw-unlock

# Or run the apply script again
nix run .#apply
```

### Missing Secrets
```bash
# Check what's available in Bitwarden
bw list items --session $(cat ~/.cache/bw-session)

# Refresh from Bitwarden
refresh-secrets
```

### Tailscale Not Connecting
```bash
# Check if key file exists and has content
cat ~/.local/share/src/nixos-config/modules/shared/config/tailscale/key

# Manually connect with the key
sudo tailscale up --authkey $(cat ~/.local/share/src/nixos-config/modules/shared/config/tailscale/key) --ssh
```

## Advantages

1. **Single Source of Truth**: All secrets managed in Bitwarden
2. **Declarative**: Secrets available to Nix configuration
3. **Secure**: No secrets in git or Nix store
4. **Convenient**: Automatic fetching during deployment
5. **Flexible**: Easy to add new secret types

## Adding New Secrets

1. Add item to Bitwarden with appropriate fields
2. Update `fetch-secrets.sh` to fetch the new secret
3. Update relevant Nix configuration to use the secret
4. Add to documentation