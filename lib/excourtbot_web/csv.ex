defmodule ExCourtbotWeb.Csv do
  alias ExCourtbot.Repo
  alias ExCourtbotWeb.Case

  require Logger

  def extract(raw_data, options) do
    delimiter = Keyword.get(options, :delimiter, ?,)
    has_headers = Keyword.get(options, :has_headers, false)
    headers = Keyword.get(options, :headers)

    mappings =
      headers
      |> Enum.filter(fn
        {_, v} -> v
        _ -> false
      end)
      |> Keyword.take([:date, :time, :date_and_time])
      |> Enum.into(%{})

    headings =
      headers
      |> Enum.map(fn
        {:date, _} -> :date
        {:time, _} -> :time
        {:date_and_time, _} -> :date_and_time
        mapping when is_atom(mapping) -> mapping
        nil -> nil
      end)

    decoded_csv = CSV.decode(raw_data, headers: headings, separator: delimiter)

    if has_headers do
      Enum.drop(decoded_csv, 1)
    else
      decoded_csv
    end
    |> Enum.map(fn row -> process(row, mappings) |> cast end)
  end

  defp process({:ok, params = %{date: date, time: time, case_number: _}}, %{
         date: date_format,
         time: time_format
       }) do
    params
    |> Map.put(:date, date |> String.trim() |> Timex.parse!(date_format))
    |> Map.put(:time, time |> String.trim() |> Timex.parse!(time_format))
  end

  defp process({:ok, params = %{date_and_time: date_and_time, case_number: _}}, %{
         date_and_time: date_and_time_format
       }) do
    params
    |> Map.put(
      :date,
      date_and_time
      |> String.trim()
      |> Timex.parse!(date_and_time_format)
      |> DateTime.to_date()
    )
    |> Map.put(
      :time,
      date_and_time
      |> String.trim()
      |> Timex.parse!(date_and_time_format)
      |> DateTime.to_time()
    )
  end

  defp process({:ok, _}, %{}),
    do: Logger.error("Unable to process row. Mappings for date and time are required")

  defp process({:ok, row}, _),
    do: Logger.error("Unable to process row date, time, and case_number are required #{row}")

  defp process({:error, message}, _), do: Logger.error("Row failed to import because #{message}")

  defp cast(case) do
    combined =
      case
      |> Map.put(
        :hearings,
        [case]
      )

    %Case{}
    |> Case.changeset(combined)
    |> Repo.insert()
  end
end
