defmodule Distillery.Commands.Import do
  @moduledoc false
  alias Courtbot.Import
  alias Distillery.Services

  def run() do
    Services.start_services()

    Import.run()

    Services.stop_services()
  end
end
