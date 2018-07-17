use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :excourtbot, ExCourtbotWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, :console, format: "[$level] $message\n"

# Configure your database
config :excourtbot, ExCourtbot.Repo,
  adapter: Ecto.Adapters.Postgres,
  username: "postgres",
  password: "postgres",
  database: "excourtbot_test",
  hostname: "localhost",
  port: System.get_env("POSTGRES_PORT_TEST"),
  pool: Ecto.Adapters.SQL.Sandbox,
  ownership_timeout: 80_000
