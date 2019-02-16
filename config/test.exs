use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :courtbot, CourtbotWeb.Endpoint,
  load_from_system_env: true,
  http: [port: 4001],
  server: false

config :rollbax,
  enabled: false

config :tesla, MyApi, adapter: Tesla.Mock

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :courtbot, Courtbot.Repo,
  load_from_system_env: true,
  url: "postgres://postgres:postgres@localhost:5432/courtbot_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :courtbot, Courtbot.Vault,
 ciphers: [
   default:
     {Cloak.Ciphers.AES.GCM,
     tag: "AES.GCM.V1", key: Base.decode64!(System.get_env("VAULT_KEY"))}
 ]
