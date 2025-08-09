{ config, pkgs, agenix, secrets, ... }:

let user = "david"; in
{
  age.identityPaths = [
    "/home/${user}/.ssh/id_ed25519"
  ];

  # OpenAI API key for Avante and other AI tools
  age.secrets."openai-api-key" = {
    symlink = false;
    path = "/home/${user}/.openai_api_key";
    file = "${secrets}/openai-api-key.age";
    mode = "600";
    owner = "${user}";
    group = "wheel";
  };

  # Your other secrets go here
  #
  # Note: the installWithSecrets command you ran to boostrap the machine actually copies over
  #       a Github key pair. However, if you want to store the keypair in your nix-secrets repo
  #       instead, you can reference the age files and specify the symlink path here. Then add your
  #       public key in shared/files.nix.
  #
  #       If you change the key name, you'll need to update the SSH configuration in shared/home-manager.nix
  #       so Github reads it correctly.

  #
  # age.secrets."github-ssh-key" = {
  #   symlink = false;
  #   path = "/home/${user}/.ssh/id_github";
  #   file =  "${secrets}/github-ssh-key.age";
  #   mode = "600";
  #   owner = "${user}";
  #   group = "wheel";
  # };

}
