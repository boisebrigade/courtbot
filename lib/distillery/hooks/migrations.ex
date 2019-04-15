defmodule Distillery.Hooks.Migrations do
  @moduledoc false
  alias Distillery.{Services, Database}

  def run() do
    Services.start_services()

    Database.run_migrations()

    Services.stop_services()
  end
end
