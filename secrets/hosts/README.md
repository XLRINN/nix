Per-host SOPS files go here, one per hostname.

Usage:
1) Ensure .sops.yaml has your Age recipient.
2) Create a host file, replacing <host> with your hostname:
   sops secrets/hosts/<host>.yaml

3) Put your private key under the 'ssh_private_key' key, e.g.:
   ssh_private_key: |
     -----BEGIN OPENSSH PRIVATE KEY-----
     ...
     -----END OPENSSH PRIVATE KEY-----

4) Commit the encrypted file. Do NOT commit any Age private keys.

The installer expects an Age private key at /etc/sops/age/keys.txt to decrypt
this file at activation. Supply it at install time (see Apply prompt) or copy it later.
