defmodule ExCourtbotWeb.Router do
  use ExCourtbotWeb, :router

  pipeline :twilio do
    plug(:fetch_session)
    plug(:accepts, ["json"])
  end

  pipeline :api do
    plug(Guardian.Plug.VerifyHeader, realm: "Bearer")
    plug(Guardian.Plug.LoadResource)
    plug(ExCourtbotWeb.Context)
  end

  scope "/", ExCourtbotWeb do
    pipe_through(:twilio)

    post("/sms", TwilioController, :sms)
    post("/sms/:locale", TwilioController, :sms)
  end

  scope "/graphiql" do
    forward("/", Absinthe.Plug.GraphiQL, schema: ExCourtbot.Schema, interface: :playground)
  end

  scope "/graphql" do
    pipe_through(:api)

    forward("/", Absinthe.Plug, schema: ExCourtbot.Schema)
  end

  scope "/", ExCourtbotWeb do
    forward("/", StaticPlug)
  end
end
