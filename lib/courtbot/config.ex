defmodule Courtbot.Config do
  use GenServer

  @moduledoc false

  require Logger

  alias Courtbot.{
    Application,
    Configuration
  }

  alias Courtbot.Configuration.{
    Rollbar,
    Twilio
  }

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
    load_configuration(1_000)

    {:noreply, state}
  end

  @impl true
  def handle_info(:load_configuration, state) do
    # Configure rollbar
    with %{rollbar: %Rollbar{environment: environment, access_token: token}} when token != nil <-
           Configuration.get([:rollbar]) do
      opts = [
        access_token: token,
        environment: environment
      ]

      Logger.info("Configuring Rollbar")

      case Logger.configure_backend({Courtbot.Rollbar, :rollbar}, opts) do
        :ok -> Logger.info("Rollbar configured")
        {:error, _message} -> Logger.error("Failed to configure rollbar")
      end
    else
      %{rollbar: nil} -> Logger.warn("Rollbar is not configured")
      %{rollbar: %Rollbar{access_token: nil}} -> Logger.warn("Rollbar access_token is not set")
    end

    # If we have tasks and a timezone set then start out tasks.
    with %{scheduled: %{tasks: scheduled}, timezone: timezone} <-
           Configuration.get([:scheduled, :timezone]) do
      Enum.map(scheduled, fn task = %{crontab: _crontab, name: name} ->
        Application.start_scheduled_task(task, name, timezone)
      end)
    else
      %{scheduled: nil, timezone: _} ->
        Logger.error("Unable to start scheduled tasks. No tasks configured.")

      %{scheduled: _, timezone: nil} ->
        Logger.error("Unable to start scheduled tasks. Timezone is not configured.")
    end

    # If we have twilio creds attempt to set usage alerts
    with %{twilio: %Twilio{account_sid: account_sid, auth_token: auth_token}}
         when account_sid != nil and auth_token != nil <- Configuration.get([:twilio]) do
      Logger.info("Creating Twilio Usage Alerts")
      twilio = TwilioApi.new(%{account_sid: account_sid, auth_token: auth_token})
      TwilioApi.create_usage_triggers(twilio)
    end

    {:noreply, state}
  end

  defp load_configuration(interval) do
    Process.send_after(self(), :load_configuration, interval)
  end
end
