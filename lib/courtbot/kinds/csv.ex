defmodule Courtbot.Kinds.Csv do
  alias Courtbot.{Case, Hearing, Party, Repo}

  require Logger

  def run(
        data,
        options = %{
          importer: %{
            delimiter: <<delimiter::utf8>>,
            has_headers: has_headers,
            field_mapping: field_mapping
          },
          types: _
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

    try do
      data
      |> CSV.decode(headers: headings, separator: delimiter, escape_max_lines: 1)
      |> Flow.from_enumerable()
      |> Flow.map(&cast_fields(&1, options))
      |> Flow.map(&insert_record/1)
      |> Enum.to_list()
    catch
      :exit, exit -> Logger.error("Failed to import #{exit}")
    end
  end

  defp insert_record({:ok, case_changeset, hearing_changeset, party_changeset}) do
    parties_conflict =
      case party_changeset do
        %{changes: %{case_name: case_name}} when not is_nil(case_name) ->
          [:case_id, :case_name]

        %{changes: %{full_name: full_name}} when not is_nil(full_name) ->
          [:case_id, :full_name]

        _ ->
          [:case_id, :first_name, :last_name]
      end

    case_conflict =
      case case_changeset do
        %{changes: %{county: county, type: type}}
        when not is_nil(county) and not is_nil(type) ->
          "(case_number, county, type)"

        %{changes: %{county: county}} when not is_nil(county) ->
          "(case_number, county) WHERE type IS NULL"

        %{changes: %{type: type}} when not is_nil(type) ->
          "(case_number, type) WHERE county IS NULL"

        _ ->
          "(case_number) WHERE county IS NULL AND type IS NULL"
      end

    Ecto.Multi.new()
    |> Ecto.Multi.insert(:case, case_changeset,
      returning: true,
      on_conflict: :replace_all_except_primary_key,
      conflict_target: {:unsafe_fragment, case_conflict}
    )
    |> Ecto.Multi.insert(
      :hearings,
      fn %{case: case} ->
        Ecto.Changeset.put_assoc(hearing_changeset, :case, case)
      end,
      on_conflict: :replace_all_except_primary_key,
      conflict_target: [:case_id, :time, :date]
    )
    |> Ecto.Multi.insert(
      :parties,
      fn %{case: case} ->
        Ecto.Changeset.put_assoc(party_changeset, :case, case)
      end,
      on_conflict: :replace_all_except_primary_key,
      conflict_target: parties_conflict
    )
    |> Repo.transaction()
  end

  defp insert_record(record), do: record

  defp cast_fields({:ok, record}, options = %{importer: _importer, types: _types}) do
    hearing = Hearing.changeset(%Hearing{}, record, options)
    party = Party.changeset(%Party{}, record)
    case = Case.changeset(%Case{}, record, options)

    {:ok, case, hearing, party}
  end

  defp cast_fields({:error, record}, _options) do
    Logger.error("Unable to import record #{record}")

    {:error, record}
  end
end
