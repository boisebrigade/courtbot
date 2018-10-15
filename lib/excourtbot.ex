defmodule ExCourtbot do
  alias ExCourtbot.{
    Csv,
    Repo,
    Subscriber,
    Notification,
    Configuration,
    Importer
  }

  alias ExCourtbotWeb.Response

  require Logger

  def import do
    # Fetch configuration from the database.
    database_config =
      Configuration.get([
        "import_kind",
        "import_origin",
        "import_source"
      ])

    Logger.info("Starting import")

    Logger.info("Creating backup hearings table")

    backup_hearings()

    # We need to check if we have a configured importer from the database.
    imported =
      case database_config do
        # We have at least the type configured, lets march on and see if we have enough.
        %{import_kind: kind} when kind == "CSV" or kind == "JSON" ->
          import_from_database_config(database_config)

        # We do not have database configuration, perhaps our configuration is in mix config.
        %{import_kind: kind} when kind == "" ->
          import_config =
            Application.get_env(:excourtbot, ExCourtbot, %{})
            |> Map.new()
            |> Map.take([:importer])

          # Nope, no configuration.
          if import_config == %{} do
            # TODO(ts): Add a perma link to documentation.
            raise "Importer must be configured, see documentation for configuration options"
          end

          import_from_mix_config(import_config)

        _ ->
          raise "Unsupported import type"
      end

    Logger.info("Cleaning up hearing data")

    replace_hearings()

    Logger.info("Finished Import")

    imported
  end

  defp import_from_database_config(%{
         import_kind: "JSON",
         import_origin: _origin,
         import_source: _source
       }),
       do: Logger.error("Not implemented yet")

  defp import_from_database_config(%{
         import_kind: "CSV",
         import_origin: origin,
         import_source: source
       }) do
    data =
      case origin do
        "FILE" -> File.stream!(source)
        "URL" -> request(source)
        _ -> raise "Unsupported import origin: #{origin}"
      end

    field_mapping =
      Importer.mapped()
      |> Enum.reduce([], fn field, acc ->
        mapping = Map.take(field, [:index, :pointer, :destination, :kind, :format, :order])

        mapping =
          case mapping do
            %{destination: destination} when not is_nil(destination) ->
              Map.put(mapping, :destination, String.to_atom(field.destination))

            _ ->
              mapping
          end

        [mapping | acc]
      end)

    # FIXME(ts): Default these?
    %{
      import_delimiter: delimiter,
      import_has_headers: has_headings
    } =
      Configuration.get([
        "import_delimiter",
        "import_has_headers"
      ])

    run_import(
      :csv,
      data,
      delimiter: delimiter,
      has_headings: has_headings,
      field_mapping: field_mapping
    )
  end

  # TODO(ts): Implement
  defp import_from_mix_config(%{importer: %{url: _url, type: {:json, _importer_config}}}),
    do: Logger.error("Not implemented yet")

  # FIXME(ts): Reintroduce functions as URL's or implement variable substitution.
  defp import_from_mix_config(%{importer: %{url: url, type: {type, importer_config}}}),
    do: run_import(type, request(url), format_importer_config(importer_config))

  defp import_from_mix_config(%{importer: %{file: file, type: {type, importer_config}}}),
    do: run_import(type, File.stream!(file), format_importer_config(importer_config))

  defp format_importer_config(config) do
    {_, configuration} =
      Keyword.get_and_update!(config, :field_mapping, fn field_mapping ->
        mapping =
          field_mapping
          |> Enum.with_index(1)
          |> Enum.map(fn
            {{destination, format}, index} ->
              if destination == :date or destination == :time or destination == :date_and_time do
                %{
                  destination: destination,
                  format: format,
                  index: index,
                  kind: "date",
                  pointer: nil
                }
              else
                %{
                  destination: destination,
                  format: format,
                  index: index,
                  kind: "type",
                  pointer: nil
                }
              end

            {destination, index} ->
              %{destination: destination, format: nil, index: index, kind: "string", pointer: nil}
          end)

        {field_mapping, mapping}
      end)

    configuration
  end

  defp run_import(:csv, data, importer_config),
    do: Csv.extract(data, importer_config)

  defp run_import(_, _, _),
    do: Logger.error("Importer has been supplied invalid configuration.")

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

  defp backup_hearings do
    backup_table =
      "hearing_" <> (Date.add(Date.utc_today(), -1) |> Timex.format!("%m_%d_%Y", :strftime))

    # Drop backup table if it has previously been created.
    Repo.query("DROP TABLE IF EXISTS #{backup_table}", [])

    # Create a new backup table based upon the current hearings table.
    Repo.query("CREATE TABLE #{backup_table} AS SELECT * FROM hearings", [])
  end

  defp replace_hearings do
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
