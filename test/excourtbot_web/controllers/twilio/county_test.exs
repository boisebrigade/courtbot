defmodule CourtbotWeb.TwilioCountyTest do
  use CourtbotWeb.ConnCase, async: true

  alias Ecto.Multi

  alias Courtbot.{Case, Hearing, Repo}
  alias CourtbotWeb.{Response, Twiml}

  @import_config [
    importer: %{
      file: Path.expand("../data/boise.csv", __DIR__),
      type:
        {:csv,
        [
          {:has_headers, true},
          {:field_mapping,
            [
              :case_number,
              :last_name,
              :first_name,
              nil,
              nil,
              nil,
              {:date, "%-m/%e/%Y"},
              {:time, "%k:%M"},
              nil,
              :county
            ]}
        ]}
    }
  ]

  @case_id Ecto.UUID.generate()
  @case_two_id Ecto.UUID.generate()

  @hearing_id Ecto.UUID.generate()
  @hearing_two_id Ecto.UUID.generate()
  @hearing_three_id Ecto.UUID.generate()

  @phone_number "2025550186"
  @case_number "aabbc000000000000"

  @county_one "canyon"

  @county_two "gym"

  @time ~T[09:00:00]
  @time_two ~T[11:00:00]

  @date Date.utc_today()

  setup do
    Application.put_env(:courtbot, Courtbot, @import_config)

    Multi.new()
    |> Multi.insert(:case, %Case{
      id: @case_id,
      first_name: "Case",
      last_name: "One",
      case_number: @case_number,
      county: @county_one
    })
    |> Multi.insert(:case_two, %Case{
      id: @case_two_id,
      first_name: "Case",
      last_name: "Two",
      case_number: @case_number,
      county: @county_two
    })
    |> Multi.insert(:hearing, %Hearing{
      id: @hearing_id,
      case_id: @case_id,
      time: @time,
      date: @date
    })
    |> Multi.insert(:hearing_two, %Hearing{
      id: @hearing_two_id,
      case_id: @case_id,
      time: @time_two,
      date: @date
    })
    |> Multi.insert(:hearing_three, %Hearing{
      id: @hearing_three_id,
      case_id: @case_two_id,
      time: @time_two,
      date: @date
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

    params = %{
      "From" => @phone_number,
      "Body" => @case_number,
      "locale" => "en",
      "time" => @time,
      "date" => @date
    }

    message =
      Response.message(:hearing_details, params) <>
        " " <> Response.message(:prompt_reminder, params)

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

    params = %{
      "From" => @phone_number,
      "Body" => @case_number,
      "locale" => "en",
      "time" => @time_two,
      "date" => @date
    }

    message =
      Response.message(:hearing_details, params) <>
        " " <> Response.message(:prompt_reminder, params)

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
