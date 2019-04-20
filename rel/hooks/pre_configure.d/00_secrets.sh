#!/usr/bin/env bash

# Generate our secrets
SECRET_KEY_BASE=$(tr -dc 'A-F0-9' < /dev/urandom | head -c64)
GUARDIAN_SECRET=$(tr -dc 'A-F0-9' < /dev/urandom | head -c64)
VAULT_KEY=$(tr -dc 'A-F0-9' < /dev/urandom | head -c32 | base64)

# If we don't have a secrets file, then make one.
if [ ! -f ${RELEASE_ROOT_DIR}/etc/courtbot.secrets.exs ]; then
  echo "Generating a secrets file"
  cat > ${RELEASE_ROOT_DIR}/etc/courtbot.secrets.exs <<EOL
use Mix.Config

config :guardian, Guardian,
  secret_key: "$GUARDIAN_SECRET"

config :courtbot, CourtbotWeb.Endpoint,
  secret_key_base: "$SECRET_KEY_BASE"

config :courtbot, Courtbot.Vault,
  ciphers: [
    default:
      {Cloak.Ciphers.AES.GCM, tag: "AES.GCM.V1", key: Base.decode64!("$VAULT_KEY")}
  ]
EOL
fi
