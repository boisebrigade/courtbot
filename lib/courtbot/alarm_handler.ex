defmodule Courtbot.AlarmHandler do
  require Logger

  def init({:ok, {:alarm_handler, _old_alarms}}) do
    Logger.info("Set Alarm Handler")

    {:ok, %{}}
  end

  def handle_event({:set_alarm, {:usage_alert, alarm}}, alarms) do
    Logger.warn(
      "Usage alert alarm for #{alarm[:time_period]} with a threshold limit of #{alarm[:trigger_value]} sms messages has been triggered. Currently #{alarm[:current_value]} sms messages have been sent."
    )

    {:ok, alarms}
  end

  def handle_event(event, state) do
    Logger.warn("Unhandled alarm event: #{inspect(event)}")

    {:ok, state}
  end
end
