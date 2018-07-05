defmodule ExCourtbot.Application do
  use Application

  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(ExCourtbot.Repo, []),
      # Start the endpoint when the application starts
      supervisor(ExCourtbotWeb.Endpoint, []),
      # Start the schedule runners.
      %{ id: "import", start: {SchedEx, :run_every, [ExCourtbot, :import, [], Application.get_env(:excourtbot, :import_time, "0 9 * * *")]} },
      %{ id: "notify", start: {SchedEx, :run_every, [ExCourtbot, :notify, [], Application.get_env(:excourtbot, :notify_time, "0 13 * * *")]} },
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ExCourtbot.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ExCourtbotWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
