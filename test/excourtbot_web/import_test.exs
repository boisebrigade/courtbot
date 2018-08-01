defmodule ExCourtbotWeb.ImportTest do
  use ExCourtbotWeb.ConnCase, async: true

  test "imports Anchorage data" do
    Application.put_env(
      :excourtbot,
      ExCourtbot,
      importer: %{
        file: "data/anchorage.csv" |> Path.expand(__DIR__),
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
    )

    records = ExCourtbot.import()

    sucessful_inserts =
      records
      |> Enum.count(fn
        {:ok, _} -> true
        _ -> false
      end)

    assert sucessful_inserts == 5

    Application.delete_env(:excourtbot, ExCourtbot.Import)
  end

  test "imports Atlanta data" do
    Application.put_env(
      :excourtbot,
      ExCourtbot,
      importer: %{
        file: "data/atlanta.csv" |> Path.expand(__DIR__),
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
    )

    records = ExCourtbot.import()

    sucessful_inserts =
      records
      |> Enum.count(fn
        {:ok, _} -> true
        _ -> false
      end)

    assert sucessful_inserts == 1

    Application.delete_env(:excourtbot, ExCourtbot)
  end

  test "imports Boise data" do
    Application.put_env(
      :excourtbot,
      ExCourtbot,
      importer: %{
        file: "data/boise.csv" |> Path.expand(__DIR__),
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
    )

    records = ExCourtbot.import()

    sucessful_inserts =
      records
      |> Enum.count(fn
        {:ok, _} -> true
        _ -> false
      end)

    assert sucessful_inserts == 6

    Application.delete_env(:excourtbot, ExCourtbot.Import)
  end

  # TODO(ts): Add tests for url sources
  # TODO(ts): Add tests for reoccuring imports
end
