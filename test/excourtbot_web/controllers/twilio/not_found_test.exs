defmodule ExCourtbotWeb.TwilioNotFoundTest do
  use ExCourtbotWeb.ConnCase, async: true

  alias Ecto.Multi

  alias ExCourtbot.Repo
  alias ExCourtbotWeb.{Case, Hearing, Response, Twiml, Subscriber}

  @phone_number "2025550186"
  @case_doesnt_exist_number "aabbc000000000000"

  @locale "en"

  test "you get a reponse if the case number is invaild", %{conn: conn} do
    initial_conn =
      post(conn, "/sms", %{"From" => @phone_number, "Body" => @case_doesnt_exist_number})

    assert initial_conn.status === 200

    params = %{"From" => @phone_number, "Body" => @case_doesnt_exist_number, "locale" => @locale}
    message = Response.message(:not_found, params)

    assert initial_conn.resp_body === Twiml.sms(message)
  end
end
