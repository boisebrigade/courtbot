# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

config :phoenix, :json_library, Jason

# General application configuration
config :courtbot,
  ecto_repos: [Courtbot.Repo]

# Configures the endpoint
config :courtbot, CourtbotWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [view: CourtbotWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: Courtbot.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :ex_twilio,
  account_sid: {:system, "TWILIO_ACCOUNT_SID"},
  auth_token: {:system, "TWILIO_AUTH_TOKEN"}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
import_config "courtbot.exs"
