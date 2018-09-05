defmodule ExCourtbotWeb.TwilioRemindTest do
  use ExCourtbotWeb.ConnCase, async: true

  alias Ecto.Multi

  alias ExCourtbot.{Case, Hearing, Repo}
  alias ExCourtbotWeb.{Response, Twiml}

  @case_id Ecto.UUID.generate()
  @case_two_id Ecto.UUID.generate()

  @hearing_id Ecto.UUID.generate()

  @phone_number "2025550186"
  @case_number "aabbc000000000000"
  @case_two_number "aabbc000000000001"

  @accept "Yes"
  @reject "No"

  @locale "en"

  @time ~T[09:00:00.000]
  @date Date.utc_today()

  setup do
    Multi.new()
    |> Multi.insert(:case, %Case{
      id: @case_id,
      case_number: @case_number,
      county: "canyon"
    })
    |> Multi.insert(:case_two, %Case{
      id: @case_two_id,
      case_number: @case_two_number,
      county: "canyon"
    })
    |> Multi.insert(:hearing, %Hearing{
      id: @hearing_id,
      case_id: @case_id,
      time: @time,
      date: @date
    })
    |> Repo.transaction()

    :ok
  end

  # TODO(ts): Check the subscriber is actually written

  test "you can subscribe to a reminder for a case", %{conn: conn} do
    # Subscribe as normal
    initial_conn = post(conn, "/sms", %{"From" => @phone_number, "Body" => @case_number})

    # Accept reminder
    remind_conn = post(initial_conn, "/sms", %{"From" => @phone_number, "Body" => @accept})

    assert remind_conn.status === 200

    params = %{"From" => @phone_number, "Body" => @case_number, "locale" => @locale}
    # Expect acceptance
    message = Response.message(:accept_reminder, params)

    assert remind_conn.resp_body === Twiml.sms(message)
  end

  test "you can reject a reminder for a case", %{conn: conn} do
    # Subscribe as normal
    initial_conn = post(conn, "/sms", %{"From" => @phone_number, "Body" => @case_number})

    # Reject reminder
    remind_conn = post(initial_conn, "/sms", %{"From" => @phone_number, "Body" => @reject})

    assert remind_conn.status === 200

    params = %{"From" => @phone_number, "Body" => @case_number, "locale" => @locale}
    # Expect rejection
    message = Response.message(:reject_reminder, params)

    assert remind_conn.resp_body === Twiml.sms(message)
  end

  test "you can subscribe to a reminder case without any hearing information", %{conn: conn} do
    # Subscribe as normal
    initial_conn = post(conn, "/sms", %{"From" => @phone_number, "Body" => @case_two_number})

    # Ensure you can enter the reminder
    remind_conn = post(initial_conn, "/sms", %{"From" => @phone_number, "Body" => @accept})

    params = %{"From" => @phone_number, "Body" => @case_number, "locale" => @locale}
    # Expect acceptance
    message = Response.message(:accept_reminder, params)

    assert remind_conn.resp_body === Twiml.sms(message)
  end

  test "you can reject a reminder for a case without any hearing information", %{conn: conn} do
    # Subscribe as normal
    initial_conn = post(conn, "/sms", %{"From" => @phone_number, "Body" => @case_two_number})

    # Ensure you can enter the reminder
    remind_conn = post(initial_conn, "/sms", %{"From" => @phone_number, "Body" => @reject})

    params = %{"From" => @phone_number, "Body" => @case_number, "locale" => @locale}
    # Expect rejection
    message = Response.message(:reject_reminder, params)

    assert remind_conn.resp_body === Twiml.sms(message)
  end

  test "you get a response if we don't know if you want to subscribe", %{conn: conn} do
    # Subscribe as normal
    initial_conn = post(conn, "/sms", %{"From" => @phone_number, "Body" => @case_number})

    # Send an unexpected response to the reminder prompt
    invalid_conn = post(initial_conn, "/sms", %{"From" => @phone_number, "Body" => "invalid"})

    assert invalid_conn.status === 200

    params = %{"From" => @phone_number, "Body" => @case_number, "locale" => @locale}
    # Expect yes or no
    message = Response.message(:yes_or_no, params)

    assert invalid_conn.resp_body === Twiml.sms(message)

    # Check that you can still subscribe
    remind_conn = post(invalid_conn, "/sms", %{"From" => @phone_number, "Body" => @accept})

    assert remind_conn.status === 200

    params = %{"From" => @phone_number, "Body" => @case_number, "locale" => @locale}
    # Expect acceptance
    message = Response.message(:accept_reminder, params)

    assert remind_conn.resp_body === Twiml.sms(message)
  end
end
