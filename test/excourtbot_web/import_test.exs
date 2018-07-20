defmodule ExCourtbotWeb.ImportTest do
  use ExCourtbotWeb.ConnCase, async: true

  test "imports Anchorage data" do
    Application.put_env(
      :excourtbot,
      ExCourtbot.Import,
      source: %{
        file: "data/anchorage.csv" |> Path.expand(__DIR__),
        type:
          {:csv,
           [
             {:has_headers, false},
             {
               :headers,
               [
                 {:date, "{0M}/{0D}/{YYYY}"},
                 :last_name,
                 :first_name,
                 nil,
                 :location,
                 {:time, "{h12}:{m} {am}"},
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
      ExCourtbot.Import,
      source: %{
        file: "data/atlanta.csv" |> Path.expand(__DIR__),
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
                {:time, "{h24}:{m}:{s}"},
                :case_number,
                nil,
                nil,
                nil
              ]},
             {:delimiter, ?|}
           ]}
      }
    )

    # Mock the Atlanta endpoint and return our local test file.
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
      ExCourtbot.Import,
      source: %{
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
                {:date, "{0M}/{0D}/{YYYY}"},
                {:time, "{h24}:{m}:{s}"},
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
