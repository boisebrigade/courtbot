defmodule CourtbotWeb.Controller.SmsTest do
  use CourtbotTest.Helper.Case
  use ExUnitProperties
  use Plug.Test

  alias Courtbot.{Case, Repo}

  setup do
    Repo.insert(CourtbotTest.Helper.Configuration.idaho())
    Repo.insert!(CourtbotTest.Helper.Case.debug_case())

    cases = %{
      valid:
        %Case{}
        |> Case.changeset(%{
          case_number: "CR01-16-00001",
          county: "A",
          type: "criminal",
          parties: [
            %{case_name: "Joe Doe vs Idaho"}
          ],
          hearings: [
            %{time: ~T[09:00:00], date: Date.utc_today()}
          ]
        })
        |> Repo.insert!(),
    }

    {:ok, cases}
  end

  test "simple inqueries should not modify session", %{valid: case_details} do
    for_case case_details do
      %Plug.Conn{private: %{plug_session: session}} =
        build_conn()
        |> text("hi")
        |> response("Reply with a case number to sign up for reminders. For example: CR00-19-00011")

      assert session == %{}, "Sending 'hi' should not affect a users session"
    end
  end

  test "sending a case number should modify your session", %{valid: case_details} do
    for_case case_details do
      %Plug.Conn{private: %{plug_session: %{"state" => state}}} =
        build_conn()
        |> text("{case_number}")

      assert state === :county, "Texting a case number should result in your workflow state being set to :county in your session"
    end
  end
end
