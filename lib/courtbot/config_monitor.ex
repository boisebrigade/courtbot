defmodule Courtbot.ConfigMonitor do
  use GenServer

  @moduledoc false

  alias Courtbot.{
    Application,
    Configuration
  }

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(_) do
    {:ok, %{}, {:continue, :init}}
  end

  @impl true
  def handle_continue(:init, state) do
    schedule_check(1_000)
    {:noreply, state}
  end

  @impl true
  def handle_info(:check, state) do

    config = with config when not is_nil(config) <- Configuration.get([:scheduled, :rollbar]) do
      if Map.equal?(state, config) do
        schedule_check(60_000)

        {:noreply, config}

      else
        schedule_check(60_000)

        %{scheduled: scheduled} = config

        with %{scheduled: previous_scheduled} <- state do
          Application.stop_scheduled_tasks(previous_scheduled)
        end

        Application.start_scheduled_tasks(scheduled)
      end

      config
    end

    {:noreply, config}
  end

  defp schedule_check(interval) do
    Process.send_after(self(), :check, interval)
  end
end
