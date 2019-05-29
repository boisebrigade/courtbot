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

config :logger,
  level: :debug,
  handle_sasl_reports: true,
  backends: [:console, {Courtbot.Rollbar, :rollbar}]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :logger, :rollbar,
  level: :info,
  format: "$message\n"

config :tesla, adapter: Tesla.Adapter.Hackney

config :courtbot, :environment, Mix.env()

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
import_config "courtbot.exs"
