defmodule CourtbotWeb.Workflow.BoiseTest do
  use CourtbotWeb.CaseHelper

  alias Courtbot.{Case, Repo}

  setup do
    Application.put_env(:courtbot, Courtbot, CourtbotTest.Helper.Configuration.boise())

    case_details =
      %Case{}
      |> Case.changeset(%{
        case_number: "abc000",
        county: "valid",
        first_name: "John",
        last_name: "Doe",
        hearings: [
          %{time: ~T[09:00:00], date: Date.utc_today()}
        ]
      })
      |> Repo.insert!()

    {:ok, case_details: case_details}
  end

  test "send hi or help", %{case_details: case_details} = _context do
    for_case case_details do
      new_conversation()
      |> text("hi")
      |> response("Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672")

      new_conversation()
      |> text("help")
      |> response("Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672")
    end
  end

  test "subscribe to case with county", %{case_details: case_details} = _context do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("We found a case for {first_name} {last_name} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?")
      |> text("yes")
      |> response("Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}")
    end
  end

  test "reject subscription to case with county", %{case_details: case_details} = _context do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("We found a case for {first_name} {last_name} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?")
      |> text("no")
      |> response("You said \"No\" so we won’t text you a reminder.")
    end
  end

  test "send invalid response when asked about subscription to case with county", %{case_details: case_details} = _context do
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

  test "attempt to subscribe to case with county but have an invalid county", %{case_details: case_details} = _context do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("invalid")
      |> response("We did not find case {case_number} in that county. Please check your case number and county. Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672")
    end
  end

  test "attempt to subscribe to a case with county but have an invalid county with valid retry", %{case_details: case_details} = _context do
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
      |> response("Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}")
    end
  end

  test "attempt to subscribe to a case with county but have an invalid county with invalid retry", %{case_details: case_details} = _context do
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

  test "attempt to subscribe to a case you are already subscribed to", %{case_details: case_details} = _context do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("We found a case for {first_name} {last_name} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?")
      |> text("yes")
      |> response("Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}")

      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("You are already subscribed to this case. To unsubscribe to this case reply with DELETE.")
    end
  end

  test "delete subscription to a case you are already subscribed to", %{case_details: case_details} = _context do
    for_case case_details do
      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("We found a case for {first_name} {last_name} in {county} County. The next hearing is on {date}, at {time}. Would you like a reminder a day before the next hearing date?")
      |> text("yes")
      |> response("Note that court schedules may change. You should always confirm your hearing date and time by going to {court_url}")

      new_conversation()
      |> text("{case_number}")
      |> response("Which county are you interested in?")
      |> text("{county}")
      |> response("You are already subscribed to this case. To unsubscribe to this case reply with DELETE.")

      new_conversation()
      |> text("delete {case_number}")
      |> response("Reply with a case number to sign up for a reminder. For example a case number looks like: CR01-18-22672")
    end
  end


end
