defmodule Courtbot.ClearSessions do
  use GenServer

  @moduledoc false

  require Logger

  alias Courtbot.{
    Repo,
    Sessions
  }

  alias Courtbot.Configuration.{
    Rollbar,
    Twilio
  }

  import Ecto.Query

  alias Courtbot.Integrations.Twilio, as: TwilioApi

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(_) do
    {:ok, %{}, {:continue, :init}}
  end

  @impl true
  def handle_continue(:init, state) do
    clear_session(1_000)

    {:noreply, state}
  end

  @impl true
  def handle_info(:clear, state) do
    Repo.delete_all(from(s in Sessions, where: s.expires_at <= ^NaiveDateTime.utc_now()))

    clear_session(60_000)

    {:noreply, state}
  end

  defp clear_session(interval) do
    Process.send_after(self(), :clear, interval)
  end
end
