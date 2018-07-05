defmodule ExCourtbotWeb.ImportTest do
  use ExCourtbotWeb.ConnCase
  use Timex
  use HTTPoison.Base

  import Mock

  test "imports Anchorage data" do
    Application.put_env(:excourtbot, ExCourtbot, source: %{
        file: "data/anchorage.csv" |> Path.expand(__DIR__),
        type: {:csv, %{
          has_headings: false,
          headings: [{:date, "{0M}/{0D}/{0YYYY}"}, nil, nil, nil, :location, {:time, "{h12}{m}{am}"}, :case_number, nil, :violation, nil],
        }}
      })

    records = ExCourtbot.import

    sucessful_inserts = records
    |> Enum.count(fn
      {:ok, _} -> true
      _ -> false
    end)

    assert sucessful_inserts == 5

    Application.delete_env(:excourtbot, ExCourtbot)
  end

  test "imports Atlanta data" do
    Application.put_env(:excourtbot, ExCourtbot, source: %{
      url: fn ->
        {:ok, date} = Timex.format(DateTime.utc_now(), "{0M}{0D}{0YYYY}")
        "http://courtview.atlantaga.gov/courtcalendars/court_online_calendar/codeamerica.#{date}.csv"
      end,
      type: {:csv, %{
        has_headings: true,
        headings: [:date, nil, nil, nil, :time, :case_number, nil, nil, nil],
        delimiter: ?|
      }}
    })

    # Mock the Atlanta endpoint and return our local test file.
    with_mock(HTTPoison, [
      get: fn
        url, _ ->
          IO.inspect url
          {
          :ok,
          %HTTPoison.Response {
            body: "data/atlanta.csv" |> Path.expand(__DIR__) |> File.stream!,
            status_code: 200
          }
        }
      end
    ]) do
      records = ExCourtbot.import

      sucessful_inserts = records
      |> Enum.count(fn
        {:ok, _} -> true
        _ -> false
      end)

      assert sucessful_inserts == 1

      Application.delete_env(:excourtbot, ExCourtbot)
    end

  end

  test "imports Boise data" do
    Application.put_env(:excourtbot, ExCourtbot, source: %{
      file: "data/boise.csv" |> Path.expand(__DIR__),
      type: {:csv, %{
        has_headings: true,
        headings: [nil, nil, nil, nil, :case_number, nil, nil, :date, :time, nil]
      }}
    })

    records = ExCourtbot.import

    sucessful_inserts = records
    |> Enum.count(fn
      {:ok, _} -> true
      _ -> false
    end)

    assert sucessful_inserts == 6

    Application.delete_env(:excourtbot, ExCourtbot)
  end

end
