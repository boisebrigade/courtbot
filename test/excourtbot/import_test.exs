defmodule ExCourtbot.ImportTest do
  use ExCourtbot.DataCase, asyc: true

  @boise_import_config [
    types: %{
      "Criminal" => ~r/^[A-Z]{2}\d{0,2}?-\d{2,4}-\d{2,}/
    },
    importer: %{
      file: Path.expand("../data/boise.csv", __DIR__),
      type:
        {:csv,
         [
           {:has_headers, true},
           {:headers,
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

  @anchorage_import_config [
    importer: %{
      file: Path.expand("../data/anchorage.csv", __DIR__),
      type:
        {:csv,
         [
           {:has_headers, false},
           {
             :headers,
             [
               {:date, "%-m/%e/%Y"},
               :last_name,
               :first_name,
               nil,
               :location,
               {:time, "%-I:%M %P"},
               :case_number,
               nil,
               :violation,
               nil
             ]
           }
         ]}
    }
  ]

  @atlanta_import_config [
    importer: %{
      file: Path.expand("../data/atlanta.csv", __DIR__),
      type:
        {:csv,
         [
           {:has_headers, true},
           {:headers,
            [
              {:date, "%-m/%e/%Y"},
              nil,
              nil,
              nil,
              {:time, "%-k:%M:%S"},
              :case_number,
              nil,
              nil,
              nil
            ]},
           {:delimiter, ?|}
         ]}
    }
  ]

  def count_fails(records) do
    records
    |> Enum.count(fn
      {:ok, _} -> false
      _ -> true
    end)
  end

  test "imports Anchorage data" do
    Application.put_env(:excourtbot, ExCourtbot, @anchorage_import_config)

    records = ExCourtbot.import()

    assert count_fails(records) == 0, "Failed to import #{count_fails(records)} records"

    Application.delete_env(:excourtbot, ExCourtbot.Import)
  end

  test "imports Atlanta data" do
    Application.put_env(:excourtbot, ExCourtbot, @atlanta_import_config)

    records = ExCourtbot.import()

    assert count_fails(records) == 0, "Failed to import #{count_fails(records)} records"

    Application.delete_env(:excourtbot, ExCourtbot.Import)
  end

  test "imports Boise data" do
    Application.put_env(:excourtbot, ExCourtbot, @boise_import_config)

    records = ExCourtbot.import()

    assert count_fails(records) == 0, "Failed to import #{count_fails(records)} records"

    Application.delete_env(:excourtbot, ExCourtbot.Import)
  end

  # TODO(ts): Add tests for url sources
  # TODO(ts): Add tests for reoccuring imports
end
