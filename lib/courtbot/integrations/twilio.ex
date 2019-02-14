defmodule Courtbot.Integrations.Twilio do
  use Tesla

  plug Tesla.Middleware.FormUrlencoded
  plug Tesla.Middleware.DecodeJson

  def new(%{account_sid: account_sid, auth_token: auth_token}) do
    Tesla.client [
      {Tesla.Middleware.BaseUrl, "https://api.twilio.com/2010-04-01/Accounts/#{account_sid}"},
      {Tesla.Middleware.BasicAuth, %{username: account_sid, password: auth_token}}
    ]
  end

  def message(client, opts) do
    post(client, "/Messages.json", opts)
  end
end
