defmodule Courtbot.Kinds.Csv do
  alias Courtbot.{Case, Configuration, Hearing, Repo}

  require Logger

  def extract(data, _options = %{
    delimiter: <<delimiter::utf8>>,
    has_headers: has_headers,
    county_duplicates: county_duplicates,
    field_mapping: field_mapping
  }) do

    # If the CSV file has headings then drop the first row
    data =
      if has_headers do
        Stream.drop(data, 1)
      else
        data
      end

    headings =
      field_mapping
      |> Enum.map(fn
        %{destination: destination} when not is_nil(destination) -> String.to_atom(destination)
        _ -> nil
      end)

    %{types: types} = Configuration.get([:types])

    fragment =
      cond do
        county_duplicates and length(types) > 0 ->
          "(case_number, county, type)"

        county_duplicates ->
          "(case_number, county) WHERE type IS NULL"

        length(types) > 0 ->
          "(case_number, type) WHERE county IS NULL"

        true ->
         "(case_number) WHERE county IS NULL AND type IS NULL"
      end

    opts = [returning: true,
      on_conflict: :replace_all_except_primary_key,
      conflict_target: {:unsafe_fragment, fragment}]

    data
    |> CSV.decode(headers: headings, separator: delimiter)
    |> Enum.to_list()
    |> Enum.reduce([], fn

    {:ok, record}, acc ->
      [Case.changeset(%Case{}, Map.merge(record, %{hearings: [record]})) | acc]
    {:error, message}, acc ->
      Logger.error("Unable to import row: #{message}")

        acc
    end)
    |> Enum.map(fn changeset = %_{changes: changes = %{hearings: [hearing]}} ->
      case Repo.insert(changeset, opts) do
        {:error, %_{errors: [case_number: _]}} ->
          %Case{id: case_id} = changes
            |> Map.take([:county, :type, :case_number])
            |> Map.to_list()
            |> Case.find_with()

          %_{changes: hearing} = hearing

          %Hearing{}
          |> Hearing.changeset(Map.merge(hearing, %{case_id: case_id}))
          |> Repo.insert()

        result -> result
      end
    end)
  end
end
