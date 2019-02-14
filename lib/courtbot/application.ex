defmodule Courtbot.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    # Define workers and child supervisors to be supervised
    children = [
      CourtbotWeb.Endpoint,
      Courtbot.Repo,
      {DynamicSupervisor, name: Courtbot.Bootstrap, strategy: :one_for_one},
    ]

    opts = [strategy: :one_for_one, name: Courtbot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    CourtbotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
