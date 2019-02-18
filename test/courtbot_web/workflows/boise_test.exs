defmodule CourtbotWeb.Workflow.BoiseTest do
  use CourtbotWeb.CaseHelper

  alias Courtbot.{Case, Repo}

  setup do
    Repo.insert(CourtbotTest.Helper.Configuration.boise())

    cases =
      %{
        valid:
          %Case{}
          |> Case.changeset(%{
            case_number: "CR01-16-00001",
            county: "county",
            type: "criminal",
            first_name: "John",
            last_name: "Doe",
            hearings: [
              %{time: ~T[09:00:00], date: Date.utc_today()}
            ]
          })
          |> Repo.insert!(),
        no_upcoming_hearings:
          %Case{}
          |> Case.changeset(%{
            case_number: "CR01-16-00002",
            county: "county",
            type: "criminal",
            first_name: "John",
            last_name: "Doe",
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
            first_name: "John",
            last_name: "Doe",
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
            first_name: "John",
            last_name: "Doe",
            hearings: [
              %{time: ~T[11:00:00], date: Date.utc_today()}
            ]
          })
          |> Repo.insert!(),
      }

    {:ok, cases}
  end

  test "send hi or help", %{valid: case_details}  do
    for_case case_details do
      new_conversation()
      |> text("hi")
      |> response("Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672")

      new_conversation()
      |> text("help")
      |> response("Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672")
    end
  end

  test "subscribe to case with county", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("We found a case for {first_name} {last_name} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?")
      |> text("yes")
      |> response("OK. We will text you a courtesy reminder the day before the hearing date. Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}")
    end
  end

  test "reject subscription to case with county", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("We found a case for {first_name} {last_name} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?")
      |> text("no")
      |> response("You said \"No\" so we won’t text you a reminder. Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}")
    end
  end

  test "send invalid response when asked about subscription to case with county", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("We found a case for {first_name} {last_name} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?")
      |> text("asdf")
      |> response("Sorry, I did not understand. Would you like a courtesy reminder a day before the hearing? Reply YES or NO")
    end
  end

  test "attempt to subscribe to case with county but have an invalid county", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("invalid")
      |> response("We did not find case {case_number} in that county. Please check your case number and county. Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672")
    end
  end

  test "attempt to subscribe to a case with county but have an invalid county with valid retry", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("invalid")
      |> response("We did not find case {case_number} in that county. Please check your case number and county. Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672")
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("We found a case for {first_name} {last_name} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?")
      |> text("yes")
      |> response("OK. We will text you a courtesy reminder the day before the hearing date. Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}")
    end
  end

  test "attempt to subscribe to a case with county but have an invalid county with invalid retry", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("invalid")
      |> response("We did not find case {case_number} in that county. Please check your case number and county. Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672")
      |> text("{county}")
      |> response("Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672")
    end
  end

  test "attempt to subscribe to a case you are already subscribed to", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("We found a case for {first_name} {last_name} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?")
      |> text("yes")
      |> response("OK. We will text you a courtesy reminder the day before the hearing date. Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}")

      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("You are already subscribed to this case. To unsubscribe to this case reply with DELETE.")
    end
  end

  test "delete subscription to a case you are already subscribed to", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("We found a case for {first_name} {last_name} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?")
      |> text("yes")
      |> response("OK. We will text you a courtesy reminder the day before the hearing date. Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}")

      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("You are already subscribed to this case. To unsubscribe to this case reply with DELETE.")

      new_conversation()
      |> text("delete {case_number}")
      |> response("OK. We will stop sending reminders for {case_number} in {county}. Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672")
    end
  end


  test "delete subscription when you have no subscriptions", %{valid: case_details} do
    for_case case_details do
      new_conversation()
      |> text("delete")
      |> response("You are not subscribed to any cases. We won't send you any reminders. Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672")
    end
  end

  test "attempt to subscribe to a case without any upcoming hearings", %{no_upcoming_hearings: case_details} do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("We did not find any upcoming hearings for {case_number} in that county. Please check your case number and county. Note that court schedules may change. You should always confirm your hearing date and time by going to https://mycourts.idaho.gov/")
    end
  end

  test "attempt to subscribe to a case with multiple counties", %{duplicate_case_number_a: case_details_a, duplicate_case_number_b: case_details_b} do
    for_case case_details_a do
      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("We found a case for {first_name} {last_name} in A County. The next hearing is on {date}, at 10:00 AM. Would you like a reminder a day before the next hearing date?")
    end

    for_case case_details_b do
      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("We found a case for {first_name} {last_name} in B County. The next hearing is on {date}, at 11:00 AM. Would you like a reminder a day before the next hearing date?")
    end
  end
end
