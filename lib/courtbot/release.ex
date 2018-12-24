defmodule Courtbot.ReleaseTasks do
  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto,
    :ecto_sql,
    :timex
  ]

  @repo Courtbot.Repo

  def migrate() do
    start_services()

    run_migrations()

    stop_services()
  end

  def import() do
    start_services()

    Courtbot.import()

    stop_services()
  end

  def notify() do
    start_services()

    Courtbot.notify()

    stop_services()
  end

  def reset() do
    drop_database()
    create_database()

    start_services()

    create_migrations_table()
    run_migrations()

    stop_services()
  end

  defp create_migrations_table() do
    Ecto.Migration.SchemaMigration.ensure_schema_migrations_table!(@repo, nil)
  end

  defp drop_database() do
    case @repo.__adapter__.storage_down(@repo.config) do
      :ok -> IO.puts "Database has been dropped"
      {:error, :already_down} -> IO.puts "Dtabase has already been dropped"
      {:error, term} when is_binary(term) ->
        raise "Database couldn't be dropped: #{term}"
      {:error, term} ->
        raise "Database couldn't be dropped: #{inspect term}"
    end
  end

  defp create_database() do
    case @repo.__adapter__.storage_up(@repo.config) do
      :ok -> IO.puts "Database has been created"
      {:error, :already_up} -> IO.puts "Database has already been created"
      {:error, term} when is_binary(term) ->
        raise "Database couldn't be created: #{term}"
      {:error, term} ->
        raise "Database couldn't be created: #{inspect term}"
    end
  end

  defp start_services do
    IO.puts("Starting dependencies..")
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for app
    IO.puts("Starting repos..")

    @repo.start_link(pool_size: 2)
  end

  defp stop_services do
    IO.puts("Success!")
    :init.stop()
  end

  defp run_migrations do
    run_migrations_for(Courtbot.Repo)
  end

  defp run_migrations_for(repo) do
    app = Keyword.get(repo.config, :otp_app)
    IO.puts("Running migrations for #{app}")
    migrations_path = priv_path_for(repo, "migrations")
    Ecto.Migrator.run(repo, migrations_path, :up, all: true)
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
