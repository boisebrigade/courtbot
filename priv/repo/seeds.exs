alias ExCourtbot.Repo
alias ExCourtbotWeb.{Case, Hearing, Subscriber}

if Mix.env == :dev do
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
    time: ~T[09:00:00.000],
    date: Ecto.Date.utc(),
    location: "County Courthouse",
    detail: "Crime"
  }

  Repo.insert! %Subscriber{
    id: "98caf3df-99e1-4b43-98d0-9eeb14057697",
    case_id: case_one_id,
    phone_number: "2025550134"
  }
end
