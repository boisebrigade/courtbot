defmodule ExCourtbotWeb.TwilioCountyTest do
  use ExCourtbotWeb.ConnCase, async: true

  alias Ecto.Multi

  alias ExCourtbot.Repo
  alias ExCourtbotWeb.{Case, Hearing, Response, Twiml, Subscriber}

  @case_id Ecto.UUID.generate()
  @case_two_id Ecto.UUID.generate()

  @hearing_id Ecto.UUID.generate()
  @hearing_two_id Ecto.UUID.generate()
  @hearing_three_id Ecto.UUID.generate()

  @subscriber_id Ecto.UUID.generate()

  @phone_number "2025550186"
  @case_number "aabbc000000000000"

  @county_one "canyon"

  @county_two "gym"

  setup do
    Multi.new()
    |> Multi.insert(:case_one, %Case{
      id: @case_id,
      case_number: @case_number,
      county: @county_one
    })
    |> Multi.insert(:case_two, %Case{
      id: @case_two_id,
      case_number: @case_number,
      county: @county_two
    })
    |> Multi.insert(:hearing, %Hearing{
      id: @hearing_id,
      case_id: @case_id,
      time: ~T[09:00:00.000],
      date: Ecto.Date.utc()
    })
    |> Multi.insert(:hearing_two, %Hearing{
      id: @hearing_two_id,
      case_id: @case_id,
      time: ~T[11:00:00.000],
      date: Ecto.Date.utc()
    })
    |> Multi.insert(:hearing_three, %Hearing{
      id: @hearing_three_id,
      case_id: @case_two_id,
      time: ~T[11:00:00.000],
      date: Ecto.Date.utc()
    })
    |> Repo.transaction()

    :ok
  end

  test "you can subscribe to a case with multiple counties, county one", %{conn: conn} do
    # Check the sucess path
    initial_conn = post(conn, "/sms", %{"From" => @phone_number, "Body" => @case_number})

    assert initial_conn.status === 200
    assert initial_conn.private[:plug_session] === %{"requires_county" => @case_number}

    params = %{"From" => @phone_number, "Body" => @case_number, "locale" => "en"}
    message = Response.message(:requires_county, params)

    assert initial_conn.resp_body === Twiml.sms(message)

    # Check that we enter into the reminder phase
    county_conn = post(initial_conn, "/sms", %{"From" => @phone_number, "Body" => @county_one})

    params = %{"From" => @phone_number, "Body" => @case_number, "locale" => "en"}

    message =
      Response.message(:hearing_details, params) <> Response.message(:prompt_reminder, params)

    assert county_conn.status === 200

    assert county_conn.resp_body === Twiml.sms(message)
  end

  test "you can subscribe to a case with multiple counties, county two", %{conn: conn} do
    # Check the sucess path
    initial_conn = post(conn, "/sms", %{"From" => @phone_number, "Body" => @case_number})

    assert initial_conn.status === 200
    assert initial_conn.private[:plug_session] === %{"requires_county" => @case_number}

    params = %{"From" => @phone_number, "Body" => @case_number, "locale" => "en"}
    message = Response.message(:requires_county, params)

    assert initial_conn.resp_body === Twiml.sms(message)

    # Check that we enter into the reminder phase
    county_conn = post(initial_conn, "/sms", %{"From" => @phone_number, "Body" => @county_two})

    params = %{"From" => @phone_number, "Body" => @case_number, "locale" => "en"}

    message =
      Response.message(:hearing_details, params) <> Response.message(:prompt_reminder, params)

    assert county_conn.status === 200

    assert county_conn.resp_body === Twiml.sms(message)
  end

  test "you get a response if we have no information for that counties case", %{conn: conn} do
    # Check the sucess path
    initial_conn = post(conn, "/sms", %{"From" => @phone_number, "Body" => @case_number})

    assert initial_conn.status === 200
    assert initial_conn.private[:plug_session] === %{"requires_county" => @case_number}

    params = %{"From" => @phone_number, "Body" => @case_number, "locale" => "en"}
    message = Response.message(:requires_county, params)

    assert initial_conn.resp_body === Twiml.sms(message)

    # Check that we enter into the reminder phase
    county_conn = post(initial_conn, "/sms", %{"From" => @phone_number, "Body" => "invalid"})

    params = %{"From" => @phone_number, "Body" => @case_number, "locale" => "en"}
    message = Response.message(:no_county, params)

    assert county_conn.status === 200

    assert county_conn.resp_body === Twiml.sms(message)
  end
end
