{ config, lib, pkgs, ... }:

let 
  user = config.users.users.${config.users.defaultUser or "nixos"}.name or "nixos";
  apiKeysFile = "/home/${user}/.local/share/src/nixos-config/modules/shared/config/api-keys/keys.env";
in
{
  # Environment variables for API keys (available system-wide)
  environment.variables = lib.mkIf (builtins.pathExists apiKeysFile) {
    # Note: These are loaded via shell initialization instead of directly here
    # to avoid putting secrets in the Nix store
  };
  
  # Create helper scripts for API key management
  environment.systemPackages = with pkgs; [
    (writeScriptBin "load-api-keys" ''
      #!/bin/bash
      # Load API keys into current shell session
      if [[ -f "${apiKeysFile}" ]]; then
        set -a
        source "${apiKeysFile}"
        set +a
  echo "✓ API keys loaded successfully"
  echo "Available keys: OPENAI_API_KEY, GITHUB_TOKEN"
      else
        echo "❌ No API keys file found at ${apiKeysFile}"
        echo "Run: fetch-secrets.sh to populate keys from Bitwarden"
      fi
    '')
    
    (writeScriptBin "check-api-keys" ''
      #!/bin/bash
      # Check which API keys are available
      echo "Checking API key availability..."
      
      if [[ -f "${apiKeysFile}" ]]; then
        source "${apiKeysFile}"
        
        [[ -n "$OPENAI_API_KEY" ]] && echo "✓ OpenAI API key available" || echo "❌ OpenAI API key missing"  
        [[ -n "$GITHUB_TOKEN" ]] && echo "✓ GitHub token available" || echo "❌ GitHub token missing"
      else
        echo "❌ No API keys file found"
      fi
    '')
    
    (writeScriptBin "refresh-secrets" ''
      #!/bin/bash
      # Refresh all secrets from Bitwarden
      echo "Refreshing secrets from Bitwarden..."
      "${pkgs.bash}/bin/bash" "/home/${user}/.local/share/src/nixos-config/scripts/fetch-secrets.sh"
    '')
  ];
  
  # Auto-load API keys in shell sessions
  environment.etc."profile.d/api-keys.sh".text = ''
    # Auto-load API keys if available
    if [[ -f "${apiKeysFile}" && -r "${apiKeysFile}" ]]; then
      set -a
      source "${apiKeysFile}"
      set +a
    fi
  '';
}