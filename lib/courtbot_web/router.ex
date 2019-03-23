defmodule CourtbotWeb.Router do
  use CourtbotWeb, :router
  use Plug.ErrorHandler

  pipeline :sms do
    plug(:fetch_session)
    plug(:accepts, ["json"])
  end

  scope "/", CourtbotWeb do
    pipe_through(:sms)

    post("/sms/:locale", SmsController, :twilio)
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

      Rollbax.report(kind, reason, stacktrace, _custom_data = %{}, occurrence_data)
    end
  end

  defp report?(:error, exception), do: Plug.Exception.status(exception) == 500
  defp report?(_kind, _reason), do: true
end
