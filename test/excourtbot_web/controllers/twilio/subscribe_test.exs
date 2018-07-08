defmodule ExCourtbotWeb.TwilioSubscribeTest do
  use ExCourtbotWeb.ConnCase, async: true

  alias Ecto.Multi

  alias ExCourtbot.Repo
  alias ExCourtbotWeb.{Case, Hearing, Subscriber}

  @case_id Ecto.UUID.generate()
  @case_two_id Ecto.UUID.generate()

  @hearing_id Ecto.UUID.generate()
  @hearing_two_id Ecto.UUID.generate()

  @subscriber_id Ecto.UUID.generate()

  @phone_number "2084470077"
  @case_number "aabbc000000000000"

  setup do
    Multi.new()
    |> Multi.insert(:case_one, %Case{
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
      time: Time.to_string(~T[09:00:00.000]),
      date: Date.to_string(Date.utc_today())
    })
    |> Multi.insert(:hearing_two, %Hearing{
      id: @hearing_two_id,
      case_id: @case_id,
      time: Time.to_string(~T[11:00:00.000]),
      date: Date.to_string(Date.utc_today())
    })
    |> Multi.insert(:subscriber, %Subscriber{
      id: @subscriber_id,
      phone_number: @phone_number
    })
    |> Repo.transaction()

    :ok
  end

  test "you can subscribe to a case via sms", %{conn: conn} do
    conn = post(conn, "/sms", %{"From" => @phone_number, "Body" => @case_number})
  end
end
