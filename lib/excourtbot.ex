defmodule ExCourtbot do
  alias ExCourtbot.{Csv, Repo, Subscriber, Notification}
  alias ExCourtbotWeb.Response

  require Logger

  def import() do
    import_config =
      Application.get_env(:excourtbot, ExCourtbot, %{})
      |> Map.new()
      |> Map.take([:importer])

    if import_config == %{} do
      raise "Importer must be configured, see documentation for configuration options"
    end

    Logger.info("Starting import")

    Logger.info("Creating backup hearings table")

    backup_table = "hearing_" <> (Date.add(Date.utc_today(), -1) |> Date.to_string())

    Repo.query("CREATE TABLE #{backup_table} AS SELECT * FROM hearings", [])

    imported =
      import_config
      |> case do
        %{importer: %{url: url, type: type}} when is_function(url) ->
          run_import(request(url.(), type), type)

        %{importer: %{url: url, type: type}} ->
          run_import(request(url, type), type)

        %{importer: %{file: file, type: type}} ->
          run_import(File.stream!(file), type)

        _ ->
          Logger.error("Parser source has not been defined")
      end

    Logger.info("Cleaning up hearing data")

    Repo.query(
      """
      BEGIN;
      DROP TABLE hearings;
      ALTER TABLE #{backup_table} RENAME TO hearings;
      COMMIT;
      """,
      []
    )

    Logger.info("Finished Import")

    imported
  end

  defp run_import(data, {:csv, options}) do
    Csv.extract(data, options)
  end

  defp run_import(_data, {:json, _options}) do
    # TODO(ts): Implement
    Logger.error("Not implemented yet")
  end

  defp run_import(_, _) do
    Logger.error("Parser config has not been defined")
  end

  def notify() do
    Logger.info("Starting notifications")

    locales =
      Application.get_env(:excourtbot, ExCourtbot, %{})
      |> Map.new()
      |> Map.take([:locales])

    if locales == %{} do
      raise "Locales must be defined for notifications, see documentation for configuration options"
    end

    %{locales: locales} = locales
    #

    Enum.map(
      Subscriber.all_pending_notifications(),
      fn params = %{
           "locale" => locale,
           "phone_number" => phone_number,
           "subscriber_id" => subscriber_id
         } ->
        from_number = Map.fetch!(locales, locale)
        to_number = phone_number

        response = Response.message(:reminder, params)

        case ExTwilio.Message.create(to: to_number, from: from_number, body: response) do
          {:ok, _} ->
            %Notification{}
            |> Notification.changeset(%{subscriber_id: subscriber_id})
            |> Repo.insert()

          {:error, message} ->
            Logger.error(message)
        end
      end
    )

    Logger.info("Finished notifications")
  end

  defp request(url, type) do
    case Tesla.get(url, follow_redirect: true) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        run_import(body, type)

      {:ok, %Tesla.Env{status: status}} ->
        Logger.error("Unhandled status code received: #{status}, while fetching #{url}")

      {:error, err} ->
        Logger.error("Unable to fetch #{url} because of: #{err}")
    end
  end
end
