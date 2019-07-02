defmodule Courtbot.Import do
  @moduledoc """
  Handles import logic based on configuration.
  """

  alias Courtbot.{
    Kinds.Csv,
    Repo,
    Configuration
  }

  def run, do: Courtbot.Import.run(Configuration.get([:importer, :types]))

  require Logger

  @doc """
  If a data source is from a file, open the file and load the data via a stream then import.
  """
  def run(config = %{importer: %{kind: kind, origin: "file", source: source}, types: _types}) do
    Logger.info("Starting file import from: #{source}")

    with {:ok, %File.Stat{size: size, mtime: _mtime}} when size > 0 <- File.stat(source) do
      backup_and_truncate_hearings()

      stream = File.stream!(source)

      # TODO(ts): Warn if mtime is over a day.
      {time, imported} = :timer.tc(&run_import/3, [kind, stream, config])

      Logger.info("Finished Import in #{time / 1_000_000}s")

      lines = count_csv_lines(stream)
      failed = count_fails(imported)

      if failed > (lines * 0.05) do
        Logger.error("More than 5% of the import failed")
      end

      imported
    else
      {:ok, %File.Stat{size: 0}} ->
        Logger.error("Unable to import. Source file, #{source}, is empty.")

      {:error, reason} ->
        Logger.error("Unable to import: #{reason}")
    end
  end

  @doc """
  If a data source is from a URL then fetch and then import.
  """
  def run(config = %{importer: %{kind: kind, origin: "url", source: source}, types: _types}) do
    Logger.info("Starting import")

    data = request(source)

    backup_and_truncate_hearings()

    {time, imported} = :timer.tc(&run_import/3, [kind, data, config])

    Logger.info("Finished Import in #{time / 1_000_000}s")

    lines = count_csv_lines(data)
    failed = count_fails(imported)

    if lines * 0.05 > failed do
      Logger.error("More than 5% of the import failed")
    end

    imported
  end

  defp run_import("csv", data, options), do: Csv.run(data, options)

  defp run_import("json", _, _),
    do: raise("JSON is currently not supported")

  defp run_import(_, _, _),
    do: raise("The supplied configuration to the importer is invalid")

  defp backup_and_truncate_hearings do
    date = Date.utc_today() |> Date.add(-1) |> Timex.format!("%m_%d_%Y", :strftime)

    backup_table = "hearing_" <> date

    # Drop backup table if it has previously been created.
    Repo.query("DROP TABLE IF EXISTS #{backup_table}", [])

    Logger.info("Creating backup hearings table")

    # Create a new backup table based upon the current hearings table.
    Repo.query("CREATE TABLE #{backup_table} AS SELECT * FROM hearings;", [])

    Logger.info("Truncating Hearings")  

    Repo.query("TRUNCATE hearings;", [])
  end

  @doc """
  Restore the previous days hearings.
  """
  def restore_hearings do
    backup_table =
      "hearing_" <> (Date.add(Date.utc_today(), -1) |> Timex.format!("%m_%d_%Y", :strftime))

    Logger.info("Restoring hearings from the previous day")

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
        {:ok, data} = StringIO.open(body)

        IO.binstream(data, :line)

      {:ok, %Tesla.Env{status: status}} ->
        Logger.error("Unhandled status code received: #{status}, while fetching #{url}")

      {:error, err} ->
        Logger.error("Unable to fetch #{url} because of: #{err}")
    end
  end

  defp count_csv_lines(stream) do
    stream
    |> Enum.to_list()
    |> Enum.count()
  end

  defp count_fails(imported) do
    Enum.count(imported, fn
      {status, _, _, _} -> status === :error
      {status, _} -> status === :error
    end)
  end
end
