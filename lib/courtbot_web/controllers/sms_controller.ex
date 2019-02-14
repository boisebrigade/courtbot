defmodule CourtbotWeb.SmsController do
  use CourtbotWeb, :controller

  alias Courtbot.Workflow
  alias CourtbotWeb.{Response, Twiml}

  def twilio(conn = %Plug.Conn{private: %{plug_session: session}}, _params = %{"From" => phone_number, "Body" => body, "locale" => locale}) do
    %{"properties" => properties, "state" => state} = Map.merge(%{"properties" => %{}, "state" => :inquery}, session)

    body = body
      |> String.trim()
      |> String.replace("-", "")
      |> String.replace("_", "")
      |> String.replace(",", "")
      |> String.downcase()

    {response, _fsm = %Courtbot.Workflow{state: state, properties: properties}} =
      Workflow.init(%Workflow{counties: true, types: true, locale: locale, state: state, properties: properties})
      |> Workflow.message(from: phone_number, body: body)
      |> Response.get_message()

    conn
    |> put_session(:state, state)
    |> put_session(:properties, properties)
    |> encode_for_twilio(response)
  end

  defp encode_for_twilio(conn, response) do
    conn
    |> put_resp_content_type("application/xml")
    |> send_resp(200, Twiml.sms(response))
  end
end
