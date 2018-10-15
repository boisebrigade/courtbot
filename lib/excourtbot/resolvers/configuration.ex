defmodule ExCourtbot.Resolver.Configuration do
  alias ExCourtbot.{Repo, Configuration}

  def get(_, _, %{context: %{current_user: _user}}) do
    config =
      Configuration.get([
        "rollbar_token",
        "twilio_sid",
        "twilio_token",
        "import_time",
        "notification_time"
      ])

    {:ok, config}
  end

  def get(_, _, _) do
    {:error, "Requires authentication"}
  end

  def edit(
        %{
          rollbar_token: rollbar_token,
          twilio_sid: twilio_sid,
          twilio_token: twilio_token
        },
        %{context: %{current_user: _user}}
      ) do
    # TODO(ts): Reduce duplication
    conf = [
      %{
        name: "twilio_sid",
        value: twilio_sid,
        updated_at: Timex.now(),
        inserted_at: Timex.now()
      },
      %{
        name: "twilio_token",
        value: twilio_token,
        updated_at: Timex.now(),
        inserted_at: Timex.now()
      },
      %{
        name: "rollbar_token",
        value: rollbar_token,
        updated_at: Timex.now(),
        inserted_at: Timex.now()
      }
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
