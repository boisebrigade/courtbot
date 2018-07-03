defmodule ExCourtbotWeb.Import do

  def import(data) do

  end

  def import() do
    Application.get_env(:excourtbot, ExCourtbot.Import)
    |> case do
      [source: %{url: url}] ->
        case HTTPoison.get(url) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          ExCourtbotWeb.Import.import(data)
        {:ok, %HTTPoison.Response{status_code: 404}} ->
          IO.puts "Not found :("
        {:error, %HTTPoison.Error{reason: reason}} ->
          IO.inspect reason
        end
      [source: %{file: file}] ->  file |> File.stream! |> ExCourtbotWeb.Import.import
      _ -> IO.inspect "none"
    end
  end
end
