alias ExCourtbot.Repo
alias ExCourtbot.{Client, Hearing, Subscriber}

if Mix.env == :dev || Mix.env == :test do
  # Repo.insert! %Case{
  #   id: "9cd4e3fd-58ce-473b-b4ee-51c61f09393f",
  #   case_number: "CASE-NUM-0000",
  #   first_name: "Foo",
  #   last_name: "Bar",
  #   county: "Generic"
  # }

  # Repo.insert! %Hearing{
  #   id: "ba722747-3346-4001-8ca1-3fcdee5844f3",
  #   case_id: "cd4e3fd-58ce-473b-b4ee-51c61f09393f",
  #   type: "criminal",
  #   date: Date.add(Date.utc_today(), 1),
  #   time: ~T[10:00:00],
  #   location: "County Courthouse",
  #   detail: "Crime"
  # }

  # subscriber = %Subscriber{}
  # |> %Subscriber.create({
  #   case_id: "cd4e3fd-58ce-473b-b4ee-51c61f09393f",
  #   hearing_id: "ba722747-3346-4001-8ca1-3fcdee5844f3",
  #   phone_number: "202-555-0134"
  # })
  # |> Repo.insert!
end
