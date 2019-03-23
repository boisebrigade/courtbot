defmodule Courtbot.Import do
  alias Courtbot.{
    Kinds.Csv,
    Repo,
    Configuration
  }

  require Logger

  def run, do: Courtbot.Import.run(Configuration.get([:importer]))

  def run(%{importer: importer = %{kind: kind, origin: "file", source: source}}) do
    Logger.info("Starting file import from: #{source}")

    with {:ok, %File.Stat{size: size}} when size > 0 <- File.stat(source) do
      backup_and_truncate_hearings()

      imported =
        run_import(
          kind,
          File.stream!(source),
          importer
        )

      Logger.info("Finished Import")

      imported
      else
        {:ok, %File.Stat{size: 0}} -> Logger.error("Unable to import. Source file, #{source}, is empty.")
        {:error, reason} -> Logger.error("Unable to import: #{reason}")
    end
  end

  def run(%{importer: importer = %{kind: kind, origin: "url", source: source}}) do
    Logger.info("Starting import")

    data = request(source)

    backup_and_truncate_hearings()

    imported =
      run_import(
        kind,
        data,
        importer
      )

    Logger.info("Finished Import")

    imported
  end

  defp run_import("csv", data, settings), do: Csv.run(data, settings)

  defp run_import("json", _, _),
    do: raise("JSON is currently not supported")

  defp run_import(_, _, _),
    do: raise("The supplied configuration to the importer is invalid")

  defp backup_and_truncate_hearings do
    Logger.info("Creating backup hearings table")

    date = Date.utc_today() |> Date.add(-1) |> Timex.format!("%m_%d_%Y", :strftime)

    backup_table = "hearing_" <> date

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
end
