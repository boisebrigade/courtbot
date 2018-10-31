defmodule ExCourtbot.ImportTest do
  use ExCourtbot.DataCase, asyc: true

  @boise_import_config %{
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
  }

  @anchorage_import_config %{
    importer: %{
      file: Path.expand("../data/anchorage.csv", __DIR__),
      type:
        {:csv,
         [
           {:has_headers, false},
           {
             :field_mapping,
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
  }

  @atlanta_import_config %{
    importer: %{
      file: Path.expand("../data/atlanta.csv", __DIR__),
      type:
        {:csv,
         [
           {:has_headers, true},
           {:field_mapping,
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
  }

  def count_fails(records) do
    records
    |> Enum.count(fn
      {:ok, _} -> false
      _ -> true
    end)
  end

  test "imports Anchorage data from mix config" do
    config = ExCourtbot.mix_config(@anchorage_import_config)

    records = ExCourtbot.import(config)

    assert count_fails(records) == 0, "Failed to import #{count_fails(records)} records"
  end

  test "imports Atlanta data from mix config" do
    config = ExCourtbot.mix_config(@atlanta_import_config)

    records = ExCourtbot.import(config)

    assert count_fails(records) == 0, "Failed to import #{count_fails(records)} records"
  end

  test "imports Boise data from mix config" do
    config = ExCourtbot.mix_config(@boise_import_config)

    records = ExCourtbot.import(config)

    assert count_fails(records) == 0, "Failed to import #{count_fails(records)} records"
  end

  # TODO(ts): Property test input data
  # TODO(ts): Verify data is inserted correctly based upon the configured input
  # TODO(ts): Test that types and county apply
  # TODO(ts): Add tests for url sources
  # TODO(ts): Add tests for reoccurring imports
  # TODO(ts): Add tests for DB configuration
end
