defmodule Distillery.Commands.Restore do
  @moduledoc false
  alias Courtbot.Import
  alias Distillery.Services

  def run() do
    Services.start_services()

    Import.restore_hearings()

    Services.stop_services()
  end
end
