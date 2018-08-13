use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :excourtbot, ExCourtbotWeb.Endpoint,
  http: [port: String.to_integer(System.get_env("PORT") || "4001")],
  server: false

config :tesla, MyApi, adapter: Tesla.Mock

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :excourtbot, ExCourtbot.Repo,
  load_from_system_env: true,
  adapter: Ecto.Adapters.Postgres,
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
