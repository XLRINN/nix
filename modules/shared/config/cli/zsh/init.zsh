if [ -z "$ZELLIJ" ] && [ -z "$ZELLIJ_RUNNING" ]; then
  export ZELLIJ_RUNNING=1
  zellij
fi

# Load API keys from environment
if [ -f /etc/secrets/api-keys ]; then
  source /etc/secrets/api-keys
fi 