defmodule CourtbotTest.Integrations.TwilioTest do
  use ExUnit.Case, async: false

  alias Courtbot.Integrations.Twilio

  setup_all do
    Tesla.Mock.mock_global(fn
      %{method: :post} ->
        %Tesla.Env{status: 201}
    end)

    :ok
  end

  test "twilio integration credentials are replaced" do
    twilio = Twilio.new(%{account_sid: "test", auth_token: "test"})

    assert twilio.pre === [
             {Tesla.Middleware.BaseUrl, :call,
              ["https://api.twilio.com/2010-04-01/Accounts/test"]},
             {Tesla.Middleware.BasicAuth, :call, [%{password: "test", username: "test"}]}
           ]
  end

  test "check twilio integration" do
    {status, _result} =
      Twilio.new(%{account_sid: "test", auth_token: "test"})
      |> Twilio.message(%{To: "+15005550006", From: "+15005550006", Body: "test"})

    assert status === :ok
  end
end
