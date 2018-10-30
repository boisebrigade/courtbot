alias ExCourtbot.{User, Repo}

if Mix.env == :dev do
  Repo.insert! %User{
    id: "cc4c18ca-8d97-4557-8a1f-4ac88da2dba6",
    user_name: "admin",
    password_hash: "$2b$12$9Ch07l8XACmUPVszsWcNL.7LuOBgYk/LBeIOrAaRcu3W1xwgK5hRO"
  }
end
