defmodule Courtbot.Kinds.Csv do
  alias Courtbot.{Case, Configuration, Hearing, Party, Repo}

  require Logger

  def run(
        data,
        _options = %{
          delimiter: <<delimiter::utf8>>,
          has_headers: has_headers,
          county_duplicates: county_duplicates,
          field_mapping: field_mapping
        }
      ) do
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
        Configuration.mapped_county?() and (Configuration.mapped_type?() or not is_nil(types)) ->
          "(case_number, county, type)"

        Configuration.mapped_county?() ->
          "(case_number, county) WHERE type IS NULL"

        Configuration.mapped_type?() or not is_nil(types) ->
          "(case_number, type) WHERE county IS NULL"

        true ->
          "(case_number) WHERE county IS NULL AND type IS NULL"
      end

    data
    |> CSV.decode(headers: headings, separator: delimiter)
    |> Enum.to_list()
    |> Enum.map(&cast_fields/1)
    |> Enum.each(fn {case_changeset, hearing_changeset, party_changeset} ->
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:case, case_changeset,
        returning: true,
        on_conflict: :replace_all_except_primary_key,
        conflict_target: {:unsafe_fragment, fragment}
      )
      |> Ecto.Multi.insert(
        :hearings,
        fn %{case: case} ->
          Hearing.changeset(Ecto.build_assoc(case, :hearings), hearing_changeset)
        end,
        on_conflict: :replace_all_except_primary_key,
        conflict_target: [:case_id, :time, :date]
      )
      |> Ecto.Multi.insert(
        :parties,
        fn %{case: case} ->
          Party.changeset(Ecto.build_assoc(case, :parties), party_changeset)
        end,
        on_conflict: :replace_all_except_primary_key,
        conflict_target: [:case_id, :first_name, :last_name]
      )
      |> Repo.transaction()
    end)
  end

  defp cast_fields({:ok, record}) do
    hearing = Hearing.changeset(%Hearing{}, record)
    party = Party.changeset(%Party{}, record)
    case = Case.changeset(%Case{}, record)

    {case, record, record}
  end

  defp cast_fields({:error, message}, acc) do
    Logger.error("Unable to import row: #{message}")

    acc
  end
end
