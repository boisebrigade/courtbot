defmodule ExCourtbotWeb.ImportTest do
  use ExCourtbotWeb.ConnCase, async: true

  test "imports from csv" do

  end

  test "imports Anchorage data" do
    Application.put_env(:excourtbot, :csv_headings, [:date, nil, nil, nil, :location, :time, :case_number, nil, :violation, nil])
    records = ExCourtbot.import_from_csv("data/anchorage.csv" |> Path.expand(__DIR__))

    sucessful_inserts = records
    |> Enum.count(fn
      {:ok, _} -> true
      _ -> false
    end)

    assert sucessful_inserts == 5

    Application.delete_env(:excourtbot, :csv_headings)
  end

  # test "imports Atlanta data" do
  #   {:ok, records} = ExCourtbot.import_from_csv("data/atlanta.csv" |> Path.expand(__DIR__))

  # end

  test "imports Boise data" do
    Application.put_env(:excourtbot, :csv_headings, [nil, nil, nil, nil, :case_number, nil, nil, :date, :time, nil])
    records = ExCourtbot.import_from_csv("data/anchorage.csv" |> Path.expand(__DIR__))

    sucessful_inserts = records
    |> Enum.count(fn
      {:ok, _} -> true
      _ -> false
    end)

    assert sucessful_inserts == 5

    Application.delete_env(:excourtbot, :csv_headings)
  end

  # test "imports Tulsa data" do
  #   {:ok, records} = ExCourtbot.import_from_csv("data/tulsa.json" |> Path.expand(__DIR__))

  # end


end
