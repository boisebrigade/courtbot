defmodule Courtbot.Application do
  use Application

  alias Courtbot.Configuration.{
    Scheduled,
    Scheduled.Tasks
  }

  require Logger

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children = [
      CourtbotWeb.Endpoint,
      Courtbot.Repo,
      {Registry, keys: :unique, name: DynamicRegistry},
      {DynamicSupervisor, name: Courtbot.Bootstrap, strategy: :one_for_one},
      Courtbot.ConfigMonitor
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

  def stop_scheduled_tasks(scheduled) do
    with %Scheduled{tasks: tasks} when tasks != [] <- scheduled do
      Enum.map(tasks, fn %Tasks{name: name} ->
        Logger.info("Stopping #{}  scheduled task")
        cancel_scheduled_item(name)
      end)
    end
  end

  def start_scheduled_tasks(scheduled) do
    with %Scheduled{tasks: tasks} when tasks != [] <- scheduled do
      tasks
      |> Enum.map(&child_spec_for_scheduled_task/1)
      |> Enum.map(fn {name, childspec} ->
        Logger.info("Starting #{name} scheduled task")

        DynamicSupervisor.start_child(Courtbot.Bootstrap, childspec)
      end)
    end
  end

  def get_scheduled_item(id) do
    list = Registry.lookup(RegistryName, id)

    if length(list) > 0 do
      {pid, _} = hd(list)
      {:ok, pid}
    else
      {:error, "does not exist"}
    end
  end

  def cancel_scheduled_item(id) do
    with {:ok, pid} <- get_scheduled_item(id) do
      DynamicSupervisor.terminate_child(Courtbot.Bootstrap, pid)
    end
  end

  defp mfa_for_task(type) when type === "notify", do: [Courtbot.Notify, :run, []]
  defp mfa_for_task(type) when type === "import", do: [Courtbot.Import, :run, []]

  defp child_spec_for_scheduled_task(%Scheduled.Tasks{name: name, crontab: crontab}) do
    {name, %{id: "scheduled-task-#{name}", start: {SchedEx, :run_every, mfa_for_task(name) ++ [crontab, [name: {:via, Registry, {DynamicRegistry, "scheduled-task-#{name}"}}]]}}}
  end
end
