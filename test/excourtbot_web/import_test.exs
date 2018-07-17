defmodule ExCourtbotWeb.ImportTest do
  use ExCourtbotWeb.ConnCase, async: true
  use HTTPoison.Base

  import Mock

#  test "imports Anchorage data" do
#    Application.put_env(
#      :excourtbot,
#      ExCourtbot,
#      source: %{
#        file: "data/anchorage.csv" |> Path.expand(__DIR__),
#        type:
#          {:csv,
#           [
#             {:has_headers, false},
#             {
#               :headers,
#               [
#                 {:date, "{0M}/{0D}/{YYYY}"},
#                 :last_name,
#                 :first_name,
#                 nil,
#                 :location,
#                 {:time, "{h12}:{m} {am}"},
#                 :case_number,
#                 nil,
#                 :violation,
#                 nil
#               ]
#             }
#           ]}
#      }
#    )
#
#    records =
#      ExCourtbot.import()
#
#    sucessful_inserts =
#      records
#      |> Enum.count(fn
#        {:ok, _} -> true
#        _ -> false
#      end)
#
#    assert sucessful_inserts == 5
#
#    Application.delete_env(:excourtbot, ExCourtbot)
#  end
#
  test "imports Atlanta data" do
    Application.put_env(
      :excourtbot,
      ExCourtbot,
      source: %{
        url: fn ->
          date = Timex.format!(DateTime.utc_now(), "{0M}{0D}{0YYYY}")

          "http://courtview.atlantaga.gov/courtcalendars/court_online_calendar/codeamerica.#{date}.csv"
        end,
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
    )

    # Mock the Atlanta endpoint and return our local test file.
    with_mock(
      HTTPoison,
      get: fn url, _ ->
        {
          :ok,
          %HTTPoison.Response{
            body: "data/atlanta.csv" |> Path.expand(__DIR__) |> File.stream!(),
            status_code: 200
          }
        }
      end
    ) do
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
  end

#  test "imports Boise data" do
#    Application.put_env(
#      :excourtbot,
#      ExCourtbot,
#      source: %{
#        file: "data/boise.csv" |> Path.expand(__DIR__),
#        type:
#          {:csv,
#           [
#             {:has_headers, true},
#             {:headings,
#              [
#                nil,
#                :first_name,
#                :last_name,
#                nil,
#                :case_number,
#                nil,
#                nil,
#                {:date, "{0M}/{0D}/{YYYY}"},
#                {:time, "{h24}:{m}"},
#                nil
#              ]}
#           ]}
#      }
#    )
#
#    records = ExCourtbot.import()
#
#    sucessful_inserts =
#      records
#      |> Enum.count(fn
#        {:ok, _} -> true
#        _ -> false
#      end)
#
#    assert sucessful_inserts == 6
#
#    Application.delete_env(:excourtbot, ExCourtbot)
#  end
end
