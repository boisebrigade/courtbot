defmodule ExCourtbot.Resolver.Configuration do
  alias ExCourtbot.{Repo, Configuration}

  import Ecto.Query

  def get(_, _, %{context: %{current_user: user}} = _context) do
    result =
      case Repo.all(Configuration.get_conf(["rollbar_token", "twilio_sid", "twilio_token"])) do
        [
          %{"twilio_sid" => twilio_sid},
          %{"twilio_token" => twilio_token},
          %{"rollbar_token" => rollbar_token}
        ] ->
          %{
            twilio_sid: twilio_sid,
            twilio_token: twilio_token,
            rollbar_token: rollbar_token
          }

        [] ->
          %{
            twilio_sid: "",
            twilio_token: "",
            rollbar_token: ""
          }
      end

    {:ok, result}
  end

  def get(_, _, _context) do
    {:error, "Requires authentication"}
  end

  def edit(
        %{rollbar_token: rollbar_token, twilio_sid: twilio_sid, twilio_token: twilio_token},
        %{context: %{current_user: user}}
      ) do
    conf = [
      %{name: "twilio_sid", value: twilio_sid, updated_at: Timex.now(), inserted_at: Timex.now()},
      %{name: "twilio_token", value: twilio_token, updated_at: Timex.now(), inserted_at: Timex.now()},
      %{name: "rollbar_token", value: rollbar_token, updated_at: Timex.now(), inserted_at: Timex.now()}
    ]

    Repo.insert_all(Configuration, conf, on_conflict: :replace_all, conflict_target: :name)

    {:ok,
     %{
       twilio_sid: twilio_sid,
       twilio_token: twilio_token,
       rollbar_token: rollbar_token
     }}
  end

  def edit(_, _) do
    {:error, "Requires authentication"}
  end
end
