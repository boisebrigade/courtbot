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
  load_from_system_env: true,
  secret_key_base: "l6LmTpsVPApJUcAfgxa8o+DellNKx1G9QLFzlG17Iu+soyWomSoTfW2dS3a3OcK+",
  render_errors: [view: ExCourtbotWeb.ErrorView, accepts: ~w(json)],
  pubsub: [name: ExCourtbot.PubSub,
           adapter: Phoenix.PubSub.PG2]


config :excourtbot,
  import_time: "0 9 * * *",
  notify_time: "0 13 * * *"

config :excourtbot, ExCourtbot,
  source: %{
    url: "",
    type: {:csv, %{
      has_headings: false,
      headings: [nil, nil, nil, nil, :case_number, nil, nil, :date, :time, nil],
      delimiter: ','
    }}
  }

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:user_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
