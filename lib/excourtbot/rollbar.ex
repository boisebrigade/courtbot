defmodule ExCourtbot.Rollbar do
  def init(config) do
    rollbar_access_token =
      if config[:access_token] do
        System.get_env("ROLLBAR_ACCESS_TOKEN") ||
          raise "expected the ROLLBAR_ACCESS_TOKEN environment variable to be set"
      else
        config[:access_token]
      end

    config
    |> Keyword.put(:access_token, rollbar_access_token)
  end
end
