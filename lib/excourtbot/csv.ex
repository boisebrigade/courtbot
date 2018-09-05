defmodule ExCourtbot.Csv do
  alias ExCourtbot.{Case, Repo}

  require Logger

  def extract(raw_data, options) do
    delimiter = Keyword.get(options, :delimiter, ?,)
    has_headers = Keyword.get(options, :has_headers, false)
    headers = Keyword.get(options, :headers)

    # Check if we have defined types, if so we'll attempt to match them
    types =
      Application.get_env(:excourtbot, ExCourtbot, %{})
      |> Map.new()
      |> Map.take([:types])

    # Certain fields can have custom formats defined that need to be used to extract specific data from the fields.
    formats =
      Enum.filter(headers, fn
        {_, v} -> v
        _ -> false
      end)
      |> Keyword.take([:date, :time, :date_and_time])
      |> Enum.into(types)

    # Remove formats from the headings
    headings =
      Enum.map(headers, fn
        {:date, _} -> :date
        {:time, _} -> :time
        {:date_and_time, _} -> :date_and_time
        mapping when is_atom(mapping) -> mapping
        nil -> nil
      end)

    decoded_csv = CSV.decode(raw_data, headers: headings, separator: delimiter)

    # If the CSV file has headings then drop the first element in the list
    records =
      if has_headers do
        Enum.drop(decoded_csv, 1)
      else
        decoded_csv
      end

    # Combine multiple records by their case number (and county if mapped)
    records =
      Enum.reduce(records, [], fn
        {:ok, record}, acc ->
          # Split the case fields from the hearing

          {detail, case, hearing} =
            case Map.split(record, [:case_number, :first_name, :last_name, :county, :type]) do
              {case = %{case_number: _, county: _}, hearing} ->
                {:with_county, case, hearing}

              {case = %{case_number: _}, hearing} ->
                {:without_county, case, hearing}
            end

          # Check if we find a previously interated over case with the same case number and or county
          found =
            Enum.find_index(acc, fn
              {:ok, rec} ->
                case rec do
                  %{case_number: case_number, county: county} when detail == :with_county ->
                    if case_number == case[:case_number] and county == case[:county] do
                      rec
                    else
                      false
                    end

                  %{case_number: case_number} when detail == :without_county ->
                    if case_number == case[:case_number] do
                      rec
                    else
                      false
                    end

                  _ ->
                    false
                end

              _ ->
                true
            end)

          # If we have a previous case, add hearings to it or add our semi-formatted record and continue
          # TODO(ts): Compare hearings and discard duplicates
          if found do
            {:ok, rec} = Enum.at(acc, found)

            {_, %{hearings: hearings}} =
              Map.split(rec, [:case_number, :first_name, :last_name, :county, :type])

            {_, acc} = List.pop_at(acc, found)
            [{:ok, Map.merge(case, %{hearings: [hearing | hearings]})} | acc]
          else
            [{:ok, Map.merge(case, %{hearings: [hearing]})} | acc]
          end

        # Don't attempt to catch any import errors at this stage
        record, acc ->
          acc ++ [record]
      end)

    Enum.map(records, fn
      {:ok, row = %{case_number: _}} ->
        row
        |> add_type(formats)
        |> format_dates(formats)
        |> cast()
        |> Repo.insert()

      {:ok, _} ->
        Logger.error("Unable to process row because case_number is not mapped")

      {:error, message} ->
        Logger.error("Unable to process row because #{message}")
    end)
  end

  defp add_type(params = %{case_number: case_number}, %{types: types})
       when not is_nil(types) do
    type =
      Enum.reduce(types, [], fn {type, regex}, _ ->
        if Regex.run(regex, case_number) do
          type
        end
      end)

    Map.put(params, :type, type)
  end

  # Noop if no types are defined
  defp add_type(row, _), do: row

  defp format_dates(params = %{hearings: hearings}, %{
         date: date_format,
         time: time_format
       }) do
    hearings =
      Enum.map(hearings, fn
        hearing = %{date: date, time: time} ->
          hearing
          |> Map.put(:date, date |> String.trim() |> Timex.parse!(date_format, :strftime))
          |> Map.put(:time, time |> String.trim() |> Timex.parse!(time_format, :strftime))
      end)

    Map.merge(params, %{hearings: hearings})
  end

  defp format_dates(params = %{hearings: hearings}, %{
         date_and_time: date_and_time_format
       }) do
    hearings =
      Enum.map(hearings, fn
        hearing = %{date_and_time: date_and_time} ->
          hearing
          |> Map.put(
            :date,
            date_and_time
            |> String.trim()
            |> Timex.parse!(date_and_time_format, :strftime)
            |> DateTime.to_date()
          )
          |> Map.put(
            :time,
            date_and_time
            |> String.trim()
            |> Timex.parse!(date_and_time_format, :strftime)
            |> DateTime.to_time()
          )
      end)

    Map.merge(params, %{hearings: hearings})
  end

  defp format_dates(_, _),
    do: Logger.error("Unable to process row. Mappings for date and time are required")

  defp cast(case) do
    %Case{}
    |> Case.changeset(case)
  end
end
