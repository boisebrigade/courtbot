defmodule ExCourtbot do
  @moduledoc """
  ExCourtbot keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  require Logger

  def import(data, type) do
    case type do
      {:csv, config} -> ExCourtbotWeb.Csv.extract(data, config)
      _ -> Logger.error "Parser config has not been defined"
    end
  end

  def import() do
    Logger.info "Starting import"

    imported = Application.get_env(:excourtbot, ExCourtbot)
    |> case do
      [source: %{url: url, type: type}] ->
        case HTTPoison.get(url, follow_redirect: true) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} -> ExCourtbot.import(body, type)
          {:ok, %HTTPoison.Response{status_code: status}} -> Logger.error "Unhandled status code received: #{status}, while fetching #{url}"
          {:error, %HTTPoison.Error{reason: reason}} -> Logger.error "Unable to fetch #{url} because of: #{reason}"
        end
      [source: %{file: file, type: type}] -> file |> File.stream! |> ExCourtbot.import(type)
      _ -> Logger.error "Parser source has not been defined"
    end

    Logger.info "Finished Import"

    imported
  end

  def notify() do
    Logger.info "Starting notifications"


    Logger.info "Finished notifications"
  end
end
