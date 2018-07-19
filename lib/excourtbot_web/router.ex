defmodule ExCourtbotWeb.Router do
  use ExCourtbotWeb, :router

  pipeline :twilio do
    plug(:fetch_session)
    plug(:accepts, ["json"])
  end

  scope "/", ExCourtbot do
    pipe_through(:twilio)

    post("/sms/:locale", TwilioController, :sms)
  end
end
