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

    body =
      body
      |> String.trim()
      |> String.replace("-", "")
      |> String.replace("_", "")
      |> String.replace(",", "")
      |> String.downcase()

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

    conn
    |> put_session(:state, state)
    |> put_session(:properties, properties)
    |> put_session(:input, input)
    |> encode_for_twilio(response)
  end

  defp encode_for_twilio(conn, response) do
    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(:ok, Twiml.sms(response))
  end
end
