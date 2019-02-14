defmodule Distillery.Hooks.Seeders do
  alias Distillery.{Services, Database}

  def run() do
    Services.start_services()

    Database.run_seeds()

    Services.stop_services()
  end
end
