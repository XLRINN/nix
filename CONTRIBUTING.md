# Contributing

## Quick Start
- Enter dev shell: `nix develop`
- Inspect outputs: `nix flake show`
- Build + activate (auto-picks current system): `nix run .#build-switch`
- First-time token apply: `nix run .#apply`
- Checks: `nix flake check` and (if using secrets) `nix run .#check-keys`

## Workflow
- Branch from `main`; keep PRs focused and small.
- Place OS-specific logic under `modules/darwin` or `modules/nixos`; reuse `modules/shared` for common pieces.
- Update adjacent README files when adding or changing modules.
- Treat `overlays/` as temporary; document intent and cleanup path.

## Commit Style
- Use short, imperative subjects; optional emoji for context.
- Example: `🔧 Update Hyprland: switch to Wayland display manager`.

## Pull Request Checklist
- Clear description and linked issues.
- Note affected platform(s)/host(s).
- Evidence of local validation:
  - `nix flake check`
  - Build: `nix run .#build-switch` (or platform-specific `nix build`)
  - Activation tested on target machine or VM
- No secrets or generated artifacts committed.
- Docs updated if behavior changes (`AGENTS.md`, module READMEs).
- Overlays justified and scoped; removal plan noted.

## Secrets
- Follow `docs/BITWARDEN_SECRETS.md` (Bitwarden + sopswarden). Use `rbw-login`/`rbw-unlock`, then `sops-deploy` as needed.
- Validate with `nix run .#check-keys`.
- Darwin integration is currently cautious (commented in flake); avoid committing secrets.

## References
- Contributor guide: `AGENTS.md`
- Secrets guide: `docs/BITWARDEN_SECRETS.md`
