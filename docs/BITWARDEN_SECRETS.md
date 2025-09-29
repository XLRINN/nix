# Bitwarden Secrets Integration

This configuration integrates Bitwarden secrets using a single recommended approach:

1. **sopsWarden (impure branch)**: Bitwarden → SOPS sync with direct secret values available in Nix (current configured flow)

## Sopswarden (SOPS + Bitwarden)

**Sopswarden** is a mature tool that combines SOPS (Secrets OPerationS) with Bitwarden for secure, declarative secret management. This is the recommended approach for production use.

### How Sopswarden Works

1. **Vault Login**: Authenticate with Bitwarden using `rbw` (alternative CLI)
2. **Secret Sync**: `sopswarden-sync` fetches secrets from Bitwarden to SOPS files
3. **Declarative Deployment**: Secrets are automatically available at `/run/secrets/`
4. **System Integration**: NixOS natively supports SOPS-encrypted secrets

### Required Bitwarden Items & Custom Fields

Create (or update) the following Bitwarden items (names must match; custom fields are case‑insensitive):

| Purpose | Item Name | Custom Field | Notes |
|---------|-----------|--------------|-------|
| Tailscale Auth | `Tailscale` | `auth-key` | Use a reusable AUTH key with --ssh if desired |
| OpenRouter API | `OpenRouter API` | `api-key` | Single key covers multiple model providers via OpenRouter |
| GitHub Token | `github` | `token` | PAT with minimal required scopes |
| GitHub SSH Key | `github` | `private-key` | Private key used for repo pushes |

OpenAI direct keys are optional when using OpenRouter.

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

### Summary of Needed Items

See table above (no path mapping needed; items + custom fields only).

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

With OpenRouter you typically only need `openrouter-api-key`. After sync and rebuild, reference secret value directly via `${secrets.openrouter-api-key}` where needed in impure modules, or `cat /run/secrets/openrouter-api-key` in scripts.

## File Structure (Active Parts)

Secrets declared under `services.sopswarden.secrets` land in `/run/secrets/…`. 
Refer to `hosts/*/default.nix` for the exact paths each host expects.

## Security Notes

- Secrets live in `/run/secrets` with restrictive permissions managed by sopswarden
- Nothing sensitive is committed to git or stored in the Nix store
- Bitwarden sessions expire regularly; re-run `unlock` when prompted

## Troubleshooting

-### Bitwarden Session Expired

```bash
# Re-authenticate and resync
rbw-login
rbw-unlock
sops-sync
```

-### Missing Secrets

```bash
# Ensure the item exists and roughly matches the expected name/field in services.sopswarden.secrets
rbw list | grep -i "tailscale"
sops-sync
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

1. Create/update Bitwarden item (match `name` + optional custom `field`)
2. Add/modify entry under `services.sopswarden.secrets` in `hosts/nixos/default.nix`
3. `rbw unlock && sopswarden-sync`
4. `sudo nixos-rebuild switch --impure`
