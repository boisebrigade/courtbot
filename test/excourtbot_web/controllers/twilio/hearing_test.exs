defmodule ExCourtbotWeb.TwilioHearingTest do
  use ExCourtbotWeb.ConnCase, async: true

  alias Ecto.Multi

  alias ExCourtbot.Repo
  alias ExCourtbotWeb.{Case, Hearing, Subscriber}

  @case_id Ecto.UUID.generate()

  @hearing_id Ecto.UUID.generate()

  @subscriber_id Ecto.UUID.generate()

  @phone_number "2025550186"
  @case_number "aabbc000000000000"

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
      date: Ecto.Date.utc()
    })
    |> Multi.insert(:subscriber, %Subscriber{
      id: @subscriber_id,
      phone_number: @phone_number
    })
    |> Repo.transaction()

    :ok
  end

  test "you can subscribe to a case via sms", %{conn: conn} do
    initial_conn = post(conn, "/sms", %{"From" => @phone_number, "Body" => @case_number})

    assert initial_conn.status == 200
    assert initial_conn.private[:plug_session] === %{"reminder" => @case_id}
  end
end
