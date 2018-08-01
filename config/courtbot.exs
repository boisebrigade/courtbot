use Mix.Config

config :excourtbot, ExCourtbot,
  locales: %{
    "en" => "12083144089"
  },
  court_url: "https://mycourts.idaho.gov/",
  queued_ttl_days: 14,
  subscribe_limit: 10,
  importer: %{
    file: "../test/excourtbot_web/data/boise.csv",
    type:
      {:csv,
       [
         {:has_headers, true},
         {:headers,
          [
            nil,
            :first_name,
            :last_name,
            nil,
            :case_number,
            nil,
            nil,
            {:date, "%-m/%e/%Y"},
            {:time, "%k:%M:%S"},
            nil
          ]}
       ]}
  }
