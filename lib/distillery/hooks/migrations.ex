defmodule Distillery.Hooks.Migrations do
  alias Distillery.{Services, Database}

  def run() do
    Services.start_services()

    Database.run_migrations()

    Services.stop_services()
  end
end
