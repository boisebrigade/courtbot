defmodule CourtbotWeb.Router do
  @moduledoc false
  use CourtbotWeb, :router
  use Plug.ErrorHandler

  require Logger

  pipeline :twilio do
    plug(CourtbotWeb.Twilio.Hmac)
    plug(:fetch_session)
    plug(:accepts, ["json"])
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  scope "/", CourtbotWeb do
    pipe_through(:twilio)

    post("/sms/:locale", SmsController, :twilio)
  end

  scope "/", CourtbotWeb do
    pipe_through(:api)

    get("/health", HealthController, :health)

    post("/status/:notificationId", SmsController, :status)

    post("/usage", SmsController, :usage)
  end

  def handle_errors(conn, %{kind: kind, reason: reason, stack: stacktrace}) do
    if report?(kind, reason) do
      conn =
        conn
        |> Plug.Conn.fetch_cookies()
        |> Plug.Conn.fetch_query_params()

      params =
        case conn.params do
          %Plug.Conn.Unfetched{aspect: :params} -> "unfetched"
          other -> other
        end

      occurrence_data = %{
        "request" => %{
          "cookies" => conn.req_cookies,
          "url" => "#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}",
          "user_ip" => List.to_string(:inet.ntoa(conn.remote_ip)),
          "headers" => Enum.into(conn.req_headers, %{}),
          "method" => conn.method,
          "params" => params
        }
      }

      # FIXME(ts): log the occurrence_data
      #       Logger.error(Exception.format(:error, reason, __STACKTRACE__))
    end
  end

  defp report?(:error, exception), do: Plug.Exception.status(exception) == 500
  defp report?(_kind, _reason), do: true
end
