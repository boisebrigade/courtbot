defmodule Courtbot.Config do
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
    load_configuration(1_000)

    {:noreply, state}
  end

  @impl true
  def handle_info(:load_configuration, state) do
    with %{rollbar: rollbar, scheduled: scheduled, timezone: timezone} <-
           Configuration.get([:scheduled, :rollbar, :timezone]) do
      Application.start_rollbar(rollbar)
      Application.start_scheduled_tasks(scheduled, timezone)
    end

    {:noreply, state}
  end

  defp load_configuration(interval) do
    Process.send_after(self(), :load_configuration, interval)
  end
end
