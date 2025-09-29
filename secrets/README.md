This directory is available if you want to keep additional encrypted material
(e.g., age-encrypted backups). The current configuration no longer uses a
Bitwarden Secrets Manager access token; all secrets are retrieved directly from
Bitwarden via `rbw` + `sopswarden` when you run the `unlock` helper.

If you do not need repository-local encrypted blobs, you can leave this
directory empty.
