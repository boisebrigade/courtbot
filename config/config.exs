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

config :ex_twilio, account_sid:   {:system, "TWILIO_ACCOUNT_SID"},
                   auth_token:    {:system, "TWILIO_AUTH_TOKEN"}

config :excourtbot,
  locales: %{
    "en" =>"12083144089"
  },
  import_time: "0 9 * * *",
  notify_time: "0 13 * * *"

config :excourtbot, ExCourtbot.Import,
  source: %{
    file: "../test/excourtbot_web/data/boise.csv",
    type:
      {:csv,
       [
         {:has_headers, true},
         {:headers,
          [
            {:date, "{0M}/{0D}/{YYYY}"},
            nil,
            nil,
            nil,
            {:time, "{0h24}:{m}"},
            :case_number,
            nil,
            nil,
            nil
          ]},
         {:delimiter, ?|}
       ]}
  }

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
