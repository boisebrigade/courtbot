defmodule ExCourtbotWeb.TwilioUnsubscribeTest do
  use ExCourtbotWeb.ConnCase, async: true

  alias Ecto.Multi

  alias ExCourtbot.Repo
  alias ExCourtbotWeb.{Case, Hearing, Response, Twiml, Subscriber}

  @case_id Ecto.UUID.generate()
  @case_two_id Ecto.UUID.generate()

  @hearing_id Ecto.UUID.generate()
  @hearing_two_id Ecto.UUID.generate()

  @subscriber_id Ecto.UUID.generate()

  @phone_number "2025550186"
  @phone_number_invalid "2025550187"
  @case_number "aabbc000000000000"

  @unsubscribe "stop"

  @locale "en"

  setup do
    Multi.new()
    |> Multi.insert(:case, %Case{
      id: @case_id,
      case_number: @case_number,
      county: "canyon"
    })
    |> Multi.insert(:case_two, %Case{
      id: @case_two_id,
      case_number: @case_number,
      county: "gym"
    })
    |> Multi.insert(:hearing, %Hearing{
      id: @hearing_id,
      case_id: @case_id,
      time: ~T[09:00:00.000],
      date: Date.utc_today()
    })
    |> Multi.insert(:hearing_two, %Hearing{
      id: @hearing_two_id,
      case_id: @case_id,
      time: ~T[11:00:00.000],
      date: Date.utc_today()
    })
    |> Multi.insert(:subscriber, %Subscriber{
      id: @subscriber_id,
      case_id: @case_id,
      locale: @locale,
      phone_number: @phone_number
    })
    |> Repo.transaction()

    :ok
  end

  test "you can unsubscribe to a case", %{conn: conn} do
    unsubscribe_conn = post(conn, "/sms", %{"From" => @phone_number, "Body" => @unsubscribe})

    assert unsubscribe_conn.status == 200

    params = %{"From" => @phone_number, "Body" => @case_number, "locale" => @locale}
    message = Response.message(:unsubscribe, params)

    assert unsubscribe_conn.resp_body === Twiml.sms(message)
  end

  test "you are alerted if you are currently not subscribed", %{conn: conn} do
    unsubscribe_conn =
      post(conn, "/sms", %{"From" => @phone_number_invalid, "Body" => @unsubscribe})

    assert unsubscribe_conn.status == 200

    params = %{"From" => @phone_number, "Body" => @case_number, "locale" => @locale}
    message = Response.message(:no_subscriptions, params)

    assert unsubscribe_conn.resp_body === Twiml.sms(message)
  end
end
