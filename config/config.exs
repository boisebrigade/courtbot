# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# General application configuration
config :excourtbot,
  ecto_repos: [ExCourtbot.Repo]

# Configures the endpoint
config :excourtbot, ExCourtbotWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "l6LmTpsVPApJUcAfgxa8o+DellNKx1G9QLFzlG17Iu+soyWomSoTfW2dS3a3OcK+",
  render_errors: [view: ExCourtbotWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: ExCourtbot.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

config :ex_twilio,
  account_sid: System.get_env("TWILIO_ACCOUNT_SID") || "account_sid",
  auth_token: System.get_env("TWILIO_AUTH_TOKEN") || "auth_token",
  # optional
  workspace_sid: {:system, "TWILIO_WORKSPACE_SID"}

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
