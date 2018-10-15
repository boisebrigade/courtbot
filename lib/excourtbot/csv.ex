defmodule ExCourtbot.Csv do
  alias ExCourtbot.{Case, Repo}

  require Logger

  def extract(raw_data, options) do
    delimiter = Keyword.get(options, :delimiter, ?,)
    has_headers = Keyword.get(options, :has_headers, false)
    field_mapping = Keyword.get(options, :field_mapping)

    # If the CSV file has headings then drop the first row
    raw_data =
      if has_headers do
        Stream.drop(raw_data, 1)
      else
        raw_data
      end

    headings =
      field_mapping
      |> Enum.sort(&(&1.index < &2.index))
      |> Enum.map(fn
        %{destination: destination} -> destination
      end)

    records = CSV.decode(raw_data, headers: headings, separator: delimiter) |> Enum.to_list()

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

    type_formats = get_field_mapping_format(field_mapping, "type")
    date_formats = get_field_mapping_format(field_mapping, "date")

    Enum.map(records, fn
      {:ok, row = %{case_number: _}} ->
        row
        |> add_type(type_formats)
        |> format_dates(date_formats)
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

  defp get_field_mapping_format(field_mapping, field_kind) do
    Enum.reduce(field_mapping, %{}, fn
      %{kind: kind, format: format, destination: destination} = _params, acc
      when kind == field_kind ->
        Map.merge(%{destination => format}, acc)

      _, acc ->
        acc
    end)
  end

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
