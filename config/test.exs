use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :courtbot, CourtbotWeb.Endpoint,
  load_from_system_env: true,
  http: [port: 4001],
  server: false

config :tesla, adapter: Tesla.Mock

# Print only warnings and errors during test
config :logger, level: :warn

config :phoenix, :stacktrace_depth, 20

# Configure your database
config :courtbot, Courtbot.Repo,
  url: "postgres://postgres:postgres@localhost:5432/courtbot_test",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :courtbot, CourtbotWeb.Endpoint,
  secret_key_base: "1C969829A72C108979C56C5F49ACF80D7F51DEC4C8398D96BEBCFE3B94332B17"

config :courtbot, Courtbot.Vault,
  ciphers: [
    default: {
      Cloak.Ciphers.AES.GCM,
      tag: "AES.GCM.V1", key: Base.decode64!("QkMwMjkxNzVCQjk5MDJEMERFNEM2ODYyNTMzMTREQUU=")
    }
  ]

config :guardian, Guardian,
  issuer: "courtbot",
  secret_key: "53B64BFDE8AA12298B09F2D01030CC3A16A93D48102B9EF92B8A68F3CB216356"

config :stream_data,
  max_runs: if(System.get_env("CI"), do: 1_000, else: 50)
