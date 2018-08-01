defmodule ExCourtbot.Mixfile do
  use Mix.Project

  def project do
    [
      app: :excourtbot,
      version: "0.0.1",
      elixir: "~> 1.6",
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
      mod: {ExCourtbot.Application, []},
      extra_applications: [:logger, :runtime_tools, :ex_twilio, :httpoison]
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
      {:phoenix, "~> 1.3.2"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_ecto, "~> 3.2"},
      {:postgrex, ">= 0.0.0"},
      {:cloak, "~> 0.6.2"},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:csv, "~> 2.0.0"},
      {:aes256, "~> 0.5.0"},
      {:sched_ex, "~> 1.0"},
      {:tesla, "~> 1.0.0"},
      {:timex, "~> 3.1"},
      {:ex_twilio, "~> 0.6.0"},
      {:ex_twiml, "~> 2.1.3"},
      {:ex_doc, "~> 0.18.0", only: :dev, runtime: false},
      {:earmark, "~> 1.2", only: :dev, runtime: false},
      {:mix_test_watch, "~> 0.6", only: :test, runtime: false},
      {:distillery, "~> 1.5", only: :prod, runtime: false},
      {:rollbax, ">= 0.0.0", only: :prod}
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
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end
end
