defmodule Courtbot.Integrations.Twilio do
  use Tesla

  plug(Tesla.Middleware.FormUrlencoded)
  plug(Tesla.Middleware.DecodeJson)

  plug(Tesla.Middleware.Logger)

  alias Courtbot.Configuration
  alias Courtbot.Integrations.Twilio

  require Logger

  def new(%{account_sid: account_sid, auth_token: auth_token}) do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, "https://api.twilio.com/2010-04-01/Accounts/#{account_sid}"},
      {Tesla.Middleware.BasicAuth, %{username: account_sid, password: auth_token}}
    ])
  end

  def send_message(client, opts) do
    post(client, "/Messages.json", opts)
  end

  def create_usage_triggers(client) do
    # Delete our existing triggers
    Twilio.delete_usage_triggers(client)

    # Check if we have usage_alert configuration
    with %{hostname: hostname, usage_alerts: usage_alerts} <-
           Configuration.get([:hostname, :usage_alerts]) do
      # Iterate over all our usage alerts
      Enum.map(usage_alerts, fn %{amount: amount, recurring: recurring} ->
        usage_trigger_opts = %{
          "TriggerValue" => amount,
          "UsageCategory" => "sms",
          "FriendlyName" => "Courtbot Usage Status Alert #{amount} #{recurring}",
          "Recurring" => recurring,
          "CallbackUrl" => "#{hostname}/usage"
        }

        post(client, "/Usage/Triggers.json", usage_trigger_opts)
      end)
    else
      _ ->
        Logger.warn("No hostname or alert amount set. Not configuring usage alerting")
        %{}
    end
  end

  def list_usage_triggers(client), do: get(client, "/Usage/Triggers.json")

  def delete_usage_trigger(client, sid), do: delete(client, "/Usage/Triggers/#{sid}.json")

  def delete_usage_triggers(client) do
    # List our current usage triggers
    case Twilio.list_usage_triggers(client) do
      {:ok, %Tesla.Env{status: 200, body: %{"usage_triggers" => usage_triggers}}} ->
        Enum.each(usage_triggers, fn %{"friendly_name" => name, "sid" => sid} ->
          if String.contains?(name, "Courtbot Usage Status Alert") do
            Twilio.delete_usage_trigger(client, sid)
          end
        end)

      {:error, _} ->
        Logger.error(
          "Unable to fetch usage triggers while attempting to delete Courtbot's existing triggers"
        )
    end
  end
end
