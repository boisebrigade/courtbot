defmodule CourtbotWeb.TwilioResubscribeTest do
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

  @hearing_id Ecto.UUID.generate()

  @subscriber_id Ecto.UUID.generate()

  @phone_number "2025550186"
  @case_number "aabbc000000000000"

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
    |> Multi.insert(:hearing, %Hearing{
      id: @hearing_id,
      case_id: @case_id,
      time: ~T[09:00:00],
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

    params = %{from: @phone_number, case_number: @case_number, locale: "en"}
    message = Response.message(:unsubscribe, params)

    assert unsubscribe_conn.resp_body === Twiml.sms(message)

    resubscribe_conn =
      post(unsubscribe_conn, "/sms", %{"From" => @phone_number, "Body" => "start"})

    params = %{from: @phone_number, case_number: @case_number, locale: "en"}
    message = Response.message(:resubscribe, params)

    assert resubscribe_conn.resp_body === Twiml.sms(message)
  end
end
