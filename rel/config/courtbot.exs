use Mix.Config

# Phoenix configuraiton
config :excourtbot, ExCourtbotWeb.Endpoint,
  server: true,
  root: ".",
  version: Mix.Project.config()[:version]

# Import our generated secrets.
# This file is generated
import_config "courtbot.secrets.exs"
