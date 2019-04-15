defmodule Distillery.Commands.Reset do
  @moduledoc false
  alias Distillery.{Services, Database}

  def run() do
    Database.drop_database()
    Database.create_database()

    Services.start_services()

    Database.create_migrations_table()
    Database.run_migrations()

    Services.stop_services()
  end
end
