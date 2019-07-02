defmodule CourtbotWeb.Twilio.Hmac do
  @moduledoc """
  HMAC Signature verification for Twilio incoming requests.

  - [Twilio docs](https://www.twilio.com/docs/usage/security)
  """

  import Plug.Conn

  require Logger

  alias Courtbot.Configuration

  def init(opts), do: opts

  def call(conn = %Plug.Conn{host: host, request_path: request_path, params: params}, _) do
    twilio_signature = get_req_header(conn, "x-twilio-signature")

    if twilio_signature != [] do
      check_signatures(conn, twilio_signature)
    else
      reject(conn, "Header x-twilio-signature was not present on request")
    end
  end

  defp check_signatures(conn, [twilio_signature]) do
    with %{twilio: %{auth_token: auth_token}} <- Configuration.get([:twilio]) do
      calculated_signature =
        hmac_signature(url_from_conn(conn) <> combine_params(conn.body_params), auth_token)

      if Plug.Crypto.secure_compare(twilio_signature, calculated_signature) do
        conn
      else
        reject(conn, "Signatures did not match")
      end
    else
      _ -> reject(conn, "Unable to fetch twilio auth token for checking hmac signature")
    end
  end

  defp url_from_conn(conn) do
    "#{Atom.to_string(conn.scheme)}://#{conn.host}#{conn.request_path}"
  end

  defp hmac_signature(data, token), do: :crypto.hmac(:sha, token, data) |> Base.encode64()

  defp combine_params(params) do
    params
    |> Map.keys()
    |> Enum.sort()
    |> Enum.map(fn key -> key <> Map.get(params, key) end)
    |> Enum.join()
  end

  defp reject(conn, reason) do
    Logger.error("HMAC verification of request failed: #{reason}")

    conn
    |> send_resp(:unauthorized, "")
    |> halt
  end
end
