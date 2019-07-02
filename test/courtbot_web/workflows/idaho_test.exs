defmodule CourtbotWeb.Workflow.IdahoTest do
  use CourtbotTest.Helper.Case
  use ExUnitProperties

  alias Courtbot.{Case, Repo}

  setup do
    Repo.insert(CourtbotTest.Helper.Configuration.idaho())

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
      no_upcoming_hearings:
        %Case{}
        |> Case.changeset(%{
          case_number: "CR01-16-00002",
          county: "A",
          type: "criminal",
          parties: [
            %{case_name: "Joe Doe vs Idaho"}
          ],
          hearings: [
            %{time: ~T[09:00:00], date: Date.add(Date.utc_today(), -1)}
          ]
        })
        |> Repo.insert!(),
      duplicate_case_number_a:
        %Case{}
        |> Case.changeset(%{
          case_number: "CR01-16-00003",
          county: "A",
          type: "criminal",
          parties: [
            %{case_name: "Joe Doe vs Idaho"}
          ],
          hearings: [
            %{time: ~T[10:00:00], date: Date.utc_today()}
          ]
        })
        |> Repo.insert!(),
      duplicate_case_number_b:
        %Case{}
        |> Case.changeset(%{
          case_number: "CR01-16-00003",
          county: "B",
          type: "criminal",
          parties: [
            %{case_name: "Joe Doe vs Idaho"}
          ],
          hearings: [
            %{time: ~T[11:00:00], date: Date.utc_today()}
          ]
        })
        |> Repo.insert!()
    }

    {:ok, cases}
  end

  @tag :skip
  property "check that arbitrary data will yield a sane response", %{valid: case_details} do
    check all input <- StreamData.binary() do
      try do
        for_case case_details do
          new_conversation()
          |> text(input)
          |> response(
            "Reply with a case number to sign up for reminders. For example: CR00-19-00011"
          )
        end
      rescue
        _e in Plug.Conn.CookieOverflowError -> assert String.length(input) > 4000
      end
    end
  end

  test "send hi or help", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("hi")
      |> response("Reply with a case number to sign up for reminders. For example: CR00-19-00011")

      new_conversation()
      |> text("help")
      |> response("Reply with a case number to sign up for reminders. For example: CR00-19-00011")
    end
  end

  test "subscribe to case with county", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?"
      )
      |> text("yes")
      |> response(
        "OK. We will text you a courtesy reminder the day before the hearing date. Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}."
      )
    end
  end

  test "reject subscription to case with county", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?"
      )
      |> text("no")
      |> response(
        "You said \"No\" so we won’t text you a reminder. You should always confirm your hearing date and time by going to {court_url}."
      )
    end
  end

  test "send invalid response when asked about subscription to case with county", %{
    valid: case_details
  } do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?"
      )
      |> text("asdf")
      |> response(
        "Sorry, I did not understand. Would you like a courtesy reminder a day before the hearing? Reply YES or NO"
      )
    end
  end

  test "attempt to subscribe to case with county but have an invalid county", %{
    valid: case_details
  } do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("invalid")
      |> response(
        "We did not find case {case_number} in that county. Please check your case number and county. Reply with a case number to sign up for reminders. For example: CR00-19-00011"
      )
    end
  end

  test "send start and receive you are not subscribed to any cases", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("start")
      |> response(
        "You are not subscribed to any cases. Reply with a case number to sign up for reminders. For example: CR00-19-00011"
      )
    end
  end

  test "send start when you are subscribed you should get reply with case number", %{
    valid: case_details
  } do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?"
      )
      |> text("yes")

      new_conversation()
      |> text("start")
      |> response("Reply with a case number to sign up for reminders. For example: CR00-19-00011")
    end
  end

  test "attempt to subscribe to a case with county but have an invalid county with valid retry",
       %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("invalid")
      |> response(
        "We did not find case {case_number} in that county. Please check your case number and county. Reply with a case number to sign up for reminders. For example: CR00-19-00011"
      )
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?"
      )
      |> text("yes")
      |> response(
        "OK. We will text you a courtesy reminder the day before the hearing date. Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}."
      )
    end
  end

  test "attempt to subscribe to a case with county but have an invalid county with invalid retry",
       %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("invalid")
      |> response(
        "We did not find case {case_number} in that county. Please check your case number and county. Reply with a case number to sign up for reminders. For example: CR00-19-00011"
      )
      |> text("{county}")
      |> response("Reply with a case number to sign up for reminders. For example: CR00-19-00011")
    end
  end

  test "attempt to subscribe to a case you are already subscribed to", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?"
      )
      |> text("yes")
      |> response(
        "OK. We will text you a courtesy reminder the day before the hearing date. Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}."
      )

      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "You are already subscribed to this case. To stop getting reminders reply with DELETE."
      )
    end
  end

  test "delete subscription to a case you are already subscribed to", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?"
      )
      |> text("yes")
      |> response(
        "OK. We will text you a courtesy reminder the day before the hearing date. Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}."
      )

      new_conversation()
      |> text("delete {case_number}")
      |> response("Are you sure you want to stop getting reminders for {cases}?")
      |> text("yes")
      |> response(
        "OK. We will stop sending reminders. Reply with a case number to sign up for a reminder. For example: CR00-19-00011"
      )
    end
  end

  test "reject delete subscription", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?"
      )
      |> text("yes")
      |> response(
        "OK. We will text you a courtesy reminder the day before the hearing date. Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}."
      )

      new_conversation()
      |> text("delete {case_number}")
      |> response("Are you sure you want to stop getting reminders for {cases}?")
      |> text("no")
      |> response("OK. You said \"No\" so we will still send you reminders.")
    end
  end

  test "send gibberish when deleting subscription", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?"
      )
      |> text("yes")
      |> response(
        "OK. We will text you a courtesy reminder the day before the hearing date. Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}."
      )

      new_conversation()
      |> text("delete {case_number}")
      |> response("Are you sure you want to stop getting reminders for {cases}?")
      |> text("asdf")
      |> response(
        "Sorry, I did not understand. Do you want to stop getting reminders for {cases}? Reply YES or NO"
      )
      |> text("yes")
      |> response(
        "OK. We will stop sending reminders. Reply with a case number to sign up for a reminder. For example: CR00-19-00011"
      )
    end
  end

  test "delete subscription when you have no subscriptions", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("delete")
      |> response(
        "You are not subscribed to any cases. We won't send you any reminders. Reply with a case number to sign up for a reminder. For example: CR00-19-00011"
      )
    end
  end

  test "delete all subscriptions when you have subscriptions", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?"
      )
      |> text("yes")
      |> response(
        "OK. We will text you a courtesy reminder the day before the hearing date. Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}."
      )

      new_conversation()
      |> text("delete")
      |> response("Are you sure you want to stop getting reminders for {cases}?")
      |> text("yes")
      |> response(
        "OK. We will stop sending reminders. Reply with a case number to sign up for a reminder. For example: CR00-19-00011"
      )
    end
  end

  test "reject deleting all subscriptions when you have subscriptions", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?"
      )
      |> text("yes")
      |> response(
        "OK. We will text you a courtesy reminder the day before the hearing date. Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}."
      )

      new_conversation()
      |> text("delete")
      |> response("Are you sure you want to stop getting reminders for {cases}?")
      |> text("no")
      |> response("OK. You said \"No\" so we will still send you reminders.")
    end
  end

  test "check that case sensitivity is not an issue when deleting ", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?"
      )
      |> text("yes")
      |> response(
        "OK. We will text you a courtesy reminder the day before the hearing date. Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}."
      )

      new_conversation()
      |> text("Delete")
      |> response("Are you sure you want to stop getting reminders for {cases}?")
      |> text("no")
      |> response("OK. You said \"No\" so we will still send you reminders.")
    end
  end

  test "respond with gibberish when deleting all subscriptions when you have subscriptions", %{
    valid: case_details
  } do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?"
      )
      |> text("yes")
      |> response(
        "OK. We will text you a courtesy reminder the day before the hearing date. Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}."
      )

      new_conversation()
      |> text("delete")
      |> response("Are you sure you want to stop getting reminders for {cases}?")
      |> text("asdf")
      |> response(
        "Sorry, I did not understand. Do you want to stop getting reminders for {cases}? Reply YES or NO"
      )
      |> text("yes")
      |> response(
        "OK. We will stop sending reminders. Reply with a case number to sign up for a reminder. For example: CR00-19-00011"
      )
    end
  end

  test "attempt to subscribe to a case without any upcoming hearings", %{
    no_upcoming_hearings: case_details
  } do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in {county} County. We do not see any future hearings scheduled. You should always confirm your hearing date and time by going to {court_url}. Would you like to be notified when a hearing is scheduled?"
      )
      |> text("yes")
      |> response(
        "OK. We will text you when a hearing is scheduled for case {cases}. Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}."
      )
    end
  end

  test "reject attempt to subscribe to a case without any upcoming hearings", %{
    no_upcoming_hearings: case_details
  } do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in {county} County. We do not see any future hearings scheduled. You should always confirm your hearing date and time by going to {court_url}. Would you like to be notified when a hearing is scheduled?"
      )
      |> text("no")
      |> response(
        "You said \"No\" so we won’t text you a reminder. You should always confirm your hearing date and time by going to {court_url}."
      )
    end
  end

  test "respond with gibberish while attempting to subscribe to a case without any upcoming hearings",
       %{no_upcoming_hearings: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in {county} County. We do not see any future hearings scheduled. You should always confirm your hearing date and time by going to {court_url}. Would you like to be notified when a hearing is scheduled?"
      )
      |> text("asdf")
      |> response(
        "Sorry, I did not understand. Would you like to be notified when a hearing is scheduled? Reply YES or NO"
      )
    end
  end

  test "attempt to subscribe to a case with multiple counties", %{
    duplicate_case_number_a: case_details_a,
    duplicate_case_number_b: case_details_b
  } do
    for_case case_details_a do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in A County. The next hearing is on {date}, at 10:00 AM. Would you like a reminder a day before the next hearing date?"
      )
    end

    # Wipe sessions so we don't have a conflict
    Repo.delete_all(Courtbot.Sessions)

    for_case case_details_b do
      new_conversation()
      |> text("{case_number}")
      |> response("We need more information to find your case. Which county is this case in?")
      |> text("{county}")
      |> response(
        "We found a case for {parties} in B County. The next hearing is on {date}, at 11:00 AM. Would you like a reminder a day before the next hearing date?"
      )
    end
  end
end
