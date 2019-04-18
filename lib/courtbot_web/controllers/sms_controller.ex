defmodule CourtbotWeb.SmsController do
  @moduledoc false

  use CourtbotWeb, :controller

  alias Courtbot.Workflow
  alias CourtbotWeb.{Response, Twiml}

  def twilio(
        conn = %Plug.Conn{private: %{plug_session: session}},
        _params = %{"From" => phone_number, "Body" => body, "locale" => locale}
      ) do
    %{"properties" => properties, "state" => state, "input" => input} =
      Map.merge(%{"properties" => %{}, "state" => :inquery, "input" => %{}}, session)

    input = Map.put(input, state, body)

    body = normalize_input(body)

    try do
      {response, _fsm = %Courtbot.Workflow{state: state, properties: properties, input: input}} =
        Workflow.init(%Workflow{
          counties: true,
          types: true,
          locale: locale,
          state: state,
          properties: properties,
          input: input
        })
        |> Workflow.message(from: phone_number, body: body)
        |> Response.get_message()

      conn =
        if state === :inquery do
          conn
          |> configure_session(drop: true)
        else
          conn
          |> put_session(:state, state)
          |> put_session(:properties, properties)
          |> put_session(:input, input)
        end

      encode_for_twilio(conn, response)

    rescue
      e ->
        Rollbax.report(:error, e, System.stacktrace())

        conn
        |> configure_session(drop: true)
        |> send_resp(:internal_server_error, "")
    end
  end

  defp normalize_input(input) do
    input
    |> String.trim()
    |> String.replace("-", "")
    |> String.replace("_", "")
    |> String.replace(",", "")
    |> String.downcase()
  end

  defp encode_for_twilio(conn, response) do
    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(:ok, Twiml.sms(response))
  end
end
