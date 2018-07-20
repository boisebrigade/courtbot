defmodule ExCourtbotWeb.Twiml do
  import ExTwiml

  def sms(message) do
    twiml do
      sms(message)
    end
  end
end
