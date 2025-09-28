This directory can hold an age-encrypted Bitwarden Secrets Manager access token for bootstrapping new machines.

Files
- bws.token.age: Encrypted with a passphrase via `age -p`. Safe to commit. Do NOT commit the passphrase.

Bootstrap
1) Prepare once (on a trusted machine):
   - Run: `BWS_ACCESS_TOKEN='<token>' BWS_TOKEN_PASSPHRASE='<pass>' bash scripts/prepare-bws-token.sh`
   - Commit `secrets/bws.token.age` to the repo.
2) On fresh machines:
   - Provide the passphrase once: `export BWS_TOKEN_PASSPHRASE='<pass>'`
   - Run `unlock` (the wizard decrypts the token and fetches secrets automatically).

Notes
- You can also store the passphrase in a keychain or private env file per machine; never commit it.
- To rotate: run `prepare-bws-token.sh` again with a new token; commit the new encrypted file.
