# Bitwarden Secrets Integration

This configuration integrates Bitwarden secrets using a single recommended approach:

1. **Sopswarden**: SOPS + Bitwarden for declarative, secure secret management (only supported flow now)

## Sopswarden (SOPS + Bitwarden)

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

### Usage

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

### Features

- ✅ **Production Ready**: Mature, tested solution
- ✅ **Truly Declarative**: Secrets defined in Nix configuration
- ✅ **Secure**: Age-encrypted SOPS files, secrets at `/run/secrets/`
- ✅ **Zero Git Exposure**: No secrets in git or Nix store
- ✅ **NixOS Native**: Built on NixOS secrets infrastructure
- ✅ **Automatic Permissions**: Proper file ownership and modes

## (Removed) Legacy Apply Script

The old inline Bitwarden scraping logic has been removed. All new deployments should rely exclusively on sopswarden + `rbw`.

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

## Managing Secrets

Use aliases defined in your shell (see Home Manager config):
```bash
rbw-login      # First time login
rbw-unlock     # Unlock vault for this session
sops-sync      # Sync & encrypt secrets
sops-deploy    # Sync + rebuild system (impure)
sops-check     # List expected secrets in /run/secrets
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

## File Structure (Active Parts)

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

scripts/                  # (Legacy helper scripts retained but not required)
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

1. **Single Source of Truth**: Bitwarden vault
2. **Declarative**: Secrets defined in Nix via sopswarden
3. **Secure**: Encrypted with SOPS / age, never in git / store
4. **Low Friction**: Simple sync + rebuild workflow
5. **Extensible**: Add new secrets by editing `services.sopswarden.secrets`

## Adding New Secrets

1. Create/update item in Bitwarden (ensure `bwPath` mapping matches)
2. Add/modify entry under `services.sopswarden.secrets` in `hosts/nixos/default.nix`
3. `rbw unlock && sops-sync`
4. `sudo nixos-rebuild switch --impure`