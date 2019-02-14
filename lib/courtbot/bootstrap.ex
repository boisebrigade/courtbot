defmodule Courtbot.Bootstrap do
  use DynamicSupervisor

  alias Courtbot.{
    Configuration,
    Configuration.Rollbar,
    Configuration.Scheduled
  }

  def start_link(), do: DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)

  @impl true
  def init(_), do: DynamicSupervisor.init(strategy: :one_for_one)

  defp child_spec_for_rollbar(opts) do
    %{id: "rollbar", start: {Rollbax.Client, :start_link, opts}}
  end

  def start_rollbar() do
    with %{rollbar: %Rollbar{environment: environment, access_token: token}} <- Configuration.get([:rollbar]) do
      opts = [
        api_endpoint: "https://api.rollbar.com/api/1/item/",
        access_token: token,
        environment: environment,
        enabled: true,
        custom: %{},
        proxy: nil
      ]

      DynamicSupervisor.start_child(__MODULE__, child_spec_for_rollbar(opts))
    end
  end

  def start_scheduled_tasks() do
    with %{scheduled: %Scheduled{task: tasks}} <- Configuration.get([:scheduled]) do
      tasks
      |> Enum.map(&child_spec_for_scheduled_task/1)
      |> Enum.map(&(DynamicSupervisor.start_child(__MODULE__, &1)))
    end
  end

  defp mfa_for_task(type) when type === "notify", do: [Courtbot.Notify, :run, []]
  defp mfa_for_task(type) when type === "import", do: [Courtbot.Import, :run, []]

  defp child_spec_for_scheduled_task(%Scheduled.Task{name: name, crontab: crontab}) do
    %{id: "scheduled-task-#{name}", start: {SchedEx, :run_every, mfa_for_task(name) ++ [crontab]}}
  end
end
