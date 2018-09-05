defmodule ExCourtbotWeb.TwilioResubscribeTest do
  use ExCourtbotWeb.ConnCase, async: true

  alias Ecto.Multi

  alias ExCourtbot.{Case, Hearing, Repo, Subscriber}
  alias ExCourtbotWeb.{Response, Twiml}

  @case_id Ecto.UUID.generate()

  @hearing_id Ecto.UUID.generate()

  @subscriber_id Ecto.UUID.generate()

  @phone_number "2025550186"
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
    |> Multi.insert(:hearing, %Hearing{
      id: @hearing_id,
      case_id: @case_id,
      time: ~T[09:00:00.000],
      date: Date.utc_today()
    })
    |> Multi.insert(
      :subscriber,
      %Subscriber{}
      |> Subscriber.changeset(%{
        id: @subscriber_id,
        case_id: @case_id,
        locale: @locale,
        phone_number: @phone_number
      })
    )
    |> Repo.transaction()

    :ok
  end

  test "you can unsubscribe to a case", %{conn: conn} do
    unsubscribe_conn = post(conn, "/sms", %{"From" => @phone_number, "Body" => @unsubscribe})

    assert unsubscribe_conn.status == 200

    params = %{"From" => @phone_number, "Body" => @case_number, "locale" => @locale}
    message = Response.message(:unsubscribe, params)

    assert unsubscribe_conn.resp_body === Twiml.sms(message)

    resubscribe_conn =
      post(unsubscribe_conn, "/sms", %{"From" => @phone_number, "Body" => "start"})

    params = %{"From" => @phone_number, "Body" => @case_number, "locale" => @locale}
    message = Response.message(:resubscribe, params)

    assert resubscribe_conn.resp_body === Twiml.sms(message)
  end
end
