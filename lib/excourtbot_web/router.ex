defmodule ExCourtbotWeb.Router do
  use ExCourtbotWeb, :router

  pipeline :twilio do
    plug(:fetch_session)
    plug(:accepts, ["json"])
  end

  scope "/", ExCourtbotWeb do
    pipe_through(:twilio)

    post("/sms", TwilioController, :sms)
    post("/sms/:locale", TwilioController, :sms)
  end

  scope "/", ExCourtbotWeb do
    forward("/", StaticPlug)
  end
end
