alias ExCourtbot.{User, Case, Hearing, Repo}

if Mix.env == :dev do
  case_one_id = "db638726-7912-496f-84a6-4a3aa869800c"

  Repo.insert! %User{
    id: "cc4c18ca-8d97-4557-8a1f-4ac88da2dba6",
    user_name: "admin",
    password_hash: "$2b$12$9Ch07l8XACmUPVszsWcNL.7LuOBgYk/LBeIOrAaRcu3W1xwgK5hRO",
    inserted_at: DateTime.utc_now,
    updated_at: DateTime.utc_now
  }

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
    time: ~T[09:00:00],
    date: Date.add(Date.utc_today(), 1),
    location: "County Courthouse",
    detail: "Crime"
  }
end
