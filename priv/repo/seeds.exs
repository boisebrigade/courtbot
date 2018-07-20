alias ExCourtbot.Repo
alias ExCourtbotWeb.{Case, Hearing, Subscriber}

#if Mix.env == :dev do
  case_one_id = "db638726-7912-496f-84a6-4a3aa869800c"

  Repo.insert! %Case{
    id: case_one_id,
    case_number: "abc123",
    first_name: "Foo",
    last_name: "Bar",
    county: "Generic"
  }

  Repo.insert! %Hearing{
    id: "299992b7-8b40-4896-b45c-c941aec1b155",
    case_id: case_one_id,
    type: "criminal",
    time: ~T[09:00:00],
    date: Date.add(Date.utc_today(), 1),
    location: "County Courthouse",
    detail: "Crime"
  }

#end
