defmodule CourtbotWeb.TwilioTypesTest do
  use CourtbotWeb.ConnCase, async: true

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

  @phone_number "2025550186"
  @case_doesnt_exist_number "aabbc000000000000"

  @locale "en"

  setup do
    Application.put_env(:courtbot, Courtbot, @import_config)
  end

  test "you get a reponse if the case number is invaild", %{conn: conn} do
    initial_conn =
      post(conn, "/sms", %{"From" => @phone_number, "Body" => @case_doesnt_exist_number})

    assert initial_conn.status === 200

    params = %{"From" => @phone_number, "Body" => @case_doesnt_exist_number, "locale" => @locale}
    message = Response.message(:not_found, params)

    assert initial_conn.resp_body === Twiml.sms(message)
  end
end
