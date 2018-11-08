defmodule Courtbot.Mixfile do
  use Mix.Project

  def project do
    [
      app: :courtbot,
      version: "0.2.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Courtbot.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.4"},
      {:ecto, "~> 3.0", override: true},
      {:ecto_sql, "~> 3.0"},
      {:phoenix_ecto, "~> 4.0"},
      {:postgrex, ">= 0.0.0"},
      {:cloak, "~> 0.7.0"},
      {:gettext, "~> 0.11"},
      {:csv, "~> 2.0.0"},
      {:aes256, "~> 0.5.0"},
      {:sched_ex, "~> 1.0"},
      {:tesla, "~> 1.0.0"},
      {:timex, "~> 3.1"},
      {:plug_cowboy, "~> 2.0"},
      {:ex_twilio, "~> 0.6.0", runtime: false},
      {:ex_twiml, "~> 2.1.3"},
      {:rollbax, ">= 0.0.0"},
      {:ex_doc, "~> 0.18.0", only: :dev, runtime: false},
      {:earmark, "~> 1.2", only: :dev, runtime: false},
      {:mix_test_watch, "~> 0.6", only: [:dev, :test], runtime: false},
      {:distillery, "~> 2.0", runtime: false}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
