# Repository Guidelines

## Project Structure & Modules
- `flake.nix`: Flake inputs/outputs, devShells, and per‑platform apps.
- `apps/<system>/`: Run targets like `swap`, `apply`, `check-keys`, `create-keys`, `copy-keys` (plus `build`/`rollback` on Darwin).
- `hosts/{darwin,nixos}/`: Host entrypoints and install helpers.
- `modules/{darwin,nixos,shared}/`: System and Home Manager modules (`packages.nix`, `home-manager.nix`, `files.nix`, `config/*`).
- `overlays/`: Per‑build overrides and temporary fixes.
- `scripts/`, `docs/`, `templates/`: Helper scripts, docs (see `docs/BITWARDEN_SECRETS.md`), and starter templates.

## Build, Test, and Dev Commands
- Develop: `nix develop` — enter the repo’s dev shell.
- Show outputs: `nix flake show` — inspect available apps/targets.
- Build + switch (auto‑detects current system): `nix run .#swap`.
- First‑run token apply (username/email/etc.): `nix run .#apply`.
- Secrets check (if used): `nix run .#check-keys`.
- Darwin build only: `nix build .#darwinConfigurations.$(uname -m)-darwin.system`.
- NixOS build only: `nix build .#nixosConfigurations.x86_64-linux.config.system.build.toplevel` (adjust system).
- Sanity checks: `nix flake check` — evaluate and run basic checks.

## Coding Style & Naming
- Nix: 2‑space indent, trailing commas, concise attribute names.
- File/app names: lower‑case with hyphens (e.g., `swap`).
- Keep platform‑specific logic under `modules/darwin` or `modules/nixos`; share common pieces in `modules/shared`.
- Prefer small, composable modules; update module READMEs when adding new ones.

## Testing Guidelines
- Always run `nix flake check` and a full build: `nix run .#swap` (or the platform‑specific `nix build` examples above).
- For hosts changes, verify both evaluation and activation on the target platform (VM or machine).
- When touching secrets, follow `docs/BITWARDEN_SECRETS.md` and validate with `nix run .#check-keys`.

## Commit & Pull Request Guidelines
- Commits: short, imperative subject; optional emoji prefix; scope first when useful.
  - Example: `🔧 Update Hyprland: switch to Wayland display manager`.
- PRs: clear description, affected platform(s)/hosts, reproduction steps, command output from a successful build/switch, and linked issues.
- Never commit secrets or generated artifacts; see `docs/BITWARDEN_SECRETS.md`.

## Security & Configuration Tips (Optional)
- Secrets are managed via Bitwarden + sopswarden; use `rbw-login`, then `sops-deploy` as documented.
- Keep overlays temporary and documented in `overlays/README.md`.
