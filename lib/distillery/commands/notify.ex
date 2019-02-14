defmodule Distillery.Commands.Notify do
  alias Courtbot.Notify
  alias Distillery.Services

  def run() do
    Services.start_services()

    Notify.run()

    Services.stop_services()
  end
end
