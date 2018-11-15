defmodule Courtbot do
  alias Courtbot.{
    Csv,
    Repo,
    Subscriber,
    Notification,
    Configuration,
    Importer
  }

  alias CourtbotWeb.Response

  require Logger

  def get_import_configuration() do
    # Fetch configuration from the database. Database configuration takes priority over file.
    database_config =
      Configuration.get([
        "import_kind",
        "import_origin",
        "import_source"
      ])

    # We need to check if we have a configured importer from the database.
    case database_config do
      # We have at least the type configured, lets march on and see if we have enough.
      %{import_kind: kind} when kind == "CSV" or kind == "JSON" ->
        database_config(database_config)

      # We do not have database configuration, perhaps our configuration is in mix config.
      %{import_kind: kind} when kind == "" ->
        import_config =
          Application.get_env(:courtbot, Courtbot, %{})
          |> Map.new()
          |> Map.take([:importer])

        # Nope, no configuration.
        if import_config == %{} do
          # TODO(ts): Add a permanent link to configuration.
          raise "Importer must be configured, see documentation for configuration options"
        end

        mix_config(import_config)

      kind ->
        raise "Unsupported import kind: " <> kind
    end
  end

  def import, do: Courtbot.import(get_import_configuration())

  def import(%{kind: _kind, origin: origin, source: source, fields: fields, settings: settings}) do
    Logger.info("Starting import")

    data =
      case origin do
        :file -> File.stream!(source)
        :url -> request(source)
        _ -> raise "Unsupported import origin: #{origin}"
      end

    backup_and_truncate_hearings()

    imported =
      run_import(
        :csv,
        data,
        delimiter: settings.delimiter,
        has_headers: settings.has_headers,
        field_mapping: fields
      )

    Logger.info("Finished Import")

    imported
  end

  def database_config(%{
        import_kind: "JSON",
        import_origin: _origin,
        import_source: _source
      }),
      do: raise "JSON configuration in the database is not implemented yet"

  def database_config(%{
        import_kind: "CSV",
        import_origin: origin,
        import_source: source
      }) do
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

    %{
      import_delimiter: _,
      import_has_headers: has_headers
    } =
      Configuration.get([
        "import_delimiter",
        "import_has_headers"
      ])

    origin =
      origin
      |> String.downcase()
      |> String.to_existing_atom()

    # FIXME(ts): use the provided value
    delimiter = ?,

    %{
      kind: :csv,
      origin: origin,
      source: source,
      settings: %{
        has_headers: has_headers !== "",
        delimiter: delimiter
      },
      fields: field_mapping
    }
  end

  # TODO(ts): Implement
  def mix_config(%{importer: %{url: _url, type: {:json, _importer_config}}}),
    do: raise "JSON configuration in mix config is not implemented yet"

  def mix_config(%{importer: %{type: {type, importer_config}} = config}) do
    default = %{
      has_headers: false,
      delimiter: ?,
    }

    # FIXME(ts): Reintroduce functions as URL's or implement variable substitution.
    {origin, source} =
      case config do
        %{file: src} -> {:file, src}
        %{url: src} -> {:url, src}
      end

    settings =
      importer_config
      |> Keyword.take([:delimiter, :has_headers])
      |> Enum.into(%{})

    settings = Map.merge(default, settings)

    fields = format_importer_config(importer_config)

    %{
      kind: type,
      origin: origin,
      source: source,
      fields: fields,
      settings: settings
    }
  end

  defp format_importer_config(config) do
    field_mapping = Keyword.take(config, [:field_mapping])

    field_mapping[:field_mapping]
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
  end

  defp run_import(:csv, data, importer_config),
    do: Csv.extract(data, importer_config)

  defp run_import(_, _, _),
    do: raise "The supplied configuration to the importer is invalid"

  def notify() do
    Logger.info("Starting notifications")

    locales =
      Application.get_env(:courtbot, Courtbot, %{})
      |> Map.new()
      |> Map.take([:locales])

    if locales == %{} do
      raise "Locales must be defined for notifications, see documentation for configuration options"
    end

    %{locales: locales} = locales

    # FIXME(ts): Get a count of pending notifications mod by 100 and use SchEx to schedule batches.
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

          {:error, message, error_code} ->
            Logger.error(
              "Failed to send notification because:" <>
                message <> " with code " <> Integer.to_string(error_code)
            )

          {:error, message} ->
            Logger.error("Failed to send notification because:" <> message)
        end
      end
    )

    Logger.info("Finished notifications")
  end

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

  def mapped_county?() do
    case get_import_configuration() do
      %{fields: fields} ->
        case Enum.find(fields, fn field -> field[:destination] == :county end) do
          field when is_map(field) -> true
          _ -> false
        end

      _ ->
        false
    end
  end

  def mapped_type?() do
    case get_import_configuration() do
      %{fields: fields} ->
        case Enum.find(fields, fn field -> field[:destination] == :type end) do
          field when is_map(field) -> true
          _ -> false
        end

      _ ->
        false
    end
  end
end
