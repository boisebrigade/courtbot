defmodule Courtbot.Application do
  use Application

  alias Courtbot.Configuration.{
    Rollbar,
    Scheduled
  }

  require Logger

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children = [
      CourtbotWeb.Endpoint,
      Courtbot.Repo,
      {DynamicSupervisor, name: ConfigSupervisor, strategy: :one_for_one},
      Courtbot.Config
    ]

    opts = [strategy: :one_for_one, name: Courtbot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CourtbotWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def start_rollbar(rollbar) do
    with %Rollbar{environment: environment, access_token: token} when not is_nil(token) <- rollbar do
      opts = [
        api_endpoint: "https://api.rollbar.com/api/1/item/",
        access_token: token,
        environment: environment,
        enabled: true,
        custom: %{},
        proxy: nil
      ]

      case DynamicSupervisor.start_child(ConfigSupervisor, %{
             id: "rollbax",
             start: {Rollbax.Client, :start_link, [opts]}
           }) do
        {:ok, _} ->
          Logger.info("Starting Rollbax")

        {:error, _} ->
          Logger.error("Unable to start Rollbax")
      end
    end
  end

  def start_scheduled_tasks(scheduled, timezone) do
    with %Scheduled{tasks: tasks} when tasks != [] <- scheduled do
      tasks
      |> Enum.map(&child_spec_for_scheduled_task(&1, timezone))
      |> Enum.map(fn {name, childspec} ->
        Logger.info("Starting scheduled-task-#{name}")

        DynamicSupervisor.start_child(ConfigSupervisor, childspec)
      end)
    end
  end

  defp mfa_for_task(type) when type === "notify", do: [Courtbot.Notify, :run, []]
  defp mfa_for_task(type) when type === "import", do: [Courtbot.Import, :run, []]

  defp child_spec_for_scheduled_task(%Scheduled.Tasks{name: name, crontab: crontab}, timezone) do
    {name,
     %{
       id: "scheduled-task-#{name}",
       start: {SchedEx, :run_every, mfa_for_task(name) ++ [crontab] ++ [timezone: timezone]}
     }}
  end
end
