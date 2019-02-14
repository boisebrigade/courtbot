defmodule Distillery.Services do
  @start_apps [
    :crypto,
    :ssl,
    :postgrex,
    :ecto,
    :ecto_sql,
    :timex
  ]

  def start_services do
    IO.puts("Starting dependencies..")
    # Start apps necessary for executing migrations
    Enum.each(@start_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for app
    IO.puts("Starting repos..")

    Courtbot.Repo.start_link(pool_size: 2)
  end

  def stop_services do
    IO.puts("Success!")
    :init.stop()
  end
end
