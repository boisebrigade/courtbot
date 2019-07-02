defmodule Courtbot.Application do
  use Application

  alias Courtbot.Configuration

  alias Courtbot.Configuration.{
    Twilio,
    Scheduled
  }

  require Logger

  def start(_type, _args) do
    :gen_event.swap_handler(:alarm_handler, {:alarm_handler, :swap}, {Courtbot.AlarmHandler, :ok})

    # Define workers and child supervisors to be supervised
    children = [
      CourtbotWeb.Endpoint,
      Courtbot.Repo,
      {DynamicSupervisor, name: ConfigSupervisor, strategy: :one_for_one},
      # Load and start processes based upon configuration
      Courtbot.Config,
      # Helper to wipe sessions at a given interval
      Courtbot.ClearSessions,
      # In memory cache for checking if an event has already occurred
      Courtbot.Idempotent
    ]

    Courtbot.Workflow.telemetry()

    opts = [strategy: :one_for_one, name: Courtbot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CourtbotWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def start_scheduled_task(task, name, timezone) when name === "import" do
    Logger.info("Attempting to scheduling task #{name}")

    case DynamicSupervisor.start_child(
           ConfigSupervisor,
           child_spec_for_scheduled_task(task, timezone)
         ) do
      {:ok, _} ->
        Logger.info("Sucessfully scheduled #{name} task")

      {:error, _} ->
        Logger.error("Failed to schedule #{name} task")
    end
  end

  def start_scheduled_task(task, name, timezone) when name === "notify" do
    with %{twilio: %Twilio{account_sid: account_sid, auth_token: auth_token}, locales: locales}
         when account_sid != nil and auth_token != nil <- Configuration.get([:twilio, :locales]) do
      case DynamicSupervisor.start_child(
             ConfigSupervisor,
             child_spec_for_scheduled_task(task, timezone)
           ) do
        {:ok, _} ->
          Logger.info("Successfully scheduled #{name} task")

        {:error, _message} ->
          Logger.error("Failed to schedule #{name} task")
      end
    else
      %{twilio: %Twilio{account_sid: nil, auth_token: nil}, locales: _} ->
        Logger.error("Failed to schedule task #{name} as twilio credentials have not been set")

      %{twilio: _, locales: nil} ->
        Logger.error("Failed to schedule task #{name} as locales have not been set")

      %{twilio: nil, locales: nil} ->
        Logger.error(
          "Failed to schedule task #{name} as locales and twilio credentials have not been set"
        )
    end
  end

  def start_scheduled_task(task, name, timezone),
    do: Logger.error("Unsupported scheduled task: #{name}")

  defp mfa_for_task(type, crontab, timezone) when type === "notify",
    do: [&Courtbot.Notify.run/0, crontab, [timezone: timezone]]

  defp mfa_for_task(type, crontab, timezone) when type === "import",
    do: [&Courtbot.Import.run/0, crontab, [timezone: timezone]]

  defp child_spec_for_scheduled_task(%Scheduled.Tasks{name: name, crontab: crontab}, timezone) do
    %{
      id: "scheduled-task-#{name}",
      start: {SchedEx, :run_every, mfa_for_task(name, crontab, timezone)}
    }
  end
end
