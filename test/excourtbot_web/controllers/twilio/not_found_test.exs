 defmodule ExCourtbotWeb.TwilioNotFoundTest do
  use ExCourtbotWeb.ConnCase, async: true

  alias Ecto.Multi

  alias ExCourtbot.Repo
  alias ExCourtbotWeb.{Case, Hearing, Subscriber}

  @phone_number "2025550186"
  @case_number "aabbc000000000000"

  test "you can subscribe to a case via sms", %{conn: conn} do
    initial_conn = post(conn, "/sms", %{"From" => @phone_number, "Body" => @case_number})
  end
 end
