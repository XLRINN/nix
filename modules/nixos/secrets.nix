{ config, pkgs, agenix, ... }:

let user = "david"; in
{
  age.identityPaths = [
    "/home/${user}/.ssh/id_ed25519"
  ];

  # Your secrets go here
  # 
  # To add a new secret:
  # 1. Create the secret file: agenix -e secrets/your-secret.age
  # 2. Add it here with proper permissions
  # 3. Reference it in your configuration

  # API Keys
  age.secrets."avante-api-key" = {
    file = ./secrets/avante-api-key.age;
    mode = "600";
    owner = "${user}";
    group = "users";
  };

  age.secrets."github-token" = {
    file = ./secrets/github-token.age;
    mode = "600";
    owner = "${user}";
    group = "users";
  };

  # SSH Keys for outgoing connections
  age.secrets."ssh-key" = {
    symlink = false;
    path = "/home/${user}/.ssh/id_ed25519";
    file = ./secrets/ssh-key.age;
    mode = "600";
    owner = "${user}";
    group = "users";
  };

  # Environment variables that reference the secrets
  environment.variables = {
    AVANTE_API_KEY = config.age.secrets."avante-api-key".path;
    GITHUB_TOKEN = config.age.secrets."github-token".path;
    GH_TOKEN = config.age.secrets."github-token".path;
  };

  # SSH client configuration
  programs.ssh = {
    enable = true;
    extraConfig = ''
      # Use the encrypted SSH key
      IdentityFile /home/${user}/.ssh/id_ed25519
      
      # Example host configurations
      Host myserver
        HostName 192.168.1.100
        User david
        Port 22
        IdentityFile /home/${user}/.ssh/id_ed25519
        
      Host github.com
        User git
        IdentityFile /home/${user}/.ssh/id_ed25519
        
      # Add your specific hosts here
      # Host mynas
      #   HostName 192.168.1.50
      #   User admin
      #   Port 22
      #   IdentityFile /home/${user}/.ssh/id_ed25519
    '';
  };
} 