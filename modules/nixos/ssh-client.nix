{ config, lib, pkgs, ... }:

{
  # System-wide OpenSSH client defaults for ephemeral VMs and rotating hosts
  programs.ssh = {
    enable = true;
    extraConfig = ''
      Host *
        # Auto-accept new host keys, but still warn on changes
        StrictHostKeyChecking accept-new
        # Learn and replace rotated host keys when server advertises them
        UpdateHostKeys yes
        # Try common ED25519 first, then RSA as fallback
        HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256
        PubkeyAcceptedKeyTypes ssh-ed25519,ssh-rsa,rsa-sha2-512,rsa-sha2-256
    '';
  };
}

