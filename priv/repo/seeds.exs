alias Courtbot.{Case, Repo}

# Debug case. This case can be used to do a health check.
if Case.find_with([case_number: "BEEPBOOP"]) === nil && System.get_env("MIX_ENV") != "test" do
  %Case{
    case_number: "BEEPBOOP",
    formatted_case_number: "BEEPBOOP"
  } |> Repo.insert!
end

env = Application.get_env(:courtbot, :environment)

with {:ok, _} <- File.stat("priv/repo/#{env}.seeds.exs") do
   Code.require_file("#{env}.seeds.exs", "priv/repo")
end
