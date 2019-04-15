defmodule CourtbotWeb.Twiml do
  @moduledoc false
  import ExTwiml

  def sms(message) do
    twiml do
      sms(message)
    end
  end
end
