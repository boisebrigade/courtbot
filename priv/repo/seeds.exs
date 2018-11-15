alias Courtbot.{Case, Repo}

# Debug case. This case can be used to do a health check.
%Case{
  case_number: "BEEPBOOP",
  formatted_case_number: "BEEPBOOP"
} |> Repo.insert!
