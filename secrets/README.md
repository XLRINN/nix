This directory contains SOPS-encrypted secrets used by all machines.

Quick start (single shared file for all hosts)

1) Generate an Age key (one time):
   age-keygen -o ~/.config/sops/age/keys.txt
   age-keygen -y ~/.config/sops/age/keys.txt  # copy the recipient into .sops.yaml

2) Update .sops.yaml: replace the placeholder recipient with your Age public key.

3) Create the shared secrets file:
   sops secrets/common.yaml

   Put entries like:
   ssh_private_key: |
     -----BEGIN OPENSSH PRIVATE KEY-----
     ...
     -----END OPENSSH PRIVATE KEY-----
   tailscale-auth-key: "tskey-..."   # optional
   openrouter-api-key: "..."         # optional
   github-token: "..."               # optional

4) Commit secrets/common.yaml (encrypted). Do NOT commit any Age private keys.

Installer note

During install, provide the Age private key once (env AGE_PRIVATE_KEY or file path in the Apply prompt).
The installer writes it to /etc/sops/age/keys.txt so the first switch can decrypt and materialize:
- ~/.ssh/id_ed25519 (from ssh_private_key)
- /run/secrets/* (for any system secrets above)
