alias Courtbot.{Case, Repo}

# Debug case. This case can be used to do a health check.

if Case.find_by_case_number("BEEPBOOP") === [] do
  %Courtbot.Case{
    case_number: "BEEPBOOP",
    formatted_case_number: "BEEPBOOP"
  } |> Courtbot.Repo.insert!
end
