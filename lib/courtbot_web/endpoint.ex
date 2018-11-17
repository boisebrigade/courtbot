defmodule CourtbotWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :courtbot

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    plug(Phoenix.CodeReloader)
  end

  plug(Plug.Logger)

  plug(
    Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug(
    Plug.Session,
    store: :cookie,
    key: "_courtbot_key",
    signing_salt: "JXkMr3AQ",
    log: :debug
  )

  plug(CourtbotWeb.Router)

  @doc """
  Callback invoked for dynamically configuring the endpoint.

  It receives the endpoint configuration and checks if
  configuration should be loaded from the system environment.
  """
  def init(_key, config) do
    if config[:load_from_system_env] do
      port = String.to_integer(System.get_env("PORT") || "4000")
      host = System.get_env("HOST") || "localhost"

      secret_key_base =
        if config[:secret_key_base] do
          config[:secret_key_base]
        else
          System.get_env("SECRET_KEY_BASE") ||
            raise "expected the SECRET_KEY_BASE environment variable to be set"
        end

      config =
        config
        |> Keyword.put(:http, port: port)
        |> Keyword.put(:url, port: port, host: host)
        |> Keyword.put(:secret_key_base, secret_key_base)

      # If we are trying to mount to 443 then set HTTPS specific settings
      config =
        if port === 443 do
          config
          |> Keyword.put(:url, scheme: "https")
          |> Keyword.put(:force_ssl, rewrite_on: [:x_forwarded_proto])
        else
          config
        end

      {:ok, config}
    else
      {:ok, config}
    end
  end
end
