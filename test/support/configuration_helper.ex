defmodule CourtbotTest.Helper.Configuration do
  @boise_importer_config [
    court_url: "https://mycourts.idaho.gov",
    importer: %{
      file: Path.expand("../data/boise.csv", __DIR__),
      type:
        {:csv,
         [
           {:has_headers, true},
           {:field_mapping,
            [
              :case_number,
              :last_name,
              :first_name,
              nil,
              nil,
              nil,
              {:date, "%-m/%e/%Y"},
              {:time, "%k:%M"},
              nil,
              :county
            ]}
         ]}
    }
  ]

  def boise() do
    @boise_importer_config
  end
end
