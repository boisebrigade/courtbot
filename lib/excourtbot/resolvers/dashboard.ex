defmodule ExCourtbot.Resolver.Dashboard do
  alias ExCourtbot.{Repo, Configuration}

  import Ecto.Query


  def get(_, _, _) do

    Repo.all(Configuration.get_conf(["rollbar_token", "twilio_sid", "twilio_token", "import_kind", "import_origin", "import_source"]))
    |> IO.inspect
    {:ok, %{}}
  end

#  def get(_, _, _context) do
#    {:error, "Requires authentication"}
#  end
end
