defmodule CourtbotWeb.TwilioUnsubscribeTest do
  use CourtbotWeb.ConnCase, async: true

  alias Ecto.Multi

  alias Courtbot.{Case, Hearing, Repo, Subscriber}
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
  @case_three_id Ecto.UUID.generate()

  @hearing_id Ecto.UUID.generate()
  @hearing_two_id Ecto.UUID.generate()

  @subscriber_id Ecto.UUID.generate()

  @phone_number "2025550186"
  @phone_number_invalid "2025550187"
  @case_number "aabbc000000000000"
  @case_number_two "aabbc000000000001"

  @unsubscribe "stop"

  @locale "en"

  setup do
    Application.put_env(:courtbot, Courtbot, @import_config)

    Multi.new()
    |> Multi.insert(:case, %Case{
      id: @case_id,
      case_number: @case_number,
      formatted_case_number: @case_number,
      county: "canyon"
    })
    |> Multi.insert(:case_two, %Case{
      id: @case_two_id,
      case_number: @case_number,
      formatted_case_number: @case_number,
      county: "gym"
    })
    |> Multi.insert(:case_three, %Case{
      id: @case_three_id,
      case_number: @case_number_two,
      formatted_case_number: @case_number_two
    })
    |> Multi.insert(:hearing, %Hearing{
      id: @hearing_id,
      case_id: @case_id,
      time: ~T[09:00:00],
      date: Date.utc_today()
    })
    |> Multi.insert(:hearing_two, %Hearing{
      id: @hearing_two_id,
      case_id: @case_id,
      time: ~T[11:00:00],
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
    |> Multi.insert(
      :subscriber_two,
      %Subscriber{}
      |> Subscriber.changeset(%{
        id: @subscriber_id,
        case_id: @case_three_id,
        locale: @locale,
        phone_number: @phone_number
      })
    )
    |> Repo.transaction()

    :ok
  end

  test "you can unsubscribe to all cases", %{conn: conn} do
    unsubscribe_conn = post(conn, "/sms", %{"From" => @phone_number, "Body" => @unsubscribe})

    assert unsubscribe_conn.status == 200

    params = %{from: @phone_number, case_number: @case_number, locale: "en"}
    message = Response.message(:unsubscribe, params)

    assert unsubscribe_conn.resp_body === Twiml.sms(message)
  end

  test "you are alerted if you are currently not subscribed", %{conn: conn} do
    unsubscribe_conn =
      post(conn, "/sms", %{"From" => @phone_number_invalid, "Body" => @unsubscribe})

    assert unsubscribe_conn.status == 200

    params = %{from: @phone_number, case_number: @case_number, locale: "en"}
    message = Response.message(:no_subscriptions, params)

    assert unsubscribe_conn.resp_body === Twiml.sms(message)
  end

  test "you can unsubscribe to a specific case", %{conn: conn} do
    unsubscribe_conn = post(conn, "/sms", %{"From" => @phone_number, "Body" => @case_number_two})

    assert unsubscribe_conn.status == 200

    params = %{from: @phone_number, case_number: @case_number, locale: "en"}
    message = Response.message(:already_subscribed, params)

    assert unsubscribe_conn.resp_body === Twiml.sms(message)

    delete_prompt_conn =
      post(unsubscribe_conn, "/sms", %{"From" => @phone_number, "Body" => "DELETE"})

    assert delete_prompt_conn.status == 200
  end

  test "you can unsubscribe to a specific case with multiple counties", %{conn: conn} do
    unsubscribe_conn = post(conn, "/sms", %{"From" => @phone_number, "Body" => @case_number})

    assert unsubscribe_conn.status == 200

    county_conn = post(unsubscribe_conn, "/sms", %{"From" => @phone_number, "Body" => "canyon"})

    assert county_conn.status == 200

    delete_prompt_conn = post(county_conn, "/sms", %{"From" => @phone_number, "Body" => "DELETE"})

    assert delete_prompt_conn.status == 200
  end
end
