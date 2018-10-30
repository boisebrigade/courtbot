defmodule ExCourtbot.Resolver.Configuration do
  alias ExCourtbot.{Repo, Configuration}

  require Logger

  def get(_, _, %{context: %{current_user: _user}}) do
    config =
      Configuration.get([
        "rollbar_token",
        "twilio_sid",
        "twilio_token",
        "import_time",
        "notification_time",
        "timezone",
        "court_url"
      ])

    {:ok, config}
  end

  def get(_, _, _) do
    {:error, "Requires authentication"}
  end

  def edit(
        %{
          twilio_sid: twilio_sid,
          twilio_token: twilio_token,
          rollbar_token: rollbar_token,
          import_time: import_time,
          notification_time: notification_time,
          timezone: timezone,
          court_url: court_url
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
      },
      %{
        name: "import_time",
        value: import_time,
        updated_at: Timex.now(),
        inserted_at: Timex.now()
      },
      %{
        name: "notification_time",
        value: notification_time,
        updated_at: Timex.now(),
        inserted_at: Timex.now()
      },
      %{
        name: "timezone",
        value: timezone,
        updated_at: Timex.now(),
        inserted_at: Timex.now()
      },
      %{
        name: "court_url",
        value: timezone,
        updated_at: Timex.now(),
        inserted_at: Timex.now()
      }
    ]

    Repo.insert_all(Configuration, conf, on_conflict: :replace_all, conflict_target: :name)

    # Stop the existing applications
    Enum.map([:rollbax, :ex_twilio], fn app -> Application.stop(app) end)

    # Set the updated account information.
    Application.put_env(:ex_twilio, :account_sid, twilio_sid)
    Application.put_env(:ex_twilio, :auth_token, twilio_token)
    Application.put_env(:rollbax, :access_token, rollbar_token)

    # Start the applications again, this time with the updated configuration.
    case Application.ensure_all_started(:rollbax) do
      {:ok, _} -> Logger.info("Restarted Rollbax and ExTwilio")
      {:error, _} ->
        # TODO(ts): Throw GQL error
        Logger.error("Unable to restart Rollbax and or ExTwilio")
    end


  case Application.ensure_all_started(:ex_twilio) do
    {:ok, _} -> Logger.info("Restarted Rollbax and ExTwilio")
    {:error, _} ->
      # TODO(ts): Throw GQL error
      Logger.error("Unable to restart Rollbax and or ExTwilio")
  end

    {:ok,
     %{
       twilio_sid: twilio_sid,
       twilio_token: twilio_token,
       rollbar_token: rollbar_token,
       import_time: import_time,
       notification_time: notification_time,
       timezone: timezone,
       court_url: court_url
     }}
  end
end
