defmodule Distillery.Database do

  def create_migrations_table() do
    Ecto.Migration.SchemaMigration.ensure_schema_migrations_table!(Courtbot.Repo, nil)
  end

  def drop_database() do
    case Courtbot.Repo.__adapter__.storage_down(Courtbot.Repo.config) do
      :ok ->
        IO.puts("Database has been dropped")

      {:error, :already_down} ->
        IO.puts("Dtabase has already been dropped")

      {:error, term} when is_binary(term) ->
        raise "Database couldn't be dropped: #{term}"

      {:error, term} ->
        raise "Database couldn't be dropped: #{inspect(term)}"
    end
  end

  def create_database() do
    case Courtbot.Repo.__adapter__.storage_up(Courtbot.Repo.config) do
      :ok ->
        IO.puts("Database has been created")

      {:error, :already_up} ->
        IO.puts("Database has already been created")

      {:error, term} when is_binary(term) ->
        raise "Database couldn't be created: #{term}"

      {:error, term} ->
        raise "Database couldn't be created: #{inspect(term)}"
    end
  end


  def run_seeds() do
    # Run the seed script if it exists
    seed_script = priv_path_for(Courtbot.Repo, "seeds.exs")

    if File.exists?(seed_script) do
      IO.puts("Running seed script..")
      Code.eval_file(seed_script)
    end
  end

  def run_migrations do
    app = Keyword.get(Courtbot.Repo.config, :otp_app)
    IO.puts("Running migrations for #{app}")
    migrations_path = priv_path_for(Courtbot.Repo, "migrations")
    Ecto.Migrator.run(Courtbot.Repo, migrations_path, :up, all: true)
  end

  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config, :otp_app)

    repo_underscore =
      repo
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    priv_dir = "#{:code.priv_dir(app)}"

    Path.join([priv_dir, repo_underscore, filename])
  end
end
