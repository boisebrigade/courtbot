defmodule Courtbot.Import do
  alias Courtbot.{
    Kinds.Csv,
    Repo,
    Configuration
  }

  require Logger

  def run, do: Courtbot.Import.run(Configuration.get([:importer]))

  def run(%{importer: importer = %{kind: kind, origin: origin, source: source}}) do
    Logger.info("Starting import")

    origin = String.to_atom(origin)

    data =
      case origin do
        :file -> File.stream!(source)
        :url -> request(source)
        _ -> raise "Unsupported import origin: #{origin}"
      end

    backup_and_truncate_hearings()

    imported =
      run_import(
        String.to_atom(kind),
        data,
        importer
      )

    Logger.info("Finished Import")

    imported
  end

  defp run_import(:csv, data, settings), do: Csv.extract(data, settings)

  defp run_import(:json, _, _),
    do: raise("JSON is currently not supported")

  defp run_import(_, _, _),
    do: raise("The supplied configuration to the importer is invalid")

  defp backup_and_truncate_hearings do
    Logger.info("Creating backup hearings table")

    backup_table =
      "hearing_" <> (Date.add(Date.utc_today(), -1) |> Timex.format!("%m_%d_%Y", :strftime))

    # Drop backup table if it has previously been created.
    Repo.query("DROP TABLE IF EXISTS #{backup_table}", [])

    # Create a new backup table based upon the current hearings table.
    Repo.query("CREATE TABLE #{backup_table} AS SELECT * FROM hearings;", [])

    Repo.query("TRUNCATE hearings;", [])
  end

  def restore_hearings do
    backup_table =
      "hearing_" <> (Date.add(Date.utc_today(), -1) |> Timex.format!("%m_%d_%Y", :strftime))

    Repo.query(
      """
      BEGIN;
      DROP TABLE hearings;
      ALTER TABLE #{backup_table} RENAME TO hearings;
      COMMIT;
      """,
      []
    )
  end

  defp request(url) do
    case Tesla.get(url, follow_redirect: true) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        body

      {:ok, %Tesla.Env{status: status}} ->
        Logger.error("Unhandled status code received: #{status}, while fetching #{url}")

      {:error, err} ->
        Logger.error("Unable to fetch #{url} because of: #{err}")
    end
  end

  def test_import(kind, origin, source) do
    data =
      case origin do
        :file -> File.stream!(source)
        :url -> request(source)
        _ -> raise "Origin not supported:  #{origin}}"
      end

    case kind do
      :csv ->
        [headers] = Stream.take(data, 1) |> Enum.to_list()
        headers |> String.replace("\n", "") |> String.split(",")

      :json ->
        raise "Importing from JSON is not currently supported"

      _ ->
        raise "Unsupported import kind: #{kind}"
    end
  end
end
