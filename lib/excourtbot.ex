defmodule ExCourtbot do
  alias ExCourtbot.Repo
  alias ExCourtbotWeb.{Csv, Subscriber}

  require Logger

  def import(data, {:csv, options}) do
    Csv.extract(data, options)
  end

  def import(_data, {:json, _options}) do
    # TODO(ts): Implement
    Logger.error("Not implemented yet")
  end

  def import(_, _) do
    Logger.error("Parser config has not been defined")
  end

  def import() do
    Logger.info("Starting import")

    Logger.info("Truncating hearings")

    backup_table = "hearing_" <> Date.utc_today() |> Date.add(-1) |> Date.to_string

    Repo.query("CREATE TABLE #{backup_table} AS SELECT * FROM hearings", [])

    imported =
      Application.get_env(:excourtbot, ExCourtbot.Import)
      |> case do
        [source: %{url: url, type: type}] when is_function(url) -> request(url.(), type)
        [source: %{url: url, type: type}] -> request(url, type)
        [source: %{file: file, type: type}] -> file |> File.stream!() |> ExCourtbot.import(type)

        _ ->
          Logger.error("Parser source has not been defined")
      end

    Logger.info("Cleaning up hearing data")

    Repo.query("""
    BEGIN;
    DROP TABLE hearings;
    ALTER TABLE #{backup_table} RENAME TO hearings;
    COMMIT;
    """, [])

    Logger.info("Finished Import")

    imported
  end

  def notify() do
    Logger.info("Starting notifications")

    Subscriber.all_pending_notifications()
    |> IO.inspect()
#    |> Enum.map()

    Logger.info("Finished notifications")
  end

  defp request(url, type) do
    case Tesla.get(url, follow_redirect: true) do
      {:ok, %Tesla.Env{status: 200, body: body}} -> ExCourtbot.import(body, type)

      {:ok, %Tesla.Env{status: status}} ->
        Logger.error("Unhandled status code received: #{status}, while fetching #{url}")

      {:error, err} ->
        Logger.error("Unable to fetch #{url} because of: #{err}")
    end
  end

end
