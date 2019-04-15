use Mix.Config

config :courtbot, CourtbotWeb.Endpoint, load_from_system_env: true

# Do not print debug messages in production
config :logger, level: :info

# Configure your database
config :courtbot, Courtbot.Repo,
  load_from_system_env: true,
  pool_size: 10,
  ssl: true
