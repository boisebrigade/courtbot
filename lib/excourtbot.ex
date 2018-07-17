defmodule ExCourtbot do
  alias ExCourtbotWeb.{Csv, Subscriber}

  require Logger

  def import(data, {:csv, options}) do
    Csv.extract(data, options)
  end

  def import(_data, {:json, _options}) do
    # TODO(ts): Implement
    Logger.error("Not implemented yet")
  end

  def import(data, _) do
    Logger.error("Parser config has not been defined")
  end

  def import() do
    Logger.info("Starting import")

    imported =
      Application.get_env(:excourtbot, ExCourtbot)
      |> case do
        [source: %{url: url, type: type}] ->
          case HTTPoison.get(url, follow_redirect: true) do
            {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
              ExCourtbot.import(body, type)

            {:ok, %HTTPoison.Response{status_code: status}} ->
              Logger.error("Unhandled status code received: #{status}, while fetching #{url}")

            {:error, %HTTPoison.Error{reason: reason}} ->
              Logger.error("Unable to fetch #{url} because of: #{reason}")
          end

        [source: %{file: file, type: type}] ->
          file |> File.stream!() |> ExCourtbot.import(type)

        _ ->
          Logger.error("Parser source has not been defined")
      end

    Logger.info("Finished Import")

    imported
  end

  def notify() do
    Logger.info("Starting notifications")

    Subscriber.all_pending_notifications()
    |> IO.inspect()

    Logger.info("Finished notifications")
  end
end
