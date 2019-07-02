defmodule Courtbot.Integration.Rollbar do
  use Tesla

  plug(Tesla.Middleware.BaseUrl, "https://api.rollbar.com")
  plug(Tesla.Middleware.JSON)

  defp new() do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, "https://api.rollbar.com"}
    ])
  end

  def log(config = %{access_token: access_token, environment: environment}, message) do
    payload = %{
      "access_token" => access_token,
      "data" => build_data(environment, message)
    }

    # FIXME(ts): Handle 401 and 500
    post(new(), "/api/1/item/", payload)
  end

  defp build_data(environment, message),
    do: %{
      "environment" => environment,
      "language" => "Elixir v" <> System.version(),
      "platform" => System.otp_release(),
      "notify" => notify(),
      "level" => Atom.to_string(message[:level]),
      timestamp: message[:timestamp],
      body: build_type(message)
    }

  # FIXME(ts): Handle Exceptions
  defp build_type(_message = %{level: level, message: message, metadata: metadata})
       when level in [:info, :warn, :error] do
    %{
      message: %{
        body: message
      }
    }
  end

  defp notify(),
    do: %{
      "name" => "Courtbot",
      "version" => unquote(Mix.Project.config()[:version])
    }
end
